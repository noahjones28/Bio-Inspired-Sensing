function [optimal_radius, results] = optimize_beam_radius(S1, varargin)
% OPTIMIZE_RADIUS_BILIPSCHITZ_MINIMAL - Minimal bi-Lipschitz optimization
%   Uses conservative bi-Lipschitz bounds to guarantee global injectivity
    
    % Parse inputs
    p = inputParser;
    addParameter(p, 'r_bounds', [0.001, 0.020], @(x) length(x)==2);
    addParameter(p, 'n_samples', 500, @isnumeric);  % Number of LHS samples
    addParameter(p, 'tau_array', [0, 0, 0], @isnumeric);
    parse(p, varargin{:});
    
    % Number of design vars
    num_radii = 20;

    % Bounds
    lb = 1.25e-3*ones(1,num_radii);
    ub = 6e-3*ones(1,num_radii);
    % Initial guess
    %r0 = 1e-3*[4.81, 6.00, 6.00, 6.00, 3.04, 1.88, 2.63, 2.80, 2.78, 1.48, 3.09, 1.39, 1.25, 1.27, 1.25, 1.25, 1.46, 2.49, 3.65, 3.50];
    r0 = linspace(2.0e-3, 1.25e-3, num_radii);
    %r0 = 1.75e-3*ones(1,20);

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
    wrenches = zeros(n_samples,6); % Initalize wrench array
    
    for i = 1:n_samples
        % Compute Jacobian using forward finite differences
        f = @(x) get_proximal_value(x, [0,0,0], false, false, S1);
        y0 = f(samples{i});
        % [J, y0] = jacobian_forward_fd(f, samples{i});
        % % Remove Tx row (not important)
        % J = J(2:end,:);
        % 
        % Populate wrenches
        wrenches(i,:) = y0;
        % 
        % svd_vals = svd(J);
        % s_min(end+1) = min(svd_vals);
        % s_max(end+1) = max(svd_vals);
        % jacobians{end+1} = J;
    end

    % Calculate pairwise separtaion matrix
    % reshape samples rows and convert to matrix
    samples_matrix = cell2mat(cellfun(@(x) reshape(x', 1, []), samples, 'UniformOutput', false));
    R = calcRij(wrenches, samples_matrix);
    % number of elements = bottom 5%
    k = max(1, floor(0.05 * numel(R)));
    % Flatten, sort ascending, take bottom k
    [sortedVals, idx] = sort(R(:), 'ascend');
    linIdx = idx(1:k);
    vals   = sortedVals(1:k);
    % Convert linear indices to row/col subscripts
    [rows, cols] = ind2sub(size(R), linIdx);
    % Mean of the bottom 5%
    R_mean_bottom_5 = mean(vals);
    
    % Form bi-Lipschitz bounds
    m_hat = min(s_min);
    M_hat = max(s_max);

    % Take mean of bottom 10% of singular values
    s_min_sorted = sort(s_min);                  % sort into ascending order
    k = ceil(0.10 * numel(s_min_sorted));          % how many elements = 10%
    s_bottom_5 = mean(s_min_sorted(1:k));         % mean of bottom 10%
    
    % Score: maximize mean of bottom 10% singular values
    %score = s_bottom_10;  % Simple: just maximize lower bound
    score = min(sortedVals);
    bounds = struct('m_hat', m_hat, 'M_hat', M_hat);
end



%% Test Force Generation
function test_forces = generate_test_forces(n_forces)
    % Ranges
    F_range = [0.1, 1.0];
    s_range = [0.02 0.20];  % Discrete values from 0.02 to 0.2
    el_range = [0, 2*pi];
    az_range = [pi/2-0.1, pi/2+0.1];
    
    % Helper
    scale = @(u,r) r(1) + u.*diff(r);
    
    % LHS for magnitudes and angles (not for s values)
    rng(1234); % fixed seed
    U1 = lhsdesign(n_forces, 4); % [F1, s1, el1, az1]
    U2 = lhsdesign(n_forces, 4); % [F2, s2, el2, az2]
    
    % Scale continuous parameters
    F1 = scale(U1(:,1), F_range);
    F2 = scale(U2(:,1), F_range);
    s1 = scale(U1(:,2), s_range);
    s2 = scale(U2(:,2), s_range);
    el1 = scale(U1(:,3), el_range);
    el2 = scale(U2(:,3), el_range);
    az1 = scale(U1(:,4), az_range);
    az2 = scale(U2(:,4), az_range);
    
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

function R = calcRij(W, X)
    % W: N×m matrix of wrenches
    % X: N×d matrix of inputs
    % R: N×N matrix of pairwise ratios R_ij
    
    N = size(W,1);
    R = zeros(N);
    
    for i = 1:N
        dW = W - W(i,:);             % differences in wrench
        dX = X - X(i,:);             % differences in input
        num = sqrt(sum(dW.^2,2));    % ||W_i - W_j||
        den = sqrt(sum(dX.^2,2));    % ||x_i - x_j||
        ratios = num ./ den;             % N×1  <-- elementwise, no transpose here
        ratios(den==0) = NaN;            % avoid div-by-zero at j=i (and any duplicates)
        R(i,:) = ratios.';               % 1×N
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