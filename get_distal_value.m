function distal_value = get_distal_value(proximal_value_target, varargin)
    close all;  
    % Properties
    weight_vector = [1, 1, 1, 1, 1, 1]; % Set weights for [Fx,Fy,Fz,Tx,Ty,Tz]
    lb_single = [0.05, 0.075, 0, 0]; % Lower bounds for [F,s,sigma,el]
    ub_single = [1, 0.2, 0.05, 2*pi]; % Upper bounds for [F,s,sigma,el]
    az_default = pi/2; % Default azimuth angle
    num_columns = numel(lb_single); % num of distal-end deisgn variables [F, s, sigma, el] 
    N_limit = 2; % Limit on how many loads to check for
    plot_progress = true; % enable or disable the live plot
    
    % Split off tau
    tau = proximal_value_target(end);
    proximal_value_target = proximal_value_target(1:end-1);

    % Create figure for real-time plotting
    if plot_progress
        fig = figure('Name', 'Optimization Progress', 'Position', [100, 100, 600, 400]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(N_limit); % distinct colors for each N
        plot_handles = gobjects(1, N_limit); % store a line handle per N
    end
    
    best_fval = Inf; best_x = [];
    for N = 1:N_limit
        fprintf('\n=== Optimizing with N = %d forces ===\n', N);
        % Initialize plotting variables
        iteration_counter = 0;
        best_values = [];
        iterations = [];
        
        % Set up bounds for N forces
        lb = repmat(lb_single, 1, N);
        ub = repmat(ub_single, 1, N);
        
        % Define objective function for current N
        objfun = @(x) objective_func(x);

        % SQP Optimization 
        options_fmincon = optimoptions('fmincon', ...
            'Algorithm', 'sqp', ... % Often more robust than interior-point
            'Display', 'iter', ...
            'MaxFunctionEvaluations', 2400, ...
            'OptimalityTolerance', 1e-8, ... % Less strict
            'StepTolerance', 1e-12, ...
            'FiniteDifferenceStepSize', 1e-3, ... % Larger step size
            'FiniteDifferenceType', 'central', ...
            'UseParallel', true, ...
            'OutputFcn', @early_stop_function);
        
        [x_final, fval] = fmincon(objfun, x0, [], [], [], [], lb, ub, [], options_fmincon);
        
        % Reshape to [F, s, sigma, el, az, tau]
        x_final = [reshape(x_final, num_columns, [])', repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        fprintf('N = %d: Final objective value = %.6e, Final x =\n', N, fval);
        disp(x_final)
        
        % Check stopping criteria
        if fval < function_tolerance
            fprintf('Function tolerance (%.1e) reached with N = %d forces!\n', function_tolerance, N);
            best_fval = fval;
            best_x = x_final;
            break;
        elseif fval < best_fval
            fprintf('Improvement found with N = %d (%.6e < %.6e)\n', N, fval, best_fval);
            best_fval = fval;
            best_x = x_final;
            if N < N_limit
                N = N + 1; % Try with more forces if limit not reached
            else
                fprintf('N_limit reached with N = %d forces!\n', N);
                break;
            end
        else
            fprintf('No improvement with N = %d (%.6e >= %.6e)\n', N, fval, best_fval);
            fprintf('Keeping previous best result with N = %d forces\n', N-1);
            N = N-1;
            break;
        end
            
        % Safety check to prevent infinite loop
        if N > 10 % Adjust this limit as needed
            fprintf('Maximum number of forces (10) reached. Stopping.\n');
            break;
        end
    end
    
    fprintf('\nFinal result: N = %d forces, objective value = %.6e, x =\n', N, best_fval);
    distal_value = best_x;
    
    function obj_val = objective_func(x)
        % Objective function for N forces
        % Reshape to [F, s, sigma, el, az, tau]
        x = [reshape(x, num_columns, [])', repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        % Calculate proximal values using forward model with N forces
        result = get_proximal_value(x);
        result = result(1:end-1); % ignore last element tau
        
        % Compute L2 norm of error vector
        error_vec = result - proximal_value_target;
        weighted_error_vec = error_vec.* weight_vector;
        obj_val = norm(weighted_error_vec)^2; % squared L2 norm
    end
    
    function stop = early_stop_function(x, optimValues, state)
        % Define stopping function with plotting for local optimization
        stop = false;
        
        if strcmp(state, 'iter')
            % Update plot data for local optimization
            iteration_counter = iteration_counter + 1;
            iterations(end+1) = iteration_counter;
            if isempty(best_values)
                best_values(end+1) = optimValues.fval;
            else
                best_values(end+1) = min(best_values(end), optimValues.fval);
            end
            
            % Update plot
            if plot_progress
                update_plot();
            end
            
            % Check stopping criteria
            if optimValues.fval < function_tolerance
                stop = true;
                fprintf('Stopping early: f(x) = %.2e < %.2e\n', optimValues.fval, function_tolerance);
            end
        end
    end
    
    function update_plot()
        % Update plot with current data
        if isempty(iterations), return; end
        y = max(best_values, realmin('double'));  % avoid log(0)

        % Create/update this N's line on the same log-y axes
        if ~isgraphics(plot_handles(N))
            plot_handles(N) = plot(ax, iterations, y, '.-', ...
                'LineWidth', 2, 'MarkerSize', 8, 'Color', colors(N,:));
        else
            set(plot_handles(N), 'XData', iterations, 'YData', y);
        end

        title(ax, sprintf('Best Objective Value: %.2e (N=%d)', y(end), N));
        xlabel(ax, 'Iteration'); ylabel(ax, 'Best Objective Value');
        
        
        drawn = find(isgraphics(plot_handles));
        legend(ax, plot_handles(drawn), ...
            arrayfun(@(k) sprintf('N = %d', k), drawn, 'UniformOutput', false), ...
            'Location','northeast');
        drawnow;
    end
end