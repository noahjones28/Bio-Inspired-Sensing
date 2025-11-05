function mean_R = pairwise_distance_scan(n_forces, r_array)
close all;
% PAIRWISE_DISTANCE_SCAN - Complete global mapping injectivity test
%
% mean_R = pairwise_distance_scan(n_forces, r_array)
%
% Inputs:
% n_forces - Number of force samples to generate
% r_array  - Radius array for beam geometry
%
% Outputs:
% mean_R - mean of per-point minimum r_ij values  % <-- CHANGED

% Update radius
update_radius(r_array);
% Generate test force samples
fprintf('Generating %d force samples...\n', n_forces);
X = generate_single_force_samples(n_forces);
% Compute forward model
fprintf('Computing forward model...\n');
W = get_proximal_values(X);
% Remove tau from force samples
X = X(:,1:5);
% Normalize both spaces
% For angles (columns 3,4), convert to sin/cos to handle wraparound
X_expanded = [X(:,1:2), sin(X(:,3)), cos(X(:,3)), sin(X(:,4)), cos(X(:,4))];
X_norm = X_expanded ./ std(X_expanded, 0, 1);
W_norm = W ./ std(W, 0, 1);

% Compute pairwise distances
fprintf('Computing pairwise distances...\n');
N = size(W_norm, 1);
R = zeros(N);
for i = 1:N
    dW = W_norm - W_norm(i,:);
    dX = X_norm - X_norm(i,:);
    num = sqrt(sum(dW.^2, 2));
    den = sqrt(sum(dX.^2, 2));
    R(i,:) = (num ./ den).';
    R(i,i) = NaN;
end

% === Per-point minima (core injectivity signal) ===
local_rij = min(R, [], 2, 'omitnan');                                  % <-- CHANGED
vals = R(~isnan(R));                                                    % all off-diagonal (kept for ref if needed)

% === Statistics (report per-point minima, not all pairs) ===
mean_R = mean(local_rij,'omitnan');                                     % <-- CHANGED
min_R  = min(local_rij,[],'omitnan');                                   % <-- CHANGED
max_R  = max(local_rij,[],'omitnan');                                   % <-- CHANGED
med_R  = median(local_rij,'omitnan');                                    % <-- CHANGED

% Print results
fprintf('\n=== Pairwise Distance Results (Per-Point Minima) ===\n');      % <-- CHANGED
fprintf('Samples: %d\n', N);
fprintf('Mean(per-point min): %.6f\n', mean_R);                          % <-- CHANGED
fprintf('Median(per-point min): %.6f\n', med_R);                         % <-- CHANGED
fprintf('Min(per-point min): %.6f\n', min_R);                            % <-- CHANGED
fprintf('Max(per-point min): %.6f\n', max_R);                            % <-- CHANGED

% Assessment (based on per-point minima)
if min_R < 1e-6
    fprintf('\n⚠️ WARNING: min per-point min r_ij ≈ 0 → NON-UNIQUE MAPPING\n');
elseif min_R < 1e-3
    fprintf('\n⚠️ CAUTION: min per-point min r_ij is small\n');
else
    fprintf('\n✓ Mapping appears globally injective in sampled region\n');
end

% Find 10 worst pairs with distance threshold (fast version)
fprintf('\n=== 10 Force Pairs with Lowest r_{ij} (distant inputs only) ===\n');
fprintf('Threshold: ΔF>0.05 OR Δs>0.01 OR Δel>3 OR Δaz>3\n');

[R_sorted, idx] = sort(vals, 'ascend');
found = 0;
k = 1;

while found < 10 && k <= length(idx)
    [i, j] = ind2sub_triu(N, idx(k));
    
    % Check threshold
    dF = abs(X(i,1) - X(j,1));
    ds = abs(X(i,2) - X(j,2));
    del = min(abs(X(i,3) - X(j,3)), 2*pi - abs(X(i,3) - X(j,3)));
    daz = min(abs(X(i,4) - X(j,4)), 2*pi - abs(X(i,3) - X(j,3))); %#ok<NASGU> (kept for completeness)
    
    if dF > 0.1 || ds > 0.06
        found = found + 1;
        fprintf('\n--- Pair %d: Samples %d and %d ---\n', found, i, j);
        fprintf('r_ij = %.6f\n', R_sorted(k));
        fprintf('Force 1: F=%.3f s=%.4f el=%.3f az=%.3f\n', X(i,1), X(i,2), X(i,3), X(i,4));
        fprintf('Force 2: F=%.3f s=%.4f el=%.3f az=%.3f\n', X(j,1), X(j,2), X(j,3), X(j,4));
        fprintf('Wrench 1: [%s]\n', sprintf('%.4f ', W(i,:)));
        fprintf('Wrench 2: [%s]\n', sprintf('%.4f ', W(j,:)));
    end
    
    k = k + 1;
