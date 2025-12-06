function distal_values = get_distal_values(proximal_values)
    % Each cell contains nx9 array: [Tx, Ty, Tz, Fx, Fy, Fz, tau1, tau2, tau3]
% Create a parallel pool if one isn't already open
if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        localCluster.NumThreads = 1;
        parpool(localCluster)
end
% get number of samples
    num_samples = size(proximal_values,1);
% Initialize futures array
    futures(1:num_samples) = parallel.FevalFuture;
% Loop through all cells
for i = 1:num_samples
        prox_target = proximal_values{i}(:, 1:6);
        tau_array = proximal_values{i}(:, 7:9);
        futures(i) = parfeval(@get_distal_value, 2, prox_target, tau_array);
end
% Initialize distal_values
    distal_values = zeros(num_samples, 7); % distal_values [F,s,theta] + f_final
% Fetch outputs for all futures
    fprintf('Processing %d samples...\n', num_samples);
for i = 1:length(futures)
try
            [result1, result2] = fetchOutputs(futures(i));
            distal_values(i, :) = [result1, result2]; % Store as row i in matrix
            fprintf('Completed %d/%d\n', i, num_samples);
catch ME
            fprintf('Error processing row %d: %s\n', i, ME.message);
            fprintf('Input values were: %s\n', mat2str(proximal_values{i}));
            rethrow(ME);
end
end
end