close all;
clc;

% Paramaters
n_test_forces = 100;
F_range = [0.2, 1.2]; 
s_range = [0.02, 0.20]; 
theta_range = [0, 2*pi];
tau_range = [0, 1.5];
s_sep_min = 0.02;

% Get test forces
test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min);

% Whitened Jacobian and force paramater scales
[Jw, param_scales] = compute_jacobian(test_forces(:, 1:6), test_forces(:, end-2:end));

% Storage
sigma_mins = zeros(n_test_forces, 1);
uncertainties = zeros(n_test_forces, 6);

for i = 1:n_test_forces
    % Get SVD
    [U, S, V] = svd(Jw{i});
    sigma_mins(i) = S(end);
    % Compute Physical Uncertainties
    [Cov_phys, Sigmas_phys] = compute_covariance_phys(Jw{i}, param_scales);
    uncertainties(i,:) = Sigmas_phys';
end

% Print results
fprintf('Mean of min singular values: %.6e\n\n', mean(sigma_mins));

% Assess reliability 
assess_performance_visual(test_forces, sigma_mins)

% PLOT THE RESULTS
plot_theoretical_bounds(uncertainties, test_forces, param_scales);


%% GENERATE TEST FORCES
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min)
    rng(1234);
    
    % We need 9 variables: 
    % [F1, F2, t1, t2, tau1, tau2, tau3, s_midpoint, s_separation_log]
    U = lhsdesign(n_test_forces, 9, 'criterion', 'maximin', 'iterations', 50);
    
    scale = @(u,r) r(1) + u.*diff(r);
    
    % 1. Standard Linear Variables
    F1   = scale(U(:,1), F_range);
    F2   = scale(U(:,2), F_range);
    t1   = scale(U(:,3), theta_range);
    t2   = scale(U(:,4), theta_range);
    tau1 = scale(U(:,5), tau_range);
    tau2 = scale(U(:,6), tau_range);
    tau3 = scale(U(:,7), tau_range);
    
    % 2. LINEAR SEPARATION SAMPLING (Simplified)
    sep_min = s_sep_min; 
    sep_max = diff(s_range); % Max possible separation
    
    % Simple Linear Interpolation: Min + u * (Max - Min)
    s_sep = sep_min + U(:,9) .* (sep_max - sep_min);
    
    % 3. Midpoint & Sliding Logic (Same as before)
    s_mid = scale(U(:,8), s_range);
    
    s1 = zeros(n_test_forces, 1);
    s2 = zeros(n_test_forces, 1);
    beam_min = s_range(1);
    beam_max = s_range(2);
    
    for i = 1:n_test_forces
        delta = s_sep(i);
        mid = s_mid(i);
        
        % Initial positions
        p1 = mid - delta/2;
        p2 = mid + delta/2;
        
        % Slide if out of bounds
        if p1 < beam_min
            shift = beam_min - p1;
            p1 = p1 + shift;
            p2 = p2 + shift;
        elseif p2 > beam_max
            shift = p2 - beam_max;
            p2 = p2 - shift;
            p1 = p1 - shift;
        end
        
        s1(i) = p2; % Store larger position in s1
        s2(i) = p1;
    end
    
    test_forces = [F1, s1, t1, F2, s2, t2, tau1, tau2, tau3];
end


