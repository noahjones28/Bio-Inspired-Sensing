function noisy_array = add_noise(input_array, noise_level, noise_type, seed)
% ADD_NOISE Adds random noise to array values
%
% Syntax: noisy_array = add_noise(input_array, noise_level, noise_type, seed)
%
% Inputs:
%   input_array - 1x6 array of numerical values
%   noise_level - (optional) noise magnitude (default: 0.1)
%                 For proportional: scalar decimal (0.1 = 10%) or 1x6 array
%                 For additive: scalar or 1x6 array of std deviations per component
%   noise_type  - (optional) 'proportional' or 'additive' (default: 'proportional')
%   seed        - (optional) random seed for reproducibility (default: 42)
%
% Output:
%   noisy_array - 1x6 array with noise added
%
% Examples:
%   values = [10, 50, 100, 5, 200, 75];
%   
%   % Proportional noise (10% of each value)
%   noisy_prop = add_noise(values, 0.1, 'proportional', 42);
%   
%   % Additive noise with different levels per component
%   % E.g., [Fx, Fy, Fz, Tx, Ty, Tz] with forces in N, torques in N·m
%   noise_std = [0.5, 0.5, 0.5, 0.02, 0.02, 0.02]; % Different noise for F vs T
%   noisy_add = add_noise(values, noise_std, 'additive', 42);

    % Set default noise level if not provided
    if nargin < 2
        noise_level = 0.20;
    end
    
    % Set default noise type if not provided
    if nargin < 3
        noise_type = 'proportional';
    end
    
    % Set default seed if not provided
    if nargin < 4
        seed = 42;
    end
    
    % Validate input array
    if length(input_array) ~= 6
        error('Input must be a 1x6 array');
    end
    
    % Validate and expand noise_level
    if isscalar(noise_level)
        % If scalar, apply same noise level to all components
        noise_level = repmat(noise_level, 1, 6);
    elseif length(noise_level) == 6
        % If 1x6 array, use as-is
        noise_level = reshape(noise_level, 1, 6); % Ensure row vector
    else
        error('noise_level must be a scalar or 1x6 array');
    end
    
    % Validate noise type
    noise_type = lower(noise_type);
    if ~ismember(noise_type, {'proportional', 'additive'})
        error('noise_type must be either ''proportional'' or ''additive''');
    end
    
    % Set random seed for reproducibility
    rng(seed);
    
    % Generate random noise using Gaussian distribution (mean=0, std=1)
    random_factors = randn(1, 6);
    
    % Apply noise based on type
    if strcmp(noise_type, 'proportional')
        % Proportional noise: noise scales with signal magnitude
        noisy_array = input_array .* (1 + noise_level .* random_factors);
    else % additive
        % Additive noise: constant noise level per component
        noisy_array = input_array + noise_level .* random_factors;
    end
end