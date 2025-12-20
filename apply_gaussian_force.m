function [S,force_vectors, force_idxs]  = apply_gaussian_force(S, distal_values)
    %% ABOUT
    % Applies a user-specified point force as a narrow gaussian
    % distributed force to SoRoSim likage S

    % Input:
    % S: SoRoSim linkage
    % distal_values: [F1,s1,theta_roll1,theta_pitch1,sigma1;...,F1,s1,theta_roll1,theta_pitch1,sigma1]

    % Output:
    % S: Updated SoRoSim linkage
    % force_vectors: 3XN force vectors of each point force in distribution
    % force_idxs: force vector indecies for quick lookup

    %% SETUP
    num_major_link = 2; % Main Link where force is to be applied
    plot_gaussain_debug = false; % true for debug visualization of gaussian distribution
    num_applied_forces = size(distal_values, 1); % number of user-specified point forces 
    num_divs = S.VLinks(num_major_link).npie-1; % number of divisions in main link
    L_div = S.VLinks(num_major_link).L/num_divs; % length of division
    quadpoints = S.CVRods{num_major_link}(2).Xs; % get quadpoints of just first div (each div has same quadpoints) 
    quadpoints_per_div = length(quadpoints);
    quadlengths = [];
    for i=1:num_divs  
        quadlengths_new = quadpoints'*L_div+L_div*(i-1);
        % Modify first and last value by tiny bit to avoid duplictae points
        quadlengths_new(1) = quadlengths_new(1)+1e-5;
        quadlengths_new(end) = quadlengths_new(end)-1e-5;
        quadlengths = [quadlengths, quadlengths_new];
    end
  
    %% COMPUTE FORCE VECTORS
    % Initialize storage cells
    force_vectors = {};
    force_divisions = {};
    force_locations = {};
    force_idxs = {};
    % for each user-specified point forces 
    for i = 1:num_applied_forces
        F = distal_values(i, 1);
        s = distal_values(i, 2);
        roll = distal_values(i, 3);
        pitch = distal_values(i, 4);
        sigma = distal_values(i, 5);
        % Convert point load into a discretized Gaussian distribution in x-y plane
        % point force is represented by a set of smaller forces whose magnitudes sum
        % to the original load and follow the prescribed Gaussian profile.
        [x_loads, F_loads] = distributePointLoad(F, s, quadlengths, sigma, plot_gaussain_debug);
        num_dist_points = length(F_loads);
        % Convert each force to 3D cartesian vector in x-y-z using angles
        [x,y,z] = rollPitchToCartesian(roll*ones(1,num_dist_points), pitch*ones(1,num_dist_points), F_loads);
        % Get target division and idx of each vector 
        [target_divisions, idxs] = get_target_divisions(quadlengths, quadpoints_per_div, x_loads);
        % Fill storage cells with result
        force_vectors{end+1} = [x; y; z];
        force_divisions{end+1} = target_divisions;
        force_locations{end+1} = get_normalized_force_location(quadpoints, quadpoints_per_div, target_divisions, idxs);
        force_idxs{end+1} = idxs;
    end
    % Convert from cell to matrix
    force_vectors = cell2mat(force_vectors);
    force_divisions = cell2mat(force_divisions);
    force_locations = cell2mat(force_locations);
    force_idxs = cell2mat(force_idxs);
    
    
    %% APPLY FORCES TO ROBOT
    num_force_vectors = size(force_vectors,2);
    S.Fp_vec = cell(1, num_force_vectors); % force vector
    S.Fp_loc = cell(1, num_force_vectors); % force location
    for i = 1:num_force_vectors
        S.Fp_vec{i} = @(t)[0, 0, 0, force_vectors(1,i),...
            force_vectors(2,i), force_vectors(3,i)]';
        S.Fp_loc{i} = [num_major_link, force_divisions(i), force_locations(i)];
    end
    S.np = num_force_vectors; % Update number of forces
    S.LocalWrench = ones(1, num_force_vectors); % Update if forces are local or global
    S.Fp_sig = PointWrenchPoints(S); % Update number of significant points
    
end


%% get_target_divisions HELPER FUNCTION
function [target_divisions, idxs] = get_target_divisions(quadlengths,quadpoints_per_div,s) 
    target_divisions = zeros(1,length(s));
    idxs = zeros(1,length(s));
    for i=1:length(s)
        [~, idxs(i)] = min(abs(quadlengths - s(i)));
        % tiny 𝜀 (1e-5) pushes exact multiples just below the boundary
        target_divisions(i) = floor((idxs(i)-1e-5)/quadpoints_per_div) + 1;
    end
