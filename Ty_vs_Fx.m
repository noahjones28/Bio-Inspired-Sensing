% Script to plot normalized Tz vs normalized Fx from get_proximal_value()
% Compares cylindrical beam vs tapered beam
% Uses 2D HSV colormap: Hue = s, Saturation = F
clear; close all; clc;

% Define material and geometric properties - ADJUST THESE AS NEEDED
E = 2.58e9;      % Young's modulus
L = 0.2;      % Length

% Define sampling ranges - ADJUST THESE AS NEEDED
F_range = linspace(0.05, 0.9, 10);  % Sample 15 points for F
s_range = linspace(0.01, 0.2, 10);   % Sample 15 points for s
theta = 0;
tau_array = [0 0 0];

% Preallocate arrays to store results
num_samples = length(F_range) * length(s_range);

% ========== FIRST RUN: CYLINDRICAL BEAM ==========
r = 1.5e-3;
I = (pi*r^4)/4;
update_radius(r, "cylindrical");

Ty_values_cyl = zeros(num_samples, 1);
Tz_values_cyl = zeros(num_samples, 1);
Fx_values_cyl = zeros(num_samples, 1);
F_values = zeros(num_samples, 1);
s_values = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, theta]);
        
        % Store Ty (index 2), Tz (index 3) and Fx (index 4)
        Ty_values_cyl(idx) = result(2);
        Tz_values_cyl(idx) = result(3);
        Fx_values_cyl(idx) = abs(result(4));
        F_values(idx) = F;  % Store F value for coloring
        s_values(idx) = s;  % Store s value for grouping
        idx = idx + 1;
    end
end

% Normalize the cylindrical beam values
Ty_normalized_cyl = Ty_values_cyl;
Tz_normalized_cyl = Tz_values_cyl;
Fx_normalized_cyl = Fx_values_cyl;

% Compute mean_R for cylindrical beam
force_samples_cyl = [F_values, s_values, repmat(theta,num_samples,1), repmat(tau_array,num_samples,1)];
mean_R_cyl = pairwise_distance_scan_3(force_samples_cyl);

% ========== UPDATE FOR TAPERED BEAM ==========
update_radius([1.9e-3, 1.25e-3], "tapered");

% ========== SECOND RUN: TAPERED BEAM ==========
Ty_values_tap = zeros(num_samples, 1);
Tz_values_tap = zeros(num_samples, 1);
Fx_values_tap = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, theta]);
        
        % Store Ty (index 2), Tz (index 3) and Fx (index 4)
        Ty_values_tap(idx) = result(2);
        Tz_values_tap(idx) = result(3);
        Fx_values_tap(idx) = abs(result(4));
        idx = idx + 1;
    end
end

% Normalize the tapered beam values
Ty_normalized_tap = Ty_values_tap;
Tz_normalized_tap = Tz_values_tap;
Fx_normalized_tap = Fx_values_tap;

% Compute mean_R for tapered beam
force_samples_tap = [F_values, s_values, repmat(theta,num_samples,1), repmat(tau_array,num_samples,1)];
mean_R_tap = pairwise_distance_scan_3(force_samples_tap);

% ========== UPDATE FOR OPTIMIZED MULTI-DIVISION ==========
%r_optimal = 1e-3*[0.831, 1.008, 1.222, 1.59, 1.354, 1.867, 1.783, 1.623, 1.581, 1.655, 2.092, 1.737, 1.808, 1.957, 1.826, 1.458, 1.573, 1.608, 0.738, 2.782];
%r_optimal = [1.25e-3, 2e-3*ones(1,19)];
r_optimal = [linspace(1.25e-3, 2e-3, 10), linspace(2e-3, 1.25e-3, 10)];
update_radius(r_optimal, "multi division");

% ========== THIRD RUN: OPTIMIZED MULTI-DIVISION ==========
Ty_values_opt = zeros(num_samples, 1);
Tz_values_opt = zeros(num_samples, 1);
Fx_values_opt = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, theta]);
        
        % Store Ty (index 2), Tz (index 3) and Fx (index 4)
        Ty_values_opt(idx) = result(2);
        Tz_values_opt(idx) = result(3);
        Fx_values_opt(idx) = abs(result(4));
        idx = idx + 1;
    end
end

% Normalize the optimized multi-division values
Ty_normalized_opt = Ty_values_opt;
Tz_normalized_opt = Tz_values_opt;
Fx_normalized_opt = Fx_values_opt;

% Compute mean_R for optimized multi-division
force_samples_opt = [F_values, s_values, repmat(theta,num_samples,1), repmat(tau_array,num_samples,1)];
mean_R_opt = pairwise_distance_scan_3(force_samples_opt);

