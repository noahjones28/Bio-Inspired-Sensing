function [optimal_radius, results] = optimize_beam_radius(S1, varargin)
% OPTIMIZE_RADIUS_BILIPSCHITZ_MINIMAL - Minimal bi-Lipschitz optimization
%   Uses conservative bi-Lipschitz bounds to guarantee global injectivity
    
    % Parse inputs
    p = inputParser;
    addParameter(p, 'r_bounds', [0.001, 0.020], @(x) length(x)==2);
    addParameter(p, 'n_samples', 100, @isnumeric);  % Number of LHS samples
    addParameter(p, 'tau_array', [0, 0, 0], @isnumeric);
    parse(p, varargin{:});
    
    % Number of design vars
    num_radii = 20;

    % Bounds
    lb = 1.25e-3*ones(1,num_radii);
    ub = 6e-3*ones(1,num_radii);
    % Initial guess
    r0 = linspace(5.75e-3, 1.5e-3, num_radii);

    % Generate samples ONCE at the beginning
    test_forces = generate_test_forces(p.Results.n_samples);
    fprintf('Generated %d LHS samples for optimization\n', p.Results.n_samples);
    
    % Objective function
    objective = @(r) -compute_bilipschitz_score(r, S1, test_forces, p.Results.n_samples, p.Results.tau_array);
    
    % Optimize use fmincon with bounds
    options = optimoptions('fmincon', ...
        'Display', 'iter', ...
        'Algorithm', 'sqp', ...  % or 'sqp'
        'FiniteDifferenceType', 'forward', ...
        'OutputFcn', @custom_output, ...
        'OptimalityTolerance', 1e-6);
    
    [optimal_radius, fval] = fmincon(objective, r0, ...
        [], [], [], [], ...  % No linear constraints
        lb, ub, ...  % Bounds
        [], options);  % No nonlinear constraints
    
    % Get final bi-Lipschitz bounds
    [score, bounds] = compute_bilipschitz_score(optimal_radius, S1, test_forces, p.Results.n_samples, p.Results.tau_array);
    
    results.optimal_radius = optimal_radius;
    results.m_hat = bounds.m_hat;
    results.M_hat = bounds.M_hat;
    results.ratio = bounds.M_hat / (bounds.m_hat + 1e-10);
    results.globally_injective = bounds.m_hat > 0;
    results.score = score;
    
    fprintf('\n=== Bi-Lipschitz Results ===\n');
    fprintf('Optimal radius: %.4f mm\n', optimal_radius * 1000);
    fprintf('m_hat (lower bound): %.4e\n', bounds.m_hat);
    fprintf('M_hat (upper bound): %.4e\n', bounds.M_hat);
end


%% Lipschitz Score Function
function [score, bounds] = compute_bilipschitz_score(r, S1, samples, n_samples, tau_array)
    % Update radius
    S1 = update_radius(S1, r);
    
    s_min = [];  % Minimum singular values at each sample
    s_max = [];  % Maximum singular values at each sample
    jacobians = {};  % Store Jacobians for later
    
    for i = 1:n_samples
        % Compute Jacobian using forward finite differences
        f = @(x) get_proximal_value(x, [0,0,0], false, false, S1);
        J = jacobian_forward_fd(f, samples{i});
        % Remove Tx row (not important)
        J = J(2:end,:);
        
        svd_vals = svd(J);
        s_min(end+1) = min(svd_vals);
        s_max(end+1) = max(svd_vals);
        jacobians{end+1} = J;
    end
    
    
    % Form bi-Lipschitz bounds
    m_hat = min(s_min);
    M_hat = max(s_max);

    % Take mean of bottom 10% of singular values
    s_min_sorted = sort(s_min);                  % sort into ascending order
    k = ceil(0.10 * numel(s_min_sorted));          % how many elements = 10%
    s_bottom_10 = mean(s_min_sorted(1:k));         % mean of bottom 10%
    
    % Score: maximize mean of bottom 10% singular values
    score = s_bottom_10;  % Simple: just maximize lower bound
    % Alternative: score = m_hat / M_hat;  % Maximize ratio
    
    bounds = struct('m_hat', m_hat, 'M_hat', M_hat);
