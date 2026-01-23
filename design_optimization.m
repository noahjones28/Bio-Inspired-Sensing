function design_optimization(design, n_test_forces)
    close all;

    %% CONFIGURATION & SETUP
    % Select Design & Bounds
    if design == "elliptical_20_links"
        % % [r_major_1, r_minor_1, Φ_1, ...,r_major_20, r_minor_20, Φ_20]  
        lb = repmat([1e-3, 1e-3, 0], 1, 20);
        ub = repmat([5e-3, 5e-3, pi], 1, 20);
    else
        error("Invalid design selected!");
    end

    % Parameters
    n_global_samples = 3;    % Samples for Global Search
    n_test_forces = 30; % In Design of Experiments (DOE), the standard rule of thumb is 10 samples per dimension.
    F_range = [0.3, 1.0]; 
    s_range = [0.02, 0.20]; 
    theta_range = [0, 2*pi];
    tau_range = [0, 1.5];
    s_sep_min = 0.02;
    Yield_Strength_PLA = 56e6;

    % Generate Test Forces
    test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min);
    
    %% STAGE 1: CONSTRAINED GLOBAL SEARCH (LHS)
    fprintf('\n=== STAGE 1: Global Feasible Search (%d samples) ===\n', n_global_samples);
    
    rng(1234);
    % Try 50 different arrangements and pick the best one.  'maximin': Maximize distance between points
    U = lhsdesign(n_global_samples, length(lb), 'criterion', 'maximin', 'iterations', 50);
    X_samples = lb + U .* (ub - lb);
    
    sample_costs = Inf(n_global_samples, 1);
    
    % Standard Loop
    for i = 1:n_global_samples
        x_curr = X_samples(i,:);
        
        % A. Check Safety (Constraint)
        % Returns c <= 0 if Safe.
        [c, ~] = safety_constraint(x_curr, test_forces, design, Yield_Strength_PLA);
        
        if any(c > 0)
            % Design is UNSAFE (FOS < 1). Discard.
            sample_costs(i) = Inf; 
        else
            % Design is SAFE. Calculate Objective.
            sample_costs(i) = objective_scalar(x_curr, test_forces, design);
        end
        
        if mod(i, 20) == 0, fprintf('LHS Sample %d/%d processed.\n', i, n_global_samples); end
    end
    
    % Find Best Safe Start
    [best_cost, idx] = min(sample_costs);
    
    if isinf(best_cost)
        fprintf('WARNING: No feasible design found in LHS. Starting from Upper Bound.\n');
        x0 = ub; 
    else
        x0 = X_samples(idx, :);
        fprintf('Found feasible start! Cost: %.4f\n', best_cost);
    end

    %% STAGE 2: LOCAL REFINEMENT (fmincon)
    fprintf('\n=== STAGE 2: Local Refinement (fmincon) ===\n');
    
    options = optimoptions('fmincon', ...
        'Algorithm', 'sqp', ...
        'Display', 'iter-detailed', ...
        'UseParallel', false, ...         % Disabled as requested
        'MaxIterations', 50, ...
        'StepTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-3, ...
        'OutputFcn', @plot_best_output);

    % Run Optimization
    [x_final, fval, ~, ~] = fmincon(@(x) objective_scalar(x, test_forces, design), ...
                                    x0, [], [], [], [], lb, ub, ...
                                    @(x) safety_constraint(x, test_forces, design, Yield_Strength_PLA), options);
    
    % Results
    fprintf('\n=== OPTIMIZATION COMPLETE ===\n');
    disp('Optimal Design Parameters:');
    disp(x_final);
    disp('Final Objective (Negative Mean Singular Value):');
    disp(fval);
end


%% OBJECTIVE FUNCTION
function cost = objective_scalar(x, test_forces, design)
    % Update Design
    S = update_design(x, design, false);
    
    % Split inputs
    force_inputs = test_forces(:, 1:6);
    tau_arrays = test_forces(:, end-2:end);

    % Get force_to_wrench jacobians for all test loads
    J_cell = compute_jacobian(force_inputs, tau_arrays, S);
    
    % Sigmoid parameters
    target_threshold = 3.0;  % Target: The specific singular value where we want the transition to happen.
    k = 2.0;  % Steepness (k): Controls width of the "Transition Zone." Higher k = stricter, binary "Pass/Fail". Lower k = smoother, gentler transition.
    leak_slope = 0.01; % Leak (alpha): The gentle slope that keeps the optimizer moving even when the Sigmoid is flat.    
    
    % Initialize total score
    total_score = 0;
    
    % Loop through test load jacobians
    for i = 1:size(J_cell,1)
        s_vals = svd(J_cell{i}); % Get singular values
        min_sv = s_vals(end); % Get min singular value
        
        % 1. Calculate margin
        margin = min_sv - target_threshold;
        
        % 2. Sigmoid score (The "Strategic Filter") S(x) = 1 / (1 + e^-k(x))
        % This naturally saturates to 1 (Safe Win) and 0 (Lost Cause)
        sigmoid_part = 1 / (1 + exp(-k * margin));
        
        % 3. Leak score (The "Guidance")
        % Adds a tiny gradient everywhere so the optimizer is never truly blind.
        leak_part = leak_slope * min_sv;
        
        % Total utility
        total_score = total_score + (sigmoid_part + leak_part);
    end
    
    % Negate for Minimizer (Maximize Score = Minimize Cost)
    cost = -total_score;
