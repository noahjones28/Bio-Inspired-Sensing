function S1 = apply_gaussian_force(S1, varargin)
% APPLYGAUSSIANFORCE Applies Gaussian or single point force(s) to the SOROSIM linkage
%
% Usage:
% S1 = applyGaussianForce(S1, force_matrix, N, doPlot)
%
% force_matrix: N×3 matrix where each row is [F_total, mu, sigma]

    % Arguments
    force_matrix = varargin{1};
    N = 100;  % default
    if length(varargin) >= 2
        N = varargin{2}; % override if provided
    end
    doPlot = false; % default
    if length(varargin) >= 3
        doPlot = varargin{3}; % override if provided
    end
    
    num_forces = size(force_matrix, 1);
    L = S1.VLinks.L;
    [~, quadpoints] = S1.CVRods{1}.Xs;
    
    % Create discretization grid for all forces
    s_vals = linspace(0, L, N);
    ds = s_vals(2) - s_vals(1);
    combined_force_profile = zeros(1, N);
    
    % Process each force individually - some may be point forces, others distributed
    for i = 1:num_forces
        F_total = force_matrix(i, 1);
        mu = force_matrix(i, 2);
        sigma = force_matrix(i, 3);
        
        if sigma == 0 || N == 1
            % This force is a point force: add to nearest grid point
            [~, closest_idx] = min(abs(s_vals - mu));
            combined_force_profile(closest_idx) = combined_force_profile(closest_idx) + F_total;
        else
            % This force is a distributed Gaussian: add to profile
            raw_profile = exp(-0.5 * ((s_vals - mu) / sigma).^2);
            raw_area = sum(raw_profile * ds);
            if raw_area > 0
                force_profile = F_total * (raw_profile / raw_area) * ds;
                combined_force_profile = combined_force_profile + force_profile;
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
        S1.Fp_vec{i} = @(t)[0, 0, 0, 0, combined_force_profile(i), 0]';
        S1.Fp_loc{i} = [1, 1, s_rounded];
    end
    
    S1.np = N;
    S1.LocalWrench = ones(1, N);
    S1.Fp_sig = PointWrenchPoints(S1);
    
    if doPlot
        figure;
        plot(s_vals, combined_force_profile, 'k--', 'LineWidth', 2);
        xlabel('Position along backbone (m)');
        ylabel('Force magnitude (N)');
        title(sprintf('Combined Force Distribution (%d forces)', num_forces));
        hold on;
        
        % Generate different colors for each force
        colors = lines(num_forces);
        legend_entries = {'Combined'};
        
        % Mark different force types
        for i = 1:num_forces
            F_total = force_matrix(i, 1);
            mu = force_matrix(i, 2);
            sigma = force_matrix(i, 3);
            
            if sigma == 0
                % Point force - mark with colored circle
                plot(mu, F_total, 'o', 'MarkerSize', 10, 'LineWidth', 3, ...
                     'Color', colors(i,:), 'MarkerFaceColor', colors(i,:));
                legend_entries{end+1} = sprintf('Point Force %d', i);
            else
                % Gaussian force - show as shaded area with unique color
                raw_profile = exp(-0.5 * ((s_vals - mu) / sigma).^2);
                raw_area = sum(raw_profile * ds);
                if raw_area > 0
                    force_profile = F_total * (raw_profile / raw_area) * ds;
                    
                    % Create shaded area
                    fill([s_vals, fliplr(s_vals)], [force_profile, zeros(1,length(s_vals))], ...
                         colors(i,:), 'FaceAlpha', 0.5, 'EdgeColor', colors(i,:), ...
                         'LineWidth', 2, 'EdgeAlpha', 0.5);
                    legend_entries{end+1} = sprintf('Gaussian %d', i);
                end
            end
        end
        
        legend(legend_entries, 'Location', 'best');
        grid on;
    end
end