function positions = plot_robot(S, q, distal_values, force_vectors, quadpoint_idxs, doPlot, fig_handle)
    if nargin < 6 % if doPlot was not provided
        doPlot = false; % default
    end
    if nargin < 7 % if fig_handle was not provided
        fig_handle = false; % default
    end
    if doPlot && ishandle(fig_handle)
        figure(fig_handle); % Use existing figure
        clf;
    elseif doPlot
        close;
        figure; % Create new figure if handle not provided
    end
    % Figure config
    set(gcf, 'Position', [1920/2, 100, 800, 800]);
    set(gca, 'Units','normalized', 'Position', [0.2 0.2 0.70 0.56]);
    hold on; grid on; axis equal; axis vis3d; 
    xlabel('Y (m)');
    ylabel('Z (m)');
    zlabel('X: Position along backbone (m)');
    title('Deflected Robot Shape in 3D + Applied Forces');
    view(135, 45);       % oblique: az=40°, el=25° (slightly elevated)
    rotate3d on;        % enable mouse rotation
    grid on;
    axis equal;

    % Get transformation matrices at all points
    g_all = S.FwdKinematics(q);
    
    % Extract positions
    starting_point_idx = 4; % idx of first significant point (points before will be ignored)
    num_points = S.nsig;
    num_forces = size(distal_values, 1);

    g_trans = reshape(g_all(:,4), 4, num_points); % pick the 4th column of each block
    quadpoint_pos_trans = g_trans(1:3, starting_point_idx:end);
    force_pos_trans = quadpoint_pos_trans(:,quadpoint_idxs);

    % Preallocate result
    force_vectors_rotated = zeros(3, 100);

    % Method 1: Loop through each vector/matrix pair
    for i = 1:100
        % Extract the i-th transformation matrix
        T = g_all((i-1)*4+1:i*4, :);  % 4x4 matrix
        
        % Extract the 3x3 rotation part (no scale present)
        R = T(1:3, 1:3);

        % Rotate the AB vector
        force_vectors_rotated(:,i) = R*force_vectors(:,i);
    end


    % --- Plot the x-axis line ---
    plot3([0 0], [0 0], [0 0.2], 'k--', 'LineWidth', 2)
        
    % --- Plot the x-axis, y-axis and z-axis global axis ---
    quiver3(0,0,0,0,1,0,0.02,'b-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,0,0,1,0.02,'r-','MaxHeadSize',1.0,'LineWidth', 2)
    quiver3(0,0,0,1,0,0,0.02,'g-','MaxHeadSize',1.0,'LineWidth', 2)
    
    % Plot deflected backbone
    plot3(force_pos_trans(2,:), force_pos_trans(3,:), force_pos_trans(1,:), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);
    
    % If any element in force_vectors is non-zero
    if any(force_vectors(:) ~= 0)
        % --- Plot the tips of force vectors ---
        % Calculate tip positions (starting from points on x-axis)
        force_scaler = 1.0;  % Scale factor for visualization
        tip_x = force_pos_trans(1,:) - force_scaler * force_vectors_rotated(1,:);
        tip_y = force_pos_trans(2,:) - force_scaler * force_vectors_rotated(2,:);
        tip_z = force_pos_trans(3,:) - force_scaler * force_vectors_rotated(3,:);
        
        % Plot the line connecting all tips
        plot3(tip_y, tip_z, tip_x, 'k-', 'LineWidth', 1);

        % Shade the region between curve and x-axis
        surf([force_pos_trans(2,:); tip_y], [force_pos_trans(3,:); tip_z], [force_pos_trans(1,:); tip_x], ...
             'FaceColor', 'm', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

        % Find and plot the largest vector (with flipped head)
        [~, max_idx] = max(vecnorm(force_vectors_rotated));
        quiver3(force_pos_trans(2,max_idx) - force_scaler * force_vectors_rotated(2,max_idx), ...
                force_pos_trans(3,max_idx) - force_scaler * force_vectors_rotated(3,max_idx), ...
                force_pos_trans(1,max_idx) - force_scaler * force_vectors_rotated(1,max_idx), ...
                force_vectors_rotated(2,max_idx), ...
                force_vectors_rotated(3,max_idx), ...
                force_vectors_rotated(1,max_idx), ...
                force_scaler, 'r-', 'LineWidth', 1.5, 'MaxHeadSize', 1.5);
       
        % Add text to top-left corner of the 3D plot
        if num_forces == 1
            text_str = sprintf('Best Parameters (N=1):\nF = %.4f\ns = %.4f\nel = %.4f\naz = %.4f', ...
                    distal_values(1), distal_values(2), distal_values(3), distal_values(4));
        elseif num_forces == 2
            text_str = sprintf('Best Parameters (N=2):\nForce 1:\nF = %.4f\ns = %.4f\nel = %.4f\naz = %.4f\nForce 2:\nF = %.4f\ns = %.4f\nel = %.4f\naz = %.4f', ...
                    distal_values(1, 1), distal_values(1, 2), distal_values(1, 3), distal_values(1, 4), distal_values(2, 1), distal_values(2, 2), distal_values(2, 3), distal_values(1, 4));
        else
            text_str = 'Error';
        end

        text(1, 0.3, 0.98, text_str, ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', 'white', ...
            'EdgeColor', 'black', ...
            'FontSize', 12, ...
            'FontName', 'Calibri', ...
            'Tag', 'BestValuesText');
    end
    drawnow; % Force immediate plot update
end