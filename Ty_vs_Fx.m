% Script to plot normalized Tz vs normalized Fx from get_proximal_value()
% Compares cylindrical beam vs tapered beam
clear; close all; clc;

% Define material and geometric properties - ADJUST THESE AS NEEDED
E = 2.58e9;      % Young's modulus
L = 0.2;      % Length

% Define sampling ranges - ADJUST THESE AS NEEDED
F_range = linspace(0.05, 0.9, 15);  % Sample 10 points for F
s_range = linspace(0.01, 0.2, 15);   % Sample 10 points for s
%s_range = [0.05, 0.15];

% Preallocate arrays to store results
num_samples = length(F_range) * length(s_range);

% ========== FIRST RUN: CYLINDRICAL BEAM ==========
r = 1.5e-3;
I = (pi*r^4)/4;
update_radius(r, "cylindrical");

Tz_values_cyl = zeros(num_samples, 1);
Fx_values_cyl = zeros(num_samples, 1);
F_values = zeros(num_samples, 1);
s_values = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, 0]);
        
        % Store Tz (index 3) and Fx (index 4)
        Tz_values_cyl(idx) = result(3);
        Fx_values_cyl(idx) = abs(result(4));
        F_values(idx) = F;  % Store F value for coloring
        s_values(idx) = s;  % Store s value for grouping
        idx = idx + 1;
    end
end

% Normalize the cylindrical beam values
Tz_normalized_cyl = Tz_values_cyl / (E * I / L);
Fx_normalized_cyl = Fx_values_cyl / (E * I / L^2);

% ========== UPDATE FOR TAPERED BEAM ==========
r = 2e-3;
I = (pi*r^4)/4;
update_radius([r, 1e-3], "tapered");

% ========== SECOND RUN: TAPERED BEAM ==========
Tz_values_tap = zeros(num_samples, 1);
Fx_values_tap = zeros(num_samples, 1);

idx = 1;
for F = F_range
    for s = s_range
        % Call the function - returns [Tx, Ty, Tz, Fx, Fy, Fz]
        result = get_proximal_value([F, s, 0]);
        
        % Store Tz (index 3) and Fx (index 4)
        Tz_values_tap(idx) = result(3);
        Fx_values_tap(idx) = abs(result(4));
        idx = idx + 1;
    end
end

% Normalize the tapered beam values
Tz_normalized_tap = Tz_values_tap / (E * I / L);
Fx_normalized_tap = Fx_values_tap / (E * I / L^2);

% ========== PLOT BOTH ON SAME FIGURE ==========
figure;
hold on;
% Plot cylindrical beam (blue)
h1 = plot(NaN, NaN, 'b-', 'LineWidth', 1.5); % For legend only
for s = s_range  % Changed from F_range
    indices = find(s_values == s);  % Changed from F_values == F
    scatter(Tz_normalized_cyl(indices), Fx_normalized_cyl(indices), 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Tz_normalized_cyl(indices), Fx_normalized_cyl(indices), 'b-', 'LineWidth', 1.5);
end
% Plot tapered beam (red)
h2 = plot(NaN, NaN, 'r-', 'LineWidth', 1.5); % For legend only
for s = s_range  % Changed from F_range
    indices = find(s_values == s);  % Changed from F_values == F
    scatter(Tz_normalized_tap(indices), Fx_normalized_tap(indices), 50, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
    plot(Tz_normalized_tap(indices), Fx_normalized_tap(indices), 'r-', 'LineWidth', 1.5);
end
% Add legend using the handles
legend([h1, h2], {'Cylindrical', 'Tapered'}, 'Location', 'best');
xlabel('Normalized Tz (Tz / (EI/L))');
ylabel('Normalized Fx (Fx / (EI/L^2))');
title('Normalized Fx vs Normalized Tz: Cylindrical vs Tapered Beam');
grid on;
hold off;