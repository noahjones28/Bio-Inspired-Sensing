% Paramaters
n_test_forces = 20;
F_range = [0.3, 1.0]; 
s_range = [0.02, 0.20]; 
theta_range = [0, 2*pi]; 
s_separate_min = 0.02;

% Get test forces
test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, s_separate_min);

% Storage
sigma_mins = zeros(n_test_forces, 1);
errors = zeros(n_test_forces, 6);

for i = 1:n_test_forces
    F_actual = test_forces(i, :);
    % Jacobian and singular values
    J = compute_jacobian(F_actual);
    % Get SVD
    [U, S, V] = svd(J{1});
    sigma_mins(i) = S(end);
end

% Print results
fprintf('Mean of min singular values: %.6e\n\n', mean(sigma_mins));


function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, s_separate_min)
    rng(1234);
    
    % 1. OVERSAMPLE: Generate many more points than needed (e.g., 20x)
    % This ensures we have enough survivors after filtering.
    n_pool = n_test_forces * 20; 
    
    % 2. Generate LHS with 'maximin' to maximize point separation initially
    U = lhsdesign(n_pool, 6, 'criterion', 'maximin', 'iterations', 50);
    
    scale = @(u,r) r(1) + u.*diff(r);
    
    F1 = scale(U(:,1), F_range); 
    s1 = scale(U(:,2), s_range); 
    t1 = scale(U(:,3), theta_range);
    
    F2 = scale(U(:,4), F_range); 
    s2 = scale(U(:,5), s_range); 
    t2 = scale(U(:,6), theta_range);
    
    candidates = [F1 s1 t1 F2 s2 t2];
    
    % 3. FILTER: Remove invalid points
    valid_mask = abs(s1 - s2) >= s_separate_min;
    valid_forces = candidates(valid_mask, :);
    
    % 4. CHECK & SELECT: Ensure we have enough, then pick 50
    num_survivors = size(valid_forces, 1);
    
    if num_survivors < n_test_forces
        error('Constraint s_separate_min is too strict! Only found %d valid forces out of %d. Increase pool size.', num_survivors, n_pool);
    end
    
    % Pick the first 50 valid ones
    test_forces = valid_forces(1:n_test_forces, :);

    % Flip so large s is first
    for i = 1:size(test_forces,1)
        if test_forces(i,2) < test_forces(i,5)
            test_forces(i,:) = [test_forces(i,4:6), test_forces(i,1:3)]; 
        end
    end
end