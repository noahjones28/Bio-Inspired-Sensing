function distal_value = get_distal_value(prox_target, varargin)
    close all; 
    % Properties
    weight_vector = [1, 1, 1, 1, 1, 1]; % Set weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    uncertainties_vector = [1e-2, 1e-2, 1e-2, 1e-2, 1e-2, 1e-2]; % Set uncertianties for [Tx,Ty,Tz,Fx,Fy,Fz]
    lb_single = [0.05, 0.05, 0]; % Lower bounds for [F,s,el]
    ub_single = [1, 0.2, 2*pi]; % Upper bounds for [F,s,el]
    az_default = pi/2; % Default azimuth angle
    N_limit = 1; % Limit on how many loads to check for
    plot_progress = true; % enable or disable the live plot
    tau = prox_target(end); % Split off tau
    prox_target = prox_target(1:end-1);
    func_tol_target = 1e-12; % Target accuracy before stopping
    f_best = Inf; x_best = [];
    uncertainty = false;
    
    % Optional simulate uncertianty
    if uncertainty
        noise = uncertainties_vector .* randn(size(prox_target));
        prox_target = prox_target + noise; % Use noisy target
    end

    % Create figure for real-time plotting
    if plot_progress
        fig = figure('Name', 'Optimization Progress', 'Position', [100, 100, 600, 400]);
        ax  = axes('Parent', fig);        % explicit axes
        set(ax,'YScale','log');           % force semilog-y
        grid(ax,'on'); box(ax,'on'); hold(ax,'on');
        colors = lines(N_limit); % distinct colors for each N
        plot_handles = gobjects(1, N_limit); % store a line handle per N
    end
    
    % Optimization start
    for N = 1:N_limit
        fprintf('\n=== Optimizing with N = %d forces ===\n', N);
        
        % Initialize plotting variables
        iteration_counter = 0;
        best_values = [];
        iterations = [];

        % Bounds
        lb = repmat(lb_single, 1, N); % lower bound
        ub = repmat(ub_single, 1, N); % upper bound
        x0 = (lb + ub)/2; % initial guess
        
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
        % Finds [F, s, el] for a single force
       
        % Generate Sobol/space-filling start points
        max_starts = 3;
        start_points = get_space_filling_points(lb, ub, max_starts);
        custom_start_points = CustomStartPointSet(start_points);
        
        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @(x) residual_vec(x), ...
            'x0', x0, ...  % Initial guess (required but will be overridden)
            'lb', lb, ...
            'ub', ub, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'levenberg-marquardt', ...
                'Display', 'off', ...
                'MaxIterations',20,...
                'FiniteDifferenceType', 'forward', ...
                'OutputFcn',@output_function)); ...

        
        % Create MultiStart object
        ms = MultiStart('Display', 'iter', ...
                        'UseParallel', false, ...
                        'OutputFcn', @stopWhenBelow, ...
                        'StartPointsToRun', 'all');


        [x_final, resnorm, exitflag, output, solutions] = run(ms, problem, custom_start_points);

        % f_final is now the sum of squared residuals (resnorm)
        f_final = resnorm;  % lsqnonlin returns this directly

        % x_final: [F, s, el]
        % Reshape x_final to [F, s, el, az, tau]
        x_final = [x_final, az_default, tau];
        fprintf('Single force optimization complete!\n')
        fprintf('Objective func = %.6e\n',f_final);
        fprintf('x =\n');
        disp(x_final)
    end

    function [x_final, f_final] = multi_force_optimization()
        % Finds [F1, s1, el1, F2, s2, el2] for two point forces
      
        lb = repmat(lb_single, 1, N); % lower bound [F1,s1,el1,F2,s2,el2...]
        ub = repmat(ub_single, 1, N); % upper bound [F1,s1,el1,F2,s2,el2...]
        jitter_frac = 5e-1;
        x0 = (lb + ub)/2 + jitter_frac*(ub - lb).*(2*rand(1, numel(lb)) - 1); % initial guess
        
        % Generate Sobol/space-filling start points
        max_starts = 20;
        start_points = get_space_filling_points(lb, ub, max_starts);
        custom_start_points = CustomStartPointSet(start_points);

        % Create optimization problem
        problem = createOptimProblem('lsqnonlin', ...
            'objective', @(x) residual_vec(x), ...
            'x0', x0, ...  % Initial guess (required but will be overridden)
            'lb', lb, ...
            'ub', ub, ...
            'options', optimoptions('lsqnonlin', ...
                'Algorithm', 'trust-region-reflective', ...
                'Display', 'off', ...
                'MaxIterations',30, ...
                'OutputFcn',@output_function)); ...
        
        % Create MultiStart object
        ms = MultiStart('Display', 'iter', ...
                        'UseParallel', false, ...
                        'MaxTime', 120, ...
                        'OutputFcn', @stopWhenBelow, ...
                        'StartPointsToRun', 'all');


        [x_final, resnorm, exitflag, output, solutions] = run(ms, problem, custom_start_points);

        % f_final is now the sum of squared residuals (resnorm)
        f_final = resnorm;  % lsqnonlin returns this directly

        % x_final: [F1, s1, el1, F2, s2, el2]    
        % Reshape x_final to [F1, s1, el1, az1, tau1; F2, s2, el2, az2, tau2]
        x_final = reshape(x_final,3,N).';  % makes it Nx3
        x_final = [x_final, repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        fprintf('Multi force optimization complete!\n')
        fprintf('Objective func = %.6e\n',f_final);
        fprintf('x =\n');
        disp(x_final)
    end
    
    function r = residual_vec(x)
        if N == 1
            % x: [F, s, el]
            % Reshape x to [F, s, el, az, tau]
            X = [x az_default, tau]; 
        else
            % x: [F1, s1, el1, F2, s2, el2]    
            % Reshape x to [F1, s1, el1, az1, tau1; F2, s2, el2, az2, tau2]
            x = reshape(x,3,N).';  % makes it Nx3
            X = [x, repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        end 
        y = get_proximal_value(X);   % returns [Tx,Ty,Tz,Fx,Fy,Fz,tau]
        y = y(1:end-1); % Pop out tau for residual computation
        r = weight_vector .* (y - prox_target);  % weighted residual vector
        r = r'; % transpose residual to column vector (lsqnonlin expects a column vector) 
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
          
            % Update plot
            if plot_progress
                update_plot();
            end
        end
    end
    
    function stop = stopWhenBelow(optimValues, state)
        stop = false;
        if strcmp(state,'iter')  % runs after each local solver call
            if optimValues.localsolution.Exitflag > 0 ...
               && optimValues.localsolution.Fval <= 1e-12
                stop = true;  % halt MultiStart
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