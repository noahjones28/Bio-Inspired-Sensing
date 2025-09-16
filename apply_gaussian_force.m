function [S1,combined_force_vectors,quadpoint_idxs]  = apply_gaussian_force(S1, varargin)
% APPLYGAUSSIANFORCE Applies Gaussian or single point force(s) to the SOROSIM linkage
% S1 = applyGaussianForce(S1, distal_values, N, doPlot)
num_major_link = 2; % Main Link where force is to be applied

    % Arguments
    distal_values = varargin{1};
    N = 100;  % default number of force points in gauss dist
    sigma = 0.01; % default stdev of gauss dist
    if length(varargin) >= 2
        N = varargin{2}; % override if provided
    end

    num_forces = size(distal_values, 1);
    L = S1.VLinks(num_major_link).L;
    division_length = S1.VLinks(num_major_link).ld{1};
    [~, quadpoints] = S1.CVRods{num_major_link}.Xs;
    
    % Create discretization grid for all forces
    s_vals = linspace(0, L, N);
    ds = s_vals(2) - s_vals(1);
    combined_force_vectors = zeros(3, N); % N 3D vectors
    
    % Process each force individually
    for i = 1:num_forces
        F = distal_values(i, 1);
        s = distal_values(i, 2);
        el = distal_values(i, 3);
        az = distal_values(i, 4);
        
        % Compute Gaussian distribution
        raw_profile = exp(-0.5 * ((s_vals - s) / sigma).^2);
        raw_area = sum(raw_profile * ds);
        if raw_area > 0
            gauss_dist = F * (raw_profile / raw_area) * ds;
            % Convert each coordinate in the distribution to cartesian
            % vector using ez and el
            [x,y,z] = sph2cart(az*ones(1, N),el*ones(1, N),gauss_dist);
            gauss_dist_vectors = [x;y;z];
            combined_force_vectors = combined_force_vectors + gauss_dist_vectors;
        else
            error('Invalid Force!')
        end

    end
    
    % Apply combined force profile to robot
    S1.Fp_vec = cell(1, N);
    S1.Fp_loc = cell(1, N);
    quadpoint_idxs = zeros(1, N);
    for i = 1:N
        % Get division number corresponding to force location
        if S1.VLinks(num_major_link).npie-1 > 1 % if more than 1 division
            if isequal(S1.VLinks(num_major_link).ld{:}) == false, error('Divisions must be same length!'); end
            if s_vals(i) > 0  
                target_division = ceil(s_vals(i)/division_length);
            else
                target_division = 1;
            end
        elseif S1.VLinks(num_major_link).npie-1 == 1
            target_division = 1;
        end

        % Get location on division
        division_frac = (s_vals(i)-(target_division-1)*division_length)/division_length;
            
        [~, idx] = min(abs(quadpoints - division_frac));
        s_rounded = quadpoints(idx);
        quadpoint_idxs(i) = idx;
        S1.Fp_vec{i} = @(t)[0, 0, 0, combined_force_vectors(1,i),...
            combined_force_vectors(2,i), combined_force_vectors(3,i)]';
        S1.Fp_loc{i} = [num_major_link, target_division, s_rounded];
    end
    
    S1.np = N;
    S1.LocalWrench = ones(1, N);
    S1.Fp_sig = PointWrenchPoints(S1);
    
end