function distal_value = get_distal_value(proximal_value_target)
    % Properties
    weight_vector = [1, 1, 1];  % Give more weight to Mz and Fx [Mz, Fx, Fy]
    lb = [0.05, 0.075, 0];
    ub = [1, 0.2, 0.05];
    global_fval_termination_value = 1e-5;
    local_fval_termination_value = 1e-8; 
    
    % Separate proximal values and parameter tau
    tau = proximal_value_target(end);
    proximal_value_target = proximal_value_target(1:end-1);
    
    % SIMPLE SURROGATE + FMINCON HYBRID
    objfun = @(x) objective_func(x);
    
    % Step 1: Global search with surrogate
    options_surr = optimoptions('surrogateopt', ...
        'MaxFunctionEvaluations', 300, ...
        'Display', 'iter', ...
        'PlotFcn', [],...
        'OutputFcn', @global_early_stop_function);
    [xglobal, fglobal] = surrogateopt(objfun, lb, ub, options_surr);
    
   % Phase 2: Local refinement with better settings
    options_fmincon = optimoptions('fmincon', ...
        'Algorithm', 'sqp', ...  % Often more robust than interior-point
        'Display', 'iter', ...
        'MaxFunctionEvaluations', 300, ...
        'OptimalityTolerance', 1e-8, ...  % Less strict
        'StepTolerance', 1e-18, ...        % Less strict
        'FiniteDifferenceStepSize', 1e-5, ... % Larger step size
        'FiniteDifferenceType', 'central', ...
        'OutputFcn', @local_early_stop_function); 
    [x_final, fval] = fmincon(objfun, xglobal, [], [], [], [], lb, ub, [], options_fmincon);
    distal_value = [x_final, tau];  
    
    function obj_val = objective_func(x)
        % Objective function
        % Calculate proximal values using forward model
        result = get_proximal_value([x,tau]);
        result = result(1:end-1); % ignore last element tau
        
        % Compute L2 norm of error vector
        error_vec = result - proximal_value_target;
        weighted_error_vec = error_vec.* weight_vector;
        obj_val = norm(weighted_error_vec)^2; % squared L2 norm
    end
    
    function stop = global_early_stop_function(x, optimValues, state)
        % Define stopping function
        stop = false;
        if strcmp(state, 'iter') && optimValues.fval < global_fval_termination_value
            stop = true;
            fprintf('Stopping early: f(x) = %.2e < %.2e\n', optimValues.fval,global_fval_termination_value);
        end
    end

    function stop = local_early_stop_function(x, optimValues, state)
        % Define stopping function
        stop = false;
        if strcmp(state, 'iter') && optimValues.fval < local_fval_termination_value
            stop = true;
            fprintf('Stopping early: f(x) = %.2e < %.2e\n', optimValues.fval,local_fval_termination_value);
        end
    end
end
        
        
        