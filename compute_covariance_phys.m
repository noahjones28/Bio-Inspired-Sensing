function [Cov_phys, Sigmas_phys] = compute_covariance_phys(Jw, param_scales)
    %% ABOUT
    % Calculates physical covariance for a SINGLE Jacobian matrix.
    % Input:
    %   Jw:           The 6x6 (or MxN) whitened Jacobian matrix (double)
    %   param_scales: The vector used to normalize the Jacobian columns
    
    %% COMPUTATION
    % 1. Create Scaling Matrix
    S_param = diag(param_scales);

    % 2. Invert Fisher Info to get Normalized Covariance
    %    (Using pinv for numerical stability)
    Cov_norm = pinv(Jw' * Jw);
    
    % 3. Convert to Physical Units
    Cov_phys = S_param * Cov_norm * S_param;
    
    % 4. Extract Standard Deviations (Sigmas)
    Sigmas_phys = sqrt(diag(Cov_phys));
end