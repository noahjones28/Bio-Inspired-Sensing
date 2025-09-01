function distal_values = get_distal_values(proximal_values, num_distal)
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end

    % Defualt argument
    if nargin < 2
        num_distal = 5; % 5 becuase[F, s, el, az, tau]
    end
    
    % Initialize futures array
    num_samples = size(proximal_values, 1);
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all rows
    for index = 1:num_samples
        proximal_value = proximal_values(index, :);  % Pass entire row
        futures(index) = parfeval(@get_distal_value, 1, proximal_value);
    end
    
    % Initialize results as num_samplesx4 matrix
    distal_values = zeros(num_samples, num_distal);
    
    % Fetch outputs for all futures
    fprintf('Processing %d samples...\n', num_samples);
    for i = 1:length(futures)
        try
            result = fetchOutputs(futures(i)); % This is 1x5
            distal_values(i, :) = result; % <-- Store as row i
            fprintf('Completed %d/%d\n', i, num_samples);
        catch ME
            fprintf('Error processing row %d: %s\n', i, ME.message);
            fprintf('Input values were: %s\n', mat2str(proximal_values(i, :)));
            rethrow(ME);
        end
    end
end