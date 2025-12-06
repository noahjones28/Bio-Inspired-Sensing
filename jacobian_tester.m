% Get test forces
forces = get_test_forces();  % Returns nx6 array
n = size(forces, 1);

% Storage
sigma_mins = zeros(n, 1);
errors = zeros(n, 6);

for i = 1:n
    F_actual = forces(i, :);
    
    % Forward then inverse
    W_sim = get_proximal_value([F_actual(1:3); F_actual(4:6)]);
    F_estimated = get_distal_value(W_sim, [0 0 0]);
    
    % Store error
    errors(i, :) = abs(F_estimated(:)' - F_actual);
    
    % Jacobian and singular values
    J = compute_jacobian(F_actual);
    % Get SVD
    [U, S, V] = svd(J);
    sigma_mins(i) = S(end);
end
% Print error matrix
fprintf('Error matrix:\n');
fprintf('%10s %10s %10s %10s %10s %10s\n', 'F1', 's1', 'theta1', 'F2', 's2', 'theta2');
fprintf('%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f\n', errors');

% Print results
fprintf('Mean of min singular values: %.6e\n\n', mean(sigma_mins));
fprintf('Mean absolute error:\n');
fprintf('  F:     %.6f\n', mean([errors(:,1); errors(:,4)]));
fprintf('  s:     %.6f\n', mean([errors(:,2); errors(:,5)]));
fprintf('  theta: %.6f\n', mean([errors(:,3); errors(:,6)]));

function X = get_test_forces()
    n_forces = 20;
    F_range = [0.3, 0.8];
    s_range = [0.04, 0.20];
    theta_range = [0, 2*pi];
    scale = @(u,r) r(1) + u.*diff(r);
    rng(1234);
    U1 = lhsdesign(n_forces, 3);
    U2 = lhsdesign(n_forces, 3);
    F1 = scale(U1(:,1), F_range);
    F2 = scale(U2(:,1), F_range);
    s1 = scale(U1(:,2), s_range);
    s2 = scale(U2(:,2), s_range);
    theta1 = scale(U1(:,3), theta_range);
    theta2 = scale(U2(:,3), theta_range);
    X = [F1 s1 theta1 F2 s2 theta2];

    % Filter forces that are too close:
    X = X(abs(X(:,2) - X(:,5)) >= 0.06, :);

    %flip so large s is first
    for i = 1:size(X,1)
        if X(i,2) < X(i,5)
            X(i,:) = [X(i,4:6), X(i,1:3)]; 
        end
    end

end