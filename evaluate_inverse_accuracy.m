function [residuals, overall_mae_F, overall_mae_s, overall_mae_theta, overall_mae_weighted] = evaluate_inverse_accuracy(distal_values)
    close all;
    
    % Define parameters
    lb = [0.1, 0.02, 0];      % lower bounds for [F, s, θ]
    ub = [0.9, 0.2, 0];  % upper bounds for [F, s, θ]
    tau_array_default = [0 0 0]; % default tau array
    %noise_sigma = [0, 0.008, 0.011, 0.071, 0, 0];
    noise_sigma = [0, 0.005, 0.005, 0.07, 0. 0];
    %noise_sigma = [0, 0, 0, 0, 0, 0];
    n = 15;             % number of samples
    n_noise = 1;        % number of noise samples per point
    plot_results = true;
    
    % If distal values not provided generate space-filling sample points
    if nargin < 1
        % Generate space-filling sample points
        distal_values = get_space_filling_points(lb, ub, n, 'lhs');  % n×3
    else
        n = size(distal_values, 1);
    end
    
    % Get proximal values with default tau array
    proximal_values = get_proximal_values([distal_values, repmat(tau_array_default,n,1)]);  % n×6
    
    % Expand by repeating each row n_noise times consecutively
    distal_values_expanded = repelem(distal_values, n_noise, 1);  % (n*n_noise)×3
    proximal_values_expanded = repelem(proximal_values, n_noise, 1);  % (n*n_noise)×6
    
    % Collect noise samples for all points
    noise_samples = zeros(n * n_noise, 6);
    for i = 1:n
        noise = generate_sobol_noise(n_noise, noise_sigma);  % n_noise×6
        idx_start = (i-1) * n_noise + 1;
        idx_end = i * n_noise;
        noise_samples(idx_start:idx_end, :) = noise;
    end
    
    % Add noise samples to expanded proximal values
    proximal_values_expanded_noisy = proximal_values_expanded + noise_samples;
    
    % Get estimated distal values with default tau array
    estimated_distal_values = get_distal_values([proximal_values_expanded_noisy, repmat(tau_array_default,n*n_noise,1)]);  % (n*n_noise)×4
    
    % Extract maximum residual norm from 4th column
    max_residual_norm = max(estimated_distal_values(:, 4));
    
    % Compute errors
    errors = zeros(n * n_noise, 3);
    errors(:, 1) = estimated_distal_values(:, 1) - distal_values_expanded(:, 1);  % ΔF
    errors(:, 2) = estimated_distal_values(:, 2) - distal_values_expanded(:, 2);  % Δs
    
    % Handle angular wrap-around for θ (shortest angular distance)
    theta_diff = estimated_distal_values(:, 3) - distal_values_expanded(:, 3);
    errors(:, 3) = mod(theta_diff + pi, 2*pi) - pi;  % Δθ with wrap-around

    % Distal weighting vector (range/typical-scale based)
    F_scale     = ub(1) - lb(1);    % = 0.8
    s_scale     = ub(2) - lb(2);    % = 0.2
    theta_scale = pi;               % one half-turn is a natural angular scale
    weight_vector = [1/F_scale, 1/s_scale, 1/theta_scale];
    
    % Compute mean absolute error for each sample point across noise samples
    errors_reshaped = reshape(errors, n_noise, n, 3);  % n_noise × n × 3
    mean_abs_errors = squeeze(mean(abs(errors_reshaped), 1));  % n × 3
    mean_abs_errors_weighted = mean_abs_errors .* weight_vector;  % n × 3 
    
    % Calculate overall MAE for each variable
    overall_mae_F = mean(mean_abs_errors(:, 1));
    overall_mae_s = mean(mean_abs_errors(:, 2));
    overall_mae_theta = mean(mean_abs_errors(:, 3));

    % Calculate overall MAE for all factors weighted
    overall_mae_weighted = mean(weight_vector .* [overall_mae_F, overall_mae_s, overall_mae_theta]);

    if plot_results
        % Display results
        fprintf('Overall MAE - F: %.4f, s: %.4f, θ: %.4f\n', overall_mae_F, overall_mae_s, overall_mae_theta);
        fprintf('Overall Weighted MAE: %.4f (dimensionless)\n', overall_mae_weighted);
        fprintf('Maximum Residual Norm: %.4e\n', max_residual_norm);
        % Create plots
        plot_error_heatmaps(distal_values, mean_abs_errors, mean_abs_errors_weighted, ...
                            overall_mae_F, overall_mae_s, overall_mae_theta, overall_mae_weighted);
    end

    % Weight all errors (not just means)
    weighted_errors = errors .* weight_vector;  % (n*n_noise) × 3
    % Flatten to column vector for lsqnonlin
    residuals = weighted_errors(:);  % (n*n_noise*3) × 1
    
