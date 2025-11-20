function optimize_beam_radius(design)
close all;
global current_mean_R; % Add global variable
current_mean_R = 0;

% OPTIMIZE_RADIUS_BILIPSCHITZ_MINIMAL - Minimal bi-Lipschitz optimization
%   Uses conservative bi-Lipschitz bounds to guarantee global injectivity

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
    else
        error("invalid design!")
    end
    
    % number of force magnitudes F and positions s
    n = 10;

    % Generate samples ONCE at the beginning
    force_samples = generate_test_forces(n);

    % Initial guess
    x0 = (lb+ub)/2;
    
    %% OPTIMIZATION
    options = optimoptions('lsqnonlin', ...
        'Algorithm', 'trust-region-reflective', ...
        'Display', 'iter-detailed', ...
        'FunctionTolerance', 1e-8, ...
        'StepTolerance', 1e-8, ...
        'OptimalityTolerance', 1e-10, ...
        'MaxIterations', 40, ...
        'FiniteDifferenceType', 'forward', ...
        'OutputFcn', @custom_output);
    
    % Run optimization with lsqnonlin
    [x_final, resnorm, residual, exitflag, output] = lsqnonlin(@(x) residual_func(x, force_samples, design), ...
        x0, lb, ub, options);
    
    disp('Optimal radii (mm):');
    disp(x_final * 1000);
    disp('Final resnorm:');
    disp(resnorm);
    disp('Final mean_R:');
    disp(current_mean_R);
end

%% RESIDUAL FUNCTION
function residual = residual_func(x, force_samples, design)
    global current_mean_R; % Access global variable
    
    % Update radius based on design variables
    S = update_radius(x, design, false);
    
    % Compute Rij score
    [mean_R, local_rij] = pairwise_distance_scan_3(force_samples, S);
    
    % Store mean_R for output function
    current_mean_R = mean_R;
    
    % Maximize 1/alpha instead of minimize alpha
    inv_local_rij = 1 ./ local_rij;
    
    residual = inv_local_rij;
end

%% FORCE SAMPLE GENERATION
function force_samples = generate_test_forces(n)
    % Ranges
    F_range = [0.1, 1.0];
    s_range = [0.02 0.20];  % Discrete values from 0.02 to 0.2
    theta = 0;
    tau_array = [0 0 0];
    
    % Create the parameter arrays
    F_array = linspace(F_range(1), F_range(2), n);
    s_array = linspace(s_range(1), s_range(2), n);
    
    % Generate all combinations using meshgrid
    [F_grid, s_grid] = meshgrid(F_array, s_array);
    n_samples = numel(F_grid);
    
    % Reshape into an N×2 array where each row is a combination
    force_samples = [F_grid(:), s_grid(:), repmat(theta,n_samples,1), repmat(tau_array, n_samples, 1)];
end

%% CUSTOM OUTPUT FUNCTION
function stop = custom_output(x, optimValues, state, varargin)
    global current_mean_R; % Access global variable
    stop = false;
    persistent iter_data best_series best_x best_resnorm best_mean_R mean_R_series
    
    if strcmp(state,'init')
        iter_data = [];
        best_series = [];
        best_x = [];
        best_resnorm = Inf;
        best_mean_R = 0;
        mean_R_series = [];
        figure;
        set(gcf, 'Position', [100, 100, 1200, 600]);
        
    elseif strcmp(state,'iter')
        iter_data(end+1) = optimValues.iteration;
        
        % Track best objective (lsqnonlin uses 'resnorm')
        if optimValues.resnorm < best_resnorm
            best_resnorm = optimValues.resnorm;
            best_x = x;
            best_mean_R = current_mean_R; % Store best mean_R
        end
        best_series(end+1) = best_resnorm;
        mean_R_series(end+1) = current_mean_R;
        
        % Plot best objective vs iteration
        subplot(2,1,1);
        plot(iter_data, best_series, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
        legend(sprintf('Best resnorm: %.6g (Max metric: %.6g) | Best mean_R: %.6g', ...
            best_resnorm, sqrt(best_resnorm), best_mean_R), 'Location', 'best');
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
        title(sprintf('Best Variables (Iter %d) | mean_R: %.6g', optimValues.iteration, best_mean_R));
        grid on;
        text(1:numel(best_x), best_x*1000+0.25, compose('%.2f', best_x*1000), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        drawnow;
    end
end