end

if found == 0
    fprintf('\nNo pairs found exceeding distance threshold.\n');
end

% Coordinates for plotting (F,s)
F = X(:,1);
s = X(:,2);

% ---------- PLOTS ----------
figure('Position', [100 100 1400 900]);

% (A) Histogram of per-point minima (not all pairs)  % <-- CHANGED
subplot(2,2,1);
histogram(local_rij, 50, 'FaceColor', [0.3 0.6 0.9]);
hold on;
yl = ylim;
plot([mean_R mean_R], yl, 'r--', 'LineWidth', 2);
plot([0.1 0.1], yl, 'r:', 'LineWidth', 1.5);
plot([0.3 0.3], yl, 'Color', [1 0.5 0], 'LineStyle', ':', 'LineWidth', 1.5);
xlabel('Per-point minimum r_{ij}');
ylabel('Frequency');
title('Distribution of Per-Point Minima r_{ij}');
legend('r_{ij}^{min} per-point', sprintf('Mean = %.3f', mean_R), 'Degenerate (<0.1)', 'Sensitive (0.3)');
grid on;

% (B) Heatmap of per-point minima over (s,F)       % <-- CHANGED
subplot(2,2,2);
[s_grid, F_grid] = meshgrid(linspace(min(s), max(s), 100), linspace(min(F), max(F), 100));
local_grid = griddata(s, F, local_rij, s_grid, F_grid, 'natural');
imagesc(linspace(min(s), max(s), 100), linspace(min(F), max(F), 100), local_grid, [0 0.5]);
set(gca, 'YDir', 'normal');
xlabel('Position s');
ylabel('Force F');
title('Per-Point Minimum r_{ij} (Injectivity Map)');

% Traffic-light colormap: <0.1 red, 0.1–0.3 orange, >0.3 green  % <-- CHANGED
caxis([0 0.5]);
n = 256;
n1 = max(1, round(n*(0.1/0.5)));
n2 = max(1, round(n*((0.3-0.1)/0.5)));
n3 = max(1, n - n1 - n2);
cmap = [repmat([1 0 0], n1, 1); repmat([1 0.5 0], n2, 1); repmat([0 0.5 0], n3, 1)];
colormap(gca, cmap);
cb = colorbar;
ylabel(cb, 'Per-point min r_{ij}');
hold on;
contour(s_grid, F_grid, local_grid, [0.1 0.1], 'k-', 'LineWidth', 1.5);
contour(s_grid, F_grid, local_grid, [0.3 0.3], 'k--', 'LineWidth', 1.5);

% Legend for color bands (kept)
subplot(2,2,4);
axis off;
text(0.1, 0.9, 'Color Guide:', 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.7, '● r_{ij} < 0.1:', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
text(0.35, 0.7, 'Non-injective (red)', 'FontSize', 12);
text(0.1, 0.5, '● 0.1 < r_{ij} < 0.3:', 'FontSize', 12, 'Color', [1 0.5 0], 'FontWeight', 'bold');
text(0.35, 0.5, 'Sensitive (orange)', 'FontSize', 12);
text(0.1, 0.3, '● r_{ij} > 0.3:', 'FontSize', 12, 'Color', [0 0.5 0], 'FontWeight', 'bold');
text(0.35, 0.3, 'Healthy (green)', 'FontSize', 12);
text(0.1, 0.1, 'Value shown: per-point minimum r_{ij}', 'FontSize', 11, 'FontAngle', 'italic');

end


function [i, j] = ind2sub_triu(N, linear_idx)
% Convert linear index of upper triangular part to (i,j)
% For symmetric matrix with NaN diagonal
count = 0;
for ii = 1:N
    for jj = 1:N
        if ii ~= jj
            count = count + 1;
            if count == linear_idx
                i = ii;
                j = jj;
                return;
            end
        end
    end
end
end

function X = generate_single_force_samples(n_forces)
% Generate force samples using Latin Hypercube Sampling
F_range = [0.1, 1.0];
s_range = [0.02, 0.20];
el_range = [0, 2*pi];
az_range = [pi/6, 5*pi/6];
scale = @(u,r) r(1) + u.*diff(r);
rng(1234);
U1 = lhsdesign(n_forces, 4);
F = scale(U1(:,1), F_range);
s = scale(U1(:,2), s_range);
el = scale(U1(:,3), el_range);
az = scale(U1(:,4), az_range);
tau = zeros(n_forces, 3);
X = [F s el az tau];
end

% Update Radius Function
function update_radius(r)
try
    load("my_robot.mat");
    for i = 1:length(r)
        S1.VLinks(2).r{i} = @(X1) r(i);
        S1.CVRods{2}(1+i).UpdateAll;
        S1 = S1.Update();
    end
    save('my_robot.mat','S1')
catch ME
    error('Failed to change beam radii: %s', ME.message);
end
end