%% PLOTTING FUNCTION
function assess_performance_visual(test_forces, sigma_mins)
    % 1. Setup Data
    sep_mm = abs(test_forces(:,2) - test_forces(:,5)) * 1000;
    [sep_sorted, idx] = sort(sep_mm);
    sigma_sorted = sigma_mins(idx);
    
    % Calculate Moving Statistics (Window size approx 15% of data)
    k = max(5, round(length(sep_mm) * 0.15)); 
    
    % First, get the raw envelope
    raw_mu = movmean(sigma_sorted, k);
    raw_min = movmin(sigma_sorted, k);
    raw_max = movmax(sigma_sorted, k);
    
    % THEN, Smooth the envelope for visualization (Gaussian window)
    % This removes the "steps" and "blocks"
    smooth_window = k; % Use same or slightly larger window
    mu_curve = smoothdata(raw_mu, 'gaussian', smooth_window);
    min_curve = smoothdata(raw_min, 'gaussian', smooth_window);
    max_curve = smoothdata(raw_max, 'gaussian', smooth_window);
    
    % Clamp logic: Ensure smoothing didn't accidentally cross physics (optional)
    % e.g. min_curve shouldn't go below 0
    min_curve(min_curve < 0) = 0;
    
    % 2. Plotting
    figure('Color', 'w'); hold on;
    
    % --- BACKGROUND ZONES ---
    y_max = max(max(sigma_sorted), 8); 
    x_lims = [min(sep_mm)-2, max(sep_mm)+2];
    
    % Red Zone: Noise Dominant (Signal < Noise floor)
    fill([x_lims(1) x_lims(2) x_lims(2) x_lims(1)], [0 0 1 1], ...
         [1 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
         
    % Orange Zone: Transition (Usable but sensitive)
    good_thresh = 5; 
    fill([x_lims(1) x_lims(2) x_lims(2) x_lims(1)], [1 1 good_thresh good_thresh], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
         
    % Green Zone: Robust Regime (High SNR)
    fill([x_lims(1) x_lims(2) x_lims(2) x_lims(1)], [good_thresh good_thresh y_max*1.5 y_max*1.5], ...
         [0.85 1 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.4);

    % --- DATA PLOTTING ---
    % Shaded Region (Min/Max)
    h_shade = fill([sep_sorted; flipud(sep_sorted)], [max_curve; flipud(min_curve)], ...
         'k', 'FaceAlpha', 0.15, 'EdgeColor', 'none'); 

    % Raw Data Points
    h_scatter = scatter(sep_mm, sigma_mins, 25, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Mean Trend Line
    h_line = plot(sep_sorted, mu_curve, 'k-', 'LineWidth', 2.5);
    
    x_text = x_lims(1) + 0.02 * diff(x_lims);  % small left margin

    % Red Zone Text
    text(x_text, 0.5, 'Noise Amplified (Gain > 1.0)', ...
         'HorizontalAlignment', 'left', 'Color', [0.8 0 0], 'FontWeight', 'bold');
    
    % Orange Zone Text
    text(x_text, 3, 'Noise Dampened (Gain 1.0 \rightarrow 0.2)', ...
         'HorizontalAlignment', 'left', 'Color', [0.8 0.4 0], 'FontWeight', 'bold');
    
    % Green Zone Text
    text(x_text, 6.5, 'Noise Suppressed (Gain < 0.2)', ...
         'HorizontalAlignment', 'left', 'Color', [0 0.5 0], 'FontWeight', 'bold');

    % --- LEGEND & FORMATTING ---
    legend([h_line, h_shade, h_scatter], ...
           {'Mean Sensitivity Trend', 'Variation Range (Min/Max)', 'Individual Test Cases'}, ...
           'Location', 'northwest', 'FontSize', 10);
           
    xlim(x_lims);
    ylim([0, y_max]);
    xlabel('Separation Distance (mm)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Singular Value (\sigma_{min})', 'FontSize', 12, 'FontWeight', 'bold');
    title('Observability Analysis: Sensitivity vs. Separation', 'FontSize', 14);
    
    box on; grid on;
    set(gca, 'Layer', 'top'); 
end


function plot_theoretical_bounds(uncertainties, p, param_scales)
    % Inputs: 
    %   uncertainties: Nx6 [sig_F1, sig_s1, sig_th1, sig_F2, sig_s2, sig_th2]
    %   p: Nx9 [F1, s1, th1, F2, s2, th2, ...]
    %   param_scales: 6x1 vector [Range_F; Range_S; Range_Th...]

    %% 1. PREPARE DATA
    n_sims = size(p, 1);
    sep_mm = abs(p(:, 2) - p(:, 5)) * 1000;
    [x_sorted, idx] = sort(sep_mm);
    U_sorted = uncertainties(idx, :);

    % Extract Sigmas (Envelope of F1 and F2)
    sig_F = max(U_sorted(:,1), U_sorted(:,4)); 
    sig_S = max(U_sorted(:,2), U_sorted(:,5)); 
    sig_T = max(U_sorted(:,3), U_sorted(:,6)); 

    %% 2. CALCULATE ROBUST MIXTURE STATS
    k = max(10, round(length(x_sorted) * 0.20)); 

    % Force
    [F_p68, F_p95, F_p99] = get_mixture_stats(sig_F, k);
    % Position
    [S_p68, S_p95, S_p99] = get_mixture_stats(sig_S, k);
    % Angle
    [T_p68, T_p95, T_p99] = get_mixture_stats(sig_T, k);

    %% 3. DEFINE PHYSICAL LIMITS (Full Range)
    % The error can be as large as the full span (Min -> Max)
    limit_F = param_scales(1); 
    limit_S = param_scales(2); 
    limit_T = param_scales(3); 

    %% 4. PLOT
    figure('Color', 'w', 'Position', [100 100 700 900]);
    t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    c1 = [0.2 0.4 0.8]; c2 = [0.4 0.6 0.9]; c3 = [0.7 0.8 1.0];
    
    % Title Construction
    main_title = sprintf('Theoretical Uncertainty (Aggregate, n=%d)', n_sims);

    % --- PANEL 1: FORCE ---
    draw_percentile_panel(x_sorted, F_p68, F_p95, F_p99, limit_F, 1.0, ...
        'Force Error (N)', main_title, c1, c2, c3);
    
    % Only show legend on top panel
    legend({'99% Bound (Worst Case)', '95% Bound', '68% Bound (Typical)', 'Physical Limit'}, ...
           'Location', 'northeast', 'FontSize', 9);

    % --- PANEL 2: POSITION ---
    draw_percentile_panel(x_sorted, S_p68, S_p95, S_p99, limit_S, 1000.0, ...
        'Position Error (mm)', [], c1, c2, c3);

    % --- PANEL 3: ANGLE ---
    draw_percentile_panel(x_sorted, T_p68, T_p95, T_p99, limit_T, 180/pi, ...
        'Angle Error (deg)', [], c1, c2, c3);

    xlabel('Separation Distance (mm)', 'FontWeight', 'bold');
    linkaxes(findall(gcf,'type','axes'), 'x');
end

%% --- STATS HELPER (MIXTURE DISTRIBUTION) ---
function [p68, p95, p99] = get_mixture_stats(data, k)
    n = length(data);
    p68 = zeros(n,1);
    p95 = zeros(n,1);
    p99 = zeros(n,1);
    
    n_samples = 500; 
    
    for i = 1:n
        idx_start = max(1, i - floor(k/2));
        idx_end = min(n, i + floor(k/2));
        window_sigmas = data(idx_start:idx_end); 
        
        % Create Mixture
        current_k = length(window_sigmas);
        noise_chunk = randn(n_samples, current_k); 
        simulated_errors = noise_chunk .* window_sigmas'; 
        all_errors = abs(simulated_errors(:));
        
        p68(i) = quantile(all_errors, 0.6827);
        p95(i) = quantile(all_errors, 0.9545);
        p99(i) = quantile(all_errors, 0.9973);
    end
    
    % Smooth
    smooth_k = max(3, round(k/4));
    p68 = smoothdata(p68, 'gaussian', smooth_k);
    p95 = smoothdata(p95, 'gaussian', smooth_k);
    p99 = smoothdata(p99, 'gaussian', smooth_k);
end

%% --- DRAWING HELPER ---
function draw_percentile_panel(x, p68, p95, p99, limit, unit_conv, y_lbl, t_str, c1, c2, c3)
    nexttile; hold on; grid on;
    
    lim_plot = limit * unit_conv;
    y68 = p68 * unit_conv;
    y95 = p95 * unit_conv;
    y99 = p99 * unit_conv;
    
    % BOUNDS: Clamp to limit
    b99 = min(y99, lim_plot);
    b95 = min(y95, lim_plot);
    b68 = min(y68, lim_plot);

    % DRAW REGIONS (Widest -> Narrowest)
    % Note the "-flipud" to fix the twist issue
    fill([x; flipud(x)], [b99; -flipud(b99)], c3, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    fill([x; flipud(x)], [b95; -flipud(b95)], c2, 'EdgeColor', 'none', 'FaceAlpha', 0.6);
    fill([x; flipud(x)], [b68; -flipud(b68)], c1, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    
    % LIMITS + PADDING
    yline(lim_plot, 'k-', 'LineWidth', 1.5, 'Color', [0.2 0.2 0.2]);
    yline(-lim_plot, 'k-', 'LineWidth', 1.5, 'Color', [0.2 0.2 0.2]);
    yline(0, 'k--', 'LineWidth', 1);

    ylabel(y_lbl, 'FontWeight', 'bold');
    if ~isempty(t_str), title(t_str, 'FontSize', 12); end
    
    % Zoom with padding (1.2x)
    ylim([-lim_plot*1.2, lim_plot*1.2]); 
    set(gca, 'Layer', 'top');
end
