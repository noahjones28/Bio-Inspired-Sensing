function [distal_value, f_final] = get_distal_value(prox_target, tau_array, noise_vector)
    close all; 
    % Properties
    force_scale = 1;   % Typical force magnitude in N
    torque_scale = 0.1;   % Typical torque magnitude in Nm
    weight_vector = [1/torque_scale, 1/torque_scale, 1/torque_scale, ...
                     1/force_scale, 1/force_scale, 1/force_scale];
    weight_vector(1) = 0;  % Ignore first element completely
    % Normalize so all weights sum to 1
    weight_vector = weight_vector / sum(weight_vector);
    lb = [0.1, 0.01, 0, 0]; % Lower bounds for [F,s,el,az]
    ub = [1, 0.2, 2*pi, pi]; % Upper bounds for [F,s,el,az]
    N_limit = 2; % Limit on how many loads to check for
    N_start = 2; % number of loads to start checking for  
    plot_residual = true; % enable or disable the live plot
    plot_force = true; % enable or disable the live plot
    func_tol_target = 1e-12; % Target accuracy before stopping
    f_best = Inf; x_best = [];
    
    % Check if we have support measurements
    use_support = size(prox_target, 1) == 4;
    
    if nargin < 3   % if noise_vector not provided
        % do nothing
    else
        % Apply pre-generated noise directly (only to main measurement)
        if use_support
            prox_target(1,:) = prox_target(1,:) + noise_vector;
        else
            prox_target = prox_target + noise_vector;
        end
    end
    
    % Create figure for real-time residual
    if plot_residual
        fig = figure('Name', 'Optimization Progress', 'Position', [100, 100, 600, 400]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(N_limit); % distinct colors for each N
        plot_handles = gobjects(1, N_limit); % store a line handle per N
    end

    % Create figure for force plot
    if plot_force  % assuming this variable exists in your scope
        fig_handle = figure;
        set(fig_handle, 'Name', 'Force Optimization Progress');
    end
    
    % Optimization start
    for N = N_start:N_limit
        fprintf('\n=== Optimizing with N = %d forces ===\n', N);
        
        % Initialize plotting variables
        iteration_counter = 0;
        best_values = [];
        iterations = [];

        % Choose problem type
        if N == 1
            [x_final, f_final] = single_force_optimization();
        else
            [x_final, f_final] = multi_force_optimization();
        end

        % Check stopping criteria
        if f_final < f_best
            fprintf('New best solution found with N = %d (%.6e < %.6e)\n', N, f_final, f_best);
            f_best = f_final;
            x_best = x_final;
            if f_final < func_tol_target
                fprintf('Target function tolerance reached!')
                break;
            end
        else
            % no improvement adding more forces
            fprintf('No improvement with N = %d (%.6e >= %.6e)\n', N, f_final, f_best);
            fprintf('Keeping previous best solution with N = %d forces\n', N-1);
            N = N-1;
            break;
        end
    end
    
    % N_limit reached
    fprintf('\n\nFinal result: \nN = %d forces \nFinal objective func = %.6e \nx =\n', N, f_best);
    disp(x_final)
    distal_value = x_best;


    function [x_final, f_final] = single_force_optimization()
        % Finds [F, s, el] or [F_main, s, el, F_sup1, F_sup2, F_sup3]
       
        if use_support
            % Bounds: [F_main, s, el, F_sup1, F_sup2, F_sup3]
            lb_single = [0.1, 0.01, 0, 0.1, 0.1, 0.1];
            ub_single = [1, 0.2, 2*pi, 1, 1, 1];
        else
            % Bounds: [F, s, el]
            lb_single = [0.1, 0.01, 0];
            ub_single = [1, 0.2, 2*pi];
        end
        
        % Generate Sobol/space-filling start points
        max_starts = 5;
        start_points = get_space_filling_points(lb_single, ub_single, max_starts);
        custom_start_points = CustomStartPointSet(start_points);
        
        % Initial guess
        x0 = (lb_single + ub_single)/2;
        
        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @(x) residual_vec(x), ...
            'x0', x0, ...  % Initial guess (required but will be overridden)
            'lb', lb_single, ...
            'ub', ub_single, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'trust-region-reflective', ...
                'Display', 'off', ...
                'FunctionTolerance', 1e-4, ...
                'StepTolerance',1e-4, ...
                'FiniteDifferenceType', 'forward', ...
                'OutputFcn',@output_function)); ...

        
        % Create MultiStart object
        ms = MultiStart('Display', 'iter', ...
                        'UseParallel', false, ...
                        'StartPointsToRun', 'all');

        [x_final, resnorm, exitflag, output, solutions] = run(ms, problem, custom_start_points);
        
        % Extract main force parameters and add az
        if use_support
            x_final = [x_final(1:3), pi/2];
        else
            x_final = [x_final, pi/2];
        end
        
        % f_final is now the sum of squared residuals (resnorm)
        f_final = resnorm;  % lsqnonlin returns this directly

        fprintf('Single force optimization complete!\n')
        fprintf('Objective func = %.6e\n',f_final);
        fprintf('x =\n');
        disp(x_final)
    end

    function [x_final, f_final] = multi_force_optimization()
        % Finds [F1, s1, el1, F2, s2, el2] or
        % [F1_main, s1, el1, F2_main, s2, el2, F1_sup1, F2_sup1, F1_sup2, F2_sup2, F1_sup3, F2_sup3]
        
        if use_support
            % Bounds: main state [F1,s1,el1,F2,s2,el2] + 3 support states [F1,F2] each
            lb_multi = [0.1, 0.02, 0, 0.1, 0.02, 0, ...  % Main
                        0.1, 0.1, 0.1, 0.1, 0.1, 0.1];    % Support forces
            ub_multi = [1, 0.2, 2*pi, 1, 0.2, 2*pi, ...  % Main
                        1, 1, 1, 1, 1, 1];                % Support forces
        else
            % Bounds: [F1,s1,el1,F2,s2,el2]
            lb_multi = [0.1, 0.02, 0, 0.1, 0.02, 0];
            ub_multi = [1, 0.2, 2*pi, 1, 0.2, 2*pi];
        end
        
        % Initial guess
        jitter_frac = 5e-1;
        x0 = (lb_multi + ub_multi)/2 + jitter_frac*(ub_multi - lb_multi).*(2*rand(1, numel(lb_multi)) - 1);
        
        % Generate Sobol/space-filling start points
        max_starts = 10;
        start_points = get_space_filling_points(lb_multi, ub_multi, max_starts);
        custom_start_points = CustomStartPointSet(start_points);

        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @(x) residual_vec(x), ...
            'x0', x0, ...  % Initial guess (required but will be overridden)
            'lb', lb_multi, ...
            'ub', ub_multi, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'trust-region-reflective', ...
                'Display', 'off', ...
                'FunctionTolerance', 1e-6, ...
                'StepTolerance', 1e-6, ...
                'FiniteDifferenceStepSize',1e-3, ...
                'OutputFcn',@output_function)); ...
        
        % Create MultiStart object
        ms = MultiStart('Display', 'iter', ...
                        'UseParallel', false, ...
                        'StartPointsToRun', 'all');


        [x_final, resnorm, exitflag, output, solutions] = run(ms, problem, custom_start_points);

        % f_final is now the sum of squared residuals (resnorm)
        f_final = resnorm;

        % Extract just the main state [F1_main, s1, el1, F2_main, s2, el2]
        x_main = x_final(1:6);
        
        % Reshape to [F1, s1, el1, az1; F2, s2, el2, az2]
        x_final = reshape(x_main, 3, N)';
        x_final = [x_final, repmat(pi/2, N, 1)];
        
        % Sort forces based on s column (descending order)
        [~, idx] = sort(x_final(:,2), 'descend');
        x_final = x_final(idx, :);
        
        fprintf('Multi force optimization complete!\n')
        fprintf('Objective func = %.6e\n',f_final);
        fprintf('x =\n');
        disp(x_final)
    end
    
    function r = residual_vec(x)
        if ~use_support
            % Original behavior: single measurement
            if N > 1
                % if multi-contact reshape x from [F1, s1, el1, F2, s2, el2] to [F1, s1, el1, az1; F2, s2, el2, az2] 
                x = reshape(x,3,N)';  % makes it Nx3
                x = [x, repmat(pi/2, N, 1)];
            else
                x = [x, pi/2];  % Add az for single force
            end 
            y = get_proximal_value(x, tau_array);   % returns [Tx,Ty,Tz,Fx,Fy,Fz]
            r = weight_vector .* (y - prox_target);  % weighted residual vector
            r = r'; % transpose residual to column vector (lsqnonlin expects a column vector)
        else
            % Support measurements: separate forces but shared geometry
            % x = [F1_main, s1, el1, ..., FN_main, sN, elN, F1_sup1, ..., FN_sup1, F1_sup2, ..., FN_sup2, F1_sup3, ..., FN_sup3]
            
            % Extract main state (F, s, el for all N)
            x_main = x(1:3*N);
            if N > 1
                x_main = reshape(x_main, 3, N)';
                x_main = [x_main, repmat(pi/2, N, 1)];
            else
                x_main = [x_main, pi/2];  % Add az for single force
            end
            
            % Main measurement
            y_main = get_proximal_value(x_main, tau_array(1,:));
            r_main = weight_vector .* (y_main - prox_target(1,:));
            
            % Supporting measurements - share same s, el, but different F
            r_support = [];
            for i = 1:3
                % Extract support forces for this measurement
                F_support = x(3*N + (i-1)*N + 1 : 3*N + i*N);
                
                % Create support state with new forces but same geometry
                x_support = x_main;
                x_support(:,1) = F_support;  % Replace forces, keep s, el, az
                
                % Use corresponding row from tau_array
                y_support = get_proximal_value(x_support, tau_array(i+1,:));
                r_i = weight_vector .* (y_support - prox_target(i+1,:));
                r_support = [r_support, r_i];
            end
            
            % Combine all residuals (4 measurements × 6 DOF = 24 elements)
            r = [r_main, r_support]';
        end
    end

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
                update_plot();
            end
            
        end
    end

    function update_force_plot(x, fig_handle)
        % Extract main state only for plotting
        x_main = x(1:3*N);
        if N > 1
            x_main = reshape(x_main, 3, N)';
            x_main = [x_main, repmat(pi/2, N, 1)];
        else
            if use_support
                x_main = [x_main, pi/2];
            else
                x_main = [x, pi/2];
            end
        end
        
        % Get proximal values with plotting enabled (use main tau)
        if use_support
            y = get_proximal_value(x_main, tau_array(1,:), true, fig_handle);
        else
            y = get_proximal_value(x_main, tau_array, true, fig_handle);
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
    
    function points = get_space_filling_points(lb, ub, n_points)
        % Simple space-filling points using Sobol or fallback methods
        % Returns n_points x ndim matrix scaled to [lb, ub]
        
        ndim = numel(lb);
        
        % Try Sobol first (best option)
        if exist('sobolset', 'file')
            sob = sobolset(ndim, 'Skip', 1000);
            unit_points = net(sob, n_points);
        % Fallback to Latin Hypercube
        elseif exist('lhsdesign', 'file')
            unit_points = lhsdesign(n_points, ndim);
        % Last resort: stratified random
        else
            unit_points = (randperm(n_points)' - 0.5)/n_points * ones(1, ndim);
            unit_points = unit_points + rand(n_points, ndim)/n_points;
        end
        
        % Scale from [0,1] to bounds
        points = lb + unit_points .* (ub - lb);
    end

end