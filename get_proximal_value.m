function proximal_value = get_proximal_value(distal_value)
    % disable plots
    load("my_robot.mat")
    F = distal_value(1);
    s = distal_value(2);
    tau = -1*abs(distal_value(3)); % Negative because pulling tendon
    % Change Force Magnitude
    S1.Fp_vec = {@(t)[0,0,0,0,F,0]'};
    % Change Force Position
    s_frac = s/S1.VLinks.L; % convert s to fraction of total length
    [~, quadpoints] = S1.CVRods{1}.Xs; % Get list of current quadpoints
    [~, idx] = min(abs(quadpoints - s_frac)); % round s_frac to nearest quadpoint
    s_rounded = quadpoints(idx);
    S1.Fp_loc = {[1 1 s_rounded]}; % update location
    S1.Fp_sig = PointWrenchPoints(S1); % update significant point
    % Initial Guess
    x0 = zeros(14,1);
    % initial joint values
    action = [tau;0;0;0;0;0;0];
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');
    Mz = u(3);
    Fx = u(4);
    Fy = u(5);
    proximal_value = [Mz,Fx,Fy,tau];