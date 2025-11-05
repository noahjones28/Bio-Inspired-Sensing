function points = get_space_filling_points(lb, ub, n_points, method)
    % Simple space-filling points using Sobol, LHS, or stratified random
    % Returns n_points x ndim matrix scaled to [lb, ub]
    % method: 'auto' (default), 'sobol', 'lhs', or 'stratified'

    if nargin < 4, method = 'auto'; end

    ndim = numel(lb);
    rng(42); % ✅ Add reproducible seed

    if strcmp(method, 'auto')
        % Try Sobol first (best option)
        if exist('sobolset', 'file')
            sob = sobolset(ndim, 'Skip', 1000);
            unit_points = net(sob, n_points);
        % Fallback to Latin Hypercube
        elseif exist('lhsdesign', 'file')
            unit_points = lhsdesign(n_points, ndim, 'criterion', 'maximin', 'iterations', 100);
        % Last resort: stratified random
        else
            unit_points = (randperm(n_points)' - 0.5)/n_points * ones(1, ndim);
            unit_points = unit_points + rand(n_points, ndim)/n_points;
        end
    elseif strcmp(method, 'sobol')
        sob = sobolset(ndim, 'Skip', 1000);
        unit_points = net(sob, n_points);
    elseif strcmp(method, 'lhs')
        unit_points = lhsdesign(n_points, ndim, 'criterion', 'maximin', 'iterations', 100);
    elseif strcmp(method, 'stratified')
        unit_points = (randperm(n_points)' - 0.5)/n_points * ones(1, ndim);
        unit_points = unit_points + rand(n_points, ndim)/n_points;
    end

    % Scale from [0,1] to bounds
    points = lb + unit_points .* (ub - lb);
end
