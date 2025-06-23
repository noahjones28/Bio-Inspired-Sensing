function S1 = applyGaussianForce(S1, F_total, mu, sigma, N, doPlot)
% APPLYGAUSSIANFORCE Applies a Gaussian or single point force to the SOROSIM linkage
%
% Inputs:
%   S1      - SorosimLinkage object
%   F       - Force amplitude (peak value)
%   mu      - Location of peak (in meters)
%   sigma   - Standard deviation (in meters). If zero or missing, applies a single point force.
%   N       - (Optional) Number of force points (default: 10)
%   doPlot  - (Optional) true to plot force distribution

    if nargin < 4 || isempty(sigma) || sigma == 0 || N == 1 
        isPointForce = true;
    else
        isPointForce = false;
    end

    if nargin < 5 || isempty(N)
        N = 100;
    end
    if nargin < 6
        doPlot = false;
    end

    L = S1.VLinks.L;
    [~, quadpoints] = S1.CVRods{1}.Xs; % Current quadrature points

    % Compute grid spacing
    s_vals = linspace(0, L, N);
    ds = s_vals(2) - s_vals(1);

    % If sigma was zero, or negative, treat as point force
    if isPointForce
        applySinglePoint();
        return;
    end

    % Check if sigma is too small to discretize:
    if sigma < ds
        % fallback to single point force at mu
        applySinglePoint();
        return;
    end


    % Raw Gaussian (unnormalized density)
    raw_profile = exp(-0.5 * ((s_vals - mu) / sigma).^2);
    % Normalize so that sum(raw_profile * ds) = 1
    raw_area = sum(raw_profile * ds);
    if raw_area <= 0
        error('Gaussian area is zero or negative; check sigma and sampling');
    end
    density_profile = raw_profile / raw_area;  % now sum(density_profile*ds) = 1
    % Point force magnitudes: F_i = F_total * density_profile(i) * ds
    force_profile = F_total * density_profile * ds;  
    % Assign to S1
    S1.Fp_vec = cell(1, N);
    S1.Fp_loc = cell(1, N);
    for i = 1:N
        s_frac = s_vals(i) / L;
        [~, idx] = min(abs(quadpoints - s_frac));
        s_rounded = quadpoints(idx);

        S1.Fp_vec{i} = @(t)[0, 0, 0, 0, force_profile(i), 0]';
        S1.Fp_loc{i} = [1, 1, s_rounded];
    end
    S1.np = N;
    S1.LocalWrench = ones(1, N); 
    S1.Fp_sig = PointWrenchPoints(S1);

    % Optional plot
    if doPlot
        figure;
        plot(s_vals, force_profile, 'LineWidth', 2);
        xlabel('Position along backbone (m)');
        ylabel('Force magnitude (N)');
        title('Gaussian Force Distribution');
        grid on;
    end

     % Nested function to apply single point
    function applySinglePoint()
        s_frac = mu / L;
        [~, idx] = min(abs(quadpoints - s_frac));
        s_rounded = quadpoints(idx);

        S1.Fp_vec = {@(t)[0, 0, 0, 0, F_total, 0]'};
        S1.Fp_loc = {[1, 1, s_rounded]};
        S1.Fp_sig = PointWrenchPoints(S1);
        if doPlot
            figure;
            stem(mu, F_total, 'filled', 'LineWidth', 2);
            xlabel('Position along backbone (m)');
            ylabel('Force magnitude (N)');
            title('Single Point Force (σ too small)');
            grid on;
        end
    end

end
