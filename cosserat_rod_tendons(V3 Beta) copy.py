import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
from scipy.optimize import fsolve
from optimization import MyOptimization

class CoupledCosseratRod:
    """
    A 2D planar Cosserat rod model with tendon actuation based on the 
    full coupled model (Equations 13-16) from Rucker & Webster (2011).
    
    Implements the full Cosserat model with configuration-dependent
    tendon forces and moments.
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
        
        # Define tendon positions in body frame (constant for straight tendons)
        # Tendon 1 at +y offset, Tendon 2 at -y offset
        self.r1 = np.array([0, self.tendon_offset, 0])  # 3D vector (z=0 for planar)
        self.r2 = np.array([0, -self.tendon_offset, 0])
        
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
    
    def _skew(self, v):
        """Convert 3D vector to skew-symmetric matrix (cross product matrix)."""
        if len(v) == 2:
            # For 2D, extend to 3D with z=0
            v = np.array([v[0], v[1], 0])
        return np.array([[0, -v[2], v[1]],
                        [v[2], 0, -v[0]],
                        [-v[1], v[0], 0]])
    
    def _compute_tendon_loads(self, theta, kappa, tau1, tau2):
        """
        Compute distributed tendon forces and moments using full Rucker & Webster model
        with Ai = -τi * (skew(ṗi)^2) / ||ṗi||³
        
        Assumes straight tendons (r̈i = 0), and neglects v̇ and u̇ (quasi-static).
        """
        # Rotation matrix R: body to world
        cos_theta = np.cos(theta)
        sin_theta = np.sin(theta)
        R = np.array([[cos_theta, -sin_theta, 0],
                    [sin_theta,  cos_theta, 0],
                    [0,          0,         1]])

        # Velocity and curvature in body frame
        v = np.array([1.0, 0.0, 0.0])  # no shear
        u = np.array([0.0, 0.0, kappa])  # rotation about z

        # Pre-allocate accumulators
        a_total = np.zeros(3)
        b_total = np.zeros(3)
        A_total = np.zeros((3, 3))
        B_total = np.zeros((3, 3))
        G_total = np.zeros((3, 3))
        H_total = np.zeros((3, 3))

        # Loop over both tendons
        for tau_i, r_i in zip([tau1, tau2], [self.r1, self.r2]):
            # ṗi = u × ri + v
            u_cross = self._skew(u)
            p_dot_i = u_cross @ r_i + v

            norm_p_dot = np.linalg.norm(p_dot_i)
            if norm_p_dot < 1e-8:
                continue  # skip if degenerate

            # Ai = -τi * skew(ṗi)^2 / ||ṗi||³
            p_hat = self._skew(p_dot_i)
            A_i = -tau_i * (p_hat @ p_hat) / (norm_p_dot ** 3)

            # Bi = skew(ri) @ Ai
            B_i = self._skew(r_i) @ A_i

            # ai = Ai @ (u × ṗi)
            u_cross_p_dot = u_cross @ p_dot_i
            a_i = A_i @ u_cross_p_dot

            # bi = skew(ri) @ ai
            b_i = self._skew(r_i) @ a_i

            # G = -Σ Ai @ skew(ri)
            G_i = -A_i @ self._skew(r_i)

            # H = -Σ Bi @ skew(ri)
            H_i = -B_i @ self._skew(r_i)

            # Accumulate
            A_total += A_i
            B_total += B_i
            G_total += G_i
            H_total += H_i
            a_total += a_i
            b_total += b_i

        # ft = R (a + A v̇ + G u̇)
        # lt = R (b + B v̇ + H u̇)
        # Here, we assume quasi-static → v̇ ≈ 0, u̇ ≈ 0
        ft_global = R @ a_total
        lt_global = R @ b_total

        # Return 2D components
        return ft_global[:2], lt_global[2]
        
        
    
    def _ode_system(self, s, y, tau1, tau2, F_ext, s_force):
        """
        ODE system for 2D Cosserat rod with full coupled tendon model.
        
        State vector y = [px, py, theta, nx, ny, M]
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
        
        # Kinematics
        v_star = np.array([1, 0])  # No shear
        p_dot = R @ v_star
        px_dot = p_dot[0]
        py_dot = p_dot[1]
        
        # Curvature from moment-curvature relation
        if EI > 0:
            kappa = M / EI
        else:
            kappa = 0
        
        theta_dot = kappa
        
        # External forces
        fx_ext = 0.0
        fy_ext = 0.0
        m_ext = 0.0
        
        # Point force application
        if abs(s - s_force) < self.segment_length / 2 and F_ext != 0:
            force_direction = np.array([sin_theta, -cos_theta])
            force_intensity = F_ext / self.segment_length
            force_vector = force_intensity * force_direction
            fx_ext += force_vector[0]
            fy_ext += force_vector[1]
        
        # Compute configuration-dependent tendon loads
        ft_tendon, mt_tendon = self._compute_tendon_loads(theta, kappa, tau1, tau2)
        
        # Total distributed forces and moments
        fx_total = fx_ext + ft_tendon[0]
        fy_total = fy_ext + ft_tendon[1]
        m_total = m_ext + mt_tendon
        
        # Force equilibrium: n' = -f
        nx_dot = -fx_total
        ny_dot = -fy_total
        
        # Moment equilibrium: M' = p' × n - m
        cross_product_z = py_dot * nx - px_dot * ny
        M_dot = cross_product_z - m_total
        
        return [px_dot, py_dot, theta_dot, nx_dot, ny_dot, M_dot]
    
    def _solve_boundary_value_problem(self, tau1, tau2, F_ext, s_force):
        """
        Solve the boundary value problem using shooting method.
        """
        def shooting_residual(initial_guess):
            """Residual function for shooting method."""
            # Initial conditions at base (s=0): clamped
            px0, py0 = 0.0, 0.0
            theta0 = 0.0
            
            # Unknown initial values
            nx0 = initial_guess[0]
            ny0 = initial_guess[1]
            M0 = initial_guess[2]
            
            y0_vec = [px0, py0, theta0, nx0, ny0, M0]
            
            # Check if force is applied before the end
            force_applied = F_ext != 0 and s_force < self.total_length
            
            if force_applied:
                # Integrate to force application point
                s_eval_1 = np.linspace(0, s_force, max(10, int(s_force / self.segment_length) + 1))
                
                try:
                    sol_1 = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),
                        [0, s_force], y0_vec,
                        t_eval=s_eval_1,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol_1.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    # Apply force discontinuity
                    y_before = sol_1.y[:, -1]
                    theta_at_force = y_before[2]
                    
                    force_direction = np.array([np.sin(theta_at_force), -np.cos(theta_at_force)])
                    force_jump = F_ext * force_direction
                    
                    y_after = y_before.copy()
                    y_after[3] += force_jump[0]
                    y_after[4] += force_jump[1]
                    
                    # Integrate from force point to end
                    s_eval_2 = np.linspace(s_force, self.total_length, 
                                         max(10, int((self.total_length - s_force) / self.segment_length) + 1))
                    
                    sol_2 = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),
                        [s_force, self.total_length], y_after,
                        t_eval=s_eval_2,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol_2.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    # Check boundary conditions at tip
                    M_tip = sol_2.y[5, -1]
                    nx_tip = sol_2.y[3, -1]
                    ny_tip = sol_2.y[4, -1]
                    
                    residual = np.array([M_tip, nx_tip, ny_tip])
                    
                except Exception as e:
                    return np.array([1e6, 1e6, 1e6])
            
            else:
                # No point force
                try:
                    sol = solve_ivp(
                        lambda s, y: self._ode_system(s, y, tau1, tau2, F_ext, s_force),
                        [0, self.total_length], y0_vec,
                        t_eval=self.s_array,
                        method='RK45', rtol=1e-8, atol=1e-10
                    )
                    
                    if not sol.success:
                        return np.array([1e6, 1e6, 1e6])
                    
                    M_tip = sol.y[5, -1]
                    nx_tip = sol.y[3, -1]
                    ny_tip = sol.y[4, -1]
                    
                    residual = np.array([M_tip, nx_tip, ny_tip])
                    
                except Exception as e:
                    return np.array([1e6, 1e6, 1e6])
            
            return residual
        
        # Initial guess - use expected values for small deflections
        if tau1 > 0 or tau2 > 0:
            # Expect compression force approximately equal to total tension
            nx0_guess = -(tau1 + tau2)
            # Expect small transverse force
            ny0_guess = 0.0
            # Expect moment approximately tau * offset
            M0_guess = (tau1 - tau2) * self.tendon_offset
        else:
            nx0_guess = 0.0
            ny0_guess = 0.0
            M0_guess = 0.0
        
        initial_guess = np.array([nx0_guess, ny0_guess, M0_guess])
        
        try:
            solution = fsolve(shooting_residual, initial_guess, xtol=1e-8)
            
            # Final integration with converged initial conditions
            nx0, ny0, M0 = solution
            y0_vec = [0.0, 0.0, 0.0, nx0, ny0, M0]
            
            force_applied = F_ext != 0 and s_force < self.total_length
            
            if force_applied:
                # Two-part integration
                sol_1 = solve_ivp(
                    lambda s, y: self._ode_system(s, y, tau1, tau2, 0, s_force),
                    [0, s_force], y0_vec,
                    t_eval=np.linspace(0, s_force, max(20, int(s_force / self.segment_length) * 2)),
                    method='RK45', rtol=1e-8, atol=1e-10
                )
                
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
                                     max(20, int((self.total_length - s_force) / self.segment_length) * 2)),
                    method='RK45', rtol=1e-8, atol=1e-10
                )
                
                # Combine and interpolate
                s_combined = np.concatenate([sol_1.t[:-1], sol_2.t])
                y_combined = np.concatenate([sol_1.y[:, :-1], sol_2.y], axis=1)
                
                sol_interp = np.zeros((6, len(self.s_array)))
                for i in range(6):
                    sol_interp[i] = np.interp(self.s_array, s_combined, y_combined[i])
                
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
        Fx = nx0  # Internal force in x-direction at base
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
                
                # Mark force application point
                s_idx = int(s / self.segment_length)
                if s_idx < len(sol_final.y[0]) and F != 0:
                    force_x = sol_final.y[0][s_idx]
                    force_y = sol_final.y[1][s_idx]
                    force_theta = sol_final.y[2][s_idx]
                    
                    ax.plot(force_x, force_y, 'ko', markersize=8, 
                           label=f'Force application (s={s:.3f}m)')
                    
                    # Draw force arrow
                    arrow_length = 0.02
                    arrow_dir = np.array([-np.sin(force_theta), np.cos(force_theta)])
                    ax.arrow(force_x, force_y, 
                            F * arrow_length * arrow_dir[0], 
                            F * arrow_length * arrow_dir[1],
                            head_width=0.005, head_length=0.003,
                            fc='green', ec='green', width=0.001)
            
            # Calculate values for display
            Fx, MB = self.calculate_proximal_values(F, s, tau1, tau2)
            
            # Calculate effective lever arm
            if tau1 > 0:
                lever_arm = MB / tau1
            else:
                lever_arm = 0.0
            
            # Info box
            info_text = (f'F = {F:.2f} N\n'
                        f's = {s:.3f} m\n'
                        f'τ1 = {tau1:.3f} N\n'
                        f'τ2 = {tau2:.3f} N\n'
                        f'Fx = {Fx:.4f} N\n'
                        f'MB = {MB:.6f} N⋅m\n'
                        f'Lever arm = {lever_arm:.6f} m\n'
                        f'(nominal = {self.tendon_offset:.6f} m)')
            
            ax.text(0.02, 0.98, info_text, transform=ax.transAxes, 
                   bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.8),
                   verticalalignment='top', fontsize=10, family='monospace')
            
            ax.set_xlabel('x (m)')
            ax.set_ylabel('y (m)')
            ax.set_title('2D Cosserat Rod - Full Coupled Model')
            ax.legend()
            ax.grid(True, alpha=0.3)
            ax.axis('equal')
            plt.tight_layout()
            plt.show()
        
        # Return final deformed shape
        if sol_final is not None and sol_final.success:
            return sol_final.y[0], sol_final.y[1]
        else:
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
    
    # Test 1: Small deflection
    print("=== Test 1: Small Deflection ===")
    F = 0.0
    s = 0.2
    tau1, tau2 = 0.8, 0.0
    
    Fx, MB = rod.calculate_proximal_values(F, s, tau1, tau2)
    print(f"Base axial force: {Fx:.4f} N")
    print(f"Base bending moment: {MB:.6f} N⋅m")
    print(f"Calculated lever arm: {MB/tau1:.6f} m (should be close to {rod.tendon_offset:.6f} m)")
    
    # Plot the large deflection case
    x_def, y_def = rod.calculate_deflection(F, s, tau1, tau2, show_plot=True)