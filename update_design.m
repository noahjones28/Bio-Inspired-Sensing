function S = update_design(r, design_name, do_save)
    %% ABOUT
    % Input: radius array, design_name, save updated linkage to directory
    % Output: updated linkage S
    

    %% SETUP
    % Set default value if not provided
    if nargin < 3
        do_save = true;
    end

    % colors
    color_1 = [0.75, 0.75, 0.75];
    color_2 = [0.25, 0.25, 0.25];
    

    %% UPDATE DESIGN
    if design_name == "elliptical_20_links" % [r_major_1, r_minor_1, Φ_1, ...,r_major_20, r_minor_20, Φ_20]    
        try
            load('my_robots\elliptical_20_links\my_robot.mat','S');
            for i = 1:S.N
                % Update ellipse major and minor axis
                r_major = r(3*i-2);
                r_minor = r(3*i-1);
                S.CVRods{i}(end).Link.a{1} = @(X1) r_major;
                S.CVRods{i}(end).Link.b{1} = @(X1) r_minor;
                
                % Update rotation
                if i > 1 % Don't rotate first segment to preserve joint
                    theta = r(3*i);
                    M = S.g_ini; % N stacked 4x4 transformation matrices
                    M = rotateSingleLink(M, i, theta);  % rotate only link i
                    S.g_ini = M;
                end

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

    % Rotation matrix
    Rx = [1    0           0          0;
          0  cos(theta)  -sin(theta)  0;
          0  sin(theta)   cos(theta)  0;
          0    0           0          1];

    % Extract and rotate link i (local rotation)
    idx_i = (i-1)*4+1 : i*4;
    M(idx_i, :) = M(idx_i, :) * Rx;

    % Apply inverse rotation to link i+1 to compensate
    if i < 20
        idx_next = i*4+1 : (i+1)*4;
        M(idx_next, :) = Rx' * M(idx_next, :);  % Rx' is the inverse for rotation matrices
    end
end