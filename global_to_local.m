function output = global_to_local(M, idxs, input)
% GLOBAL_TO_LOCAL Transforms points or point-functions to local link frames
%   Inputs:
%       M     - (4N)x4 stacked transformation matrices
%       idxs  - 1xK vector of link indices
%       input - EITHER:
%               • 3xK matrix of points [x;y;z] in global frame
%               • 1xK cell array of function handles @(X)->[x;y;z]
%   Output:
%       output - Same type as input, transformed to local frames

    K = length(idxs);
    
    % Validate
    if iscell(input)
        if length(input) ~= K
            error('Number of functions must match length of idxs.');
        end
    else
        if size(input, 2) ~= K
            error('Number of columns must match length of idxs.');
        end
    end
    
    % Pre-compute rotations
    num_links = size(M, 1) / 4;
    R_all = precompute_rotations(M, num_links);
    
    % Handle based on input type
    if iscell(input)
        % Function handles
        output = cell(1, K);
        for k = 1:K
            R = R_all{idxs(k)};
            f = input{k};
            output{k} = @(X) R' * f(X);
        end
    else
        % Numeric array
        output = zeros(3, K);
        for k = 1:K
            R = R_all{idxs(k)};
            output(:, k) = R' * input(:, k);
        end
    end
end

function R_all = precompute_rotations(M, num_links)
    R_all = cell(num_links, 1);
    R_cumulative = eye(3);
    for k = 1:num_links
        row_start = (k-1)*4 + 1;
        R_k = M(row_start:row_start+2, 1:3);
        R_cumulative = R_cumulative * R_k;
        R_all{k} = R_cumulative;
    end
end