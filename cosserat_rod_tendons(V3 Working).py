import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
from scipy.optimize import fsolve
from optimization import MyOptimization

class CoupledCosseratRod:
    """
    A 2D planar Cosserat rod model with tendon actuation based on the 
    "Simplified No-Shear Model" (Equation 17) from Rucker & Webster (2011).
    
    Implements the full Cosserat model with proper force/moment equilibrium.
    """
    
    def __init__(self, r_array, youngs_modulus, segment_length=0.01, 
                 tendon_offset=None):
        """
        Initialize the 2D Cosserat rod model.
        """
        self.r_array = np.array(r_array)
        self.n_segments = len(r_array)
        self.n_nodes = self.n_segments + 1
        self.E = youngs_modulus
        self.segment_length = segment_length
        self.total_length = self.n_segments * segment_length
        
        # Tendon configuration (2 tendons, straight axial routing)
        if tendon_offset is None:
            self.tendon_offset = 0.8 * np.mean(r_array)
        else:
            self.tendon_offset = tendon_offset
            
        # Arc length array
        self.s_array = np.linspace(0, self.total_length, self.n_nodes)
        
        print(f"Rod setup: {self.n_segments} segments, total length = {self.total_length:.3f} m")
        print(f"Tendon offset: {self.tendon_offset:.4f} m")
        
    def _get_segment_properties(self, s_idx):
        """Get material properties for segment at index s_idx."""
        idx = max(0, min(s_idx, self.n_segments - 1))
        r = self.r_array[idx]
        
        # Cross-sectional properties
        A = np.pi * r**2
        I = np.pi * r**4 / 4  # Second moment of area for circular cross-section
        
        # Bending stiffness
        EI = self.E * I
        
        return A, I, EI
    
    def _ode_system(self, s, y, tau1, tau2, F_ext, s_force):
        """
        ODE system based on Equation 17 for 2D no-shear model.
        
        State vector y = [px, py, theta, nx, ny, M]
        where:
        - px, py: position coordinates
        - theta: orientation angle
        - nx, ny: internal forces
        - M: internal bending moment
        """
        px, py, theta, nx, ny, M = y
        
        # Get segment properties
        s_idx = int(s / self.segment_length)
        s_idx = max(0, min(s_idx, self.n_segments - 1))
        A, I, EI = self._get_segment_properties(s_idx)
        
        # Current rotation matrix (2D)
        cos_theta = np.cos(theta)
        sin_theta = np.sin(theta)
        R = np.array([[cos_theta, -sin_theta],
                      [sin_theta,  cos_theta]])
        
        # No-shear kinematic equations: p' = R * v* where v* = [1, 0]
        v_star = np.array([1, 0])  # Tangent along rod in local frame
        p_dot = R @ v_star
        px_dot = p_dot[0]
        py_dot = p_dot[1]
        
        # Curvature from moment-curvature relation: kappa = M / EI
        if EI > 0:
            kappa = M / EI
        else:
            kappa = 0
        
        # Angular velocity: theta' = kappa
        theta_dot = kappa
        
        # External forces per unit length
        fx_ext = 0.0
        fy_ext = 0.0
        m_ext = 0.0
        
        # Point force application (perpendicular to current rod segment)
        if abs(s - s_force) < self.segment_length / 2 and F_ext != 0:
            # Force perpendicular to current rod direction
            # Current rod tangent: [cos(theta), sin(theta)]
            # Perpendicular direction: [sin(theta), -cos(theta)] (90° CW rotation)
            force_direction = np.array([sin_theta, -cos_theta])
            
            # Apply force as distributed load over small region
            force_intensity = F_ext / self.segment_length
            force_vector = force_intensity * force_direction
            fx_ext += force_vector[0]
            fy_ext += force_vector[1]
        
        # Tendon forces and moments
        ft_x = 0.0
        ft_y = 0.0
        mt_tendon = 0.0
        
        if tau1 > 0 or tau2 > 0:
            # For straight axial tendons, primary effect is moment
            # Differential tension creates bending moment
            mt_tendon = (tau1 - tau2) * self.tendon_offset / self.segment_length
            
            # Tendon tensions create distributed axial COMPRESSION in the rod
            # (tendons pull, so rod is compressed)
            total_tension = tau1 + tau2
            if total_tension > 0:
                # Axial compression distributed along rod (negative for compression)
                compression_per_length = total_tension / self.total_length
                # Components depend on current rod orientation
                ft_x -= compression_per_length * cos_theta  # Negative = compression
                ft_y -= compression_per_length * sin_theta
        
        # Force equilibrium: n' + f = 0
        # Therefore: n' = -f
        fx_total = fx_ext + ft_x
        fy_total = fy_ext + ft_y
        
        nx_dot = -fx_total
        ny_dot = -fy_total
        
        # Moment equilibrium: M' - p' × n + m_ext = 0 (flipped sign for cross product)
        # p' × n = [px_dot, py_dot] × [nx, ny] = px_dot * ny - py_dot * nx
        cross_product_z = py_dot * nx - px_dot * ny
        
        M_dot = cross_product_z - m_ext - mt_tendon
        
        return [px_dot, py_dot, theta_dot, nx_dot, ny_dot, M_dot]
    
    def _solve_boundary_value_problem(self, tau1, tau2, F_ext, s_force):
        """
        Solve the boundary value problem using shooting method.
        Handles point load as boundary condition discontinuity.
        """
        def shooting_residual(initial_guess):
            """Residual function for shooting method."""
            # Initial conditions at base (s=0): clamped
            px0, py0 = 0.0, 0.0  # Fixed position
            theta0 = 0.0         # Fixed orientation (horizontal)
            
            # Unknown initial values (to be determined by shooting)
            nx0 = initial_guess[0]  # Initial internal force x
            ny0 = initial_guess[1]  # Initial internal force y  
            M0 = initial_guess[2]   # Initial moment
            
            y0_vec = [px0, py0, theta0, nx0, ny0, M0]
            
            # Check if force is applied before the end
            force_applied = F_ext != 0 and s_force < self.total_length
            
            if force_applied:
                # Integrate to force application point
                s_eval_1 = np.linspace(0, s_force, max(2, int(s_force / self.segment_length) + 1))
                
                try:
                    sol_1 = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),  # No force yet
                        [0, s_force], y0_vec,
                        t_eval=s_eval_1,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol_1.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    # State just before force application
                    y_before = sol_1.y[:, -1]
                    
                    # Apply boundary condition: discontinuity in forces due to point load
                    # Force is perpendicular to rod at this point
                    theta_at_force = y_before[2]
                    cos_theta = np.cos(theta_at_force)
                    sin_theta = np.sin(theta_at_force)
                    
                    # Force direction: perpendicular to rod (upward relative to rod)
                    force_direction = np.array([sin_theta, -cos_theta])
                    force_jump = F_ext * force_direction
                    
                    # Apply discontinuity: n_after = n_before + F_jump
                    y_after = y_before.copy()
                    y_after[3] += force_jump[0]  # nx jump
                    y_after[4] += force_jump[1]  # ny jump
                    # No moment jump for point force (only for point moment)
                    
                    # Integrate from force point to end
                    s_eval_2 = np.linspace(s_force, self.total_length, 
                                         max(2, int((self.total_length - s_force) / self.segment_length) + 1))
                    
                    sol_2 = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),  # Force already applied
                        [s_force, self.total_length], y_after,
                        t_eval=s_eval_2,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol_2.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    # Combine solutions
                    s_combined = np.concatenate([s_eval_1[:-1], s_eval_2])
                    y_combined = np.concatenate([sol_1.y[:, :-1], sol_2.y], axis=1)
                    
                    # Check boundary conditions at tip
                    M_tip = y_combined[5, -1]  # Moment at tip should be zero
                    
                    # For free end, also check force consistency
                    nx_tip = y_combined[3, -1]
                    ny_tip = y_combined[4, -1]
                    
                    residual = np.array([M_tip, nx_tip, ny_tip])
                    
                except Exception as e:
                    return np.array([1e6, 1e6, 1e6])
            
            else:
                # No point force - integrate entire length
                try:
                    sol = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, F_ext, s_force),
                        [0, self.total_length], y0_vec,
                        t_eval=self.s_array,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    # Boundary conditions at tip
                    M_tip = sol.y[5, -1]  # Free moment
                    nx_tip = sol.y[3, -1]  # Should be related to tendon tensions
                    ny_tip = sol.y[4, -1]  # Should be zero for no transverse load
                    
                    residual = np.array([M_tip, nx_tip, ny_tip])
                    
                except Exception as e:
                    return np.array([1e6, 1e6, 1e6])
            
            return residual
        
        # Initial guess for shooting method
        initial_guess = np.array([1.0, 0.1, 0.01])  # [nx0, ny0, M0]
        
        try:
            solution = fsolve(shooting_residual, initial_guess, xtol=1e-8)
            
            # Final integration with converged initial conditions
            nx0, ny0, M0 = solution
            y0_vec = [0.0, 0.0, 0.0, nx0, ny0, M0]
            
            # Handle point force if present
            force_applied = F_ext != 0 and s_force < self.total_length
            
            if force_applied:
                # Two-part integration with discontinuity
                sol_1 = solve_ivp(
                    lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),
                    [0, s_force], y0_vec,
                    t_eval=np.linspace(0, s_force, max(2, int(s_force / self.segment_length) + 1)),
                    method='RK45', rtol=1e-8, atol=1e-10
                )
                
                # Apply force discontinuity
                y_after = sol_1.y[:, -1].copy()
                theta_at_force = y_after[2]
                force_direction = np.array([np.sin(theta_at_force), -np.cos(theta_at_force)])
                force_jump = F_ext * force_direction
                y_after[3] += force_jump[0]
                y_after[4] += force_jump[1]
                
                sol_2 = solve_ivp(
                    lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),
                    [s_force, self.total_length], y_after,
                    t_eval=np.linspace(s_force, self.total_length, 
                                     max(2, int((self.total_length - s_force) / self.segment_length) + 1)),
                    method='RK45', rtol=1e-8, atol=1e-10
                )
                
                # Combine solutions and interpolate to standard grid
                s_combined = np.concatenate([sol_1.t[:-1], sol_2.t])
                y_combined = np.concatenate([sol_1.y[:, :-1], sol_2.y], axis=1)
                
                # Interpolate to regular grid
                sol_interp = np.zeros((6, len(self.s_array)))
                for i in range(6):
                    sol_interp[i] = np.interp(self.s_array, s_combined, y_combined[i])
                
                # Create mock solution object
                class MockSol:
                    def __init__(self, y):
                        self.y = y
                        self.success = True
                
                return MockSol(sol_interp), nx0, ny0, M0
            
            else:
                # Single integration
                sol = solve_ivp(
                    lambda s, y: self._ode_system(s, y, tau1, tau2, F_ext, s_force),
                    [0, self.total_length], y0_vec,
                    t_eval=self.s_array,
                    method='RK45', rtol=1e-8, atol=1e-10
                )
                
                return sol, nx0, ny0, M0
            
        except Exception as e:
            print(f"Boundary value problem failed: {e}")
            return None, None, None, None
    
    def calculate_proximal_values(self, F, s, tau1, tau2):
        """
        Calculate axial force and bending moment at the base.
        """
        sol, nx0, ny0, M0 = self._solve_boundary_value_problem(tau1, tau2, F, s)
        
        if sol is None:
            return 0.0, 0.0
        
        # Base reactions
        # Fx: axial component (along initial rod direction = x-axis)
        Fx = nx0  # Internal force in x-direction at base
        
        # MB: bending moment magnitude
        MB = abs(M0)  # Initial moment magnitude
        
        return Fx, MB
    
    def calculate_distal_values(self, axial_force, bending_moment_mag, tau, optimizer):
        x0 = np.array([0.25, self.total_length/2])
        xu = np.array([0.5, self.total_length])
        xl = np.array([0.1, 0.05])
        F, s = optimizer.solve(axial_force=axial_force, bending_moment_mag=bending_moment_mag, tau=tau,
                               x0=x0, xl=xl, xu=xu, bending_model=self)
        return F, s

    
    def calculate_deflection(self, F, s, tau1, tau2, show_plot=False):
        """
        Calculate the deflected shape of the rod.
        """
        # Solve for different loading conditions
        
        # 1. Original unloaded shape
        sol_original, _, _, _ = self._solve_boundary_value_problem(0, 0, 0, s)
        
        # 2. Shape with tendon actuation only
        sol_tendon, _, _, _ = self._solve_boundary_value_problem(tau1, tau2, 0, s)
        
        # 3. Final shape with both tendon and external force
        sol_final, _, _, _ = self._solve_boundary_value_problem(tau1, tau2, F, s)
        
        if show_plot:
            fig, ax = plt.subplots(1, 1, figsize=(12, 8))
            
            # Plot shapes
            if sol_original is not None and sol_original.success:
                ax.plot(sol_original.y[0], sol_original.y[1], 'k--', 
                       linewidth=2, label='Original (unloaded)', alpha=0.7)
            
            if sol_tendon is not None and sol_tendon.success:
                ax.plot(sol_tendon.y[0], sol_tendon.y[1], 'b-', 
                       linewidth=2, label='Tendon actuation only')
            
            if sol_final is not None and sol_final.success:
                ax.plot(sol_final.y[0], sol_final.y[1], 'r-', 
                       linewidth=3, label='Final shape')
                
                # Mark force application point and draw force arrow
                s_idx = int(s / self.segment_length)
                if s_idx < len(sol_final.y[0]) and F != 0:
                    force_x = sol_final.y[0][s_idx]
                    force_y = sol_final.y[1][s_idx]
                    force_theta = sol_final.y[2][s_idx]
                    
                    ax.plot(force_x, force_y, 'ko', markersize=3, 
                           label=f'Force application (s={s:.3f}m)')
                    
                    # Draw force arrow perpendicular to rod segment
                    arrow_length = 0.1*F
                    arrow_head_length = 0.003
                    dx = -np.sin(force_theta)
                    dy = np.cos(force_theta)
                    force_direction = np.array([dx, dy])
                    arrow_end = arrow_length * force_direction
                    arrow_start_x = force_x-(arrow_end[0]+np.sign(F)*arrow_head_length*dx)
                    arrow_start_y = force_y-(arrow_end[1]+np.sign(F)*arrow_head_length*dy)
                    ax.arrow(arrow_start_x, arrow_start_y, arrow_end[0], arrow_end[1],
                            head_width=0.003, head_length=arrow_head_length,
                            fc='green', ec='green', width=0.0005)
            
            # Calculate values for display
            Fx, MB = self.calculate_proximal_values(F, s, tau1, tau2)
            
            # Info box
            info_text = f'F = {F:.2f} N\ns = {s:.3f} m\nτ1 = {tau1:.2f} N\nτ2 = {tau2:.2f} N\nFx = {Fx:.2f} N\nMB = {MB:.4f} N⋅m'
            ax.text(0.02, 0.98, info_text, transform=ax.transAxes, 
                   bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.8),
                   verticalalignment='top', fontsize=10, family='monospace')
            
            ax.set_xlabel('x (m)')
            ax.set_ylabel('y (m)')
            ax.set_title('2D Cosserat Rod Deformation (Equation 17 Implementation)')
            ax.legend()
            ax.grid(True, alpha=0.3)
            ax.axis('equal')
            plt.tight_layout()
            plt.show()
        
        # Return final deformed shape
        if sol_final is not None and sol_final.success:
            return sol_final.y[0], sol_final.y[1]
        else:
            # Return straight rod if solution failed
            x_straight = self.s_array.copy()
            y_straight = np.zeros_like(x_straight)
            return x_straight, y_straight


# Example usage
if __name__ == "__main__":
    # Create a rod with PLA material properties
    r_array = np.full(20, 1.125*1e-3)
    youngs_modulus = 2.12e9  # PLA (Pa)
    
    rod = CoupledCosseratRod(r_array, youngs_modulus, segment_length=0.01, tendon_offset=8e-3)
    opt = MyOptimization()
    
    # Test different force application points
    print("=== Lever Arm Test ===")
    F = 0.0
    s = 0.2
    tau1, tau2 = 0.001, 0.0
    
    # Calculate base reactions
    Fx, MB = rod.calculate_proximal_values(F, s, tau1, tau2)
    print(f"Base axial force: {Fx:.4f} N")
    print(f"Base bending moment: {MB:.6f} N⋅m")
    
    # Calculate and plot deflection
    x_def, y_def = rod.calculate_deflection(F, s, tau1, tau2, show_plot=True)

    # Calculate distal values
    #F, s = rod.calculate_distal_values(Fx, MB, tau1, opt)
    #print(f"F: {F:.4f} N")
    #print(f"s: {s:.6f} m")