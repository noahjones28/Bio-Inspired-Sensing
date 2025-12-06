function J_normalized = compute_jacobian(p, eps)
% Computes normalized Jacobian of get_proximal_values using central difference
%
% Input:
%   p   - [F1, s1, theta1, F2, s2, theta2]
%   eps - finite difference step (optional, default 1e-6)
%
% Output:
%   J_normalized - 6x6 normalized Jacobian

if nargin < 2
    eps = 1e-3;
end

% Hardcoded scales
L = 0.2;
param_scales = [1; L; 2*pi; 1; L; 2*pi];
wrench_scales = [0.1; 0.1; 0.1; 1; 1; 1];

p = p(:)';
J_raw = zeros(6, 6);

for j = 1:6
    step = eps * param_scales(j);  % scale-aware step
    
    p_plus = p;
    p_minus = p;

    p_plus(j) = p(j) + step;
    p_minus(j) = p(j) - step;

    W_plus = get_proximal_value([p_plus(1:3);p_plus(4:6)]);
    W_minus = get_proximal_value([p_minus(1:3);p_minus(4:6)]);

    J_raw(:, j) = (W_plus(:) - W_minus(:)) / (2 * step);
end


% Normalize
J_normalized = diag(1 ./ wrench_scales) * J_raw * diag(param_scales);

sv = svd(J_normalized);
sigma_min = sv(end);
fprintf('Smallest singular value: %.6e\n', sigma_min);

end