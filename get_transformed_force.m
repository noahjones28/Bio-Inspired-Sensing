function [contact_xyz, force_vector_global] = get_transformed_force(S, q, contatct_node_idx, force_vector_local)
    % Extract positions
    num_divs = S.VLinks(2).npie-1; % number of divisions
    quadpoints = S.CVRods{2}(2).Xs; % get quadpoints of just first div (each div has same quadpoints) 
    quadpoints_per_div = length(quadpoints);
    num_quadpoints_total = S.nsig;
    num_quadpoints_link = quadpoints_per_div*num_divs;
    
    % Get transformation matrices at all points
    g_all = S.FwdKinematics(q);
    g_link = g_all((num_quadpoints_total-num_quadpoints_link)*4+1:end, :); % isolate transformation matrices of our main link
    g_col4 = reshape(g_link(:,4), 4, num_quadpoints_link); % pick the 4th column of each block
    positions = g_col4(1:3, :); % extarct xyz position from each matrix
    contact_xyz = positions(:,contatct_node_idx)';

    % Extract the i-th transformation matrix
    T = g_link((contatct_node_idx-1)*4+1:contatct_node_idx*4, :);  % 4x4 matrix
    % Extract the 3x3 rotation part (no scale present)
    R = T(1:3, 1:3);
    % Rotate the AB vector
    force_vector_global = R*force_vector_local;
    % Divide by its magnitude to normalize
    force_vector_global = force_vector_global / norm(force_vector_global);
    
end