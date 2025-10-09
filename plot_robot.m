function positions = plot_robot(S, q, distal_values, tau_array, force_vectors, force_idxs, doPlot, fig_handle)
    plot_geometry = true;
    plot_regulization_gaussian = false;

    if nargin < 7 % if doPlot was not provided
        doPlot = false; % default
    end
    if nargin < 8 % if fig_handle was not provided
        fig_handle = false; % default
    end
    if doPlot && ishandle(fig_handle)
        figure(fig_handle); % Use existing figure
        clf;
        % Figure config
        set(gcf, 'Position', [1920/2, 100, 800, 800]);
        set(gca, 'Units','normalized', 'Position', [0.2 0.2 0.70 0.56]);
        hold on; grid on; axis equal; axis vis3d; 
    elseif doPlot && plot_geometry
        close;
        S.plotq(q) % plot geometry 
        figure(gcf); % Create new figure if handle not provided
    elseif doPlot
        close;
        figure; % Create new figure if handle not provided
        % Figure config
        set(gcf, 'Position', [1920/2, 100, 800, 800]);
        set(gca, 'Units','normalized', 'Position', [0.2 0.2 0.70 0.56]);
        hold on; grid on; axis equal; axis vis3d; 
    end
    
    % Axis setup
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title('Deflected Robot Shape');
    view(120, 15);
    rotate3d on; grid on; axis equal;
    
    % Extract positions
    num_divs = S.VLinks(2).npie-1; % number of divisions
    quadpoints = S.CVRods{2}(2).Xs; % get quadpoints of just first div (each div has same quadpoints) 
    quadpoints_per_div = length(quadpoints);
    num_quadpoints_total = S.nsig;
    num_quadpoints_link = quadpoints_per_div*num_divs;
    num_forces = size(distal_values, 1);
    
    % Get transformation matrices at all points
    g_all = S.FwdKinematics(q);
    g_link = g_all((num_quadpoints_total-num_quadpoints_link)*4+1:end, :); % isolate transformation matrices of our main link
    g_col4 = reshape(g_link(:,4), 4, num_quadpoints_link); % pick the 4th column of each block
    position = g_col4(1:3, :); % extarct xyz position from each matrix
    
    % Define undeflected backbone positions (along x-axis)
    beam_length = 0.2;
    undeflected_x = linspace(0, beam_length, num_quadpoints_link);
    undeflected_backbone = [undeflected_x; zeros(1, num_quadpoints_link); zeros(1, num_quadpoints_link)];

    % Rotate force vectors
    force_vectors_rotated = zeros(size(force_vectors,1), size(force_vectors,2));
    for i = 1:length(force_idxs)
        idx = force_idxs(i);
        % Extract the i-th transformation matrix
        T = g_link((idx-1)*4+1:idx*4, :);  % 4x4 matrix
        
        % Extract the 3x3 rotation part (no scale present)
        R = T(1:3, 1:3);
        
        % Rotate the AB vector
        force_vectors_rotated(:,i) = R*force_vectors(:,i);
    end
    
    % Get translations
    translations = zeros(3, num_quadpoints_link);
    for i = 1:num_quadpoints_link
        % translation
        translations(:,i) = position(:,i) - undeflected_backbone(:,i);
    end


    % Plot the undeflected backbone
    h_undeflected = plot3(undeflected_backbone(1,:), undeflected_backbone(2,:), undeflected_backbone(3,:), 'k--', 'LineWidth', 2);
        
    % --- Plot the x-axis, y-axis and z-axis global axis ---
    quiver3(0,0,0,1,0,0,0.02,'r-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,1,0,0.02,'g-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,0,1,0.02,'b-','MaxHeadSize',1.0,'LineWidth', 2)
    
    % Plot deflected backbone
    plot3(position(1,:), position(2,:), position(3,:), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);

    % Plot deflected tendons
    tendon1_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(30); undeflected_backbone(3,:)+8e-3*sind(30)];
    tendon2_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(150); undeflected_backbone(3,:)+8e-3*sind(150)];
    tendon3_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(270); undeflected_backbone(3,:)+8e-3*sind(270)];
    tendon1_deflected = tendon1_undeflected+translations;
    tendon2_deflected = tendon2_undeflected+translations;
    tendon3_deflected = tendon3_undeflected+translations;
    h_tendon1 = plot3(tendon1_deflected(1,:), tendon1_deflected(2,:), tendon1_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#9334e6'));
    h_tendon2 = plot3(tendon2_deflected(1,:), tendon2_deflected(2,:), tendon2_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#e1477e'));
    h_tendon3 = plot3(tendon3_deflected(1,:), tendon3_deflected(2,:), tendon3_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#741b47'));
    
    % Get backbone positions of the forces
    force_positions = position(:,force_idxs);

    % If any element in force_vectors is non-zero
    if any(force_vectors(:) ~= 0)
        % --- Plot the tips of force vectors ---
        % Calculate tip positions (starting from points on x-axis)
        force_scaler = 0.5;  % Scale factor for visualization
        tip_x = force_positions(1,:) - force_scaler * force_vectors_rotated(1,:);
        tip_y = force_positions(2,:) - force_scaler * force_vectors_rotated(2,:);
        tip_z = force_positions(3,:) - force_scaler * force_vectors_rotated(3,:);
        
        if plot_regulization_gaussian
            % Plot the line connecting all tips
            plot3(tip_x, tip_y, tip_z, 'k-', 'LineWidth', 1);
            % Shade the region between curve and x-axis
            surf([force_positions(1,:); tip_x], [force_positions(2,:); tip_y], [force_positions(3,:); tip_z], ...
                 'FaceColor', 'm', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        end

        % Find and plot the largest vectors also sort the peaks from largest to smallest
        [pks, locs] = findpeaks(vecnorm(force_vectors_rotated));
        % Check endpoints manually
        vec_norms = vecnorm(force_vectors_rotated);
        n = length(vec_norms);
        % Check if first point is a local maximum
        if n > 1 && vec_norms(1) > vec_norms(2)
            pks = [vec_norms(1); pks];
            locs = [1; locs];
        end
        % Check if last point is a local maximum
        if n > 1 && vec_norms(end) > vec_norms(end-1)
            pks = [pks; vec_norms(end)];
            locs = [locs; n];
        end
        % Now sort by locs in decneding order
        [locs, sortIdx] = sort(locs, 'ascend');
        pks = pks(sortIdx);
        
        colors = {'#24a146', '#27bcd1'}; % Colors for different forces
        h_forces = []; % Handles for legend
        
        for i = 1:length(locs)
            color_idx = mod(i-1, length(colors)) + 1;
            h = quiver3(force_positions(1,locs(i)) - force_scaler*force_vectors_rotated(1,locs(i)), ...
                    force_positions(2,locs(i)) - force_scaler*force_vectors_rotated(2,locs(i)), ...
                    force_positions(3,locs(i)) - force_scaler*force_vectors_rotated(3,locs(i)), ...
                    force_scaler*force_vectors_rotated(1,locs(i)), ...
                    force_scaler*force_vectors_rotated(2,locs(i)), ...
                    force_scaler*force_vectors_rotated(3,locs(i)), ...
                    0, 'Color', hex2rgb(colors{color_idx}), 'LineWidth', 3, 'MaxHeadSize', 0.5);
            h_forces(i) = h;
        end
        
        % Add legend with parameter values for forces and tendons
        legend_labels = cell(1, length(locs) + 3);
        legend_handles = [h_forces, h_tendon1, h_tendon2, h_tendon3, h_undeflected];
        
        for i = 1:length(locs)
            if num_forces == 1
                legend_labels{i} = sprintf('Force %d: \\bfF\\rm = %.3f N, \\bfs\\rm = %.3f m, \\bfel\\rm = %.3f rad, \\bfaz\\rm = %.3f rad', ...
                    i, distal_values(1), distal_values(2), distal_values(3), distal_values(4));
            else
                legend_labels{i} = sprintf('Force %d: \\bfF\\rm = %.3f N, \\bfs\\rm = %.3f m, \\bfel\\rm = %.3f rad, \\bfaz\\rm = %.3f rad', ...
                    i, distal_values(i, 1), distal_values(i, 2), distal_values(i, 3), distal_values(i, 4));
            end
        end
        
        % Add tendon labels
        legend_labels{length(locs) + 1} = sprintf('Tendon 1: \\bftau\\rm = %.3f', tau_array(1));
        legend_labels{length(locs) + 2} = sprintf('Tendon 2: \\bftau\\rm = %.3f', tau_array(2));
        legend_labels{length(locs) + 3} = sprintf('Tendon 3: \\bftau\\rm = %.3f', tau_array(3));
        legend_labels{length(locs) + 4} = 'Initial Deflection';
        
        legend(legend_handles, legend_labels, 'Location', 'southeast');
    end

    drawnow; % Force immediate plot update
end