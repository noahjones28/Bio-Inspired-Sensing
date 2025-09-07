function proximal_value = get_proximal_value(distal_values, doPlot, fig_handle)
    if nargin < 3   % if fig_handle was not provided
        fig_handle = false;      % default value
    end
    if nargin < 2   % if doPlot was not provided
        doPlot = false;     % default value
    end
    add_tendon_contribution_from_spreadsheet = false;
    spreadsheet_filename = '\SoRoSim Robots\my_robot(2.0to1.0)\tendon_table.xlsx';
    % distal_values N×6 matrix [F, s, el, az, tau]
    % Load robot
    load("my_robot.mat");
    % Extract tau (always the last element)
    tau = -1*abs(distal_values(end)); % Negative because pulling tendon

    % %Change radius (commented out in original)
    % vals = [0.00351997, 0.00153437, 0.00320329, 0.00143504, 0.00289957,...
    %     0.00132352, 0.00260732, 0.00120121, 0.00232522, 0.00106937,...
    %     0.00205208, 0.00092908, 0.00178689, 0.00078132, 0.00152873,...
    %     0.00062695, 0.00127678, 0.00046673, 0.00103034, 0.00030133];
    % for i=1:20
    %     S1.VLinks.r{i} = @(X1)vals(i);
    %     S1.CVRods{1}(i+1).UpdateAll;
    %     S1 = S1.Update();
    % end
    
    % S1.VLinks.r{1} = @(X1) (0.0012*exp(-6*X1*L1.L)*sin(314*X1*L1.L))+(0.0012+0.00127)-0.01*X1*L1.L;
    % S1.CVRods{1}(1+1).UpdateAll;
    % S1 = S1.Update();

    % Apply multiple Gaussian forces
    S1 = apply_gaussian_force(S1, distal_values, 200, doPlot, fig_handle);
    
    % Initial Guess
    x0 = zeros(18,1);
    % initial joint values
    action = [tau;0;0;0;0;0;0];
    [q,u,lambda] = S1.statics(x0,action,'plotResult',true,'Display','off');
    u = -u(1:end-1)'; %flip sign, remove tau, transpose
    
    % u = [Tx_body,Ty_body,Tz_body,Fx_body,Fy_body,Fz_body]
    % minus signs are added becuase u is the wrench on the robot body not
    % on the 6-axis ft sensor
    if add_tendon_contribution_from_spreadsheet && tau ~= 0
        [row_vector, row_index] = findClosestRow(spreadsheet_filename, 1, 1, tau);
        u = u+row_vector;
    end
    
    Tx = u(1);
    Ty = u(2);
    Tz = u(3);
    Fx = u(4);
    Fy = u(5);
    Fz = u(6);
    
    proximal_value = [Tx,Ty,Tz,Fx,Fy,Fz,tau];

end