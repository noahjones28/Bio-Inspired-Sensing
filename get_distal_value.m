function [distal_value, resnorm_final] = get_distal_value(prox_target, tau_array)
    close all; 
    
    %% Setup
    % Properties
    lb = [0.1, 0.02, 0, 0.1, 0.02, 0]; % Lower bounds for estimation of [F,s,theta1]
    ub = [1, 0.2, 2*pi, 1, 0.2, 2*pi]; % Upper bounds for estimation of [F,s,theta1]
    plot_residual = true; % enable or disable the live plot
    plot_force = true; % enable or disable the live plot
    do_offset_correction = false; % apply offset correction to raw data if needed
    sensor_offset = 90e-3; %Adjust the offset between the 6axis f/t sensor and the beam base
    n_perturbations = size(prox_target, 1)-1;
    iteration_counter = 0; % Initialize plotting variables
    best_values = [];
    iterations = [];

    % Weightings and Normalization
    force_scale = 1;   % Typical force magnitude in N
    torque_scale = 0.1;   % Typical torque magnitude in Nm
    weight_vector = [1/torque_scale, 1/torque_scale, 1/torque_scale, 1/force_scale, 1/force_scale, 1/force_scale]; % Weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    channel_filter = [1, 1, 1, 1, 1, 1]; % Use only Ty, Tz, Fx

    % Offset correction
    if do_offset_correction && sensor_offset > 0
        prox_target(:,2) = prox_target(:,2)+sensor_offset*prox_target(:,6); % Ty_base = Ty_sensor+sensor_offset*Fz_sensor
        prox_target(:,3) = prox_target(:,3)-sensor_offset*prox_target(:,5); % Tz_base = Tz_sensor-sensor_offset*Fy_sensor
    end
    
    % Check if we have support measurements 
    use_support = n_perturbations > 0;
    
    % Create figure for real-time residual
    if plot_residual
        fig = figure('Name', 'Optimization Progress', 'Position', [100, 100, 600, 400]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(size(prox_target,1)); % distinct colors for each N
        plot_handles = gobjects(1, size(prox_target,1)); % store a line handle per N
    end

    % Create figure for force plot
    if plot_force  % assuming this variable exists in your scope
        fig_handle = figure;
        set(fig_handle, 'Name', 'Force Optimization Progress');
    end
    
    %% Optimization Run
    [x_final, f_final] = single_force_optimization();

    fprintf('Force optimization complete!\n')
    fprintf('[F1, s1, θ1, F2, s2, θ2] =\n');
    disp(x_final)
    fprintf('Final residual norm = %.6e\n',f_final);
    distal_value = x_final;
    resnorm_final = f_final;


    %% Optimization Configuration
    function [x_final, f_final] = single_force_optimization()
        if use_support
            % Append the first element F to the back n_perturbations times
            lb = [lb, repmat(lb(1), 1, n_perturbations)];
            ub = [ub, repmat(ub(1), 1, n_perturbations)];
        end
        
        n_vars = length(lb);
        
        %% Stage 1: Latin Hypercube Sampling (Global Exploration)
        n_samples = 400;
        rng(1234);  % For reproducibility
        
        % Generate LHS samples in [0, 1]^n
        lhs_samples = lhsdesign(n_samples, n_vars);
        
        % Scale to actual bounds
        X_lhs = lb + lhs_samples .* (ub - lb);
        
        % Evaluate objective on all samples
        residuals = zeros(n_samples, 1);
        for i = 1:n_samples
            r = residual_vec(X_lhs(i, :));
            residuals(i) = sum(r.^2);  % Sum of squared residuals
        end
        
        %% Stage 2: Select Top K Candidates
        K = 10;  % Number of top candidates (between 10-20)
        [~, sorted_idx] = sort(residuals, 'ascend');
        top_k_idx = sorted_idx(1:K);
        start_points = X_lhs(top_k_idx, :);
        
        %% Stage 3: MultiStart Least Squares
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
        
        %% Post-processing
        % Remove supporting measurements from x_final
        x_final = x_final(1:end - n_perturbations);
        
        % Wrap theta values to [0, 2*pi]
        x_final(3) = mod(x_final(3), 2*pi);
        x_final(6) = mod(x_final(6), 2*pi);
        
        % Ensure force 1 is most distal force
        if x_final(2) < x_final(5)
            x_final = [x_final(4:end), x_final(1:3)];
        end
    end
    
    function r = residual_vec(x)
        if ~use_support
            % Simple mode: weighted residual
            y = get_proximal_value([x(1:3);x(4:6)], tau_array(1,:));
            r = (weight_vector .* (y - prox_target))';
            return;
        end
        
        % Extract baseline parameters and compute baseline wrench
        x_base = x(1:3);  % [F, s, theta]
        y_base = get_proximal_value(x_base, tau_array(1,:));
        
        % Magnitude residual (force scale)
        r_main_mag = norm(channel_filter .* y_base) - ...
                norm(channel_filter .* prox_target(1,:));

        
        % ΔW residuals for each perturbation
        r_perturbation_dirs = [];
        for i = 1:n_perturbations
            % Compute perturbed wrench
            x_perturb = [x(3+i), x_base(2:3)];  % [Fi, s, theta]
            y_perturb = get_proximal_value(x_perturb, tau_array(i+1,:));
            
            % Compute and normalize ΔW
            delta_pred = weight_vector .* (y_perturb - y_base);
            delta_meas = weight_vector .* (prox_target(i+1,:) - prox_target(1,:));

            % Compute norms
            delta_pred_norm = max(norm(delta_pred), 1e-12);
            delta_meas_norm = max(norm(delta_meas), 1e-12);
         
            % Direction of ΔW (normalized)
            delta_pred_noralized = delta_pred / delta_pred_norm;
            delta_meas_normalized = delta_meas / delta_meas_norm;
            perturbation_dir = delta_pred_noralized - delta_meas_normalized; 
            r_perturbation_dirs = [r_perturbation_dirs, perturbation_dir];
        end
        
        % Weighting
        A = 0.3;  % magnitude
        B = 1.0;  % ΔW direction
 
        r = [A*r_main_mag, B*r_perturbation_dirs]';
    end
    
    %% Output functions
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

            % Update plot with current force configuration if new best
            if plot_force
                if f == best_values(end) && ishandle(fig_handle)
                    update_force_plot(x, fig_handle);
                end
            end
          
            % Update residual plot
            if plot_residual
                update_residual_plot();
            end 
        end
    end
    
    function update_force_plot(x, fig_handle)
        % Wrap theta values to [0, 2*pi]
        x(3) = mod(x(3), 2*pi);
        x(6) = mod(x(6), 2*pi);
        % Get proximal values with plotting enabled
        if ~use_support
            y = get_proximal_value([x(1:3);x(4:6)], tau_array, true, fig_handle);
        else
            y = get_proximal_value(x(1:3), tau_array(1,:), true, fig_handle);
        end
    end
    
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
