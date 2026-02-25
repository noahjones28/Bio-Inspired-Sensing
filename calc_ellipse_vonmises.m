function [max_vm, fos] = calc_ellipse_vonmises(r_major, r_minor, Tx, Ty, Tz, yield_strength)
%   Inputs:
%       r_major, r_minor - Axis lengths (scalars or arrays)
%       Tx, Ty, Tz       - Moments (scalars or arrays)
%       yield_strength   - Material Yield Strength in Pa (e.g., 31e6 for PLA Z-axis)
%
%   Outputs:
%       max_vm - Array of maximum Von Mises stresses (Pa)
%       fos    - Array of Factor of Safety values

    %% 1. Geometric Setup
    a = r_major; 
    b = r_minor;

    % Area Moments of Inertia (Updated to element-wise operations)
    Iy = (pi .* b .* a.^3) ./ 4;   
    Iz = (pi .* a .* b.^3) ./ 4;

    %% 2. Calculate Stresses at Critical Points
    
    % --- Point A: Tip of the Major Axis (z = a, y = 0)
    sigma_bending_A = abs(Ty .* a) ./ Iy;
    tau_torsion_A   = (2 .* abs(Tx)) ./ (pi .* a.^2 .* b); 
    vm_A = sqrt(sigma_bending_A.^2 + 3 .* tau_torsion_A.^2);

    % --- Point B: Tip of the Minor Axis (z = 0, y = b) ---
    sigma_bending_B = abs(Tz .* b) ./ Iz;
    tau_torsion_B   = (2 .* abs(Tx)) ./ (pi .* a .* b.^2);
    vm_B = sqrt(sigma_bending_B.^2 + 3 .* tau_torsion_B.^2);

    %% 3. Determine Maximum & Factor of Safety
    % max() compares arrays element-wise
    max_vm = max(vm_A, vm_B);
    
    % Calculate Factor of Safety
    fos = yield_strength ./ max_vm;
end