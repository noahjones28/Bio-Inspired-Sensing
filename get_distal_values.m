function distal_values = get_distal_values(proximal_values, N)
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end

    tau_arrays = proximal_values(:, 7:end); % [tau1, tau2, tau3]
    proximal_values = proximal_values(:, 1:6); % [Tx, Ty, Tz, Fx, Fy, Fz]
    
    
    % Initialize futures array
    num_samples = size(proximal_values, 1);
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all rows
    for index = 1:num_samples
        proximal_value = proximal_values(index, :);  % Pass entire row
        tau_array = tau_arrays(index, :);
        futures(index) = parfeval(@get_distal_value, 2, proximal_value, tau_array);
    end
    
    % Initialize distal_values based on N
    if N == 1
        % Initialize results as num_samples x 4 matrix + f_final
        distal_values = zeros(num_samples, 5);
    elseif N == 2
        % Initialize as num_samples x 8 matrix (2 rows of 4 stacked horizontally)
        distal_values = zeros(num_samples, 9);
    end
    
    % Fetch outputs for all futures
    fprintf('Processing %d samples...\n', num_samples);
    for i = 1:length(futures)
        try
            [result1, result2] = fetchOutputs(futures(i));
            if N == 1
                distal_values(i, :) = [result1, result2]; % Store as row i in matrix
            elseif N == 2
                % result is 2x4, reshape to 1x8 by concatenating rows horizontally
                distal_values(i, :) = [result1(1, :), result1(2, :), result2];
            end
            fprintf('Completed %d/%d\n', i, num_samples);
        catch ME
            fprintf('Error processing row %d: %s\n', i, ME.message);
            fprintf('Input values were: %s\n', mat2str(proximal_values(i, :)));
            rethrow(ME);
        end
    end
end