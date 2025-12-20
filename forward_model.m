function [proximal_wrench] = forward_model(distal_values, tau_array, doPlot, fig_handle, S1)
    %% ABOUT
    % Input: External applied forces x = [F1,s1,theta1;...FN,sN,thetaN] and
    % tendon tensions τ = [τ1, τ2, τ3]

    % Output: Proximal wrench Wm = [Tx,Ty,Tz,Fx,Fy,Fz]


    %% SETUP
    theta_pitch_default = pi/2; % Pitch angle [0,pi] (default pi/2 = perpendicular)
    sigma_default = 0.005; % Gaussian force distribution spread (stdev)
    tau_array_default = [0,0,0]; % Default tendon tensions
    N = size(distal_values,1); % Number of applied forces
    sensor_offset = 90e-3; % Adjust the offset between the 6axis f/t sensor and the beam base
   
    % Set default values
    if nargin < 5   % if SoRoSim Linkage S1 was not provided
        load("my_robot.mat");   % Default load my_robot
    end
    if nargin < 4   % if fig_handle was not provided
        fig_handle = false;      % Set default value
    end
    if nargin < 3   % if doPlot was not provided
        doPlot = false;     % Set default value
    end
    if nargin < 2   % if tau_array was not provided
        tau_array = tau_array_default;     % Set default value
    end
    if size(distal_values,2) < 4 % if theta_pitch not provided
        distal_values = [distal_values, repmat(theta_pitch_default, N, 1)]; % Set default value
    end
    if size(distal_values,2) < 5 % if sigma not provided assign
        distal_values = [distal_values, repmat(sigma_default, N, 1)]; % Set default value
    end

    % Set initial guess depending on linkage configuration
    if S1.VLinks(2).npie-1 == 5 % if using 5 divisions beam
        x0 = zeros(66,1); % inital guesss
    elseif S1.VLinks(2).npie-1 == 20 % if using 20 divisions beam 
        x0 = zeros(246,1); % inital guesss
    else % if using single division beam 
        x0 = zeros(18,1);
    end

    % Sign convention:
    %   tau_array < 0 → tendon pulling (tension)
    %   tau_array > 0 → pushing (compression)
    tau_array = -1*abs(tau_array);

    % Sort forces by descending s so force 1 is most distal
    [~, idx] = sort(distal_values(:,2), 'descend');
    distal_values = distal_values(idx, :);


    %% APPLY FORCE TO LINKAGE
    % Apply external load modeled as Gaussian Curve
    [S1, force_vectors, force_idxs] = apply_gaussian_force(S1, distal_values);
    

    %% STATICS SIMULATION
    % Initial tendon tenions and joint position values 
    action = [tau_array';0;0;0;0;0;0];

    % Statics simulation
    [q,u,lambda] = S1.statics(x0,action,'plotResult',false,'Display','off');
    
    % Plot deflected robot
    if doPlot
        plot_robot(S1, q, distal_values, tau_array, force_vectors, force_idxs, doPlot, fig_handle);
    end
   

    %% POST PROCESSING
    % Sign convention:
    %   u < 0 → force on joint (reaction force)
    %   u > 0 → force on robot
    Tx_sensor = -u(1);
    Ty_sensor = -u(2);
    Tz_sensor = -u(3);
    Fx_sensor = -u(4);
    Fy_sensor = -u(5);
    Fz_sensor = -u(6);
    
    % Apply offset correction if using sensor offset (remove geometric coupling)
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