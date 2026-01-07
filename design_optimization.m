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
    n_global_samples = 10;    % Samples for Global Search
    F_range = [0.3, 1.0]; 
    s_range = [0.02, 0.20]; 
    theta_range = [0, 2*pi];
    tau_range = [0, 1.5];
    s_separate_min = 0.02;
    Yield_Strength_PLA = 56e6; 

    % Generate Test Forces
    test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_separate_min);
    
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
    % Update Design (Ensure this function updates the global S object or similar)
    S = update_design(x, design, false);

    % Split forces and tau_arrays
    test_forces = test_forces(:, 1:6);
    tau_arrays = test_forces(:, end-2:end);
    
    % Get Jacobians (Using your existing function)
    J_cell = compute_jacobian(test_forces, tau_arrays, S);
    
    sigma_mins = zeros(size(J_cell,1), 1);
    for i = 1:size(J_cell,1)
        s_vals = svd(J_cell{i});
        sigma_mins(i) = s_vals(end);
    end
    
    % MAXIMIZE mean singular value -> MINIMIZE negative mean
    cost = -mean(sigma_mins);
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
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_separate_min)
    rng(1234);
    
    % 1. OVERSAMPLE: Generate many more points than needed (e.g., 20x)
    % This ensures we have enough survivors after filtering.
    n_pool = n_test_forces * 20; 
    
    % 2. Generate LHS with 'maximin' to maximize point separation initially
    U = lhsdesign(n_pool, 9, 'criterion', 'maximin', 'iterations', 50);
    
    scale = @(u,r) r(1) + u.*diff(r);
    
    F1   = scale(U(:,1), F_range);
    s1   = scale(U(:,2), s_range);
    t1   = scale(U(:,3), theta_range);
    F2   = scale(U(:,4), F_range);
    s2   = scale(U(:,5), s_range);
    t2   = scale(U(:,6), theta_range);
    tau1 = scale(U(:,7), tau_range);
    tau2 = scale(U(:,8), tau_range);
    tau3 = scale(U(:,9), tau_range);
    
    candidates = [F1 s1 t1 F2 s2 t2 tau1 tau2 tau3];
    
    % 3. FILTER: Remove invalid points
    valid_mask = abs(s1 - s2) >= s_separate_min;
    valid_forces = candidates(valid_mask, :);
    
    % 4. CHECK & SELECT: Ensure we have enough, then pick n_test_forces
    num_survivors = size(valid_forces, 1);
    if num_survivors < n_test_forces
        error('Constraint s_separate_min is too strict! Only found %d valid forces out of %d. Increase pool size.', num_survivors, n_pool);
    end
    
    % Pick the first n_test_forces valid ones
    test_forces = valid_forces(1:n_test_forces, :);
    
    % Flip so large s is first (swap force 1 and force 2 columns)
    for i = 1:size(test_forces,1)
        if test_forces(i,2) < test_forces(i,5)
            test_forces(i,1:6) = [test_forces(i,4:6), test_forces(i,1:3)];
        end
    end
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