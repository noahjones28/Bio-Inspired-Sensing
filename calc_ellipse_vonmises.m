function [max_vm, fos] = calc_ellipse_vonmises(a, b, Tx, Ty, Tz, yield_strength)
%   Inputs:
%       a, b             - Semi-axes (a in y-direction, b in z-direction)
%       Tx, Ty, Tz       - Internal moments
%       yield_strength   - Material Yield Strength in Pa
%
%   Outputs:
%       max_vm - Maximum Von Mises stress (Pa)
%       fos    - Factor of Safety

    %% 1. Geometric Setup
    Iy = (pi .* a .* b.^3) ./ 4;   % Second moment about y-axis
    Iz = (pi .* a.^3 .* b) ./ 4;   % Second moment about z-axis

    %% 2. Calculate Stresses
    % Maximum bending stress (combines both Ty and Tz)
    sigma_max_bending = sqrt((Ty .* b ./ Iy).^2 + (Tz .* a ./ Iz).^2);
    
    % Maximum torsional shear stress (worst of the two tips)
    tau_max_torsion = max(2.*abs(Tx)./(pi.*a.^2.*b), 2.*abs(Tx)./(pi.*a.*b.^2));
    
    % Von Mises
    max_vm = sqrt(sigma_max_bending.^2 + 3.*tau_max_torsion.^2);

    %% 3. Factor of Safety
    fos = yield_strength ./ max_vm;
end