end


%% CONSTRAINT FUNCTION
function [c, ceq] = safety_constraint(x, test_forces, design, yield_strength)
    % Update the design before running forward model
    S = update_design(x, design, false);

    % Identify Worst-Case Load using Moment Estimator
    % test_forces: [F1 s1 theta1 F2 s2 theta2]
    F1 = test_forces(:, 1); s1 = test_forces(:, 2);
    F2 = test_forces(:, 4); s2 = test_forces(:, 5);
    
    % Metric: Sum of Force * Distance (Moment Approximation)
    moment_estimate = (F1 .* s1) + (F2 .* s2);
    
    % Pick index with highest moment potential
    [~, max_idx] = max(moment_estimate);
    worst_force = test_forces(max_idx, :);
    worst_force = [worst_force(1:3);worst_force(4:6)];
    tau_array = test_forces(max_idx, end-2:end);
    
    % Run Forward Model and teturns internal wrenches for the updated design under the worst load
    [~, internal_wrenches] = forward_model(worst_force, tau_array, false, false, S); 
    
    % Extract Moments
    Tx = internal_wrenches(:, 1);
    Ty = internal_wrenches(:, 2);
    Tz = internal_wrenches(:, 3);
    
    % Calculate FOS of each link
    r_maj_vec = x(1:3:end)';
    r_min_vec = x(2:3:end)';
    [~, fos_array] = calc_ellipse_vonmises(r_maj_vec, r_min_vec, Tx, Ty, Tz, yield_strength);
    
    % 6. Define Constraint
    % We require ALL links to have FOS >= 1.0
    % Optimization expects c <= 0, so: 1.0 - min(FOS) <= 0
    c = 1.0 - min(fos_array);
    ceq = [];
end


%% GENERATE TEST FORCES
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min)
    rng(1234);
    
    % We need 9 variables: 
    % [F1, F2, t1, t2, tau1, tau2, tau3, s_midpoint, s_separation_log]
    U = lhsdesign(n_test_forces, 9, 'criterion', 'maximin', 'iterations', 50);
    
    scale = @(u,r) r(1) + u.*diff(r);
    
    % 1. Standard Linear Variables
    F1   = scale(U(:,1), F_range);
    F2   = scale(U(:,2), F_range);
    t1   = scale(U(:,3), theta_range);
    t2   = scale(U(:,4), theta_range);
    tau1 = scale(U(:,5), tau_range);
    tau2 = scale(U(:,6), tau_range);
    tau3 = scale(U(:,7), tau_range);
    
    % 2. LINEAR SEPARATION SAMPLING (Simplified)
    sep_min = s_sep_min; 
    sep_max = diff(s_range); % Max possible separation
    
    % Simple Linear Interpolation: Min + u * (Max - Min)
    s_sep = sep_min + U(:,9) .* (sep_max - sep_min);
    
    % 3. Midpoint & Sliding Logic (Same as before)
    s_mid = scale(U(:,8), s_range);
    
    s1 = zeros(n_test_forces, 1);
    s2 = zeros(n_test_forces, 1);
    beam_min = s_range(1);
    beam_max = s_range(2);
    
    for i = 1:n_test_forces
        delta = s_sep(i);
        mid = s_mid(i);
        
        % Initial positions
        p1 = mid - delta/2;
        p2 = mid + delta/2;
        
        % Slide if out of bounds
        if p1 < beam_min
            shift = beam_min - p1;
            p1 = p1 + shift;
            p2 = p2 + shift;
        elseif p2 > beam_max
            shift = p2 - beam_max;
            p2 = p2 - shift;
            p1 = p1 - shift;
        end
        
        s1(i) = p2; % Store larger position in s1
        s2(i) = p1;
    end
    
    test_forces = [F1, s1, t1, F2, s2, t2, tau1, tau2, tau3];
end


%% PLOT BEST OUTPUT
function stop = plot_best_output(x, optimValues, state)
    persistent best_fval best_x iter_history fval_history fig_handle
    stop = false;
    
    switch state
        case 'init'
            best_fval = Inf;
            best_x = [];
            iter_history = [];
            fval_history = [];
            fig_handle = figure('Name', 'Optimization Progress');
            
        case 'iter'
            if optimValues.fval < best_fval
                best_fval = optimValues.fval;
                best_x = x;
                iter_history(end+1) = optimValues.iteration;
                fval_history(end+1) = best_fval;
                
                % Print to console
                fprintf('Iter %d | Best fval: %.3e | Best x: ', optimValues.iteration, best_fval);
                fprintf('%.3e ', best_x);
                fprintf('\n');
                
                % Update plot
                figure(fig_handle); clf;
                plot(iter_history, fval_history, 'b-o', 'LineWidth', 1.5);
                xlabel('Iteration'); ylabel('Objective Value');
                title(sprintf('Best: %.3e at iter %d', best_fval, optimValues.iteration));
                grid on;
                drawnow;
            end
            
        case 'done'
            % Keep figure open
    end
end