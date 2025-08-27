function S1 = apply_gaussian_force(S1, varargin)
% APPLYGAUSSIANFORCE Applies Gaussian or single point force(s) to the SOROSIM linkage
%
% Usage:
% S1 = applyGaussianForce(S1, distal_values, N, doPlot)
%
% distal_values: N×3 matrix where each row is [F_total, mu(location), sigma(spread), az(azimuth angle), el(elevation angle)]

    % Arguments
    distal_values = varargin{1};
    N = 100;  % default
    if length(varargin) >= 2
        N = varargin{2}; % override if provided
    end
    doPlot = false; % default
    if length(varargin) >= 3
        doPlot = varargin{3}; % override if provided
    end
    
    num_forces = size(distal_values, 1);
    L = S1.VLinks.L;
    [~, quadpoints] = S1.CVRods{1}.Xs;
    
    % Create discretization grid for all forces
    s_vals = linspace(0, L, N);
    ds = s_vals(2) - s_vals(1);
    combined_force_vectors = zeros(3, N); % N 3D vectors
    
    % Process each force individually - some may be point forces, others distributed
    for i = 1:num_forces
        F = distal_values(i, 1);
        mu = distal_values(i, 2);
        sigma = distal_values(i, 3);
        el = distal_values(i, 4);
        az = distal_values(i, 5);
        
        if sigma == 0 || N == 1
            % Compute point force
            % Convert from polar to cartesian
            [x,y,z] = sph2cart(az,el,F);
            F_vector = -1*[x;y;z]; % Flip direction becuase we want vector pointing towards body
            % Add to nearest grid point
            [~, closest_idx] = min(abs(s_vals - mu));
            % Add to combined array
            combined_force_vectors(:,closest_idx) = combined_force_vectors(:,closest_idx) + F_vector;
        else
            % Compute Gaussian distribution
            raw_profile = exp(-0.5 * ((s_vals - mu) / sigma).^2);
            raw_area = sum(raw_profile * ds);
            if raw_area > 0
                gauss_dist = F * (raw_profile / raw_area) * ds;
                % Convert each coordinate in the distribution to cartesian
                % vector using ez and el
                [x,y,z] = sph2cart(az*ones(1, N),el*ones(1, N),gauss_dist);
                gauss_dist_vectors = -1*[x;y;z]; % Flip direction becuase we want vector pointing towards body
                combined_force_vectors = combined_force_vectors + gauss_dist_vectors;
            end
        end
    end
    
    % Apply combined force profile to robot
    S1.Fp_vec = cell(1, N);
    S1.Fp_loc = cell(1, N);
    for i = 1:N
        s_frac = s_vals(i) / L;
        [~, idx] = min(abs(quadpoints - s_frac));
        s_rounded = quadpoints(idx);
        S1.Fp_vec{i} = @(t)[0, 0, 0, combined_force_vectors(1,i),...
            combined_force_vectors(2,i), combined_force_vectors(3,i)]';
        S1.Fp_loc{i} = [1, 1, s_rounded];
    end
    
    S1.np = N;
    S1.LocalWrench = ones(1, N);
    S1.Fp_sig = PointWrenchPoints(S1);
    
    if doPlot
        figure; hold on; grid on; axis equal;
        xlabel('X component of force'); ylabel('Y component of force'); zlabel('Z: Position along backbone (m)');
        title('3D Force Vectors Along Robot Body');

        % --- Plot the x-axis line ---
        plot3(s_vals, zeros(1,length(s_vals)), zeros(1,length(s_vals)), 'k-', 'LineWidth', 2);
        view(3); % <-- Force 3D view
        % --- Plot the x-axis, y-axis and z-axis global axis ---
        quiver3(0,0,0,1,0,0,0.02,'r-','MaxHeadSize',1.0,'LineWidth', 2)
        quiver3(0,0,0,0,1,0,0.02,'g-','MaxHeadSize',1.0,'LineWidth', 2)
        quiver3(0,0,0,0,0,1,0.02,'b-','MaxHeadSize',1.0,'LineWidth', 2)
        
        % Plot vectors at each z-position
        for i = 1:N
            % Position on z-axis
            origin = [s_vals(i) 0 0];  
            % Vector components
            vec = combined_force_vectors(:,i)';   
            
            % Plot the vector using quiver3
            force_scaler = 0.2;
            quiver3(origin(1)-force_scaler*vec(1), origin(2)-force_scaler*vec(2), ...
                origin(3)-force_scaler*vec(3),vec(1), vec(2), vec(3),...
                force_scaler, 'm-','MaxHeadSize',1.0,'LineWidth',1);
        end
    end

%     if doPlot
%         figure;
%         plot(s_vals, combined_force_vectors, 'k--', 'LineWidth', 2);
%         xlabel('Position along backbone (m)');
%         ylabel('Force magnitude (N)');
%         title(sprintf('Combined Force Distribution (%d forces)', num_forces));
%         hold on;
% 
%         % Generate different colors for each force
%         colors = lines(num_forces);
%         legend_entries = {'Combined'};
% 
%         % Mark different force types
%         for i = 1:num_forces
%             F_total = distal_values(i, 1);
%             mu = distal_values(i, 2);
%             sigma = distal_values(i, 3);
% 
%             if sigma == 0
%                 % Point force - mark with colored circle
%                 plot(mu, F_total, 'o', 'MarkerSize', 10, 'LineWidth', 3, ...
%                      'Color', colors(i,:), 'MarkerFaceColor', colors(i,:));
%                 legend_entries{end+1} = sprintf('Point Force %d', i);
%             else
%                 % Gaussian force - show as shaded area with unique color
%                 raw_profile = exp(-0.5 * ((s_vals - mu) / sigma).^2);
%                 raw_area = sum(raw_profile * ds);
%                 if raw_area > 0
%                     force_profile = F_total * (raw_profile / raw_area) * ds;
% 
%                     % Create shaded area
%                     fill([s_vals, fliplr(s_vals)], [force_profile, zeros(1,length(s_vals))], ...
%                          colors(i,:), 'FaceAlpha', 0.5, 'EdgeColor', colors(i,:), ...
%                          'LineWidth', 2, 'EdgeAlpha', 0.5);
%                     legend_entries{end+1} = sprintf('Gaussian %d', i);
%                 end
%             end
%         end
% 
%         legend(legend_entries, 'Location', 'best');
%         grid on;
%     end
% end