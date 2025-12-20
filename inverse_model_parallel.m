function distal_values = inverse_model_parallel(proximal_values)
    %% ABOUT
    % INVERSE_MODEL_PARALLEL Computes distal values from proximal values in parallel
    %   Inputs:
    %   proximal_values - (num_samples x 9) array [Tx, Ty, Tz, Fx, Fy, Fz, tau1, tau2, tau3; ... ]
    %
    %   Outputs:
    %   distal_values - (num_samples x 7) array [F1, s1, theta1, F2, s2,
    %   theta2, f_final]


    %% SETUP
    % Initialize parallel pool if needed
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localluster.Jobs)
        parpool(localCluster)
    end
    
    output_columns = 7; % Number of output columns (7 for two forces)
    num_samples = size(proximal_values, 1); % Number of samples to be estimated 
    futures(1:num_samples) = parallel.FevalFuture; % Pre-allocate futures array
    distal_values = zeros(num_samples, output_columns); % Pre-allocate output matrix


    %% SUBMIT PARALLEL JOBS
    for i = 1:num_samples
        % Extract inputs for this sample
        torque_force = proximal_values{i}(:, 1:6); % [Tx, Ty, Tz, Fx, Fy, Fz]
        tau_values   = proximal_values{i}(:, 7:9); % [tau1, tau2, tau3]
        
        % Submit async job
        n_outputs = 2; % distal_value, resnorm_final
        futures(i) = parfeval(@inverse_model, n_outputs, torque_force, tau_values);
    end

    %% COLLECT RESULTS
    fprintf('Processing %d samples...\n', num_samples);
    
    for i = 1:num_samples
        try
            [result1, result2] = fetchOutputs(futures(i));
            distal_values(i, :) = [result1, result2];
            fprintf('Completed %d/%d\n', i, num_samples);
            
        catch ME
            fprintf('Error processing row %d: %s\n', i, ME.message);
            fprintf('Input values were: %s\n', mat2str(proximal_values{i}));
            rethrow(ME);
        end
    end

end