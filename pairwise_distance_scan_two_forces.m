function mean_R = pairwise_distance_scan_two_forces(n_forces)
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
%update_radius([1.5e-3, 1.125e-3], "tapered")
%update_radius([1.5e-3, 1.125e-3, 1.5e-3, 1.125e-3], "elliptical tapered")
%a = 1.6e-3*ones(1,20);
%a([5,10,15]) = 1.2e-3;
%update_radius(a, "multi division")
%update_radius(1.5e-3, "cylindrical")
% Generate test force samples
fprintf('Generating %d force samples...\n', n_forces);
X = generate_double_force_samples(n_forces);
% Compute forward model with probes
fprintf('Computing forward model...\n');

W = get_proximal_values(X);

% Remove az1, az2, and tau from force samples
X(:, [4, 8, 9, 10, 11]) = [];

% Normalize both spaces

F_scale = 0.8;   % 1.0 or your upper bound
s_scale = 0.2;      % beam length or max s
X_norm = [X(:,1)/F_scale, X(:,2)/s_scale, sin(X(:,3)), cos(X(:,3)), X(:,4)/F_scale, X(:,5)/s_scale, sin(X(:,6)), cos(X(:,6))];

M_scale_W = max(abs(W(:,1:3)), [], 'all');   % moments
F_scale_W = max(abs(W(:,4:6)), [], 'all');   % forces

W_norm = W;
W_norm(:,1:3) = W(:,1:3) / M_scale_W;
W_norm(:,4:6) = W(:,4:6) / F_scale_W;

% Compute pairwise distances
fprintf('Computing pairwise distances...\n');
N = size(W_norm, 1);
R = zeros(N);
for i = 1:N
    dW = W_norm - W_norm(i,:);
    dX = X_norm - X_norm(i,:);
    
    % Also compute flipped version (swap force 1 and force 2)
    X_norm_flipped = X_norm(:, [5:8, 1:4]);
    dX_flipped = X_norm_flipped - X_norm(i,:);
    
    num = sqrt(sum(dW.^2, 2));
    den = sqrt(sum(dX.^2, 2));
    den_flipped = sqrt(sum(dX_flipped.^2, 2));
    
    % Use minimum of normal and flipped distances
    den = min(den, den_flipped);
    
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

% To get the mean of the lowest n% values of a MATLAB array
n = 5;              % percentage you want (example: 20%)
k = floor(numel(local_rij) * n/100);     % number of lowest elements to take
mean_R_lowest = mean(mink(local_rij, k));

% Print results
fprintf('\n=== Pairwise Distance Results (Per-Point Minima) ===\n');      % <-- CHANGED
fprintf('Samples: %d\n', N);
fprintf('Mean(per-point min): %.6f\n', mean_R);                          % <-- CHANGED
fprintf('Mean(lowest %.2f percent): %.6f\n', n, mean_R_lowest);                          % <-- CHANGED



% Assessment (based on per-point minima)
if min_R < 1e-6
    fprintf('\n⚠️ WARNING: min per-point min r_ij ≈ 0 → NON-UNIQUE MAPPING\n');
elseif min_R < 1e-3
    fprintf('\n⚠️ CAUTION: min per-point min r_ij is small\n');
else
    fprintf('\n✓ Mapping appears globally injective in sampled region\n');
end

% Find 20 worst pairs with distance threshold (fast version)
fprintf('\n=== 20 Force Pairs with Lowest r_{ij} (distant inputs only) ===\n');
fprintf('Threshold: ΔF>0.05 OR Δs>0.01 OR Δel>3 OR Δaz>3\n');

[R_sorted, idx] = sort(vals, 'ascend');
found = 0;
k = 1;

while found < 20 && k <= length(idx)
    [i, j] = ind2sub_triu(N, idx(k));
    
    found = found + 1;
    fprintf('\n--- Pair %d: Samples %d and %d ---\n', found, i, j);
    fprintf('r_ij = %.6f\n', R_sorted(k));
    fprintf('Force 1: F1=%.3f s1=%.4f el1=%.3f F2=%.3f s2=%.4f el2=%.3f\n', X(i,1), X(i,2), X(i,3), X(i,4), X(i,5), X(i,6));
    fprintf('Force 2: F1=%.3f s1=%.4f el1=%.3f F2=%.3f s2=%.4f el2=%.3f\n', X(j,1), X(j,2), X(j,3), X(j,4), X(j,5), X(j,6));
    fprintf('W1 = [Tx=%.4f, Ty=%.4f, Tz=%.4f, Fx=%.4f, Fy=%.4f, Fz=%.4f]\n', W(i,1), W(i,2), W(i,3), W(i,4), W(i,5), W(i,6));
    fprintf('W2 = [Tx=%.4f, Ty=%.4f, Tz=%.4f, Fx=%.4f, Fy=%.4f, Fz=%.4f]\n', W(j,1), W(j,2), W(j,3), W(j,4), W(j,5), W(j,6));
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

function X = generate_double_force_samples(n_forces)
% Generate force samples using Latin Hypercube Sampling
F_range = [0.3, 0.8];
s_range = [0.04, 0.20];
el_range = [0, 2*pi];
scale = @(u,r) r(1) + u.*diff(r);
rng(1234);
U1 = lhsdesign(n_forces, 4);
U2 = lhsdesign(n_forces, 4);
F1 = scale(U1(:,1), F_range);
F2 = scale(U2(:,1), F_range);
s1 = scale(U1(:,2), s_range);
s2 = scale(U2(:,2), s_range);
el1 = scale(U1(:,3), el_range);
el2 = scale(U2(:,3), el_range);
az1 = pi/2*ones(n_forces, 1);
az2 = pi/2*ones(n_forces, 1);
tau = repmat([0, 0 0], size(F1, 1), 1);
X = [F1 s1 el1 az1 F2 s2 el2 az2 tau];

% Filter forces that are too close:
%X = X(abs(X(:,2) - X(:,6)) >= 0.06, :);
end
