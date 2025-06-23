function proximal_values = get_proximal_values(distal_values, num_proximal)
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end
    
    % Defualt argument
    if nargin < 2
        num_proximal = 4; % (4 becuase Mz,Fx,Fy,tau)
    end
    
    % Initialize futures array
    num_samples = size(distal_values, 1);
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all rows
    for index = 1:num_samples
        distal_value = distal_values(index, :);  % Pass entire row
        futures(index) = parfeval(@get_proximal_value, 1, distal_value);
    end
    
    % Initialize results as 100x4 matrix
    proximal_values = zeros(num_samples, num_proximal);
    
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