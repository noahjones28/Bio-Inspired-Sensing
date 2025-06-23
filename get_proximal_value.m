function proximal_value = get_proximal_value(distal_value)
    % disable plots
    load("my_robot.mat")
    F = distal_value(1);
    s = distal_value(2);
    sigma = distal_value(3);
    tau = -1*abs(distal_value(4)); % Negative because pulling tendon
    % Change radius
    %S1.VLinks.r = {[@(X1)X1.*(-1.0./1.0e+3)+1.5e-3]};
    %S1.CVRods{1}(end).UpdateAll;
    %S1 = S1.Update();
    % Apply Force distribution
    S1 = applyGaussianForce(S1, F, s, sigma, 200, false);
    % Initial Guess
    x0 = zeros(14,1);
    % initial joint values
    action = [tau;0;0;0;0;0;0];
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');
    Mz = u(3);
    Fx = u(4);
    Fy = u(5);
    proximal_value = [Mz,Fx,Fy,tau];