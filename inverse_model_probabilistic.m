function [distal_value, resnorm_final, confidence] = inverse_model_probabilistic(prox_target, tau_array, plot_enabled)
    close all;
    %% ABOUT
    % Input: Measured proximal wrench Wm = [Tx,Ty,Tz,Fx,Fy,Fz] (via ATI Mini40 IP65 6-axis
    % force-torque sensor) and measured tendon tensions τ = [τ1, τ2, τ3] (via load cells) 

    % Output:
    %   distal_value   : MAP estimate of external applied forces x = [F1,s1,theta1,F2,s2,theta2]
    %   resnorm_final  : residual norm at MAP (in sigma units)
    %   confidence     : struct with probabilistic diagnostics
    %       .top_weight      : posterior weight of MAP candidate (0-1)
    %       .effective_N     : effective number of competing solutions
    %       .posterior_mean  : weight-averaged estimate across all candidates
    %       .all_candidates  : all local minima (one per row)
    %       .all_weights     : posterior weight for each candidate
    %       .all_residuals   : residual norm for each candidate
    

    %% SETUP
    lb = [0.3, 0.02, 0, 0.3, 0.02, 0]; % Lower bounds for estimation of [F,s,theta]
    ub = [1.5, 0.2, 2*pi, 1.5, 0.2, 2*pi]; % Upper bounds for estimation of [F,s,theta]
    x_typical = (lb + ub) / 2;
    n_design_vars = length(ub); % Number of design variables
    n_global_samples = 5; % Number of LHS samples for global exploration (need many for posterior approx)
    iteration_counter = 0; % Initialize plotting variables
    best_values = [];
    iterations = [];
    % PER-CHANNEL NOISE STD from mismatch analysis (was range-based R = [1,1,1,60,20,20])
    % Weighting by 1/sigma makes the cost function proportional to negative log-likelihood
    % under Gaussian noise, i.e. maximum-likelihood estimation.
    sigma_channels = [0.004, 0.011, 0.012, 0.062, 0.137, 0.102];
    weight_vector = 1./sigma_channels; % Weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    min_sep = 0.02; % minimum allowable |s1 - s2|
    if nargin < 3
        plot_enabled = true; % default: plots on when called normally
    end
    
    if plot_enabled
        % Initialize live residual plot
        fig = figure('Name', 'Optimization Progress', 'Position', [0, 0, 960, 1080]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(size(prox_target,1)); % distinct colors for each N
        plot_handles = gobjects(1, size(prox_target,1)); % store a line handle per N
        
        % Initialize live force-visualization plot
        fig_handle = figure;
        set(fig_handle, 'Name', 'Force Optimization Progress');
    end
    

    %% MAIN
    % Run force optimization and get MAP estimate + probabilistic confidence info
    [x_final, f_final, conf] = force_optimization();
    fprintf('Force optimization complete!\n')
    fprintf('MAP estimate [F1, s1, θ1, F2, s2, θ2] =\n');
    disp(x_final)
    fprintf('Posterior mean [F1, s1, θ1, F2, s2, θ2] =\n');
    disp(conf.posterior_mean)
    fprintf('Final residual norm (sigma units) = %.6e\n', f_final);
    fprintf('Top posterior weight = %.3f\n', conf.top_weight);
    fprintf('Effective number of competing solutions = %.2f\n', conf.effective_N);
    fprintf('Total candidate solutions = %d\n', length(conf.all_residuals));
    distal_value = x_final;
    resnorm_final = f_final;
    confidence = conf;

    % Overlay ghost arrows showing posterior uncertainty across top-K candidates
    if plot_enabled && ishandle(fig_handle)
        overlay_ghost_arrows(conf, fig_handle);
    end


    %% OPTIMIZATION CONFIG
    function [x_final, f_final, conf] = force_optimization()
        rng(1234);
        lhs_samples = lhsdesign(n_global_samples, n_design_vars, 'Criterion', 'maximin', 'Iterations', 50);
        X_lhs = lb + lhs_samples .* (ub - lb);
    
        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @residual_vec, ...
            'x0', X_lhs(1,:), ...
            'lb', lb, ...
            'ub', ub, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'trust-region-reflective', ...
                'Display', 'off', ...
                'FunctionTolerance', 1e-8, ...
                'StepTolerance', 1e-8, ...
                'OptimalityTolerance', 1e-8, ...
                'MaxIterations', 50, ...
                'FiniteDifferenceType', 'forward', ...
                'TypicalX', x_typical, ...
                'OutputFcn', @output_function));
    
        % Feed all LHS points as custom start points
        startpts = CustomStartPointSet(X_lhs);
    
        % Run MultiStart, keeping all local solutions
        ms = MultiStart('Display', 'iter', 'UseParallel', false);
        [~, ~, ~, ~, allmins] = run(ms, problem, startpts);
    
        % Extract all solutions and their residuals
        all_x = arrayfun(@(m) m.X, allmins, 'UniformOutput', false);
        all_f = arrayfun(@(m) m.Fval, allmins);
        all_x = vertcat(all_x{:});
    
        % Filter by separation constraint
        separations = abs(all_x(:,2) - all_x(:,5));
        valid = separations >= min_sep;
    
        if any(valid)
            valid_x = all_x(valid, :);
            valid_f = all_f(valid);
        else
            warning('No solutions meet separation constraint. Using all solutions.');
            valid_x = all_x;
            valid_f = all_f;
        end

        % --- POSTERIOR WEIGHTING ---
        % Residuals are already in sigma units (because noise-weighted objective),
        % so likelihood of each candidate is exp(-0.5 * resnorm^2).
        % With uniform prior over bounds, posterior ∝ likelihood.
        log_weights = -0.5 * (valid_f.^2);
        log_weights = log_weights - max(log_weights); % numerical stability
        weights = exp(log_weights);
        weights = weights / sum(weights);

        % --- MAP ESTIMATE (lowest residual = highest weight) ---
        [f_final, best_idx] = min(valid_f);
        x_map = valid_x(best_idx, :);

        % --- POSTERIOR MEAN (weighted average across all candidates) ---
        x_mean = (weights(:)' * valid_x);

        % --- CONFIDENCE DIAGNOSTICS ---
        top_weight = max(weights);
        effective_N = 1 / sum(weights.^2);

        % Ensure force 1 is most distal in MAP estimate
        if x_map(2) < x_map(5)
            x_map = [x_map(4:6), x_map(1:3)];
        end

        % Also reorder posterior mean for consistency
        if x_mean(2) < x_mean(5)
            x_mean = [x_mean(4:6), x_mean(1:3)];
        end

        x_final = x_map;

        % Package confidence info
        conf = struct(...
            'top_weight', top_weight, ...
            'effective_N', effective_N, ...
            'posterior_mean', x_mean, ...
            'all_candidates', valid_x, ...
            'all_weights', weights, ...
            'all_residuals', valid_f);
    end


    %% RESIDUAL VECTOR
    function r = residual_vec(x)
        % Run estimated force through forward model to get simulated wrench
        y = forward_model([x(1:3);x(4:6)], tau_array(1,:));
        % Compare simulated wrench to measured wrench and weight by 1/sigma
        % (noise-weighted = maximum-likelihood under Gaussian noise)
        r = (weight_vector .* (y - prox_target))';

    end
    

    %% CUSTOM OUTPUT FUNCTION
    function stop = output_function(x, optimValues, state)
        % Initial condition
        stop = false;

        if strcmp(state, 'iter') % Each iteration
            % Update iteration count
            iteration_counter = iteration_counter + 1;
            iterations(end+1) = iteration_counter;

            % Get objective function value
            f = optimValues.resnorm; % For lsqnonlin, use resnorm 
            
            % Update best value
            if isempty(best_values)
                best_values(end+1) = f;
            else
                best_values(end+1) = min(best_values(end), f);
            end

            if plot_enabled
                if f == best_values(end) && ishandle(fig_handle)
                    %Update live force-visualization plot if there is a new best
                    update_force_plot(x, fig_handle);
                end
                % Update live residual plot
                update_residual_plot();
            end         
        end
    end
    

    %% UPDATE LIVE FORCE-VISUALIZATION PLOT
    function update_force_plot(x, fig_handle)
        % Run forward model with plotting enabled and pass fig_handle
        y = forward_model([x(1:3);x(4:6)], tau_array, true, fig_handle);
    end
    
    %% UPDATE LIVE RESIDUAL PLOT
    function update_residual_plot()
        % Update plot with current data
        if isempty(iterations), return; end
        y = max(best_values, realmin('double'));  % avoid log(0)

        % Create/update this N's line on the same log-y axes
        if ~isgraphics(plot_handles(1))
            plot_handles(1) = plot(ax, iterations, y, '.-', ...
                'LineWidth', 2, 'MarkerSize', 8, 'Color', colors(1,:));
        else
            set(plot_handles(1), 'XData', iterations, 'YData', y);
        end

        title(ax, sprintf('Best Objective Value: %.2e', y(end)));
        xlabel(ax, 'Iteration'); ylabel(ax, 'Best Objective Value');
        drawnow;
    end


    %% OVERLAY GHOST ARROWS (posterior uncertainty visualization)
    function overlay_ghost_arrows(conf_in, fig_h)
        % Draws top-K ghost arrows on the force-visualization figure with
        % opacity scaled to posterior weight. The MAP arrow (drawn by
        % forward_model during optimization) stays on top; ghosts show the
        % spread in F, s, theta across the posterior.
        %
        % NOTE: ghost arrow tails are placed at (s, 0, 0) on the undeformed
        % backbone as an approximation. For exact placement on the deformed
        % backbone, SoRoSim's FwdKinematics transform would need to be
        % evaluated at each candidate's (s1, s2) contact points.

        if ~ishandle(fig_h), return; end
        figure(fig_h);
        ax_list = findobj(fig_h, 'Type', 'axes');
        if isempty(ax_list), return; end
        ax_fig = ax_list(1);
        hold(ax_fig, 'on');

        top_k = 5;
        arrow_scale = 0.03; % m per N, for arrow-length visibility

        % Sort candidates by weight descending; skip index 1 (MAP already drawn)
        [sorted_w, sorted_idx] = sort(conf_in.all_weights, 'descend');
        n_ghosts = min(top_k, length(sorted_idx) - 1);

        % Color convention matching existing plot (magenta / cyan)
        force_colors = [1.0, 0.0, 1.0;   % Force 1: magenta
                        0.0, 1.0, 1.0];  % Force 2: cyan

        for i = 2:(n_ghosts + 1)
            idx = sorted_idx(i);
            x_cand = conf_in.all_candidates(idx, :);
            w = sorted_w(i);
            alpha = max(w, 0.1); % clamp so very low-weight ghosts stay faintly visible

            for f = 1:2
                F_mag = x_cand(3*(f-1) + 1);
                s_pos = x_cand(3*(f-1) + 2);
                theta = x_cand(3*(f-1) + 3);

                tail = [s_pos, 0, 0];
                tip  = tail + F_mag * arrow_scale * [0, cos(theta), sin(theta)];

                color_rgba = [force_colors(f, :), alpha];

                plot3(ax_fig, [tail(1), tip(1)], [tail(2), tip(2)], [tail(3), tip(3)], ...
                    '-', 'LineWidth', 1.5, 'Color', color_rgba);

                plot3(ax_fig, tail(1), tail(2), tail(3), 'o', ...
                    'MarkerSize', 4, 'MarkerFaceColor', force_colors(f, :), ...
                    'MarkerEdgeColor', 'none', 'Color', color_rgba);
            end
        end

        drawnow;
    end
end