end



%% Test Force Generation
function test_forces = generate_test_forces(n_forces)
    % Ranges
    F = [0.1, 1.0];
    s_values = 0.02:0.02:0.20;  % Discrete values from 0.02 to 0.2
    el = [-pi, pi];
    az = [pi/2-0.1, pi/2+0.1];
    
    % Helper
    scale = @(u,r) r(1) + u.*diff(r);
    
    % LHS for magnitudes and angles (not for s values)
    rng(1234); % fixed seed
    U1 = lhsdesign(n_forces, 3); % [F1, el1, az1]
    U2 = lhsdesign(n_forces, 3); % [F2, el2, az2]
    
    % Scale continuous parameters
    F1 = scale(U1(:,1), F);
    F2 = scale(U2(:,1), F);
    el1 = scale(U1(:,2), el);
    el2 = scale(U2(:,2), el);
    az1 = scale(U1(:,3), az);
    az2 = scale(U2(:,3), az);
    
    % Sample s1 and s2 from discrete values, ensuring s1 ≠ s2
    s1 = zeros(n_forces, 1);
    s2 = zeros(n_forces, 1);
    
    for i = 1:n_forces
        % Randomly sample s1
        s1(i) = s_values(randi(length(s_values)));
        
        % Sample s2, ensuring it's different from s1
        available_s2 = s_values(s_values ~= s1(i));
        s2(i) = available_s2(randi(length(available_s2)));
    end
    
    % Return as 2×4 matrices (8 parameters total)
    test_forces = cell(n_forces, 1);
    for i = 1:n_forces
        test_forces{i} = [F1(i) s1(i) el1(i) az1(i);
                         F2(i) s2(i) el2(i) az2(i)];
    end
end


%% Update Radius Function
function S1 = update_radius(S1, r)
    try
        for i = 1:length(r)
             S1.VLinks(2).r{i} = @(X1) r(i);
             S1.CVRods{2}(1+i).UpdateAll;
             S1 = S1.Update();
        end
    catch ME
        error('Failed to change beam radii: %s', ME.message);
    end
end

%% Custom output function for plotting
function stop = custom_output(x, optimValues, state, varargin)
     stop = false;
    persistent iter_data best_series best_x best_fval
    if strcmp(state,'init')
     iter_data=[]; best_series=[]; best_x=[]; best_fval=Inf;
     set(gcf, 'Position', [100, 100, 1200, 600]);
    elseif strcmp(state,'iter')
     iter_data(end+1)=optimValues.iteration;
    if optimValues.fval<best_fval, best_fval=optimValues.fval; best_x=x; end
     best_series(end+1)=best_fval;
    % Plot best objective vs iteration (connected with lines + markers)
     subplot(2,1,1);
     plot(iter_data,best_series,'-o','LineWidth',1.5,'MarkerSize',6,'MarkerFaceColor','b');
     legend(sprintf('Best fval: %.6g', best_fval), 'Location', 'best');
     xlabel Iteration; ylabel('Best Objective (σ_min) So Far'); title('fmincon Progress'); grid on;
    % Plot best design variables so far
     subplot(2,1,2);
     bar(best_x*1000,'FaceColor',[0.2 0.6 0.8],'BarWidth',0.7);
     ylim([0, max(best_x*1000)+1]);
     xlabel('Design Variable'); ylabel('Radius (mm)');
     title(sprintf('Best Variables (Iter %d)',optimValues.iteration)); grid on;
     text(1:numel(best_x),best_x*1000+0.25,compose('%.2f', best_x*1000),'HorizontalAlignment','center','FontWeight','bold');
     drawnow;
    end
end