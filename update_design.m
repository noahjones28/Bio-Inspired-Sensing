function S = update_design(r, design_name, do_save)
    %% ABOUT
    % Input: radius array, design_name, save updated linkage to directory
    % Output: updated linkage S
    

    %% SETUP
    % Set default value if not provided
    if nargin < 3
        do_save = true;
    end

    % Paramaters
    color_1 = [0.75, 0.75, 0.75];
    color_2 = [0.25, 0.25, 0.25];
    young_mod = 2.11e9; % Young's Modulus of each link (PC)
    

    %% UPDATE DESIGN
    if design_name == "elliptical_20_links" % [r_major_1, r_minor_1, Φ_1, ...,r_major_20, r_minor_20, Φ_20]    
        try
            %load('my_robots\elliptical_20_links\my_robot.mat','S');
            %load('my_robots\tendon_TEST\my_robot.mat','S');
            load('my_robots\elliptical_20_links_3_tendons\my_robot.mat','S');
            num_tendons = S.n_sact; % Get number of tendons
            num_links = S.N; % Get number of links
            M = S.g_ini; % N stacked 4x4 transformation matrices
            for i = 1:num_links
                % Update ellipse major and minor axis
                r_major = r(3*i-2);
                r_minor = r(3*i-1);
                S.CVRods{i}(end).Link.a{1} = @(X1) r_major;
                S.CVRods{i}(end).Link.b{1} = @(X1) r_minor;
                
                % Update rotation
                if i > 1 % Don't rotate first segment to preserve joint axis
                    theta = r(3*i);
                    M = rotateSingleLink(M, i, theta);  % rotate only link i
                    S.g_ini = M;
                end

                % Rotate tendons into local frame
                if num_tendons > 0
                    tendon_func_global = S.CableFunction.dc_fn(:, i)';  % Extract column, transpose to row
                    link_idxs = repmat(i, 1, num_tendons);
                    tendon_func_local = global_to_local(M, link_idxs, tendon_func_global);
                    S.CableFunction.dc_fn(:, i) = tendon_func_local';   % Transpose back and assign
                end

                % Update Young's Modulus of each link
                S.CVRods{i}(end).Link.E = young_mod;

                % Update color
                if mod(i, 2) == 1
                    active_color = color_1;
                else
                    active_color = color_2;
                end
                S.CVRods{i}(end).Link.color = active_color;

                % Update link with changes
                S.CVRods{i}(end).UpdateAll;
            end
            % Update linkage with changes
            S = S.Update();
            if do_save
                save('my_robot.mat','S')
            end
        catch ME
            error('Failed to change design: %s', ME.message);
        end
    else
        error('invalid design_name!')
    end
end


%% ROTATION MATRIX
function M = rotateSingleLink(M, i, theta)
% ROTATESINGLELINK Rotates only link i without affecting subsequent links
%   Inputs:
%       M     - 80x4 matrix (20 stacked 4x4 transformation matrices)
%       i     - index of link to rotate (1-20)
%       theta - rotation angle in radians (about x-axis)

    % Total number of links
    i_max = size(M, 1)/4; % divide by 4 rows in each transformation matrix

    % Rotation matrix
    Rx = [1    0           0          0;
          0  cos(theta)  -sin(theta)  0;
          0  sin(theta)   cos(theta)  0;
          0    0           0          1];

    % Extract and rotate link i (local rotation)
    idx_i = (i-1)*4+1 : i*4;
    M(idx_i, :) = M(idx_i, :) * Rx;

    % Apply inverse rotation to link i+1 to compensate
    if i < i_max
        idx_next = i*4+1 : (i+1)*4;
        M(idx_next, :) = Rx' * M(idx_next, :);  % Rx' is the inverse for rotation matrices
    end
    
end