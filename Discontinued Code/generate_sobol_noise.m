function noise_samples = generate_sobol_noise(n_samples, noise_sigma)
% GENERATE_SOBOL_NOISE Generate Sobol-sequence based Gaussian noise
%
% Syntax: noise_samples = generate_sobol_noise(n_samples, noise_sigma)
%
% Inputs:
%   n_samples   - Number of noise samples to generate
%   noise_sigma - 1x6 array of noise std deviations [Tx,Ty,Tz,Fx,Fy,Fz]
%
% Output:
%   noise_samples - n_samples x 6 array of Gaussian noise values
%
% Example:
%   noise_sigma = [0.005, 0.01, 0.01, 0.1, 0.1, 0.1];
%   noise = generate_sobol_noise(150, noise_sigma);

    % Generate Sobol sequence in [0,1]^6
    sob = sobolset(6, 'Skip', 1000);
    unit_samples = net(sob, n_samples);
    
    % Convert uniform [0,1] to Gaussian N(0,1)
    noise_samples = norminv(unit_samples);
    
    % Scale by noise_sigma
    noise_samples = noise_samples .* noise_sigma;
end