end


%% get_normalized_force_location HELPER FUNCTION
function normalized_force_locations = get_normalized_force_location(quadpoints,quadpoints_per_div,target_divisions, idx)
    normalized_force_locations = zeros(1,length(idx));
    for i=1:length(idx)
        normalized_force_locations(i) = quadpoints(idx(i)-(target_divisions(i)-1)*quadpoints_per_div);
    end
end


%% rollPitchToCartesian HELPER FUNCTION
function [x, y, z] = rollPitchToCartesian(roll, pitch, norm)
    x = norm .* cos(pitch);
    y = norm .* sin(pitch) .* cos(roll);
    z = norm .* sin(pitch) .* sin(roll);
end


%% distributePointLoad HELPER FUNCTION
function [x_loads, F_loads] = distributePointLoad(F_total, x0, x_available, sigma, plotFlag)
    % Distributes a point load using a Gaussian distribution
    %
    % Inputs:
    %   F_total      - Total force magnitude (scalar)
    %   x0           - Location of original point load
    %   x_available  - Vector of available x-coordinates (non-uniform)
    %   sigma        - Standard deviation of Gaussian distribution
    %   plotFlag     - (optional) true to show plot, false otherwise (default: false)
    %
    % Outputs:
    %   x_loads      - x-coordinates where loads are applied
    %   F_loads      - Magnitude of load at each x-coordinate
    
    if nargin < 5
        plotFlag = false;
    end
    
    % Evaluate Gaussian at each available point
    gaussian_weights = exp(-((x_available - x0).^2) / (2 * sigma^2));
    
    % Normalize so sum equals F_total
    F_loads = F_total * gaussian_weights / sum(gaussian_weights);
    
    % Return the coordinates
    x_loads = x_available;
    
    % Optional: filter out very small loads (< 0.1% of total)
    threshold = 0.001 * F_total;
    keep_idx = F_loads > threshold;
    x_loads = x_loads(keep_idx);
    F_loads = F_loads(keep_idx);
    
    % Renormalize after filtering
    F_loads = F_total * F_loads / sum(F_loads);
    
    % Plot if requested
    if plotFlag
        figure;
        
        % Create continuous Gaussian curve for reference
        x_continuous = linspace(min(x_available), max(x_available), 200);
        gaussian_continuous = exp(-((x_continuous - x0).^2) / (2 * sigma^2));
        gaussian_continuous = F_total * gaussian_continuous / sum(gaussian_weights);
        
        % Plot continuous Gaussian
        plot(x_continuous, gaussian_continuous, 'b-', 'LineWidth', 1.5, ...
             'DisplayName', 'Continuous Gaussian');
        hold on;
        
        % Plot distributed loads as stems
        stem(x_loads, F_loads, 'filled', 'LineWidth', 1, 'MarkerSize', 4, ...
             'Color', [0.85, 0.33, 0.1], 'DisplayName', 'Distributed loads');
        
        % Mark original load location
        plot(x0, F_total, 'rx', 'MarkerSize', 15, 'LineWidth', 3, ...
             'DisplayName', 'Original load location');
        
        % Mark all available points (even those with zero/filtered loads)
        plot(x_available, zeros(size(x_available)), 'ko', 'MarkerSize', 4, ...
             'DisplayName', 'Available grid points');
        
        xlabel('Position (m)', 'FontSize', 12);
        ylabel('Force (N)', 'FontSize', 12);
        title(sprintf('Gaussian Distribution of Point Load (\\sigma = %.4f m)', sigma), ...
              'FontSize', 13);
        legend('Location', 'best');
        grid on;
        
        % Add text box with summary
        textStr = sprintf(['Total Force: %.2f N\n' ...
                          'Number of loads: %d\n' ...
                          'Sum check: %.2f N'], ...
                          F_total, length(x_loads), sum(F_loads));
        annotation('textbox', [0.15, 0.75, 0.25, 0.15], 'String', textStr, ...
                   'BackgroundColor', 'white', 'EdgeColor', 'black', ...
                   'FontSize', 10, 'FitBoxToText', 'on');
        
        hold off;
    end
end