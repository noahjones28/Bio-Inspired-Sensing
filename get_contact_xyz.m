function contact_xyz = get_contact_xyz(S, q, contatct_node_idx)
    % Extract positions
    num_divs = S.VLinks(2).npie-1; % number of divisions
    quadpoints = S.CVRods{2}(2).Xs; % get quadpoints of just first div (each div has same quadpoints) 
    quadpoints_per_div = length(quadpoints);
    num_quadpoints_total = S.nsig;
    num_quadpoints_link = quadpoints_per_div*num_divs;
    num_forces = size(distal_values, 1);
    
    % Get transformation matrices at all points
    g_all = S.FwdKinematics(q);
    g_link = g_all((num_quadpoints_total-num_quadpoints_link)*4+1:end, :); % isolate transformation matrices of our main link
    g_col4 = reshape(g_link(:,4), 4, num_quadpoints_link); % pick the 4th column of each block
    position = g_col4(1:3, :); % extarct xyz position from each matrix
end