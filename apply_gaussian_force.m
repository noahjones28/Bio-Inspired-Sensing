function S  = apply_gaussian_force(S, distal_values)
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
    plot_gaussain_debug = false; % true for debug visualization of gaussian distribution
    num_applied_forces = size(distal_values, 1); % number of user-specified point forces 
    link_length = S.VLinks(end).L; % Length of each link
    num_links = S.N; % Number of links
    % List of normalized quadpoints on a link
    % We assume all links have the same quadpoints
    quadpoints_local = S.CVRods{end}(end).Xs';
    quadpoint_globalx = get_quadpoint_globalx(link_length, num_links, quadpoints_local);
  
    %% COMPUTE FORCE VECTORS
    % Initialize storage cells
    force_vectors = {};
    force_links = {};
    force_locations = {};
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
        [x_loads, F_loads] = distributePointLoad(F, s, quadpoint_globalx, sigma, plot_gaussain_debug);
        num_dist_points = length(F_loads);
        % Convert each force to 3D cartesian vector in x-y-z using angles
        [x,y,z] = rollPitchToCartesian(roll*ones(1,num_dist_points), pitch*ones(1,num_dist_points), F_loads);
        F_global = [x;y;z];
        % Get target links
        link_idxs = get_link_idxs(x_loads, link_length, num_links);
        % Get local normalized locations
        locations = get_normalized_locations(x_loads, link_idxs, link_length, num_links, quadpoints_local);
        % Map the global force vector into the local frame of link i
        F_local = global_to_local(S.g_ini, link_idxs, F_global);

        % Fill storage cells with result
        force_vectors{end+1} = F_local;
        force_links{end+1} = link_idxs;
        force_locations{end+1} = locations;
    end
    % Convert from cell to matrix
    force_vectors = cell2mat(force_vectors);
    force_links = cell2mat(force_links);
    force_locations = cell2mat(force_locations);
    force_divisions = 1;
    
    
    %% APPLY FORCES TO ROBOT
    num_force_vectors = size(force_vectors,2);
    S.Fp_vec = cell(1, num_force_vectors); % force vector
    S.Fp_loc = cell(1, num_force_vectors); % force location
    for i = 1:num_force_vectors
        S.Fp_vec{i} = @(t)[0, 0, 0, force_vectors(1,i),...
            force_vectors(2,i), force_vectors(3,i)]';
        S.Fp_loc{i} = [force_links(i), force_divisions, force_locations(i)];
    end
    S.np = num_force_vectors; % Update number of forces
    S.LocalWrench = ones(1, num_force_vectors); % Update if forces are local or global
    S.Fp_sig = PointWrenchPoints(S); % Update number of significant points
    
end

%% get_quadpoint_globalx
function quadpoint_globalx = get_quadpoint_globalx(link_length, num_links, quadpoints_local)        
    beam_offsets = (0 : num_links-1) * link_length;
    global_matrix = (quadpoints_local(:) * link_length) + beam_offsets;
    quadpoint_globalx = global_matrix(:)';
    quadpoint_globalx = unique(quadpoint_globalx);
end

%% get_target_links
function link_idxs = get_link_idxs(x, link_length, num_links)
    link_idxs = floor(x / link_length) + 1;
    % Edge case handling: 
    % If x is exactly 0.2, the formula gives 21. We clamp it to 20.
    link_idxs = min(link_idxs, num_links);
    % Clamp the lower bound to 1
    % This handles cases where s < 0 (e.g., -1e-10) which would cause index 0
    link_idxs = max(link_idxs, 1);
end


%% get_normalized_locations
function locations = get_normalized_locations(x, link_idxs, link_length, num_links, quadpoints_local) 
    % Calculate local percentage (0.0 to 1.0)
    % Formula: (GlobalPos / Length) - (BeamsBefore)
    percent = (x ./ link_length) - (link_idxs - 1);
    % Optional: Clamp percentage to [0, 1] to handle float noise 
    percent = max(0, min(percent, 1));
    % Calculate absolute difference between quadpoints and percent
    diffs = abs(quadpoints_local' - percent);
    % Find the index of the minimum difference
    [~, idx] = min(diffs);
    %
    locations = quadpoints_local(idx);
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

