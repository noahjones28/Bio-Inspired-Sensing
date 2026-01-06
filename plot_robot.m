function plot_robot(S, q, distal_values, internal_wrenches, doPlot, fig_handle)
    plot_geometry = true;
    vonmises_fos_overlay = true;
    plot_regulization_gaussian = true;
    plot_tendons = false;
    export_plot = false;
    colors = {'#FF00FF', '#00FFFF'}; % Colors for different forces

    if nargin < 5 % if doPlot was not provided
        doPlot = false; % default
    end
    if nargin < 6 % if fig_handle was not provided
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
        if vonmises_fos_overlay
            S = vonmises_fos_overlay_func(S,internal_wrenches);
        end
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
    rotate3d on; grid on; axis equal
    camlight(120, 45);
    
    % Parameters
    num_sig = S.nsig;
    num_forces = size(distal_values, 1);
    linkage_length = 0.1;
    force_idxs = S.Fp_sig'; % List of quadpoint idxs with an applied force 
    
    % get force vectors
    force_vectors_cell = cellfun(@(f) f(0), S.Fp_vec, 'UniformOutput', false);
    force_vectors = cell2mat(force_vectors_cell); % convert to matrix
    force_vectors(1:3, :) = [];

    % Get transformation matrices at all significant points
    transform_matrices = S.FwdKinematics(q);
    col_4 = reshape(transform_matrices(:,4), 4, num_sig); % pick the 4th column of each block
    pos_xyz = col_4(1:3, :); % extarct xyz position from each matrix
    
    % Define undeflected backbone positions (along x-axis)
    undeflected_x = linspace(0, linkage_length, num_sig);
    undeflected_backbone = [undeflected_x; zeros(1, num_sig); zeros(1, num_sig)];

    % Rotate force vectors
    force_vectors_rotated = zeros(size(force_vectors,1), size(force_vectors,2));
    for i = 1:size(force_vectors,2)
        idx = force_idxs(i);
        % Extract the i-th transformation matrix
        T = transform_matrices((idx-1)*4+1:idx*4, :);  % 4x4 matrix
        
        % Extract the 3x3 rotation part (no scale present)
        R = T(1:3, 1:3);
        
        % Rotate the AB vector
        force_vectors_rotated(:,i) = R*force_vectors(:,i);
    end
    
    % Get translations
    translations = zeros(3, num_sig);
    for i = 1:num_sig
        % translation
        translations(:,i) = pos_xyz(:,i) - undeflected_backbone(:,i);
    end

    % Plot the undeflected backbone
    h_undeflected = plot3(undeflected_backbone(1,:), undeflected_backbone(2,:), undeflected_backbone(3,:), 'k--', 'LineWidth', 2);
        
    % --- Plot the x-axis, y-axis and z-axis global axis ---
    quiver3(0,0,0,1,0,0,0.02,'r-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,1,0,0.02,'g-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,0,1,0.02,'b-','MaxHeadSize',1.0,'LineWidth', 2)
    
    % Plot deflected backbone
    plot3(pos_xyz(1,:), pos_xyz(2,:), pos_xyz(3,:), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);

    
    % Plot deflected tendons
    if plot_tendons
        tendon1_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(30); undeflected_backbone(3,:)+8e-3*sind(30)];
        tendon2_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(150); undeflected_backbone(3,:)+8e-3*sind(150)];
        tendon3_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(270); undeflected_backbone(3,:)+8e-3*sind(270)];
        tendon1_deflected = tendon1_undeflected+translations;
        tendon2_deflected = tendon2_undeflected+translations;
        tendon3_deflected = tendon3_undeflected+translations;
        h_tendon1 = plot3(tendon1_deflected(1,:), tendon1_deflected(2,:), tendon1_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#9334e6'));
        h_tendon2 = plot3(tendon2_deflected(1,:), tendon2_deflected(2,:), tendon2_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#e1477e'));
        h_tendon3 = plot3(tendon3_deflected(1,:), tendon3_deflected(2,:), tendon3_deflected(3,:), 'm-.', 'LineWidth', 2, 'MarkerSize', 10, 'Color', hex2rgb('#741b47'));
    end
    
    % Get backbone positions of the forces
    force_positions = pos_xyz(:,force_idxs);

    % If any element in force_vectors is non-zero
    if any(force_vectors(:) ~= 0)
        % --- Plot the tips of force vectors ---
        % Calculate tip positions (starting from points on x-axis)
        force_scaler = 0.05/max(vecnorm(force_vectors_rotated)); % Normalize and scale
        tip_x = force_positions(1,:) - force_scaler * force_vectors_rotated(1,:);
        tip_y = force_positions(2,:) - force_scaler * force_vectors_rotated(2,:);
        tip_z = force_positions(3,:) - force_scaler * force_vectors_rotated(3,:);

        if plot_regulization_gaussian
            if num_forces == 1
                % Plot the line connecting all tips
                plot3(tip_x, tip_y, tip_z, 'k-', 'LineWidth', 1);
                % Shade the region between curve and x-axis
                surf([force_positions(1,:); tip_x], [force_positions(2,:); tip_y], [force_positions(3,:); tip_z], ...
                     'FaceColor', hex2rgb(colors{1}), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            else
                % Find jump point between forces (abrupt change in position)
                dists = vecnorm(diff(force_positions, 1, 2));
                [~, jump_idx] = max(dists);
                
                idx1 = 1:jump_idx;
                idx2 = (jump_idx+1):size(force_positions,2);
                
                % Plot the line connecting tips for each force separately
                plot3(tip_x(idx1), tip_y(idx1), tip_z(idx1), 'k-', 'LineWidth', 1);
                plot3(tip_x(idx2), tip_y(idx2), tip_z(idx2), 'k-', 'LineWidth', 1);
                
                % Shade force 1 region
                surf([force_positions(1,idx1); tip_x(idx1)], [force_positions(2,idx1); tip_y(idx1)], [force_positions(3,idx1); tip_z(idx1)], ...
                     'FaceColor', hex2rgb(colors{1}), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                
                % Shade force 2 region
                surf([force_positions(1,idx2); tip_x(idx2)], [force_positions(2,idx2); tip_y(idx2)], [force_positions(3,idx2); tip_z(idx2)], ...
                     'FaceColor', hex2rgb(colors{2}), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            end
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
        if plot_tendons
            legend_labels = cell(1, length(locs) + 4);
            legend_handles = [h_forces, h_tendon1, h_tendon2, h_tendon3, h_undeflected];
        else
            legend_labels = cell(1, length(locs) + 1);
            legend_handles = [h_forces, h_undeflected];
        end
        
        for i = 1:length(locs)
            if num_forces == 1
                legend_labels{i} = sprintf('Force %d: \\bfF\\rm = %.3f N, \\bfs\\rm = %.3f m, \\bfθ\\rm = %.3f rad', ...
                    i, distal_values(1), distal_values(2), distal_values(3));
            else
                legend_labels{i} = sprintf('Force %d: \\bfF\\rm = %.3f N, \\bfs\\rm = %.3f m, \\bfθ\\rm = %.3f rad', ...
                    i, distal_values(i, 1), distal_values(i, 2), distal_values(i, 3));
            end
        end
        
        % Add tendon labels if plotting tendons
        if plot_tendons
            legend_labels{length(locs) + 1} = sprintf('Tendon 1: \\bftau\\rm = %.3f', tau_array(1));
            legend_labels{length(locs) + 2} = sprintf('Tendon 2: \\bftau\\rm = %.3f', tau_array(2));
            legend_labels{length(locs) + 3} = sprintf('Tendon 3: \\bftau\\rm = %.3f', tau_array(3));
            legend_labels{length(locs) + 4} = 'Initial Deflection';
        else
            legend_labels{length(locs) + 1} = 'Initial Deflection';
        end
        legend(legend_handles, legend_labels, 'Location', 'southeast');
    end
    drawnow; % Force immediate plot update

    % Optional export plot
    if export_plot
        exportgraphics(gcf, 'FixedPlot.pdf', 'ContentType', 'image', 'Resolution', 600);
    end
end

%% Vonmises FOS overlay
function S = vonmises_fos_overlay_func(S, internal_wrenches)
    yield_strength = 35e6;
    for i=1:S.N
        r_major = S.CVRods{i}(end).Link.a{1}(0);
        r_minor = S.CVRods{i}(end).Link.b{1}(0);
        Tx = internal_wrenches(i,1);
        Ty = internal_wrenches(i,2);
        Tz = internal_wrenches(i,3);
        [max_vm, fos] = calc_ellipse_vonmises(r_major, r_minor, Tx, Ty, Tz, yield_strength);
        
        % fos to color
        if fos <= 1
            % Red
            color = [1, 0, 0];
        elseif fos <= 2
            % Interpolate red to yellow (increase green)
            t = fos - 1;  % t goes from 0 to 1
            color = [1, t, 0];
        elseif fos <= 3
            % Interpolate yellow to green (decrease red)
            t = fos - 2;  % t goes from 0 to 1
            color = [1 - t, 1, 0];
        else
            % Green
            color = [0, 1, 0];
        end
        % Update link color
        S.CVRods{i}(end).Link.color = color;
        S.CVRods{i}(end).UpdateAll;
    end
    % Update linkage with changes
    S = S.Update();
end