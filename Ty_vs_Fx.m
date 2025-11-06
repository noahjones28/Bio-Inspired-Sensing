% Script to plot normalized Tz vs normalized Fx from get_proximal_value()
% Compares cylindrical beam vs tapered beam
clear; close all; clc;

% Define material and geometric properties - ADJUST THESE AS NEEDED
E = 2.58e9;      % Young's modulus
L = 0.2;      % Length

% Define sampling ranges - ADJUST THESE AS NEEDED
F_range = linspace(0.05, 0.9, 15);  % Sample 10 points for F
s_range = linspace(0.01, 0.2, 15);   % Sample 10 points for s
theta = 0;

% Preallocate arrays to store results
num_samples = length(F_range) * length(s_range);

% ========== FIRST RUN: CYLINDRICAL BEAM ==========
r = 1.5e-3;
I = (pi*r^4)/4;
update_radius(r, "cylindrical");

Ty_values_cyl = zeros(num_samples, 1);  % ADDED
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
        Ty_values_cyl(idx) = result(2);  % ADDED
        Tz_values_cyl(idx) = result(3);
        Fx_values_cyl(idx) = abs(result(4));
        F_values(idx) = F;  % Store F value for coloring
        s_values(idx) = s;  % Store s value for grouping
        idx = idx + 1;
    end
end

% Normalize the cylindrical beam values
Ty_normalized_cyl = Ty_values_cyl / (E * I / L);  % ADDED
Tz_normalized_cyl = Tz_values_cyl / (E * I / L);
Fx_normalized_cyl = Fx_values_cyl / (E * I / L^2);

% ========== UPDATE FOR TAPERED BEAM ==========
%r = 2e-3;
r_optimal = 1e-3*[0.831, 1.008, 1.222, 1.59, 1.354, 1.867, 1.783, 1.623, 1.581, 1.655, 2.092, 1.737, 1.808, 1.957, 1.826, 1.458, 1.573, 1.608, 0.738, 2.782];
%I = (pi*r^4)/4;
update_radius(r_optimal, "multi division");

% ========== SECOND RUN: TAPERED BEAM ==========
Ty_values_tap = zeros(num_samples, 1);  % ADDED
Tz_values_tap = zeros(num_samples, 1);
Fx_values_tap = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, theta]);
        
        % Store Ty (index 2), Tz (index 3) and Fx (index 4)
        Ty_values_tap(idx) = result(2);  % ADDED
        Tz_values_tap(idx) = result(3);
        Fx_values_tap(idx) = abs(result(4));
        idx = idx + 1;
    end
end

% Normalize the tapered beam values
Ty_normalized_tap = Ty_values_tap / (E * I / L);  % ADDED
Tz_normalized_tap = Tz_values_tap / (E * I / L);
Fx_normalized_tap = Fx_values_tap / (E * I / L^2);

% ========== CALCULATE COMMON X-AXIS LIMITS ==========  % ADDED
all_T_values = [Ty_normalized_cyl; Ty_normalized_tap; Tz_normalized_cyl; Tz_normalized_tap];
x_limits = [min(all_T_values), max(all_T_values)];

% ========== PLOT BOTH ON SAME FIGURE WITH SUBPLOTS ==========
figure;

% Subplot 1: Tz vs Fx
subplot(1,2,1);
hold on;

% Plot cylindrical beam (blue)
h1 = plot(NaN, NaN, 'b-', 'LineWidth', 1.5); % For legend only
for s = s_range
    indices = find(s_values == s);
    scatter(Tz_normalized_cyl(indices), Fx_normalized_cyl(indices), 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Tz_normalized_cyl(indices), Fx_normalized_cyl(indices), 'b-', 'LineWidth', 1.5);
    if s == max(s_range)  % ADDED
        text(Tz_normalized_cyl(indices(end)), Fx_normalized_cyl(indices(end)), sprintf(' F=%.2f, s=%.2f', F_values(indices(end)), s), 'FontSize', 8, 'Color', 'b');  % MODIFIED
    end  % ADDED
end

% Plot tapered beam (red)
h2 = plot(NaN, NaN, 'r-', 'LineWidth', 1.5); % For legend only
for s = s_range
    indices = find(s_values == s);
    scatter(Tz_normalized_tap(indices), Fx_normalized_tap(indices), 50, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Tz_normalized_tap(indices), Fx_normalized_tap(indices), 'r-', 'LineWidth', 1.5);
    if s == max(s_range)  % ADDED
        text(Tz_normalized_tap(indices(end)), Fx_normalized_tap(indices(end)), sprintf(' F=%.2f, s=%.2f', F_values(indices(end)), s), 'FontSize', 8, 'Color', 'r');  % MODIFIED
    end  % ADDED
end

legend([h1, h2], {'Cylindrical', 'Tapered'}, 'Location', 'best');
xlabel('Normalized Tz (Tz / (EI/L))');
ylabel('Normalized Fx (Fx / (EI/L^2))');
title('Normalized Fx vs Normalized Tz');
xlim(x_limits);  % ADDED
grid on;
hold off;

% Subplot 2: Ty vs Fx
subplot(1,2,2);
hold on;

% Plot cylindrical beam (blue)
h1 = plot(NaN, NaN, 'b-', 'LineWidth', 1.5);
for s = s_range
    indices = find(s_values == s);
    scatter(Ty_normalized_cyl(indices), Fx_normalized_cyl(indices), 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Ty_normalized_cyl(indices), Fx_normalized_cyl(indices), 'b-', 'LineWidth', 1.5);
    if s == max(s_range)  % ADDED
        text(Ty_normalized_cyl(indices(end)), Fx_normalized_cyl(indices(end)), sprintf(' F=%.2f, s=%.2f', F_values(indices(end)), s), 'FontSize', 8, 'Color', 'b');  % MODIFIED
    end  % ADDED
end

% Plot tapered beam (red)
h2 = plot(NaN, NaN, 'r-', 'LineWidth', 1.5);
for s = s_range
    indices = find(s_values == s);
    scatter(Ty_normalized_tap(indices), Fx_normalized_tap(indices), 50, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Ty_normalized_tap(indices), Fx_normalized_tap(indices), 'r-', 'LineWidth', 1.5);
    if s == max(s_range)  % ADDED
        text(Ty_normalized_tap(indices(end)), Fx_normalized_tap(indices(end)), sprintf(' F=%.2f, s=%.2f', F_values(indices(end)), s), 'FontSize', 8, 'Color', 'r');  % MODIFIED
    end  % ADDED
end

legend([h1, h2], {'Cylindrical', 'Tapered'}, 'Location', 'best');
xlabel('Normalized Ty (Ty / (EI/L))');
ylabel('Normalized Fx (Fx / (EI/L^2))');
title('Normalized Fx vs Normalized Ty');
xlim(x_limits);  % ADDED
grid on;
hold off;