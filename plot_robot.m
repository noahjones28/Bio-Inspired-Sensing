function plot_robot(S, q, distal_values, tau_array, internal_wrenches, doPlot, fig_handle)
    % Parameters
    plot_geometry = true;
    vonmises_fos_overlay = true;
    plot_regulization_gaussian = true;
    plot_tendons = true;
    plot_disks = true;
    export_plot = false;
    yield_strength = 62e6; % Polycarbonate (PC)
    colors = {'#FF00FF', '#00FFFF'}; % Colors for different forces

    if nargin < 6 % if doPlot was not provided
        doPlot = false; % default
    end
    if nargin < 7 % if fig_handle was not provided
        fig_handle = false; % default
    end
    if doPlot && ishandle(fig_handle)
        figure(fig_handle); % Use existing figure
        clf;
        % Figure config
        set(gcf, 'Position', [960, 0, 960, 1080]);
        set(gca, 'Units','normalized', 'Position', [0.2 0.2 0.70 0.56]);
        hold on; grid on; axis equal; axis vis3d; 
    elseif doPlot && plot_geometry
        close;
        if vonmises_fos_overlay
            [S, fos_values] = vonmises_fos_overlay_func(S,internal_wrenches,yield_strength);
        end
        S.plotq(q) % plot geometry 
        if vonmises_fos_overlay
            add_fos_colorbar();  % Add colorbar AFTER plot is created
        end
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
    %view(270, 90) 
    %camva(5)   % zoom in (narrow view angle)
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
        
    % --- Plot the x-axis, y-axis and z-axis global axis ---
    quiver3(0,0,0,1,0,0,0.02,'r-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,1,0,0.02,'g-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,0,1,0.02,'b-','MaxHeadSize',1.0,'LineWidth', 2)
    
    % Plot deflected backbone
    plot3(pos_xyz(1,:), pos_xyz(2,:), pos_xyz(3,:), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);

    % Plot disks at each significant point
    if plot_disks
        theta = linspace(0, 2*pi, 50);
        r = 0.01;
        disk_t = 0.00175/2; % half-thickness (1.75mm total)
        hole_r = 0.001; % 2mm diameter holes
        hole_d = 0.008; % 8mm offset from backbone
        hole_ang = [30, 150, 270]; % tendon angles
        theta_h = linspace(0, 2*pi, 20);
        disk_alpha = 0.5;
        
        disk_front = [ disk_t*ones(size(theta)); r*cos(theta); r*sin(theta); ones(size(theta))];
        disk_back  = [-disk_t*ones(size(theta)); r*cos(theta); r*sin(theta); ones(size(theta))];
        
        link_skip = 2;  % Plot every 2nd link
        points_per_link = num_sig / S.N;
        for i = link_skip:link_skip:S.N
            idx = i * points_per_link;
            T = transform_matrices((idx-1)*4+1:idx*4, :);
            ftf = T * disk_front;
            btf = T * disk_back;
            % Front/back faces
            fill3(ftf(1,:), ftf(2,:), ftf(3,:), [0.8 0.8 0.8], 'FaceAlpha', disk_alpha);
            fill3(btf(1,:), btf(2,:), btf(3,:), [0.8 0.8 0.8], 'FaceAlpha', disk_alpha);
            % Outer cylindrical wall
            surf([ftf(1,:); btf(1,:)], [ftf(2,:); btf(2,:)], [ftf(3,:); btf(3,:)], ...
                'FaceColor', [0.75 0.75 0.75], 'FaceAlpha', disk_alpha, 'EdgeColor', 'none');
            % Edge outlines
            plot3(ftf(1,:), ftf(2,:), ftf(3,:), 'k', 'LineWidth', 1);
            plot3(btf(1,:), btf(2,:), btf(3,:), 'k', 'LineWidth', 1);
            % Tendon holes — inverse-rotate global tendon offset into local frame
            R = T(1:3, 1:3);
            for h = 1:3
                global_off = [0; hole_d*cosd(hole_ang(h)); hole_d*sind(hole_ang(h))];
                local_off = R' * global_off;  % rotate global offset into disk-local coords
                cy = local_off(2);
                cz = local_off(3);
                hf = T * [ disk_t*ones(size(theta_h)); cy+hole_r*cos(theta_h); cz+hole_r*sin(theta_h); ones(size(theta_h))];
                hb = T * [-disk_t*ones(size(theta_h)); cy+hole_r*cos(theta_h); cz+hole_r*sin(theta_h); ones(size(theta_h))];
                fill3(hf(1,:), hf(2,:), hf(3,:), [0.2 0.2 0.2], 'FaceAlpha', 1);
                fill3(hb(1,:), hb(2,:), hb(3,:), [0.2 0.2 0.2], 'FaceAlpha', 1);
                surf([hf(1,:); hb(1,:)], [hf(2,:); hb(2,:)], [hf(3,:); hb(3,:)], ...
                    'FaceColor', [0.3 0.3 0.3], 'FaceAlpha', 1, 'EdgeColor', 'none');
            end
        end
    end

    % Plot FOS text labels for links with FOS < 1
    if vonmises_fos_overlay && exist('fos_values', 'var')
        points_per_link_fos = num_sig / S.N;
        for i = 1:S.N
            if fos_values(i) < 1
                mid_idx = round((i - 0.5) * points_per_link_fos);
                mid_idx = max(1, min(mid_idx, num_sig));
                fos_color = S.CVRods{i}(end).Link.color;
                text(pos_xyz(1, mid_idx), pos_xyz(2, mid_idx) + 0.006, pos_xyz(3, mid_idx), ...
                    sprintf('%.2f', fos_values(i)), ...
                    'FontWeight', 'bold', 'Color', fos_color, 'FontSize', 10, ...
                    'HorizontalAlignment', 'center');
            end
        end
    end
    
    % Plot deflected tendons
    if plot_tendons
        tendon1_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(30); undeflected_backbone(3,:)+8e-3*sind(30)];
        tendon2_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(150); undeflected_backbone(3,:)+8e-3*sind(150)];
        tendon3_undeflected = [undeflected_backbone(1,:); undeflected_backbone(2,:)+8e-3*cosd(270); undeflected_backbone(3,:)+8e-3*sind(270)];
        tendon1_deflected = tendon1_undeflected+translations;
        tendon2_deflected = tendon2_undeflected+translations;
        tendon3_deflected = tendon3_undeflected+translations;
        h_tendon1 = plot3(tendon1_deflected(1,:), tendon1_deflected(2,:), tendon1_deflected(3,:), 'm-', 'LineWidth', 3, 'MarkerSize', 10, 'Color', hex2rgb('#898989'));
        h_tendon2 = plot3(tendon2_deflected(1,:), tendon2_deflected(2,:), tendon2_deflected(3,:), 'm-', 'LineWidth', 3, 'MarkerSize', 10, 'Color', hex2rgb('#898989'));
        h_tendon3 = plot3(tendon3_deflected(1,:), tendon3_deflected(2,:), tendon3_deflected(3,:), 'm-', 'LineWidth', 3, 'MarkerSize', 10, 'Color', hex2rgb('#898989'));
    end
    
    % Endpoint labels for tendons — offset radially to avoid overlap
    label_offset = 0.003;
    tendon_angles = [30, 150, 270]; % degrees, matching tendon placement
    tendon_labels = {'T1', 'T2', 'T3'};
    tendon_endpoints = {tendon1_deflected, tendon2_deflected, tendon3_deflected};
    
    for t = 1:3
        ep = tendon_endpoints{t}(:, end);
        dy = label_offset * cosd(tendon_angles(t));
        dz = label_offset * sind(tendon_angles(t));
        text(ep(1), ep(2) + dy, ep(3) + dz, tendon_labels{t}, ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 2);
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
            legend_handles = [h_forces, h_tendon1, h_tendon2, h_tendon3];
        else
            legend_labels = cell(1, length(locs) + 1);
            legend_handles = [h_forces];
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
function [S, fos_values] = vonmises_fos_overlay_func(S, internal_wrenches, yield_strength)
    fos_values = zeros(S.N, 1);
    
    for i = 1:S.N
        r_major = S.CVRods{i}(end).Link.a{1}(0);
        r_minor = S.CVRods{i}(end).Link.b{1}(0);
        Tx = internal_wrenches(i,1);
        Ty = internal_wrenches(i,2);
        Tz = internal_wrenches(i,3);
        [max_vm, fos] = calc_ellipse_vonmises(r_major, r_minor, Tx, Ty, Tz, yield_strength);
        
        fos_values(i) = fos;
        
        % FOS to color
        if fos <= 1
            color = [fos, 0, 0];           % Black → Red
        elseif fos <= 2
            t = fos - 1;
            color = [1, t, 0];             % Red → Yellow
        elseif fos <= 3
            t = fos - 2;
            color = [1 - t, 1, 0];         % Yellow → Green
        else
            color = [0, 1, 0];             % Green
        end
        
        S.CVRods{i}(end).Link.color = color;
        S.CVRods{i}(end).UpdateAll;
    end
    
    S = S.Update();
end

%% FOS Colorbar
function add_fos_colorbar()
    n = 256;
    cmap = zeros(n, 3);
    for i = 1:n
        fos = 3 * (i - 1) / (n - 1);
        if fos <= 1
            cmap(i,:) = [fos, 0, 0];       % Black → Red
        elseif fos <= 2
            t = fos - 1;
            cmap(i,:) = [1, t, 0];         % Red → Yellow
        else
            t = fos - 2;
            cmap(i,:) = [1 - t, 1, 0];     % Yellow → Green
        end
    end
    
    colormap(gca, cmap);
    clim([0 3]);
    cb = colorbar('Location', 'eastoutside');
    cb.Label.String = 'Von Mises Factor of Safety';
    cb.Label.FontWeight = 'bold';
    cb.Label.FontSize = 12;
    cb.FontSize = 11;
    cb.FontWeight = 'bold';
    cb.Ticks = [0 1 2 3];
    cb.TickLabels = {'0', '1', '2', '3+'};
end