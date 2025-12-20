function design_optimization(design, n_test_forces)
    close all;

    %% ABOUT
    % Input: base geometric design and number of test forces


    %% SETUP
    % Select base design and define design variables 
    if design == "tapered"
        % Load selected design
        load('my_robots\my_robot_cylindrical_3tendon\my_robot.mat');
        % Define bounds on design variables [r1,r2]
        lb = [1.25e-3, 1.25e-3];
        ub = [2e-3, 2e-3];
    elseif design == "multi division"
        % Load selected design
        load('my_robots\my_robot_multi_division_20_3tendon\my_robot.mat');
        % Define bounds on design variables [r1,r2,...,r20]
        lb = 1.25e-3*ones(1,20); 
        ub = 2e-3*ones(1,20);
    elseif design == "elliptical twisted"
        % Load selected design
        load("my_robots\my_robot_elliptical_twisted_3tendon\my_robot.mat");
        % Define bounds on design variables [r_major_1,r_minor_1,r_major_2,r_minor_2, pre_twist]
        lb = [1.25e-3, 1.25e-3, 1e-3, 1e-3, 0];
        ub = [4e-3, 4e-3, 4e-3, 4e-3, 100];
    elseif design == "elliptical multi division"
        % Load selected design
        load("my_robots\my_robot_elliptical_multi_3tendon\my_robot.mat");
        % Define bounds on design variables [r_major_1,r_minor_1,...,r_major_20,r_minor_20]
        lb = 1.25e-3*ones(1,40);
        ub = 4e-3*ones(1,40);
    else
        error("invalid design!")
    end

    % Paramaters
    n_global_samples = 500; % Number of LHS samples for global exploration of design space
    n_design_vars = length(lb); % Number of design variables
    global current_mean;  % Add global variable ofr current objective tracking
    current_mean = 0; 
    F_range = [0.3, 0.8]; % Test force bounds 
    s_range = [0.04, 0.20];
    theta_range = [0, 2*pi];
    s_separate_min = 0.1; % Minimum inter-force separation

    % Generate test forces ONCE at the beginning
    test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, s_separate_min);


    %% STAGE 1: LATIN HYPERCUBE SAMPLING (GLOBAL EXPLORATION) 
    % Fixed seed for reproducibility 
    rng(1234);
    % Generate LHS samples
    U = lhsdesign(n_global_samples, n_design_vars);
    % Scale to actual bounds
    X_init = lb + U .* (ub - lb);
    
    % Evaluate residual at all sample points
    resnorms = zeros(n_init, 1);
    for i = 1:n_init
        r = residual_vec(X_init(i,:), test_forces, design);
        resnorms(i) = sum(r.^2);
        if mod(i,50) == 0
            fprintf('LHS sampling: %d/%d\n', i, n_init);
        end
    end
    
    % Select best (lowest resnorm) sample as initial guess
    [~, best_idx] = min(resnorms);
    x0 = X_init(best_idx, :);
    fprintf('Best initial point (resnorm = %.6g):\n', resnorms(best_idx));
    disp(x0);
    

    %% STAGE 2: NON-LINEAR LEAST SQUARES REFINEMENT
    options = optimoptions('lsqnonlin', ...
        'Algorithm', 'trust-region-reflective', ...
        'Display', 'iter-detailed', ...
        'FunctionTolerance', 1e-8, ...
        'StepTolerance', 1e-8, ...
        'OptimalityTolerance', 1e-10, ...
        'MaxIterations', 40, ...
        'FiniteDifferenceType', 'forward', ...
         'TypicalX', x0, ...
        'OutputFcn', @custom_output);
    
    % Run optimization with lsqnonlin
    [x_final, resnorm, residual, exitflag, output] = lsqnonlin(@(x) residual_vec(x, test_forces, design), ...
        x0, lb, ub, options);
    
    disp('Optimal design parameters:');
    disp(x_final)
    disp('Final resnorm:');
    disp(resnorm);
    disp('Final mean:');
    disp(current_mean);
end


%% RESIDUAL VECTOR
function residual = residual_vec(x, test_forces, design)
    global current_mean; % Access global variable

    % Update design based on design variables and don't save
    S = update_design(x, design, false);
    
    % Initialize storage array for min singular value of each test force 
    sigma_mins = zeros(size(test_forces,1), 1);

    % Get force to wrench jacobians for all test forces
    J_cell = compute_jacobian(test_forces, S);

    % Do SVD for each jacobian and extarct min singular value 
    for i=1:size(J_cell,1)
        % Get SVD
        sigma = svd(J_cell{i});
        sigma_mins(i) = sigma(end);
    end
    
    % Take mean of min singular values and store in global variable
    current_mean = mean(sigma_mins);
    
    % Maximize the reciprocal of sigma_mins to maximize sigma_mins
    residual = 1./sigma_mins;
end


%% GENERATE TEST FORCES
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, s_separate_min)
    % Fixed seed for reproducibility
    rng(1234);
    % Generate test forces using LHS
    scale = @(u,r) r(1) + u.*diff(r);
    U1 = lhsdesign(n_test_forces, 3);
    U2 = lhsdesign(n_test_forces, 3);
    F1 = scale(U1(:,1), F_range);
    F2 = scale(U2(:,1), F_range);
    s1 = scale(U1(:,2), s_range);
    s2 = scale(U2(:,2), s_range);
    theta1 = scale(U1(:,3), theta_range);
    theta2 = scale(U2(:,3), theta_range);
    test_forces = [F1 s1 theta1 F2 s2 theta2];
    % Filter out forces that exceed s_separate_min
    test_forces = test_forces(abs(test_forces(:,2) - test_forces(:,5)) >= s_separate_min, :);
end

%% CUSTOM OUTPUT FUNCTION
function stop = custom_output(x, optimValues, state, varargin)
    global current_mean; % Access global variable
    stop = false;
    persistent iter_data best_series best_x best_resnorm best_mean mean_series
    
    if strcmp(state,'init')
        iter_data = [];
        best_series = [];
        best_x = [];
        best_resnorm = Inf;
        best_mean = 0;
        mean_series = [];
        figure;
        set(gcf, 'Position', [100, 100, 1200, 600]);
        
    elseif strcmp(state,'iter')
        iter_data(end+1) = optimValues.iteration;
        
        % Track best objective (lsqnonlin uses 'resnorm')
        if optimValues.resnorm < best_resnorm
            best_resnorm = optimValues.resnorm;
            best_x = x;
            best_mean = current_mean; % Store best mean
        end
        best_series(end+1) = best_resnorm;
        mean_series(end+1) = current_mean;
        
        % Plot best objective vs iteration
        subplot(2,1,1);
        plot(iter_data, best_series, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
        legend(sprintf('Best resnorm: %.6g (Max metric: %.6g) | Best mean_sigma: %.6e', ...
            best_resnorm, sqrt(best_resnorm), best_mean), 'Location', 'best');
        xlabel('Iteration');
        ylabel('Best Resnorm So Far');
        title('lsqnonlin Progress');
        grid on;
        
        % Plot best design variables so far
        subplot(2,1,2);
        bar(best_x*1000, 'FaceColor', [0.2 0.6 0.8], 'BarWidth', 0.7);
        ylim([0, max(best_x*1000)+1]);
        xlabel('Design Variable');
        ylabel('Radius (mm)');
        title(sprintf('Best Variables (Iter %d) | mean : %.6e', optimValues.iteration, best_mean));
        grid on;
        text(1:numel(best_x), best_x*1000+0.25, compose('%.3e', best_x), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        drawnow;
    end
end