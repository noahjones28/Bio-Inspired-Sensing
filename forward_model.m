function [proximal_wrench, internal_wrenches] = forward_model(distal_values, tau_array, doPlot, fig_handle, S)
    %% ABOUT
    % Input: External applied forces x = [F1,S,theta1;...FN,sN,thetaN] and
    % tendon tensions τ = [τ1, τ2, τ3]

    % Output: Proximal wrench Wm = [Tx,Ty,Tz,Fx,Fy,Fz]


    %% SETUP
    theta_pitch_default = pi/2; % Pitch angle [0,pi] (default pi/2 = perpendicular)
    sigma_default = 0.005; % Gaussian force distribution spread (stdev)
    tau_array_default = [0,0,0]; % Default tendon tensions
    N = size(distal_values,1); % Number of applied forces
   
    % Set default values
    if nargin < 5   % if SoRoSim Linkage S was not provided
        load('my_robot.mat','S');   % Default load my_robot
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

    % Set initial guess W0 depending on total number of degrees of freedom
    ndof = S.ndof;
    W0 = zeros(ndof,1);

    % Sign convention:
    %   tau_array < 0 → tendon pulling (tension)
    %   tau_array > 0 → pushing (compression)
    tau_array = -1*abs(tau_array);

    % Sort forces by descending s so force 1 is most distal
    [~, idx] = sort(distal_values(:,2), 'descend');
    distal_values = distal_values(idx, :);


    %% APPLY FORCE TO LINKAGE
    % Apply external load modeled as Gaussian Curve
    S = apply_gaussian_force(S, distal_values);
    

    %% STATICS SIMULATION
    % Initial joint position values 
    initial_joint = [0;0;0;0;0;0];
    action = [tau_array';initial_joint]; % append tendon actuation

    % Statics simulation
    [q,u,lambda] = S.statics(W0,action,'plotResult',false,'Display','off');
  

    %% PROXIMAL WRENCH
    % Sign convention:
    %   u < 0 → force on joint (reaction force)
    %   u > 0 → force on robot
    Tx_sensor = -u(1);
    Ty_sensor = -u(2);
    Tz_sensor = -u(3);
    Fx_sensor = -u(4);
    Fy_sensor = -u(5);
    Fz_sensor = -u(6);
    
    % Output
    proximal_wrench = [Tx_sensor,Ty_sensor,Tz_sensor,Fx_sensor,Fy_sensor,Fz_sensor];
    
    
    %% INTERNAL STRAINS/WRENCHES
    strains = S.ScrewStrain(q);
    strains = reshape(strains, 6, S.nsig);
    nsig_per_link = S.nsig / S.N;
    internal_strains = strains(:, 2:nsig_per_link:end);
    internal_wrenches = zeros(6, S.N);  % Preallocate  
    for i = 1:S.N
        Es = S.CVRods{i}(end).Es(1:6, 1:end);
        internal_wrenches(:, i) = Es * internal_strains(:, i);
    end
    internal_wrenches = internal_wrenches(1:3,:)';
    
    %% PLOTTING
    if doPlot
        plot_robot(S, q, distal_values, tau_array, internal_wrenches, doPlot, fig_handle);
    end
end