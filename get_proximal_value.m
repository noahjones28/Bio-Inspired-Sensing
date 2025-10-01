function [proximal_value, u] = get_proximal_value(distal_values, tau_array, doPlot, fig_handle, S1)
    % distal_values [F, s, el, az]
    % tau_array [tau1, tau2, tau3]
    
    if nargin < 5   % if S1 was not provided
        load("my_robot.mat");   % default load robot
    end
    if nargin < 4   % if fig_handle was not provided
        fig_handle = false;      % default value
    end
    if nargin < 3   % if doPlot was not provided
        doPlot = false;     % default value
    end
    if nargin < 2   % if tau_array was not provided
        tau_array = [0,0,0];     % default value
    end
    
    % ALWAYS make tau negative for pulling tendons (push is positive)
    tau_array = -1*abs(tau_array);

    % Apply multiple Gaussian forces
    [S1, force_vectors, force_idxs] = apply_gaussian_force(S1, distal_values);
    
    % Initial guess
    if S1.VLinks(2).npie-1 == 5 
        x0 = zeros(66,1); % if 5 divisions
    elseif S1.VLinks(2).npie-1 == 20 
        x0 = zeros(246,1);
    else
        x0 = zeros(18,1);
    end


    % Initial joint values
    action = [tau_array';0;0;0;0;0;0];

    %Statics simulation
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');

    % Plot robot
    if doPlot
        plot_robot(S1, q, distal_values, force_vectors, force_idxs, doPlot, fig_handle);
    end
    
    % Flip sign of u becuase we want force on robot not on joint  
    Tx = -u(1);
    Ty = -u(2);
    Tz = -u(3);
    Fx = -u(4);
    Fy = -u(5);
    Fz = -u(6);

    proximal_value = [Tx,Ty,Tz,Fx,Fy,Fz];

end