end

function plot_error_heatmaps(distal_values, mean_abs_errors, mean_abs_errors_weighted, ...
    overall_mae_F, overall_mae_s, overall_mae_theta, overall_mae_weighted)
% Extract F, s, and θ values from original samples
    F_values = distal_values(:, 1);
    s_values = distal_values(:, 2);

% Create interpolated grids for s-F space
    [s_grid_F, F_grid] = meshgrid(linspace(min(s_values), max(s_values), 100), ...
                                   linspace(min(F_values), max(F_values), 100));

% Interpolate errors onto grids using scatteredInterpolant
    F_interp = scatteredInterpolant(s_values, F_values, mean_abs_errors(:, 1), 'linear', 'linear');
    mae_F_grid = F_interp(s_grid_F, F_grid);
    
    s_interp = scatteredInterpolant(s_values, F_values, mean_abs_errors(:, 2), 'linear', 'linear');
    mae_s_grid = s_interp(s_grid_F, F_grid);
    
    theta_interp = scatteredInterpolant(s_values, F_values, mean_abs_errors(:, 3), 'linear', 'linear');
    mae_theta_grid = theta_interp(s_grid_F, F_grid);
    
    weighted_interp = scatteredInterpolant(s_values, F_values, mean(mean_abs_errors_weighted, 2), 'linear', 'linear');
    mae_weighted_grid = weighted_interp(s_grid_F, F_grid);

% Create figure with subplots
    figure;

% Top: Combined MAE (s-F space)
    subplot(2, 3, 1);
    contourf(s_grid_F, F_grid, mae_weighted_grid, 20, 'LineColor', 'none');
    hold on;
    scatter(s_values, F_values, 30, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
    hold off;
    colorbar;
    clim([0, inf]);  % Force colorbar to start at 0
    colormap('parula');
    xlabel('s (position)');
    ylabel('F (force)');
    title(sprintf('Weighted Mean MAE (F, s, θ)\nOverall: %.4f', overall_mae_weighted));

% Bottom left: Mean absolute error in F (s-F space)
    subplot(2, 3, 4);
    contourf(s_grid_F, F_grid, mae_F_grid, 20, 'LineColor', 'none');
    hold on;
    scatter(s_values, F_values, 30, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
    hold off;
    colorbar;
    clim([0, inf]);  % Force colorbar to start at 0
    colormap('parula');
    xlabel('s (position)');
    ylabel('F (force)');
    title(sprintf('MAE in F\nOverall: %.4f', overall_mae_F));

% Bottom middle: Mean absolute error in s (s-F space)
    subplot(2, 3, 5);
    contourf(s_grid_F, F_grid, mae_s_grid, 20, 'LineColor', 'none');
    hold on;
    scatter(s_values, F_values, 30, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
    hold off;
    colorbar;
    clim([0, inf]);  % Force colorbar to start at 0
    colormap('parula');
    xlabel('s (position)');
    ylabel('F (force)');
    title(sprintf('MAE in s\nOverall: %.4f', overall_mae_s));

% Bottom right: Mean absolute error in θ (s-F space)
    subplot(2, 3, 6);
    contourf(s_grid_F, F_grid, mae_theta_grid, 20, 'LineColor', 'none');
    hold on;
    scatter(s_values, F_values, 30, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
    hold off;
    colorbar;
    clim([0, inf]);  % Force colorbar to start at 0
    colormap('parula');
    xlabel('s (position)');
    ylabel('F (force)');
    title(sprintf('MAE in θ\nOverall: %.4f', overall_mae_theta));
end