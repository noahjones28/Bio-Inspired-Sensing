function [S,combined_force_vectors]  = apply_gaussian_force(S, distal_values)
% APPLYGAUSSIANFORCE Applies Gaussian or single point force(s) to the SOROSIM linkage
% S = applyGaussianForce(S, distal_values, N, doPlot)
    num_major_link = 2; % Main Link where force is to be applied
    target_division = 1;
    sigma = 0.01; % default stdev of gauss dist

    num_forces = size(distal_values, 1);
    L = S.VLinks(num_major_link).L;
    N = S.CVRods{num_major_link}(2).nip; % # of quadpoints/# of point forces
    [~, quadpoints] = S.CVRods{num_major_link}.Xs;

    quadlengths = quadpoints'*L;
    ds = diff(quadlengths);
    ds = [ds,ds(end)];
    
    combined_force_vectors = zeros(3, N); % N 3D vectors
    
    % Process each force individually
    for i = 1:num_forces
        F = distal_values(i, 1);
        s = distal_values(i, 2);
        el = distal_values(i, 3);
        az = distal_values(i, 4);
        
        % Compute Gaussian distribution
        raw_profile = exp(-0.5 * ((quadlengths - s) / sigma).^2);
        raw_area = sum(raw_profile .* ds);
        if raw_area > 0
            gauss_dist = F * (raw_profile / raw_area) .* ds;
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
    S.Fp_vec = cell(1, N);
    S.Fp_loc = cell(1, N);
    for i = 1:N
        S.Fp_vec{i} = @(t)[0, 0, 0, combined_force_vectors(1,i),...
            combined_force_vectors(2,i), combined_force_vectors(3,i)]';
        S.Fp_loc{i} = [num_major_link, target_division, quadpoints(i)];
    end
    
    S.np = N;
    S.LocalWrench = ones(1, N);
    S.Fp_sig = PointWrenchPoints(S);
    
end