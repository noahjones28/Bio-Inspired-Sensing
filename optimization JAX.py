import jax
import jax.numpy as jnp
import jaxopt
from functools import partial
from cosserat_rod_tendons_V4_JAX import CoupledCosseratRod

def objective_jax(x, tau, Fx_target, MB_target, bending_model_params):
    """JAX-compatible objective function."""
    F, s = x[0], x[1]
    
    F = jnp.float32(F)
    s = jnp.float32(s)
    tau1 = jnp.float32(0)
    tau2 = jnp.float32(tau)
    # Forward simulation
    Fx_sim, MB_sim = calculate_proximal_values_jax(bending_model_params, F, s, tau1, tau2)
    
    # L2 norm of error
    error_vec = jnp.array([Fx_sim - Fx_target, MB_sim - MB_target])
    return jnp.linalg.norm(error_vec)**2

class MyOptimizationJAX:
    def __init__(self):
        pass
    
    def solve(self, axial_force, bending_moment_mag, tau, x0, xl, xu, bending_model):
        """Solve optimization using JAXopt BFGS."""
        # Convert to JAX arrays
        x0_jax = jnp.array(x0, dtype=jnp.float32)
        Fx_target = jnp.float32(axial_force)
        MB_target = jnp.float32(bending_moment_mag) 
        tau_jax = jnp.float32(tau)
        
        # Create objective function
        objective_partial = partial(objective_jax, 
                                  tau=tau_jax,
                                  Fx_target=Fx_target, 
                                  MB_target=MB_target,
                                  bending_model_params=bending_model.params)
        
        # Optimize using BFGS
        solver = jaxopt.BFGS(fun=objective_partial, maxiter=2, tol=1e-8)
        result = solver.run(x0_jax)
        
        print(f"Converged: {result.state.error < 1e-6}")
        print(f"Final objective: {objective_partial(result.params):.6e}")
        print(f"Iterations: {result.state.iter_num}")
        print(f"Solution: F={result.params[0]:.6f}, s={result.params[1]:.6f}")
        
        return result.params

# Example usage
if __name__ == "__main__":
    from cosserat_rod_tendons_V4_JAX import CoupledCosseratRod, calculate_proximal_values_jax
    
    # Create rod
    r_array = 1e-3 * jnp.array([
        1.192449935, 1.056414721, 1.184485918, 1.43225516, 1.977073619,
        1.682181794, 1.518782633, 1.820982147, 1.444977114, 1.711688436,
        1.981179713, 1.578414946, 1.833039007, 1.674709584, 1.892747419,
        1.489604833, 1.558534919, 1.950597422, 1.21079506, 1.68104385
    ], dtype=jnp.float32)
    youngs_modulus = 2.12e9  # PLA (Pa)
    
    rod = CoupledCosseratRod(r_array, youngs_modulus, segment_length=0.01)
    optimizer = MyOptimizationJAX()
    
    # Solve
    target_Fx = -0.1683
    target_MB = 0.046245
    tau = 0.0
    x0 = jnp.array([0.25, 0.15])
    xl = jnp.array([0.1, 0.05])
    xu = jnp.array([0.5, 0.19])
    
    optimal_x = optimizer.solve(target_Fx, target_MB, tau, x0, xl, xu, rod)
    print(f"Optimal solution: F={optimal_x[0]:.6f}, s={optimal_x[1]:.6f}")