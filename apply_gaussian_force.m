function [S,force_vectors, force_idxs]  = apply_gaussian_force(S, distal_values)
% APPLYGAUSSIANFORCE Applies Gaussian or single point force(s) to the SOROSIM linkage
% S = applyGaussianForce(S, distal_values, N, doPlot)
    num_major_link = 2; % Main Link where force is to be applied
    sigma = 0.005; % Standard deviation of Gaussian distribution
    plot_gaussain_debug = false; 
    
   % Get quadpoints and quadlengths
    num_applied_forces = size(distal_values, 1);
    num_divs = S.VLinks(2).npie-1; % number of divisions
    L_div = S.VLinks(num_major_link).L/num_divs; % length of division
    quadpoints = S.CVRods{num_major_link}(2).Xs; % get quadpoints of just first div (each div has same quadpoints) 
    quadpoints_per_div = length(quadpoints);
    quadlengths = [];
    for i=1:num_divs  
        quadlengths_new = quadpoints'*L_div+L_div*(i-1);
        % Modify first and last value by tiny bit to avoid duplictae points
        quadlengths_new(1) = quadlengths_new(1)+1e-5;
        quadlengths_new(end) = quadlengths_new(end)-1e-5;
        quadlengths = [quadlengths, quadlengths_new];
    end
  
    % Compute Force Vectors
    force_vectors = {};
    force_divisions = {};
    force_locations = {};
    force_idxs = {};
    for i = 1:num_applied_forces
        F = distal_values(i, 1);
        s = distal_values(i, 2);
        el = distal_values(i, 3);
        az = distal_values(i, 4);
        % Distribute a point load using a Gaussian distribution
        [x_loads, F_loads] = distributePointLoad(F, s, quadlengths, sigma, plot_gaussain_debug);
        num_dist_points = length(F_loads);
        % Convert each force to cartesian vector using az and el
        [x,y,z] = sph2cart(az*ones(1,num_dist_points),el*ones(1,num_dist_points),F_loads);
        % Get target division and idx of each vector 
        [target_divisions, idxs] = get_target_divisions(quadlengths, quadpoints_per_div, x_loads);
        
        force_vectors{end+1} = [x; y; z];
        force_divisions{end+1} = target_divisions;
        force_locations{end+1} = get_normalized_force_location(quadpoints, quadpoints_per_div, target_divisions, idxs);
        force_idxs{end+1} = idxs;
    end
    % Convert from cell to matrix
    force_vectors = cell2mat(force_vectors);
    force_divisions = cell2mat(force_divisions);
    force_locations = cell2mat(force_locations);
    force_idxs = cell2mat(force_idxs);

    % Sort force_idxs in ascending order and get the sorting indices
    [force_idxs, sort_order] = sort(force_idxs);

    % Reorder all other arrays using the same sorting indices
    force_vectors = force_vectors(:, sort_order);  
    force_divisions = force_divisions(sort_order);
    force_locations = force_locations(sort_order);

    % Apply combined force profile to robot
    num_force_vectors = size(force_vectors,2);
    S.Fp_vec = cell(1, num_force_vectors);
    S.Fp_loc = cell(1, num_force_vectors);
    for i = 1:num_force_vectors
        S.Fp_vec{i} = @(t)[0, 0, 0, force_vectors(1,i),...
            force_vectors(2,i), force_vectors(3,i)]';
        S.Fp_loc{i} = [num_major_link, force_divisions(i), force_locations(i)];
    end
    
    S.np = num_force_vectors;
    S.LocalWrench = ones(1, num_force_vectors);
    S.Fp_sig = PointWrenchPoints(S);
    
end

function [target_divisions, idxs] = get_target_divisions(quadlengths,quadpoints_per_div,s) 
    target_divisions = zeros(1,length(s));
    idxs = zeros(1,length(s));
    for i=1:length(s)
        [~, idxs(i)] = min(abs(quadlengths - s(i)));
        % tiny 𝜀 (1e-5) pushes exact multiples just below the boundary
        target_divisions(i) = floor((idxs(i)-1e-5)/quadpoints_per_div) + 1;
    end
end

function normalized_force_locations = get_normalized_force_location(quadpoints,quadpoints_per_div,target_divisions, idx)
    normalized_force_locations = zeros(1,length(idx));
    for i=1:length(idx)
        normalized_force_locations(i) = quadpoints(idx(i)-(target_divisions(i)-1)*quadpoints_per_div);
    end
end