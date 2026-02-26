function design_optimization(design)
    close all;

    %% CONFIGURATION & SETUP
    % Select Design & Bounds
    if design == "elliptical_20_links"
        lb = repmat([1e-3, 1e-3, 0], 1, 20);
        ub = repmat([6e-3, 6e-3, pi/2], 1, 20);
        expand_design = @(x) x;            % identity — already full
        fixed_idx = 3;
        fixed_val = 0;    
    elseif design == "circular_uniform"
        lb = 1e-3;
        ub = 6e-3;
        expand_design = @(r) repmat([r, r, 0], 1, 20);  % single r → [r,r,0, r,r,0, ...]
        fixed_idx = [];                     % nothing to fix
        fixed_val = [];
    else
        error("Invalid design selected!");
    end

    % Parameters
    n_global_samples = 1;    % Samples for Global Search
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
    
    
    %% STAGE 1: GLOBAL SEARCH (LHS)
    fprintf('\n=== STAGE 1: Global Feasible Search (%d samples) ===\n', n_global_samples);
    
    % Tighten radii lower bounds for sampling to avoid thin infeasible designs
    lb_global = lb;
    lb_global(1:3:end) = 2e-3;  % ry
    lb_global(2:3:end) = 2e-3;  % rz
    
    % Generate space-filling samples using Latin Hypercube Sampling
    rng(1234);
    U = lhsdesign(n_global_samples, length(lb), 'criterion', 'maximin', 'iterations', 50);
    X_samples = lb_global + U .* (ub - lb_global);
    
    sample_costs = Inf(n_global_samples, 1);
    sample_constraints = Inf(n_global_samples, 1);
    n_feasible = 0;
    
    for i = 1:n_global_samples
        x_curr = expand_design(X_samples(i,:));
        
        % Check safety constraint: c <= 0 means safe (FOS >= 1)
        [c, ~] = safety_constraint(x_curr, yield_strength, F_range, s_range, theta_range);
        sample_constraints(i) = max(c);
        
        if any(c > 0)
            % INFEASIBLE: Assign a large base cost (1e20) so any feasible design
            % always ranks better. Add the violation magnitude so that among
            % infeasible designs, the least-violated one is preferred.
            sample_costs(i) = 1e20 + max(c);
        else
            % FEASIBLE: Evaluate the actual objective function
            sample_costs(i) = objective_scalar(x_curr, test_forces);
            n_feasible = n_feasible + 1;
        end
        
        if mod(i, 10) == 0, fprintf('LHS Sample %d/%d processed.\n', i, n_global_samples); end
    end
    
    % Select best sample and report
    [best_cost, idx] = min(sample_costs);
    fprintf('Global search: %d/%d samples passed safety constraint (%.1f%%)\n', ...
        n_feasible, n_global_samples, 100*n_feasible/n_global_samples);
    x0 = X_samples(idx, :);
    if best_cost >= 1e20
        fprintf('WARNING: No feasible design found. Starting from least infeasible.\n');
    else
        fprintf('Found feasible start! Cost: %.4f\n', best_cost);
    end
    fprintf('x0: '); fprintf('%.4f ', x0); fprintf('\n');
    
    % Save Global Search Results
    headers = [{'Sample', 'Cost', 'Constraint'}, ...
               arrayfun(@(i) sprintf('x%d', i), 1:length(lb), 'UniformOutput', false)];
    writecell(headers, 'Global_Search_Results.xlsx', 'Sheet', 1, 'Range', 'A1');
    writematrix([(1:n_global_samples)', sample_costs, sample_constraints, X_samples], ...
                'Global_Search_Results.xlsx', 'Sheet', 1, 'Range', 'A2');
    fprintf('Global search results saved to Global_Search_Results.xlsx\n');


    %% STAGE 2: LOCAL REFINEMENT (fmincon)
    fprintf('\n=== STAGE 2: Local Refinement (fmincon) ===\n');
    
    % Set up which variables the optimizer sees vs. which are held fixed
    if isempty(fixed_idx)
        opt_idx = 1:length(x0);                      % nothing fixed, optimize everything
        expand = @(x_red) expand_design(x_red);
    else
        opt_idx = setdiff(1:length(x0), fixed_idx);   % skip fixed variables
        expand = @(x_red) expand_design(insertval(x_red, fixed_idx, fixed_val, length(x0)));
    end
    
    options = optimoptions('fmincon', ...
        'Algorithm', 'sqp', ...
        'Display', 'iter-detailed', ...
        'UseParallel', false, ...         % Disabled
        'MaxIterations', 100, ...
        'FunctionTolerance', 1e-4, ...
        'ConstraintTolerance', 1e-3, ...
        'TypicalX', x_typical(opt_idx), ...
        'FiniteDifferenceStepSize', 1e-4, ... % Larger step needed; default ~1e-8 is below noise floor of forward model
        'OutputFcn', @(x,ov,st) plot_best_output(expand(x), ov, st));

    % Run Optimization
    [x_final, fval, ~, ~] = fmincon(@(x) objective_scalar(expand(x), test_forces), ...
                                    x0(opt_idx), [], [], [], [], lb(opt_idx), ub(opt_idx), ...
                                    @(x) safety_constraint(expand(x), yield_strength, F_range, s_range, theta_range), options);
    
    % Reconstruct full 60-variable result
    x_final = expand(x_final);

    % Results
    fprintf('\n=== OPTIMIZATION COMPLETE ===\n');
    disp('Optimal Design Parameters:');
    disp(x_final);
    disp('Final Objective (Negative Mean Singular Value):');
    disp(fval);
end


%% OBJECTIVE FUNCTION
function cost = objective_scalar(x, test_forces)
    % Update Design
    S = update_design(x, false);
    
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
function [c, ceq] = safety_constraint(x, yield_strength, F_range, s_range, theta_range)
    S = update_design(x, false);

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
    
    % We require ALL links to have FOS >= 1.0
    % Optimization expects c <= 0, so: 1.0 - min(FOS) <= 0
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
    persistent best_fval best_x iter_history fval_history fig_handle xlsx_file
    stop = false;
    
    switch state
        case 'init'
            best_fval = Inf;
            best_x = [];
            iter_history = [];
            fval_history = [];
            fig_handle = figure('Name', 'Optimization Progress');
            
            % Create Excel file with headers
            xlsx_file = 'Local_Refinement_Results.xlsx';
            n_vars = length(x);
            headers = [{'Iteration', 'fval', 'Constraint', 'StepSize', 'FirstOrderOpt'}, ...
                arrayfun(@(i) sprintf('x%d', i), 1:n_vars, 'UniformOutput', false)];
            try
                writecell(headers, xlsx_file, 'Sheet', 1, 'Range', 'A1');
            catch
                fprintf('Warning: Could not write to Excel (file open?). Continuing.\n');
            end
            
        case 'iter'
            % Append row to Excel
            row_num = optimValues.iteration + 2; % +1 for header, +1 because iterations start at 0
            row_data = [optimValues.iteration, optimValues.fval, optimValues.constrviolation, ...
                optimValues.stepsize, optimValues.firstorderopt, x];
            try
                writematrix(row_data, xlsx_file, 'Sheet', 1, 'Range', sprintf('A%d', row_num));
            catch
                fprintf('Warning: Could not write iter %d to Excel.\n', optimValues.iteration);
            end
            
            if optimValues.fval < best_fval
                best_fval = optimValues.fval;
                best_x = x;
                iter_history(end+1) = optimValues.iteration;
                fval_history(end+1) = best_fval;
                
                fprintf('Iter %d | Best fval: %.3e | Best x: ', optimValues.iteration, best_fval);
                fprintf('%.3e ', best_x);
                fprintf('\n');
                
                figure(fig_handle); clf;
                plot(iter_history, fval_history, 'b-o', 'LineWidth', 1.5);
                xlabel('Iteration'); ylabel('Objective Value');
                title(sprintf('Best: %.3e at iter %d', best_fval, optimValues.iteration));
                grid on;
                drawnow;
            end
            
        case 'done'
    end
end

%% HELPER FUNCTION
function x_full = insertval(x_red, idx, val, n)
    x_full = zeros(1, n);
    x_full(idx) = val;
    x_full(setdiff(1:n, idx)) = x_red;
end