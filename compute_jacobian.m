function Jw = compute_jacobian(p, S)
    %% ABOUT
    % Computes normalized Jacobian of get_proximal_values using central difference
    
    % Input:
    % p: Nx6 array [F1, S, theta1, F2, s2, theta2; ...]
    % S: Linkage
    
    % Output:
    % Jw: the whitened (noise-normalized), nondimensionalized sensitivity matrix (jacobian) 
    
    
    %% SETUP
    % Set default values
    if nargin < 2
        load("my_robot.mat",'S');
    end
    % Parameters
    eps = 1e-3; % Base step size
    print_output = false; % Print smallest singular value
    % Per-channel standard deviation of the error between hardware measurements and model predictions.
    % This error captures model mismatch, hysteresis, non-elastic bending, and measurement uncertainty.
    % Estimated from 40+ hardware experiments.
    sigma = [0.00173, 0.01598, 0.01215,	0.06838, 0.06938, 0.09147];
    range_force = 1.0; % Newtons (Max Operating Range)
    range_pos = 0.2;    % Meters (Max Operating Range)
    range_theta = 2*pi; % Radians (Max Operating Range)
    wrench_scales = sigma'; % Output Scale: We want 1.0 to represent "1 unit of Noise"
    param_scales = [range_force; range_pos; range_theta; ... % Input Scale: We want 1.0 to represent "Full Scale Input"
                    range_force; range_pos; range_theta];
    N = size(p, 1); % Number of test forces 
    Jw = cell(N, 1); % Storage array for all the jacobians
    steps = eps * param_scales';  % 1x6 scaled steps vector
    % Build all perturbations for all parameter sets at once
    % Each parameter set needs 12 rows (6 plus + 6 minus)
    all_forces = zeros(N * 12, 9);
    
    
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
        
        sv = svd(Jw{i});
        if print_output
            fprintf('Smallest singular value (%d): %.6e\n', i, sv(end));
        end
    end
end