function optimize_beam_radius(design, n_forces, n_samples)
close all;

global current_mean; % Add global variable
current_mean = 0;

    %% SETUP
    if design == "tapered"
        % Load tapered robot
        load('my_robots\my_robot_cylindrical_3tendon\my_robot.mat');
        % Bounds
        lb = [1.25e-3, 1.25e-3]; % [r1,r2]
        ub = [2e-3, 2e-3];
    elseif design == "multi division"
        % Load multi division robot
        load('my_robots\my_robot_multi_division_20_3tendon\my_robot.mat');
        % Bounds
        lb = 1.25e-3*ones(1,20);
        ub = 2e-3*ones(1,20);
    elseif design == "elliptical twisted"
        % Load elliptical twisted robot
        load("my_robots\my_robot_elliptical_twisted_3tendon\my_robot.mat");
        % Bounds
        lb = [1.25e-3, 1.25e-3, 1e-3, 1e-3, 0]; % [r_major_1,r_minor_1,r_major_2,r_minor_2, pre_twist]
        ub = [4e-3, 4e-3, 4e-3, 4e-3, 100];
    elseif design == "elliptical multi division"
        % Load elliptical twisted robot
        load("my_robots\my_robot_elliptical_multi_3tendon\my_robot.mat");
        % Bounds
        lb = 1.25e-3*ones(1,40);
        ub = 4e-3*ones(1,40);
    else
        error("invalid design!")
    end

    % Generate samples ONCE at the beginning
    force_samples = generate_test_forces(n_forces,n_samples);

    % Initial guess using LHS sampling
    n_init = 500;
    rng(1234);
    n_vars = length(lb);
    U = lhsdesign(n_init, n_vars);
    X_init = lb + U .* (ub - lb);  % Scale to bounds
    
    % Evaluate residual at all sample points
    resnorms = zeros(n_init, 1);
    for i = 1:n_init
        r = residual_func(X_init(i,:), force_samples, design);
        resnorms(i) = sum(r.^2);
        if mod(i,50) == 0
            fprintf('LHS sampling: %d/%d\n', i, n_init);
        end
    end
    
    % Select best point as initial guess
    [~, best_idx] = min(resnorms);
    x0 = X_init(best_idx, :);
    fprintf('Best initial point (resnorm = %.6g):\n', resnorms(best_idx));
    disp(x0);
    
    %% OPTIMIZATION
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
    [x_final, resnorm, residual, exitflag, output] = lsqnonlin(@(x) residual_func(x, force_samples, design), ...
        x0, lb, ub, options);
    
    disp('Optimal design parameters:');
    disp(x_final)
    disp('Final resnorm:');
    disp(resnorm);
    disp('Final mean:');
    disp(current_mean);
end

%% RESIDUAL FUNCTION
function residual = residual_func(x, force_samples, design)
    global current_mean; % Access global variable

    x = [x(1:20);x(21:end);x(1:20);x(21:end)];

    % Update radius based on design variables
    S = update_radius(x, design, false);
    
    % Storage
    sigma_mins = zeros(size(force_samples,1), 1);

    % Jacobian and singular values
    J_cell = compute_jacobian(force_samples, S);
    for i=1:size(J_cell,1)
        % Get SVD
        sigma = svd(J_cell{i});
        sigma_mins(i) = sigma(end);
    end
    
    % Store mean for output function
    current_mean = mean(sigma_mins);
    
    residual = 1./sigma_mins;
end

%% FORCE SAMPLE GENERATION
function force_samples = generate_test_forces(n_forces, n_samples)
    F_range = [0.3, 0.8];
    s_range = [0.04, 0.20];
    theta_range = [0, 2*pi];
    scale = @(u,r) r(1) + u.*diff(r);
    rng(1234);
    if n_forces == 1
        U = lhsdesign(n_samples, 3);
        F = scale(U(:,1), F_range);
        s = scale(U(:,2), s_range);
        theta = scale(U(:,3), theta_range);
        force_samples = [F s theta];
    elseif n_forces == 2
        U1 = lhsdesign(n_samples, 3);
        U2 = lhsdesign(n_samples, 3);
        F1 = scale(U1(:,1), F_range);
        F2 = scale(U2(:,1), F_range);
        s1 = scale(U1(:,2), s_range);
        s2 = scale(U2(:,2), s_range);
        theta1 = scale(U1(:,3), theta_range);
        theta2 = scale(U2(:,3), theta_range);
        force_samples = [F1 s1 theta1 F2 s2 theta2];

        % Filter forces that are too close:
        force_samples = force_samples(abs(force_samples(:,2) - force_samples(:,5)) >= 0.1, :);
    end
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