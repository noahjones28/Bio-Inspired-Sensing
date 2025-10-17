function [W_base, J4] = gaussianBaseWrenchJacobian_local(S1, q,  F, center, elev, azim, sigma)
% Map [dF, dCenter, dElev, dAzim] -> d(base wrench) for follower/local forces.

    num_major_link = 2;
    L = S1.VLinks(num_major_link).L;
    % build quadlengths and ds exactly the same way
    [~, quadpoints] = S1.CVRods{num_major_link}.Xs;
    quadlengths = quadpoints' * L;          % if Xs are in [-1,1], map first: (quadpoints+1)/2 * L
    ds = diff(quadlengths); ds = [ds, ds(end)];
    
    % profile and its center derivative at the SAME node positions
    un     = exp(-0.5 * ((quadlengths - center)/sigma).^2);
    dun_dc = un .* ((quadlengths - center)/(sigma^2));
    
    % include ds in both numerator and denominator (matches FD path)
    A      = sum(un .* ds);
    Adc    = sum(dun_dc .* ds);
    w_node = (un .* ds) / A;
    
    % quotient rule with ds (this is what FD differentiates)
    dw_dc_node = ((dun_dc .* ds) * A - (un .* ds) * Adc) / (A^2);


    J_all = S1.Jacobian(q);
    
    uL        = [cos(elev)*cos(azim);  cos(elev)*sin(azim);  sin(elev)];
    duL_delev = [-sin(elev)*cos(azim); -sin(elev)*sin(azim);  cos(elev)];
    duL_dazim = [-cos(elev)*sin(azim);  cos(elev)*cos(azim);  0];
    
    F_loc_dir = [0;0;0; uL];
    F_loc_de  = [0;0;0; duL_delev];
    F_loc_da  = [0;0;0; duL_dazim];
    
    W_base = zeros(6,1); dF=zeros(6,1); dC=zeros(6,1); dE=zeros(6,1); dA=zeros(6,1);
    
    for j = 1:numel(S1.Fp_sig)
        si = S1.Fp_sig(j);
        Jb = J_all((si-1)*6+1 : si*6, 1:6);
    
        W_base = W_base + Jb.' * (F * w_node(j)     * F_loc_dir);
        dF     = dF     + Jb.' * (      w_node(j)   * F_loc_dir);        % ∂/∂F
        dC     = dC     + Jb.' * (F *   dw_dc_node(j) * F_loc_dir);      % ∂/∂center
        dE     = dE     + Jb.' * (F *   w_node(j)   * F_loc_de);         % ∂/∂elev (unchanged)
        dA     = dA     + Jb.' * (F *   w_node(j)   * F_loc_da);         % ∂/∂azim (unchanged)
    end
    
    J4 = [dF, dC, dE, dA];
end
