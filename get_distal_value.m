function [distal_value, resnorm_final] = get_distal_value(prox_target, tau_array)
    close all; 
    
    %% Setup
    % Properties
    lb = [0.05, 0.01, 0]; % Lower bounds for estimation of [F,s,theta1]
    ub = [2, 0.2, 2*pi]; % Upper bounds for estimation of [F,s,theta1]
    plot_residual = true; % enable or disable the live plot
    plot_force = true; % enable or disable the live plot
    iteration_counter = 0; % Initialize plotting variables
    best_values = [];
    iterations = [];

    % Weightings and Normalization
    force_scale = 1;   % Typical force magnitude in N
    torque_scale = 0.1;   % Typical torque magnitude in Nm
    weight_vector = [0, 1/torque_scale, 1/torque_scale, 1/force_scale, 0, 0]; % Weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    weight_vector = weight_vector / sum(weight_vector); % Normalize so all weights sum to 1
    
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
    fprintf('[F, s, θ1] = ');
    disp(x_final)
    fprintf('Final residual norm = %.6e\n',f_final);
    distal_value = x_final;
    resnorm_final = f_final;


    %% Optimization Configuration
    function [x_final, f_final] = single_force_optimization()
        % Generate Sobol/space-filling start points
        n_starts = 1; % Number of random starting points
        start_points = get_space_filling_points(lb, ub, n_starts);
        custom_start_points = CustomStartPointSet(start_points);
        
        % Initial guess
        x0 = (lb + ub)/2;
        
        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @(x) residual_vec(x), ...
            'x0', x0, ...  % Initial guess (required but will be overridden)
            'lb', lb, ...
            'ub', ub, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'trust-region-reflective', ...
                'Display', 'off', ...
                'FunctionTolerance', 1e-10, ...
                'StepTolerance',1e-10, ...
                'FiniteDifferenceType', 'forward', ...
                'OutputFcn',@output_function)); ...
        
        % Create MultiStart object
        ms = MultiStart('Display', 'iter', ...
                        'UseParallel', false, ...
                        'StartPointsToRun', 'all');

        [x_final, resnorm, exitflag, output, solutions] = run(ms, problem, custom_start_points);
        
        % f_final is now the sum of squared residuals (resnorm)
        f_final = resnorm;  % lsqnonlin returns this directly
    end
    
    %% Residual
    function r = residual_vec(x)
        y = get_proximal_value(x, tau_array(1,:));   % returns [Tx,Ty,Tz,Fx,Fy,Fz]
        r = weight_vector .* (y - prox_target);  % weighted residual vector
        r = r'; % transpose residual to column vector (lsqnonlin expects a column vector)
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
        % Get proximal values with plotting enabled
        y = get_proximal_value(x, tau_array, true, fig_handle);
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