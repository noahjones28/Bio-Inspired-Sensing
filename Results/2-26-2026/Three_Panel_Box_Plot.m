%% Three-Panel Box Plot - Cylindrical Baseline vs Optimized
% Reads data from JMP_Stacked_Table.xlsx and creates a 3-panel figure
% matching the JMP box plot style.

clear; clc; close all;

%% Read Data
T = readtable('JMP Stacked Table.xlsx');

% Split by design
isBL = strcmp(T.Design, 'Cylindrical Baseline');
isOpt = strcmp(T.Design, 'Optimized');

% Extract error columns for each group
angle_BL  = T.AngleError_deg_(isBL);
angle_Opt = T.AngleError_deg_(isOpt);

force_BL  = T.ForceError_N_(isBL);
force_Opt = T.ForceError_N_(isOpt);

pos_BL    = T.PositionError_mm_(isBL);
pos_Opt   = T.PositionError_mm_(isOpt);

%% Colors (match JMP: black for Baseline, blue for Optimized)
colBL  = [0 0 0];       % black
colOpt = [0 0.384 0.608]; % dark blue (#00629B)

%% Create Figure
fig = figure('Position', [100 100 1400 500], 'Color', 'w');

metrics   = {force_BL, force_Opt; pos_BL, pos_Opt; angle_BL, angle_Opt};
ylabels   = {'Force Error (N)', 'Position Error (mm)', 'Angle Error (deg)'};
groupNames = {'Cylindrical Baseline', 'Optimized'};

for k = 1:3
    subplot(1, 3, k); hold on;

    dataBL  = metrics{k, 1};
    dataOpt = metrics{k, 2};

    % Box positions
    posBL  = 1;
    posOpt = 2;

    % --- Draw box plots manually for color control ---
    drawBoxPlot(dataBL,  posBL,  colBL,  0.35);
    drawBoxPlot(dataOpt, posOpt, colOpt, 0.35);

    % --- Overlay individual data points (swarmchart, like JMP) ---
    swarmchart(repmat(posBL,  size(dataBL)),  dataBL,  30, colBL,  'filled', ...
        'MarkerFaceAlpha', 0.7, 'XJitterWidth', 0.3);
    swarmchart(repmat(posOpt, size(dataOpt)), dataOpt, 30, colOpt, 'filled', ...
        'MarkerFaceAlpha', 0.7, 'XJitterWidth', 0.3);

    % --- Format axes ---
    set(gca, 'XTick', [1 2], 'XTickLabel', groupNames, ...
        'XTickLabelRotation', 0, ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'Box', 'on', 'LineWidth', 0.8, ...
        'YGrid', 'on', 'YMinorTick', 'on', 'YMinorGrid', 'on', ...
        'GridAlpha', 0.3, 'MinorGridAlpha', 0.15);
    xlim([0.4 2.6]);
    ylabel(ylabels{k}, 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Design', 'FontSize', 14, 'FontWeight', 'bold');
    title(ylabels{k}, 'FontSize', 14, 'FontWeight', 'bold');

    hold off;
end

%% Save
exportgraphics(fig, 'Three_Panel_BoxPlot.png', 'Resolution', 300);
fprintf('Figure saved to Three_Panel_BoxPlot.png\n');

%% ========== Helper Function ==========
function drawBoxPlot(data, xPos, col, width)
    % Draws a single box-and-whisker at the given x position.
    q1  = prctile(data, 25);
    q2  = prctile(data, 50);  % median
    q3  = prctile(data, 75);
    iqr = q3 - q1;

    % Whisker limits (1.5*IQR, capped at data range)
    wLo = max(min(data), q1 - 1.5 * iqr);
    wHi = min(max(data), q3 + 1.5 * iqr);

    hw = width / 2;  % half-width

    % Box
    rectangle('Position', [xPos - hw, q1, width, q3 - q1], ...
        'EdgeColor', col, 'LineWidth', 1.5);

    % Median line
    line([xPos - hw, xPos + hw], [q2 q2], 'Color', col, 'LineWidth', 2);

    % Whiskers
    line([xPos xPos], [q1 wLo], 'Color', col, 'LineWidth', 1.2);
    line([xPos xPos], [q3 wHi], 'Color', col, 'LineWidth', 1.2);

    % Whisker caps
    capW = hw * 0.6;
    line([xPos - capW, xPos + capW], [wLo wLo], 'Color', col, 'LineWidth', 1.2);
    line([xPos - capW, xPos + capW], [wHi wHi], 'Color', col, 'LineWidth', 1.2);
end