function noisy_array = add_proportional_noise(input_array, noise_level)
    % ADD_PROPORTIONAL_NOISE Adds random noise proportional to each value's magnitude
    %
    % Syntax: noisy_array = add_proportional_noise(input_array, noise_level)
    %
    % Inputs:
    %   input_array - 1x6 array of numerical values
    %   noise_level - (optional) noise magnitude as decimal (default: 0.1 = 10%)
    %                 For example: 0.05 = 5% noise, 0.2 = 20% noise
    %
    % Output:
    %   noisy_array - 1x6 array with proportional noise added
    %
    % Example:
    %   values = [10, 50, 100, 5, 200, 75];
    %   noisy_values = add_proportional_noise(values, 0.1);  % 10% noise
    
    % Set default noise level if not provided
    if nargin < 2
        noise_level = 0.10;  % Default 10% noise
    end
    
    % Validate input
    if length(input_array) ~= 6
        error('Input must be a 1x6 array');
    end
    
    % Generate random noise proportional to each value
    % Using randn for Gaussian distribution (mean=0, std=1)
    random_factors = randn(1, 6);
    
    % Add proportional noise: each value gets noise = value * noise_level * random_factor
    noisy_array = input_array .* (1 + noise_level * random_factors);
end