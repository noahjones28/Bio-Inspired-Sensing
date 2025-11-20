function [mean_R, local_rij] = pairwise_distance_scan_3(force_samples, S)
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

channel_filter = [0 0 1 1 0 0]; % Just use Tz and Fx for now

% Extract force samples
X = force_samples;
% Compute forward model
fprintf('Computing forward model...\n');
% Compute wrench
if nargin < 2
    W = get_proximal_values(X);
else
    W = get_proximal_values(X,S);
end
W = channel_filter .* W;
% Remove tau and theta from force samples
X = X(:,1:2);

% Compute column-wise std
X_std = std(X, 0, 1);
% Create a mask for non-zero std columns
mask = X_std ~= 0;
% Normalize only non-zero-std columns
X_norm = X;
X_norm(:,mask) = X(:,mask) ./ X_std(mask);

% Compute column-wise std
W_std = std(W, 0, 1);
% Create a mask for non-zero std columns
mask = W_std ~= 0;
% Normalize only non-zero-std columns
W_norm = W;
W_norm(:,mask) = W(:,mask) ./ W_std(mask);

% Compute pairwise distances
fprintf('Computing pairwise distances...\n');
N = size(W_norm, 1);
R = zeros(N);
for i = 1:N
    dW = W_norm - W_norm(i,:);
    dX = X_norm - X_norm(i,:);
    % Euclidean (L2) norm
    num = sqrt(sum(dW.^2, 2));
    den = sqrt(sum(dX.^2, 2));
    R(i,:) = (num ./ den).';
    R(i,i) = NaN;
end

% === Per-point minima (core injectivity signal) ===
local_rij = min(R, [], 2, 'omitnan');                                  % <-- CHANGED
                                                
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

