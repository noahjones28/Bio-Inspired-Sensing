function proximal_value = get_proximal_value(distal_values, tau_array, doPlot, fig_handle)
    % distal_values [F, s, el, az]
    % tau_array [tau1, tau2, tau3]

    if nargin < 4   % if fig_handle was not provided
        fig_handle = false;      % default value
    end
    if nargin < 3   % if doPlot was not provided
        doPlot = false;     % default value
    end

    % Load robot
    load("my_robot.mat");

    % Apply multiple Gaussian forces
    [S1, force_vectors, quadpoint_idxs] = apply_gaussian_force(S1, distal_values, 100, doPlot, fig_handle);
    
    % Initial guess
    x0 = zeros(18,1);

    % Initial joint values
    action = [tau_array';0;0;0;0;0;0];

    %Statics simulation
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');

    % Plot robot
    if doPlot
        plot_robot(S1, q, distal_values, force_vectors, quadpoint_idxs, doPlot, fig_handle);
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