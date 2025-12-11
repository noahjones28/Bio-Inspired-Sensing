function [proximal_wrench, contact_xyz, force_vector_global] = get_proximal_value(distal_values, tau_array, doPlot, fig_handle, S1)
    % distal_values [F, s, theta1, theta2, sigma]
    % tau_array [tau1, tau2, tau3]
    
    % Properties
    theta2_default = pi/2; % default value
    sigma_default = 0.005; % default value
    tau_array_default = [0,0,0]; % default value
    N = size(distal_values,1); % number of forces
    sensor_offset = 90e-3; %Adjust the offset between the 6axis f/t sensor and the beam base
   
    % Set default values
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
        tau_array = tau_array_default;     % default value
    end
    if size(distal_values,2) < 4 % if theta2 not provided assign it default value
        distal_values = [distal_values, repmat(theta2_default, N, 1)];
    end
    if size(distal_values,2) < 5 % if sigma not provided assign it default value
        distal_values = [distal_values, repmat(sigma_default, N, 1)];
    end
    if S1.VLinks(2).npie-1 == 5 % if using 5 divisions beam
        x0 = zeros(66,1); % inital guesss
    elseif S1.VLinks(2).npie-1 == 20 % if using 20 divisions beam 
        x0 = zeros(246,1); % inital guesss
    else % if using single division beam 
        x0 = zeros(18,1);
    end

    % ALWAYS make tau negative for pulling tendons (push is positive)
    tau_array = -1*abs(tau_array);

    % Sort distal_values based on s column (descending order)
    [~, idx] = sort(distal_values(:,2), 'descend');
    distal_values = distal_values(idx, :);

    % Apply external load modeled as Gaussian Curve
    [S1, force_vectors, force_idxs] = apply_gaussian_force(S1, distal_values);

    % Initial joint values
    action = [tau_array';0;0;0;0;0;0];

    %Statics simulation
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');
    
    % Plot deflected robot
    if doPlot
        plot_robot(S1, q, distal_values, tau_array, force_vectors, force_idxs, doPlot, fig_handle);
    end

    % Get contact position
    [~, idx] = max(vecnorm(force_vectors));
    contatct_node_idx = force_idxs(idx);
    force_vector = force_vectors(:,idx);
    [contact_xyz, force_vector_global] = get_transformed_force(S1, q, contatct_node_idx, force_vector);


    % Flip sign of u becuase we want force on robot not on joint  
    Tx_sensor = -u(1);
    Ty_sensor = -u(2);
    Tz_sensor = -u(3);
    Fx_sensor = -u(4);
    Fy_sensor = -u(5);
    Fz_sensor = -u(6);
    
    % Transport wrench back to beam base if using sensor offset (remove geometric coupling)
    if sensor_offset > 0
        Ty_base = Ty_sensor+sensor_offset*Fz_sensor; % +offset
        Tz_base = Tz_sensor-sensor_offset*Fy_sensor; % -offset
    else
       Ty_base = Ty_sensor;
       Tz_base = Tz_sensor;
    end
    
    % Output
    proximal_wrench = [Tx_sensor,Ty_base,Tz_base,Fx_sensor,Fy_sensor,Fz_sensor];

end