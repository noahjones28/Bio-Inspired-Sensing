function proximal_values = forward_model_parallel(distal_values, S)
    % FORWARD_MODEL_PARALLEL Computes proximal values in parallel
    %   Accepts distal_values as:
    %     - Nx6 matrix: [F, s, theta, tau1, tau2, tau3]
    %     - Nx9 matrix: [F1, s1, theta1, F2, s2, theta2, tau1, tau2, tau3]
    
    % Initialize parallel pool if needed
    if isempty(gcp('nocreate'))
        localCluster = parcluster('Noah12');
        delete(localCluster.Jobs)
        parpool(localCluster)
    end
    
    numRows = size(distal_values, 1);
    numCols = size(distal_values, 2);
    
    % Parse input: separate distal values from tau values
    if numCols == 6
        tau_arrays = distal_values(:, 4:6);         % Nx3 tau values
        distal_values = distal_values(:, 1:3);      % Nx3 distal params
    else  % numCols == 9
        tau_arrays = distal_values(:, 7:9);         % Nx3 tau values
        distal_values = reshape(distal_values(:, 1:6)', 3, 2, []);  % 3x2xN
        distal_values = permute(distal_values, [3 2 1]);            % Nx2x3
    end
    
    % Submit parallel jobs
    futures(1:numRows) = parallel.FevalFuture;
    for i = 1:numRows
        % Extract row: 1x3 for 6-col input, 2x3 for 9-col input
        dv = squeeze(distal_values(i, :, :));
        tau = tau_arrays(i, :);
        
        if nargin < 2 % If SoRoSim linkage S not provided
            futures(i) = parfeval(@forward_model, 1, dv, tau);
        else % If SoRoSim linkage S provided
            futures(i) = parfeval(@forward_model, 1, dv, tau, false, false, S);
        end
    end
    
    % Collect results
    proximal_values = zeros(numRows, 6);
    for i = 1:numRows
        try
            proximal_values(i, :) = fetchOutputs(futures(i));
        catch ME
            fprintf('Error row %d: %s\nInput: %s\n', i, ME.message, mat2str(dv));
            rethrow(ME);
        end
    end
end