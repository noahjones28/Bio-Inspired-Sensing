import numpy as np
from pyslsqp import optimize
from pyslsqp.postprocessing import print_dict_as_table
from scipy.optimize import differential_evolution

class MyOptimization:
    def __init__(self, elasticaInstance=None, model=None):
        pass
    def objective(self, x):
        #Design Variables
        F = x[0]
        s = x[1]
        # Objective function
        Fx_sim, MB_sim = self.bending_model.calculate_proximal_values(F, s, self.tau, 0)
        # Compute L2 norm of error vector
        error_vec = np.array([Fx_sim - self.Fx_target,MB_sim - self.MB_target])
        obj = np.linalg.norm(error_vec)**2  # squared L2 norm
        #obj = (Fx_sim - self.Fx_target)**2 + (MB_sim - self.MB_target)**2
        return obj
    
    def grad_central(self, x, h=1e-2):
        grad = np.zeros_like(x)
        for i in range(len(x)):
            x1 = x.copy()
            x2 = x.copy()
            x1[i] += h
            x2[i] -= h
            grad[i] = (self.objective(x1) - self.objective(x2)) / (2 * h)
        return grad

    def solve(self, axial_force, bending_moment_mag, tau, x0, xl, xu, bending_model):
        # Initial Condition (F0, s0)
        self.x0 = x0
        # Target Values
        self.Fx_target = axial_force 
        self.MB_target = bending_moment_mag
        # Static Parameters
        self.tau = tau
        # Class Objects
        self.bending_model = bending_model
        # optimize returns a dictionary that contains the results from optimization
        #results = optimize(x0, obj=self.objective, acc=1e-8, grad=self.grad_central, xu=xu, xl=xl, visualize=True, obj_scaler=1e6)
        bounds = [(xl[0], xu[0]), (xl[1], xu[1])]
        results = differential_evolution(self.objective, bounds, strategy='rand1bin', maxiter=20, popsize=15, tol=1e-6, seed=41, disp=True)
        #print_dict_as_table(results)
        return results['x']