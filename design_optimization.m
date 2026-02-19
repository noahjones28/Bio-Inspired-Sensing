function design_optimization(design)
    close all;

    %% CONFIGURATION & SETUP
    % Select Design & Bounds
    if design == "elliptical_20_links"
        % [r_major_1, r_minor_1, Φ_1, ...,r_major_20, r_minor_20, Φ_20] 
        lb = repmat([1e-3, 1e-3, 0], 1, 20);
        ub = repmat([6e-3, 6e-3, pi/2], 1, 20);
    else
        error("Invalid design selected!");
    end

    % Parameters
    n_global_samples = 3;    % Samples for Global Search
    n_test_forces = 60; % In Design of Experiments (DOE), the standard rule of thumb is 10 samples per dimension.
    F_range = [0.3, 1.5]; 
    s_range = [0.02, 0.20]; 
    theta_range = [0, 2*pi];
    tau_range = [0, 3];
    s_sep_min = 0.02;
    x_typical = (lb + ub) / 2; 
    yield_strength = 62e6; % Polycarbonate (PC) Tensile Strength (X-Y)

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
        [c, ~] = safety_constraint(x_curr, design, yield_strength, F_range, s_range, theta_range);
        
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
        'UseParallel', false, ...         % Disabled
        'MaxIterations', 100, ...
        'FunctionTolerance', 1e-4, ...
        'ConstraintTolerance', 1e-3, ...
        'TypicalX', x_typical, ...
        'OutputFcn', @plot_best_output);

    % Run Optimization
    [x_final, fval, ~, ~] = fmincon(@(x) objective_scalar(x, test_forces, design), ...
                                    x0, [], [], [], [], lb, ub, ...
                                    @(x) safety_constraint(x, design, yield_strength, F_range, s_range, theta_range), options);
    
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
    
    % Initialize total score
    total_score = 0;
    
    % Loop through test load jacobians
    for i = 1:size(J_cell,1)
        % Get condition number of Jacobian
        k = cond(J_cell{i});
        
        % Get score
        score = -1/k;
        
        % Total utility
        total_score = total_score + score;
    end
    
    % Take the mean 
    mean_score = total_score/size(J_cell,1);
    
    % Cost function
    cost = mean_score;
end


%% CONSTRAINT FUNCTION
function [c, ceq] = safety_constraint(x, design, yield_strength, F_range, s_range, theta_range)
    S = update_design(x, design, false);

    F_max = F_range(2);
    s_tip = s_range(2);

    % Zero tendon tension: least rigid, worst case for applied force stress
    tau_worst = [0, 0, 0];

    % Grid over force angles only
    n_angles = 8;
    thetas = linspace(0, 2*pi, n_angles + 1);
    thetas(end) = [];  % remove duplicate 2*pi
    [T1, T2] = ndgrid(thetas, thetas);
    combos = [T1(:), T2(:)];

    r_maj_vec = x(1:3:end)';
    r_min_vec = x(2:3:end)';
    worst_fos = inf;

    for k = 1:size(combos, 1)
        worst_force = [F_max, s_tip, combos(k,1);
                       F_max, s_tip, combos(k,2)];

        [~, internal_wrenches] = forward_model(worst_force, tau_worst, false, false, S);

        Tx = internal_wrenches(:, 1);
        Ty = internal_wrenches(:, 2);
        Tz = internal_wrenches(:, 3);

        [~, fos_array] = calc_ellipse_vonmises(r_maj_vec, r_min_vec, Tx, Ty, Tz, yield_strength);

        worst_fos = min(worst_fos, min(fos_array));
    end

    c = 1.0 - worst_fos;
    ceq = [];
end

%% GENERATE TEST FORCES
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min)
    rng(1234);

    % Generate 9 LHS variables with good space-filling properties:
    %   U(:,1) = F1 magnitude
    %   U(:,2) = F2 magnitude
    %   U(:,3) = theta1 angle
    %   U(:,4) = theta2 angle
    %   U(:,5) = tau1 tendon tension
    %   U(:,6) = tau2 tendon tension
    %   U(:,7) = tau3 tendon tension
    %   U(:,8) = s1 position (distal force)
    %   U(:,9) = s2 position (proximal force)
    U = lhsdesign(n_test_forces, 9, 'criterion', 'maximin', 'iterations', 50);
    scale = @(u,r) r(1) + u.*diff(r);

    % Scale force magnitudes, angles, and tendon tensions to their ranges
    F1   = scale(U(:,1), F_range);
    F2   = scale(U(:,2), F_range);
    t1   = scale(U(:,3), theta_range);
    t2   = scale(U(:,4), theta_range);
    tau1 = scale(U(:,5), tau_range);
    tau2 = scale(U(:,6), tau_range);
    tau3 = scale(U(:,7), tau_range);

    % Sample both positions independently across the full beam
    s_raw1 = scale(U(:,8), s_range);
    s_raw2 = scale(U(:,9), s_range);

    % Sort so s1 is always the more distal force
    s1 = max(s_raw1, s_raw2);
    s2 = min(s_raw1, s_raw2);

    % Resample any pairs that violate minimum separation
    too_close = (s1 - s2) < s_sep_min;
    while any(too_close)
        n_fix = sum(too_close);
        s_new1 = s_range(1) + rand(n_fix,1) * diff(s_range);
        s_new2 = s_range(1) + rand(n_fix,1) * diff(s_range);
        s1(too_close) = max(s_new1, s_new2);
        s2(too_close) = min(s_new1, s_new2);
        too_close = (s1 - s2) < s_sep_min;
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