% ========== CALCULATE COMMON X-AXIS LIMITS ==========
all_T_values = [Ty_normalized_cyl; Ty_normalized_tap; Ty_normalized_opt; Tz_normalized_cyl; Tz_normalized_tap; Tz_normalized_opt];
x_range = max(all_T_values) - min(all_T_values);
x_limits = [min(all_T_values) - 0.05*x_range, max(all_T_values) + 0.05*x_range];

% ========== CREATE HSV COLORMAP ==========
% Normalize F and s to [0, 1]
F_norm = (F_values - min(F_range)) / (max(F_range) - min(F_range));
s_norm = (s_values - min(s_range)) / (max(s_range) - min(s_range));

% Map s to hue range [0, 0.85] to avoid red repetition (0 and 1 both map to red)
hue_range = 0.85;
hue_values = s_norm * hue_range;

% Create HSV colors: Hue = s (mapped to 0-0.85), Saturation = F, Value = 1
hsv_colors = [hue_values, F_norm, ones(num_samples, 1)];
rgb_colors = hsv2rgb(hsv_colors);

% ========== PLOT BOTH ON SAME FIGURE WITH SUBPLOTS ==========
figure('Position', [100, 100, 1200, 900]);

% Create interpolation grid for smoother surface
n_interp = 50;
F_interp = linspace(min(F_range), max(F_range), n_interp);
s_interp = linspace(min(s_range), max(s_range), n_interp);
[F_grid, s_grid] = meshgrid(F_interp, s_interp);

% Subplot 1: Tz vs Fx (Cylindrical) - Full view
subplot(2,2,1);
hold on;

% Interpolate Tz and Fx values
Tz_cyl_interp = griddata(F_values, s_values, Tz_normalized_cyl, F_grid, s_grid, 'cubic');
Fx_cyl_interp = griddata(F_values, s_values, Fx_normalized_cyl, F_grid, s_grid, 'cubic');

% Create color matrix for the surface
F_norm_grid = (F_grid - min(F_range)) / (max(F_range) - min(F_range));
s_norm_grid = (s_grid - min(s_range)) / (max(s_range) - min(s_range));
hue_grid = s_norm_grid * hue_range;

% Convert HSV to RGB for surface coloring
C_cyl = zeros(n_interp, n_interp, 3);
for i = 1:n_interp
    for j = 1:n_interp
        hsv_val = [hue_grid(i,j), F_norm_grid(i,j), 1];
        C_cyl(i,j,:) = hsv2rgb(hsv_val);
    end
end

% Plot surface
surf(Tz_cyl_interp, Fx_cyl_interp, zeros(size(Tz_cyl_interp)), C_cyl, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);  % View from top (2D projection)

% Overlay original data points as tiny black dots
scatter(Tz_normalized_cyl, Fx_normalized_cyl, 5, 'k', 'filled');

xlabel('Normalized Tz', 'FontWeight', 'bold', 'FontSize', 13);
ylabel('Normalized Fx', 'FontWeight', 'bold', 'FontSize', 13);
title(sprintf('Cylindrical Beam\n(mean R=%.3f)', mean_R_cyl));
xlim([x_limits(1), x_limits(2)*1.15]);  % Add 15% padding on the right
ylim([min(Fx_normalized_cyl)*0.95, max(Fx_normalized_cyl)*1.05]);
set(gca, 'FontWeight', 'bold', 'FontSize', 11);
grid on;

% Add faint outline showing zoomed region
rectangle('Position', [0, 0, 0.04, 0.1], 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1, 'LineStyle', '--');

hold off;

% Create inset axes for cylindrical zoomed view (positioned in bottom right)
ax1_pos = get(gca, 'Position');
inset1 = axes('Position', [ax1_pos(1)+ax1_pos(3)*0.55, ax1_pos(2)+ax1_pos(4)*0.05, ax1_pos(3)*0.4, ax1_pos(4)*0.4]);
hold on;
surf(Tz_cyl_interp, Fx_cyl_interp, zeros(size(Tz_cyl_interp)), C_cyl, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);
scatter(Tz_normalized_cyl, Fx_normalized_cyl, 3, 'k', 'filled');
xlim([0, 0.04]);
ylim([0, 0.1]);
box on;
set(gca, 'FontSize', 8);
title('Zoomed', 'FontSize', 8);
hold off;

% Subplot 2: Tz vs Fx (Tapered) - Full view
subplot(2,2,2);
hold on;

% Interpolate Tz and Fx values
Tz_tap_interp = griddata(F_values, s_values, Tz_normalized_tap, F_grid, s_grid, 'cubic');
Fx_tap_interp = griddata(F_values, s_values, Fx_normalized_tap, F_grid, s_grid, 'cubic');

% Create color matrix for the surface (same as cylindrical)
C_tap = C_cyl;  % Same color mapping based on F and s

% Plot surface
surf(Tz_tap_interp, Fx_tap_interp, zeros(size(Tz_tap_interp)), C_tap, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);  % View from top (2D projection)

% Overlay original data points as tiny black dots
scatter(Tz_normalized_tap, Fx_normalized_tap, 5, 'k', 'filled');

