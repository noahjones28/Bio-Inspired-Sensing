function [distal_value, resnorm_final] = inverse_model(prox_target, tau_array)
    close all;
    %% ABOUT
    % Input: Measured proximal wrench Wm = [Tx,Ty,Tz,Fx,Fy,Fz] (via ATI Mini40 IP65 6-axis
    % force-torque sensor) and measured tendon tensions τ = [τ1, τ2, τ3] (via load cells) 

    % Output: Estimated external applied forces x = [F1,s1,theta1;...FN,sN,thetaN]
    

    %% SETUP
    lb = [0.1, 0.02, 0, 0.1, 0.02, 0]; % Lower bounds for estimation of [F,s,theta]
    ub = [1, 0.2, 2*pi, 1, 0.2, 2*pi]; % Upper bounds for estimation of [F,s,theta]
    n_design_vars = length(ub); % Number of design variables
    plot_residual = true; % Enable or disable the live residual plot
    plot_force = true; % Enable or disable the live force-visualization plot
    simulation = true; % Set to 'false' if using empirical measurements, 'true' if running a simulation.
    sensor_offset = 90e-3; % Adjust the offset between the 6axis f/t sensor and the beam base
    n_global_samples = 400; % Number of LHS samples for global exploration 
    n_start_points = 5;  % Number of top candidate start points to refine (must be less than n_global_samples)
    iteration_counter = 0; % Initialize plotting variables
    best_values = [];
    iterations = [];

    if ~simulation
        % Apply offset correction to raw data)
        if sensor_offset > 0
            prox_target(:,2) = prox_target(:,2)+sensor_offset*prox_target(:,6); % Ty_base = Ty_sensor+sensor_offset*Fz_sensor
            prox_target(:,3) = prox_target(:,3)-sensor_offset*prox_target(:,5); % Tz_base = Tz_sensor-sensor_offset*Fy_sensor
        end
        
        % Residual Weighting: Residuals are weighted to reduce the influence
        % of noisy measurements and prioritize reliable ones. 
        % Noise-Based Scaling: Each output wrench component is scaled by the
        % inverse of it's error standard deviation, σ_error.
        sigma_error = [0.005, 0.01598, 0.01215,	0.06838, 0.06938, 0.09147];
        weight_vector = 1./sigma_error;
    else
        % Weightings for simulation
        force_scale = 1;   % Typical force magnitude in N
        torque_scale = 0.1;   % Typical torque magnitude in Nm
        weight_vector = [1/torque_scale, 1/torque_scale, 1/torque_scale, 1/force_scale, 1/force_scale, 1/force_scale]; % Weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    end
    
    % Initialize live residual plot
    if plot_residual
        fig = figure('Name', 'Optimization Progress', 'Position', [100, 100, 600, 400]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(size(prox_target,1)); % distinct colors for each N
        plot_handles = gobjects(1, size(prox_target,1)); % store a line handle per N
    end

    % Initialize live force-visualization plot
    if plot_force  % assuming this variable exists in your scope
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
        %% STAGE 1: LATIN HYPERCUBE SAMPLING (GLOBAL EXPLORATION) 
        % Fixed seed for reproducibility 
        rng(1234);
        % Generate LHS samples
        lhs_samples = lhsdesign(n_global_samples, n_design_vars);
        % Scale to actual bounds
        X_lhs = lb + lhs_samples .* (ub - lb);
        % Evaluate objective on all samples
        residuals = zeros(n_global_samples, 1);
        for i = 1:n_global_samples
            r = residual_vec(X_lhs(i, :));
            residuals(i) = sum(r.^2);  % Sum of squared residuals
        end
        
        % Select top K candidates
        K = n_start_points;
        [~, sorted_idx] = sort(residuals, 'ascend');
        top_k_idx = sorted_idx(1:K);
        start_points = X_lhs(top_k_idx, :);
        

        %% STAGE 2: MULTISTART NON-LINEAR LEAST SQUARES REFINEMENT
        % Configure lsqnonlin options
        lsq_options = optimoptions('lsqnonlin', ...
            'Algorithm', 'trust-region-reflective', ...
            'Display', 'off', ...
            'FunctionTolerance', 1e-8, ...
            'StepTolerance', 1e-8, ...
            'OptimalityTolerance', 1e-10, ...
            'MaxIterations', 50, ...
            'FiniteDifferenceType', 'forward', ...
            'OutputFcn', @output_function);
        
        % Create optimization problem for MultiStart
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @residual_vec, ...
            'x0', start_points(1, :), ...
            'lb', lb, ...
            'ub', ub, ...
            'options', lsq_options);
        
        % Create custom start points from LHS top-K
        custom_starts = CustomStartPointSet(start_points);
        
        % Configure MultiStart
        ms = MultiStart('Display', 'iter', ...
            'UseParallel', false, ...
            'StartPointsToRun', 'all');
        
        % Run MultiStart with custom start points
        [x_final, f_final] = run(ms, problem, custom_starts);
        
        % Ensure force 1 is most distal force
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

            % Update live force-visualization plot if there is a new best
            if plot_force
                if f == best_values(end) && ishandle(fig_handle)
                    update_force_plot(x, fig_handle);
                end
            end
          
            % Update live residual plot
            if plot_residual
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
