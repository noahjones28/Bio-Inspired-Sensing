function J = jacobian_central_fd(f, x0, h)
% JACOBIAN_CENTRAL_FD  Central-difference Jacobian for y=f(x).
%   J = jacobian_central_fd(f, x0)        % auto step sizes
%   J = jacobian_central_fd(f, x0, h)     % custom step(s)
%
% Inputs
%   f  : function handle, f(x) -> 6x1 vector  (x is 4x1: [F;s;el;az])
%   x0 : 4x1 evaluation point
%   h  : (optional) either scalar step or 4x1 per-variable steps
%
% Output
%   J  : 6x4 central-difference Jacobian at x0
  
    % Evaluate once at x0
    y0 = f(x0);
    if ~isvector(x0) || numel(x0) ~= 4
        error('x0 must be a 4x1 vector [F; s; el; az].');
    end
    x0 = x0(:);
    m = numel(y0);    % should be 6
    n = numel(x0);    % 4
    J = zeros(m, n);
    sigma = 0.01;

    % Default step sizes if not provided
    if nargin < 3 || isempty(h)
        % scale-aware defaults (angles assumed in radians)
        h = [max(1e-6, 1e-6*abs(x0(1)));   % F
             sigma/10000;  % s - much smaller step!
             1e-6;                         % el
             1e-6];                        % az
    elseif isscalar(h)
        h = repmat(h, n, 1);
    else
        h = h(:);
        if numel(h) ~= n, error('h must be scalar or a 4x1 vector.'); end
    end

    % Central differences column-by-column
    for k = 1:n
        ek = zeros(n,1); ek(k) = 1;
        yph = f(x0 + h(k)*ek);
        ymh = f(x0 - h(k)*ek);
        J(:,k) = (yph - ymh) / (2*h(k));
    end
end
