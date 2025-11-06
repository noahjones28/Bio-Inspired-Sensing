function points = get_space_filling_points(lb, ub, n_points, method)
    % Simple space-filling points using Sobol, LHS, or stratified random
    % Returns n_points x ndim matrix scaled to [lb, ub]

    ndim = numel(lb);
    rng(42); % ✅ Add reproducible seed

    if strcmp(method, 'sobol')
        sob = sobolset(ndim, 'Skip', 1100);
        unit_points = net(sob, n_points);
    elseif strcmp(method, 'lhs')
        unit_points = lhsdesign(n_points, ndim, 'criterion', 'maximin', 'iterations', 100);
    end

    % Scale from [0,1] to bounds
    points = lb + unit_points .* (ub - lb);
end
