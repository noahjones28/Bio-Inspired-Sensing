function proximal_values = get_proximal_values(distal_values)
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end
    
    tau_arrays = distal_values(:, 5:end); % [tau1, tau2, tau3]
    distal_values = distal_values(:, 1:4); % [F, s, el, az]
    
    % Initialize futures array
    num_samples = size(distal_values, 1);
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all rows
    for index = 1:num_samples
        distal_value = distal_values(index, :);  % Pass entire row
        tau_array = tau_arrays(index, :);
        futures(index) = parfeval(@get_proximal_value, 1, distal_value, tau_array);
    end
    
    % Initialize results as matrix
    proximal_values = zeros(num_samples, 6);
    
    % Fetch outputs for all futures
    for i = 1:length(futures)
        try
            result = fetchOutputs(futures(i));  % This is 1x3
            proximal_values(i, :) = result;  % <-- Store as row i
        catch ME
            fprintf('Error processing row %d: %s\n', i, ME.message);
            fprintf('Input values were: %s\n', mat2str(distal_values(i, :)));
            rethrow(ME);
        end
    end
end