xlabel('Normalized Tz', 'FontWeight', 'bold', 'FontSize', 13);
ylabel('Normalized Fx', 'FontWeight', 'bold', 'FontSize', 13);
title(sprintf('Tapered Beam\n(mean R=%.3f)', mean_R_tap));
xlim([x_limits(1), x_limits(2)*1.15]);  % Add 15% padding on the right
ylim([min(Fx_normalized_tap)*0.95, max(Fx_normalized_tap)*1.05]);
set(gca, 'FontWeight', 'bold', 'FontSize', 11);
grid on;

% Add faint outline showing zoomed region
rectangle('Position', [0, 0, 0.04, 0.1], 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1, 'LineStyle', '--');

hold off;

% Create inset axes for tapered zoomed view (positioned in bottom right)
ax2_pos = get(gca, 'Position');
inset2 = axes('Position', [ax2_pos(1)+ax2_pos(3)*0.55, ax2_pos(2)+ax2_pos(4)*0.05, ax2_pos(3)*0.4, ax2_pos(4)*0.4]);
hold on;
surf(Tz_tap_interp, Fx_tap_interp, zeros(size(Tz_tap_interp)), C_tap, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);
scatter(Tz_normalized_tap, Fx_normalized_tap, 3, 'k', 'filled');
xlim([0, 0.04]);
ylim([0, 0.1]);
box on;
set(gca, 'FontSize', 8);
title('Zoomed', 'FontSize', 8);
hold off;

% Subplot 3: Tz vs Fx (Optimized Multi-Division) - Full view
subplot(2,2,3);
hold on;

% Interpolate Tz and Fx values
Tz_opt_interp = griddata(F_values, s_values, Tz_normalized_opt, F_grid, s_grid, 'cubic');
Fx_opt_interp = griddata(F_values, s_values, Fx_normalized_opt, F_grid, s_grid, 'cubic');

% Create color matrix for the surface (same as cylindrical)
C_opt = C_cyl;  % Same color mapping based on F and s

% Plot surface
surf(Tz_opt_interp, Fx_opt_interp, zeros(size(Tz_opt_interp)), C_opt, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);  % View from top (2D projection)

% Overlay original data points as tiny black dots
scatter(Tz_normalized_opt, Fx_normalized_opt, 5, 'k', 'filled');

xlabel('Normalized Tz', 'FontWeight', 'bold', 'FontSize', 13);
ylabel('Normalized Fx', 'FontWeight', 'bold', 'FontSize', 13);
title(sprintf('Optimized Multi-Division\n(mean R=%.3f)', mean_R_opt));
xlim([x_limits(1), x_limits(2)*1.15]);  % Add 15% padding on the right
ylim([min(Fx_normalized_opt)*0.95, max(Fx_normalized_opt)*1.05]);
set(gca, 'FontWeight', 'bold', 'FontSize', 11);
grid on;

% Add faint outline showing zoomed region
rectangle('Position', [0, 0, 0.04, 0.1], 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1, 'LineStyle', '--');

hold off;

% Create inset axes for optimized zoomed view (positioned in bottom right)
ax3_pos = get(gca, 'Position');
inset3 = axes('Position', [ax3_pos(1)+ax3_pos(3)*0.55, ax3_pos(2)+ax3_pos(4)*0.05, ax3_pos(3)*0.4, ax3_pos(4)*0.4]);
hold on;
surf(Tz_opt_interp, Fx_opt_interp, zeros(size(Tz_opt_interp)), C_opt, 'EdgeColor', 'none', 'FaceColor', 'interp');
view(2);
scatter(Tz_normalized_opt, Fx_normalized_opt, 3, 'k', 'filled');
xlim([0, 0.04]);
ylim([0, 0.1]);
box on;
set(gca, 'FontSize', 8);
title('Zoomed', 'FontSize', 8);
hold off;

% Subplot 4: 2D Colormap Legend
subplot(2,2,4);
hold on;

% Create a grid showing the 2D colormap
n_grid = 50;
[F_grid, s_grid] = meshgrid(linspace(0, 1, n_grid), linspace(0, 1, n_grid));
hsv_grid = cat(3, s_grid * hue_range, F_grid, ones(size(F_grid)));
rgb_grid = hsv2rgb(hsv_grid);

image([min(F_range), max(F_range)], [min(s_range), max(s_range)], rgb_grid);
set(gca, 'YDir', 'normal', 'FontWeight', 'bold', 'FontSize', 10);
xlabel('F (Saturation)', 'FontWeight', 'bold', 'FontSize', 11);
ylabel('s (Hue)', 'FontWeight', 'bold', 'FontSize', 11);
title('Color Encoding');
axis tight;
hold off;

% Add overall title
sgtitle('Normalized Fx vs Normalized Tz with 2D Color Encoding (Hue=s, Saturation=F)');