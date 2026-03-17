function [distal_value, resnorm_final] = inverse_model(prox_target, tau_array, plot_enabled)
    close all;
    %% ABOUT
    % Input: Measured proximal wrench Wm = [Tx,Ty,Tz,Fx,Fy,Fz] (via ATI Mini40 IP65 6-axis
    % force-torque sensor) and measured tendon tensions τ = [τ1, τ2, τ3] (via load cells) 

    % Output: Estimated external applied forces x = [F1,s1,theta1;...FN,sN,thetaN]
    

    %% SETUP
    lb = [0.3, 0.02, 0, 0.3, 0.02, 0]; % Lower bounds for estimation of [F,s,theta]
    ub = [1.5, 0.2, 2*pi, 1.5, 0.2, 2*pi]; % Upper bounds for estimation of [F,s,theta]
    x_typical = (lb + ub) / 2;
    n_design_vars = length(ub); % Number of design variables
    n_global_samples = 1; % Number of LHS samples for global exploration 
    iteration_counter = 0; % Initialize plotting variables
    best_values = [];
    iterations = [];
    % SENSING RANGES from ATI spec sheet 
    R = [1, 1, 1, 60, 20, 20];
    weight_vector = 1./R; % Weights for [Tx,Ty,Tz,Fx,Fy,Fz]
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
    % Run force optimization and get solution x_final and renorm f_final
    [x_final, f_final] = force_optimization();
    fprintf('Force optimization complete!\n')
    fprintf('[F1, s1, θ1, F2, s2, θ2] =\n');
    disp(x_final)
    fprintf('Final residual norm = %.6e\n',f_final);
    distal_value = x_final;
    resnorm_final = f_final;


    %% OPTIMIZATION CONFIG
    function [x_final, f_final] = force_optimization()
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
            [f_final, best_idx] = min(all_f(valid));
            valid_x = all_x(valid, :);
            x_final = valid_x(best_idx, :);
        else
            warning('No solutions meet separation constraint. Returning overall best.');
            [f_final, best_idx] = min(all_f);
            x_final = all_x(best_idx, :);
        end
    
        % Ensure force 1 is most distal
        if x_final(2) < x_final(5)
            x_final = [x_final(4:end), x_final(1:3)];
        end
    end


    %% RESIDUAL VECTOR
    function r = residual_vec(x)
        % Run estimated force through forward model to get simulated wrench
        y = forward_model([x(1:3);x(4:6)], tau_array(1,:));
        % Compare simulated wrench to measured wrench and weight
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
end
