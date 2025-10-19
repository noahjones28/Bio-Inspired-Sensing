function distal_values = get_distal_values(proximal_values, N, noise_sigma)
    % proximal_values is now Nx1 cell array
    % Each cell contains (1+n)x9 array: [Tx, Ty, Tz, Fx, Fy, Fz, tau1, tau2, tau3]
    
    % Create a parallel pool if one isn't already open
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end
    
    num_samples = length(proximal_values);  % Changed: length instead of size
    
    if nargin < 3   % if noise_sigma not provided
        noise_sigma = zeros(1,6);
    end

    if noise_sigma == zeros(1,6)
        % do nothing
    else
        % Generate Sobol noise once
        noise_samples = generate_sobol_noise(num_samples, noise_sigma);
    end
    
    % Initialize futures array
    futures(1:num_samples) = parallel.FevalFuture;
    
    % Loop through all cells
    for index = 1:num_samples
        data = proximal_values{index};  % Changed: extract from cell
        prox_target = data(:, 1:6);     % Changed: extract prox (1+n)x6
        tau_array = data(:, 7:9);       % Changed: extract tau (1+n)x3
        
        if noise_sigma == zeros(1,6)
            futures(index) = parfeval(@get_distal_value, 2, prox_target, tau_array);
        else
            noise_sample = noise_samples(index, :);
            futures(index) = parfeval(@get_distal_value, 2, prox_target, tau_array, noise_sample);
        end
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
            fprintf('Input values were: %s\n', mat2str(proximal_values{i}));  % Changed: cell indexing
            rethrow(ME);
        end
    end
end