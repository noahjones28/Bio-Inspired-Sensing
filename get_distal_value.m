function distal_value = get_distal_value(proximal_value_target, varargin)
    close all;  
    % Properties
    weight_vector = [1, 1, 1, 1, 1, 1]; % Set weights for [Tx,Ty,Tz,Fx,Fy,Fz]
    lb_single = [0.05, 0.075, 0, 0]; % Lower bounds for [F,s,sigma,el]
    ub_single = [1, 0.2, 0.02, 2*pi]; % Upper bounds for [F,s,sigma,el]
    az_default = pi/2; % Default azimuth angle
    num_columns = numel(lb_single); % num of distal-end deisgn variables [F, s, sigma, el] 
    N_limit = 1; % Limit on how many loads to check for
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
    
    f_best = Inf; x_best = [];
    for N = 1:N_limit
        fprintf('\n=== Optimizing with N = %d forces ===\n', N);
        % Initialize plotting variables
        iteration_counter = 0;
        best_values = [];
        iterations = [];
        
        lb = repmat(lb_single, 1, N);     % column
        ub = repmat(ub_single, 1, N);     % column
        jitter_frac = 1e-2;
        x0 = (lb + ub)/2 + jitter_frac*(ub - lb).*(2*rand(1, numel(lb)) - 1);
        
        % residual vector
        resfun = @(x) residual_vec(x, N, num_columns, az_default, tau, proximal_value_target, weight_vector);
        % Objective function
        objfun = @(x) sum(residual_vec(x, N, num_columns, az_default, tau, proximal_value_target, weight_vector).^2);

        % SQP Optimization 
        options_fmincon = optimoptions('fmincon', ...
        'Algorithm', 'interior-point', ... % Often more robust than interior-point
            'Display', 'iter', ...
            'MaxFunctionEvaluations', 3000, ...
            'OptimalityTolerance', 1e-8, ... % Less strict
            'StepTolerance', 1e-12, ... % Less strict
            'FiniteDifferenceType', 'forward', ...
            'UseParallel', true, ...
            'OutputFcn', @output_function, ...
            'Display', 'iter');
    
        [x_final, f_final] = fmincon(objfun, x0, [], [], [], [], lb, ub, [], options_fmincon);

        % Reshape to [F, s, sigma, el, az, tau]
        x_final = [reshape(x_final, num_columns, [])', repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        fprintf('N = %d: Final objective value = %.6e, Final x =\n', N, f_final);
        disp(x_final)
        
        % Check stopping criteria
        if f_final < f_best
            fprintf('Improvement found with N = %d (%.6e < %.6e)\n', N, f_final, f_best);
            f_best = f_final;
            x_best = x_final;
        else
            % no improvement adding more forces
            fprintf('No improvement with N = %d (%.6e >= %.6e)\n', N, f_final, f_best);
            fprintf('Keeping previous best result with N = %d forces\n', N-1);
            N = N-1;
            break;
        end
    end
    
    fprintf('\nFinal result: N = %d forces, objective value = %.6e, x =\n', N, f_best);
    disp(x_final)
    distal_value = x_best;
    
    function r = residual_vec(x, N, num_columns, az_default, tau, prox_target, w)
        % Reshape to [F, s, sigma, el, az, tau;
        %               F, s, sigma, el, az, tau ...]
        X = [reshape(x, num_columns, [])', repmat(az_default, N, 1), repmat(tau, N, 1)]; 
        y = get_proximal_value(X);   % returns [Fx,Fy,Fz,Tx,Ty,Tz,tau]
        y = y(1:end-1); % Pop out tau for residual computation
        r = w .* (y - prox_target);  % residual vector
        r = r'; % convert to column vector (lsqnonlin requirement)
    end

    function stop = output_function(x, optimValues, state)
        if strcmp(state, 'iter')
            % Update plot data for local optimization
            iteration_counter = iteration_counter + 1;
            iterations(end+1) = iteration_counter;
            f = optimValues.fval; % square of residual
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
        stop = false;
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