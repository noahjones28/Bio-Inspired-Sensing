function [Jw, param_scales] = compute_jacobian(p, tau_array, S)
    %% ABOUT
    % Computes the whitened (noise-normalized) Jacobian using central difference
    
    % Input:
    % p: Nx6 array [F1, S, theta1, F2, s2, theta2; ...]
    % tau: 1x3 array [tau1, tau2, tau3]
    % S: Linkage
    
    % Output:
    % Jw: the whitened (noise-normalized), nondimensionalized sensitivity matrix (jacobian)
    % param_scales: helpful for calculating covariance matrix
    
    
    %% SETUP
    % Set default values
    if nargin < 3
        load("my_robot.mat",'S');
    end
    if nargin < 2
        tau_array = zeros(1,3);
    end

    % Parameters
    eps = 1e-3; % Base step size
    print_output = false; % Print smallest singular value
    % SENSING RANGES from ATI spec sheet 
    sigma = [1, 1, 1, 60, 20, 20];
    range_force = 1.2; % Newtons (Max Operating Range)
    range_pos = 0.18;    % Meters (Max Operating Range)
    range_theta = 2*pi; % Radians (Max Operating Range)
    wrench_scales = sigma'; % Output Scale: We want 1.0 to represent "1 unit of Noise"
    param_scales = [range_force; range_pos; range_theta; ... % Input Scale: We want 1.0 to represent "Full Scale Input"
                    range_force; range_pos; range_theta];
    N = size(p, 1); % Number of test forces 
    Jw = cell(N, 1); % Storage array for all the jacobians
    steps = eps * param_scales';  % 1x6 scaled steps vector
    % Build all perturbations for all parameter sets at once
    % Each parameter set needs 12 rows (6 plus + 6 minus)
    all_forces = zeros(N * 12, 6);
    % Append the tau array to end of each row
    all_forces = [all_forces, repelem(tau_array, 12, 1)];
    
    
    %% JACOBIAN COMPUTATION (CENTRAL FINITE DIFFERENCE) (WHITENED NOISE-NORMALIZED)
    % Compute Perturbations
    for i = 1:N
        p_i = p(i, :);
        base_idx = (i - 1) * 12;
        
        % Plus perturbations (rows 1-6)
        all_forces(base_idx + (1:6), 1:6) = repmat(p_i, 6, 1) + diag(steps);
        
        % Minus perturbations (rows 7-12)
        all_forces(base_idx + (7:12), 1:6) = repmat(p_i, 6, 1) - diag(steps);
    end
    
    % Get wrench for each perturbed test force
    all_W = forward_model_parallel(all_forces, S);
    
    % For each test force build jacobian
    for i = 1:N
        base_idx = (i - 1) * 12;
        W_plus = all_W(base_idx + (1:6), :);
        W_minus = all_W(base_idx + (7:12), :);
        
        % Compute raw Jacobian
        J_raw = (W_plus - W_minus)' ./ (2 * steps);
        
        % Apply input and output scalings to get noise-whitened, nondimensionalized Jacobian
        Jw{i} = diag(1 ./ wrench_scales) * J_raw * diag(param_scales);
        
        % optional if print_output
        if print_output
            % Get condition number
            k = cond(Jw{i});
            fprintf('Condition number (%d): %.6e\n', i, k);
        end
    end
end