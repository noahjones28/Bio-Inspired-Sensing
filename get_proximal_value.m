function proximal_value = get_proximal_value(distal_value)
    % Load robot
    load("my_robot.mat")
    % Extract tau (always the last element)
    tau = -1*abs(distal_value(end)); % Negative because pulling tendon
    % Extract force parameters (everything except the last elements taus)
    force_matrix = distal_value(:,1:end-1); % N×3 matrix [F, s, sigma]
    
    % Change radius (commented out in original)
    %S1.VLinks.r = {[@(X1)X1.*(-1.0./1.0e+3)+1.5e-3]};
    %S1.CVRods{1}(end).UpdateAll;
    %S1 = S1.Update();
    
    % Apply multiple Gaussian forces
    S1 = apply_gaussian_force(S1, force_matrix, 200);
    
    % Initial Guess
    x0 = zeros(14,1);
    % initial joint values
    action = [tau;0;0;0;0;0;0];
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');
    
    Mx = u(1);
    My = u(2);
    Mz = u(3);
    Fx = u(4);
    Fy = u(5);
    Fz = u(6);
    
    proximal_value = [Mx,My,Mz,Fx,Fy,Fz,tau];
end