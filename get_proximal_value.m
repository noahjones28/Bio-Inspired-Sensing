function [proximal_value, u] = get_proximal_value(distal_values, tau_array, doPlot, fig_handle)
    % distal_values [F, s, el, az]
    % tau_array [tau1, tau2, tau3]

    if nargin < 4   % if fig_handle was not provided
        fig_handle = false;      % default value
    end
    if nargin < 3   % if doPlot was not provided
        doPlot = false;     % default value
    end
    
    % ALWAYS make tau negative for pulling tendons (push is positive)
    tau_array = -1*tau_array;

    % Load robot
    load("my_robot.mat");

    % S1.VLinks(2).r{1} = @(X1) 1.25e-3;
    % S1.CVRods{2}(1+1).UpdateAll;
    % S1 = S1.Update();

    % Apply multiple Gaussian forces
    [S1, force_vectors] = apply_gaussian_force(S1, distal_values);
    
    % Initial guess
    x0 = zeros(18,1);

    % Initial joint values
    action = [tau_array';0;0;0;0;0;0];

    %Statics simulation
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');

    % Plot robot
    if doPlot
        plot_robot(S1, q, distal_values, force_vectors, doPlot, fig_handle);
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