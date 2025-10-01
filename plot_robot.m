function positions = plot_robot(S, q, distal_values, force_vectors, force_idxs, doPlot, fig_handle)
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
    view(225, 45);       % oblique: az=40°, el=25° (slightly elevated)
    rotate3d on;        % enable mouse rotation
    grid on;
    axis equal;
    
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

    % Preallocate result
    force_vectors_rotated = zeros(size(force_vectors,1), size(force_vectors,2));

    % Method 1: Loop through each vector/matrix pair
    for i = 1:length(force_idxs)
        idx = force_idxs(i);
        % Extract the i-th transformation matrix
        T = g_link((idx-1)*4+1:idx*4, :);  % 4x4 matrix
        
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
    plot3(position(2,:), position(3,:), position(1,:), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);
    
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
        
        % Plot the line connecting all tips
        plot3(tip_y, tip_z, tip_x, 'k-', 'LineWidth', 1);

        % Shade the region between curve and x-axis
        surf([force_positions(2,:); tip_y], [force_positions(3,:); tip_z], [force_positions(1,:); tip_x], ...
             'FaceColor', 'm', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

        % Find and plot the largest vector (with flipped head)
        [~, max_idx] = max(vecnorm(force_vectors_rotated));
        quiver3(force_positions(2,max_idx) - force_scaler * force_vectors_rotated(2,max_idx), ...
                force_positions(3,max_idx) - force_scaler * force_vectors_rotated(3,max_idx), ...
                force_positions(1,max_idx) - force_scaler * force_vectors_rotated(1,max_idx), ...
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