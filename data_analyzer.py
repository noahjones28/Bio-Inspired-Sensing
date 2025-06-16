import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import griddata
import matplotlib.colors as colors

class MyDataAnalyzer:
    def __init__(self):
        pass
    def validate(self, x_test, y_test, x_noise = np.zeros(3), n_trials = 10, elastica=None, surrogate_model=None, plot_results=True):
        # Validate surrogate model
        delta_F_array = np.zeros((len(x_test), n_trials))
        delta_s_array = np.zeros((len(x_test), n_trials))
        for i, (x, y) in enumerate(zip(x_test, y_test)):
            axial_force = x[0]
            bending_moment_mag = x[1]
            tendon_displacement = x[2]
            F = y[0]
            s = y[1]
            for j in range(n_trials):
                F_hat, s_hat = elastica.get_distal_values(
                    axial_force, bending_moment_mag, tendon_displacement, surrogate_model,
                    axial_noise=x_noise[0], moment_noise=x_noise[1], tendon_noise=x_noise[2]
                )
                delta_F_array[i, j] = (F_hat - F)
                delta_s_array[i, j] = (s_hat - s)
    

        # Mean and standard deviation per point across trials
        delta_F_mean = np.mean(delta_F_array, axis=1)
        delta_F_stdev = np.std(delta_F_array, axis=1, ddof=1) # ddof=1 → uses sample standard deviation (unbiased estimator).
        delta_s_mean = np.mean(delta_s_array, axis=1)
        delta_s_stdev = np.std(delta_s_array, axis=1, ddof=1)

        # Flatten arrays to combine all points and trials
        all_delta_F = delta_F_array.flatten()
        all_delta_s = delta_s_array.flatten()

        # Overall mean and standard deviation
        delta_F_mean_overall = np.mean(all_delta_F)
        delta_F_stdev_overall = np.std(all_delta_F, ddof=1)
        delta_s_mean_overall = np.mean(all_delta_s)
        delta_s_stdev_overall = np.std(all_delta_s, ddof=1)
         
        # Print results
        print("Validaition Results:\n")
        print("Overall Results:\n")
        print(f"Mean ΔF: {delta_F_mean_overall:.4f}")
        print(f"Standard Deviation ΔF: {delta_F_stdev_overall:.4f}")
        print(f"Mean Δs: {delta_s_mean_overall:.4f}")
        print(f"Standard Deviation Δs: {delta_s_stdev_overall:.4f}")
        # Create heatmaps
        if plot_results:
            F_array = y_test[:, 0]
            s_array = y_test[:, 1]
            self.plot_heatmap(x_array=s_array, y_array=F_array, var1_mean=delta_F_mean, var1_stdev=delta_F_stdev,
                              var2_mean=delta_s_mean, var2_stdev=delta_s_stdev, var1_title="ΔF", var2_title="Δs",
                              x_label="s (m)", y_label="F (N)")

        return delta_F_mean_overall, delta_s_mean_overall, delta_F_stdev_overall, delta_s_stdev_overall
        
        
    def plot_heatmap(self, x_array, y_array, var1_mean, var1_stdev, var2_mean, var2_stdev, var1_title, var2_title, x_label, y_label):
        # Generate meshgrid
        x_grid = np.linspace(min(x_array), max(x_array), 100)
        y_grid = np.linspace(min(y_array), max(y_array), 100)
        y_mesh, x_mesh = np.meshgrid(y_grid, x_grid)

        # Interpolate data to grids
        mean1_grid = griddata((y_array, x_array), var1_mean, (y_mesh, x_mesh), method='cubic')
        std1_grid  = griddata((y_array, x_array), var1_stdev,  (y_mesh, x_mesh), method='cubic')
        mean2_grid = griddata((y_array, x_array), var2_mean, (y_mesh, x_mesh), method='cubic')
        std2_grid  = griddata((y_array, x_array), var2_stdev,  (y_mesh, x_mesh), method='cubic')

        # Create color normalizers centered at 0
        norm_mean1 = colors.TwoSlopeNorm(vmin=np.nanmin(mean1_grid), vcenter=0.0, vmax=np.nanmax(mean1_grid))
        norm_mean2 = colors.TwoSlopeNorm(vmin=np.nanmin(mean2_grid), vcenter=0.0, vmax=np.nanmax(mean2_grid))

        # Create 2x2 subplots
        fig, axs = plt.subplots(2, 2, figsize=(12, 10))

        # Top left: mean of var1
        c1 = axs[0, 0].contourf(x_mesh, y_mesh, mean1_grid, levels=100, cmap='coolwarm', norm=norm_mean1)
        fig.colorbar(c1, ax=axs[0, 0], label=f"Mean {var1_title}")
        axs[0, 0].set_title(f"Mean {var1_title}")
        axs[0, 0].set_xlabel(x_label)
        axs[0, 0].set_ylabel(y_label)

        # Bottom left: stdev of var1
        c2 = axs[1, 0].contourf(x_mesh, y_mesh, std1_grid, levels=100, cmap='viridis')
        fig.colorbar(c2, ax=axs[1, 0], label=f"Stdev {var1_title}")
        axs[1, 0].set_title(f"Stdev {var1_title}")
        axs[1, 0].set_xlabel(x_label)
        axs[1, 0].set_ylabel(y_label)

        # Top right: mean of var2
        c3 = axs[0, 1].contourf(x_mesh, y_mesh, mean2_grid, levels=100, cmap='coolwarm', norm=norm_mean2)
        fig.colorbar(c3, ax=axs[0, 1], label=f"Mean {var2_title}")
        axs[0, 1].set_title(f"Mean {var2_title}")
        axs[0, 1].set_xlabel(x_label)
        axs[0, 1].set_ylabel(y_label)

        # Bottom right: stdev of var2
        c4 = axs[1, 1].contourf(x_mesh, y_mesh, std2_grid, levels=100, cmap='viridis')
        fig.colorbar(c4, ax=axs[1, 1], label=f"Stdev {var2_title}")
        axs[1, 1].set_title(f"Stdev {var2_title}")
        axs[1, 1].set_xlabel(x_label)
        axs[1, 1].set_ylabel(y_label)

        plt.tight_layout()
        plt.show()