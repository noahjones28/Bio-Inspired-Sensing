function proximal_values = get_proximal_values(distal_values, S)
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end
   
    % Get number of rows
    numRows = size(distal_values, 1);

    % Preallocate cell array
    distal_values_cell = cell(numRows, 1);
    
    % Loop through each row of the array
    if size(distal_values,2) == 6 % [F, s, theta, tau1, tau2, tau3]
        for i = 1:numRows
            distal_values_cell{i} = distal_values(i, 1:3);
            tau_arrays = distal_values(:, 4:end); 
        end
    elseif size(distal_values,2) == 9
        for i = 1:numRows
            distal_values_cell{i} = [distal_values(i, 1:3); distal_values(i, 4:6)];
            tau_arrays = distal_values(:, 7:end); 
        end
    end
    
    % Initialize futures array
    num_samples = numel(distal_values_cell);
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all rows
    for index = 1:num_samples
        distal_value = distal_values_cell{index};  % Pass entire row
        tau_array = tau_arrays(index, :);
        if nargin < 2 
            futures(index) = parfeval(@get_proximal_value, 1, distal_value, tau_array);
        else
            futures(index) = parfeval(@get_proximal_value, 1, distal_value, tau_array, false, false, S);
        end
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