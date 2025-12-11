function J_normalized = compute_jacobian(p, S1)
% Computes normalized Jacobian of get_proximal_values using central difference
%
% Input:
%   p   - Nx6 array [F1, s1, theta1, F2, s2, theta2; ...]
%   S   - ...
%
% Output:
%   J_normalized - cell array of N 6x6 normalized Jacobians

if nargin < 2
    load("my_robot.mat");
end

% Step size
eps = 1e-3;

% SENSOR sigma (experimental)
sigma = [0.00173, 0.01598, 0.01215,	0.06838, 0.06938, 0.09147];

% DESIGN SPECS (Operating Ranges)
range_force = 1.0; % Newtons (Max expected force)
range_pos = 0.2;    % Meters (Length of beam)
range_theta = 2*pi; % Radians (Max angle)

% SCALING
% Output Scale: We want 1.0 to represent "1 unit of Noise"
wrench_scales = sigma';
% Input Scale: We want 1.0 to represent "Full Scale Input"
param_scales = [range_force; range_pos; range_theta; ...
                range_force; range_pos; range_theta];

% Storage
N = size(p, 1);
J_normalized = cell(N, 1);
steps = eps * param_scales';  % 1x6

% Build all perturbations for all parameter sets at once
% Each parameter set needs 12 rows (6 plus + 6 minus)
all_forces = zeros(N * 12, 9);

for i = 1:N
    p_i = p(i, :);
    base_idx = (i - 1) * 12;
    
    % Plus perturbations (rows 1-6)
    all_forces(base_idx + (1:6), 1:6) = repmat(p_i, 6, 1) + diag(steps);
    
    % Minus perturbations (rows 7-12)
    all_forces(base_idx + (7:12), 1:6) = repmat(p_i, 6, 1) - diag(steps);
end

% Single call to get_proximal_values
all_W = get_proximal_values(all_forces, S1);

% Extract results and compute Jacobians
for i = 1:N
    base_idx = (i - 1) * 12;
    
    W_plus = all_W(base_idx + (1:6), :);
    W_minus = all_W(base_idx + (7:12), :);
    
    % Compute raw Jacobian
    J_raw = (W_plus - W_minus)' ./ (2 * steps);
    
    % Normalize
    J_normalized{i} = diag(1 ./ wrench_scales) * J_raw * diag(param_scales);
    
    sv = svd(J_normalized{i});
    fprintf('Smallest singular value (%d): %.6e\n', i, sv(end));
end
end