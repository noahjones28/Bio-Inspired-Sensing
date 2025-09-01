# GENERAL
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import numpy as np
from scipy.interpolate import griddata
# MATLAB
import matlab.engine
matlab_eng = matlab.engine.start_matlab()

class DataAnalyzer:
    def __init__(self):
        pass
    def collect_samples(self, F_limits=np.array([0.05, 1]), s_limits=np.array([0.05, 0.2]), el_limits=np.array([0, 0.05]), az=np.pi/2, tau_limits=np.array([0, 1]), n_samples=10):
        F_array = np.random.uniform(F_limits[0], F_limits[1], size=n_samples)
        s_array = np.random.uniform(s_limits[0], s_limits[1], size=n_samples)
        el_array = np.random.uniform(el_limits[0], el_limits[1], size=n_samples)
        az_array = np.full(n_samples, az)
        tau_array = np.random.uniform(tau_limits[0], tau_limits[1], size=n_samples)
        distal_values = np.stack((F_array, s_array, el_array, az_array, tau_array), axis=1)
        proximal_values = matlab_eng.get_proximal_values(distal_values)
        np.save('proximal_values.npy', proximal_values)
        np.save('distal_values.npy', distal_values)

    def validate_inverse_model(self, proximal_values, target_distal_values, mean_error=np.zeros(6), std_error=np.zeros(6), n_trials=3, plot_results=True):
        # Validate inverse model using knowm data
        delta_F_array = np.zeros((len(target_distal_values), n_trials))
        delta_s_array = np.zeros((len(target_distal_values), n_trials))
        delta_el_array = np.zeros((len(target_distal_values), n_trials))
        for j in range(n_trials):
            error = np.random.normal(loc=mean_error, scale=std_error, size=tuple([proximal_values.shape[0], proximal_values.shape[1]-1]))
            try:
                proximal_values[:, :proximal_values.shape[1]-1] += error
            except ValueError:
                print("Error array must have same dimension as proximal_values!")
            distal_values = matlab_eng.get_distal_values(proximal_values)
            F_hats = np.array(distal_values)[:,0]
            s_hats = np.array(distal_values)[:,1]
            el_hats = np.array(distal_values)[:,2]
            F_targets = target_distal_values[:,0]
            s_targets = target_distal_values[:,1]
            el_targets = target_distal_values[:,2]
            delta_F_array[:, j] = (F_hats - F_targets)
            delta_s_array[:, j] = (s_hats - s_targets)
            delta_el_array[:, j] = (el_hats - el_targets)

        # Mean and standard deviation per point across trials
        delta_F_mean = np.mean(delta_F_array, axis=1)
        delta_F_stdev = np.std(delta_F_array, axis=1, ddof=1) # ddof=1 → uses sample standard deviation (unbiased estimator).
        delta_s_mean = np.mean(delta_s_array, axis=1)
        delta_s_stdev = np.std(delta_s_array, axis=1, ddof=1)
        delta_el_mean = np.mean(delta_el_array, axis=1)
        delta_el_stdev = np.std(delta_el_array, axis=1, ddof=1)

        # Flatten arrays to combine all points and trials
        all_delta_F = delta_F_array.flatten()
        all_delta_s = delta_s_array.flatten()
        all_el_sigma = delta_el_array.flatten()

        # Overall mean and standard deviation
        delta_F_mean_overall = np.mean(all_delta_F)
        delta_F_stdev_overall = np.std(all_delta_F, ddof=1)
        delta_s_mean_overall = np.mean(all_delta_s)
        delta_s_stdev_overall = np.std(all_delta_s, ddof=1)
        delta_el_mean_overall = np.mean(all_el_sigma)
        delta_el_stdev_overall = np.std(all_el_sigma, ddof=1)
         
        # Print results
        print("Validaition Results:\n")
        print("Overall Results:\n")
        print(f"Mean ΔF: {delta_F_mean_overall:.6f}")
        print(f"Standard Deviation ΔF: {delta_F_stdev_overall:.6f}")
        print(f"Mean Δs: {delta_s_mean_overall:.6f}")
        print(f"Standard Deviation Δs: {delta_s_stdev_overall:.6f}")
        print(f"Mean Δel: {delta_el_mean_overall:.6f}")
        print(f"Standard Deviation Δel: {delta_el_stdev_overall:.6f}")
        # Create heatmaps
        if plot_results:
            F_array = target_distal_values[:, 0]
            s_array = target_distal_values[:, 1]
            self.plot_heatmap(x_array=s_array, y_array=F_array, var1_mean=delta_F_mean, var1_stdev=delta_F_stdev,
                              var2_mean=delta_s_mean, var2_stdev=delta_s_stdev, var3_mean=delta_el_mean,
                              var3_stdev=delta_el_stdev, var1_title="ΔF", var2_title="Δs", var3_title="Δel",
                              x_label="s (m)", y_label="F (N)")

        return delta_F_mean_overall, delta_s_mean_overall, delta_el_mean_overall, delta_F_stdev_overall, delta_s_stdev_overall, delta_el_stdev_overall
        
        
    def plot_heatmap(self, x_array, y_array, var1_mean, var1_stdev, var2_mean, var2_stdev, var3_mean, var3_stdev, var1_title, var2_title, var3_title, x_label, y_label):
        # Generate meshgrid
        x_grid = np.linspace(min(x_array), max(x_array), 100)
        y_grid = np.linspace(min(y_array), max(y_array), 100)
        y_mesh, x_mesh = np.meshgrid(y_grid, x_grid)

        # Interpolate data to grids
        mean1_grid = griddata((y_array, x_array), var1_mean, (y_mesh, x_mesh), method='cubic')
        std1_grid  = griddata((y_array, x_array), var1_stdev,  (y_mesh, x_mesh), method='cubic')
        mean2_grid = griddata((y_array, x_array), var2_mean, (y_mesh, x_mesh), method='cubic')
        std2_grid  = griddata((y_array, x_array), var2_stdev,  (y_mesh, x_mesh), method='cubic')
        mean3_grid = griddata((y_array, x_array), var3_mean, (y_mesh, x_mesh), method='cubic')
        std3_grid  = griddata((y_array, x_array), var3_stdev,  (y_mesh, x_mesh), method='cubic')


        try:
            # Try centering at 0 first
            norm_mean1 = colors.TwoSlopeNorm(vmin=np.nanmin(mean1_grid), vcenter=0.0, vmax=np.nanmax(mean1_grid))
            norm_mean2 = colors.TwoSlopeNorm(vmin=np.nanmin(mean2_grid), vcenter=0.0, vmax=np.nanmax(mean2_grid))
            norm_mean3 = colors.TwoSlopeNorm(vmin=np.nanmin(mean3_grid), vcenter=0.0, vmax=np.nanmax(mean3_grid))

        except ValueError:
            # If that fails, center at the mean
            vcenter_value = np.nanmean(mean1_grid)
            norm_mean1 = colors.TwoSlopeNorm(vmin=np.nanmin(mean1_grid), vcenter=vcenter_value, vmax=np.nanmax(mean1_grid))
            vcenter_value = np.nanmean(mean2_grid)
            norm_mean2 = colors.TwoSlopeNorm(vmin=np.nanmin(mean2_grid), vcenter=vcenter_value, vmax=np.nanmax(mean2_grid))
            vcenter_value = np.nanmean(mean3_grid)
            norm_mean3 = colors.TwoSlopeNorm(vmin=np.nanmin(mean3_grid), vcenter=vcenter_value, vmax=np.nanmax(mean3_grid))

        # Create 2x3 subplots
        fig, axs = plt.subplots(2, 3, figsize=(12, 10))

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

        # Top middle: mean of var2
        c3 = axs[0, 1].contourf(x_mesh, y_mesh, mean2_grid, levels=100, cmap='coolwarm', norm=norm_mean2)
        fig.colorbar(c3, ax=axs[0, 1], label=f"Mean {var2_title}")
        axs[0, 1].set_title(f"Mean {var2_title}")
        axs[0, 1].set_xlabel(x_label)
        axs[0, 1].set_ylabel(y_label)

        # Bottom middle: stdev of var2
        c4 = axs[1, 1].contourf(x_mesh, y_mesh, std2_grid, levels=100, cmap='viridis')
        fig.colorbar(c4, ax=axs[1, 1], label=f"Stdev {var2_title}")
        axs[1, 1].set_title(f"Stdev {var2_title}")
        axs[1, 1].set_xlabel(x_label)
        axs[1, 1].set_ylabel(y_label)

        # Top right: mean of var3
        c3 = axs[0, 2].contourf(x_mesh, y_mesh, mean3_grid, levels=100, cmap='coolwarm', norm=norm_mean3)
        fig.colorbar(c3, ax=axs[0, 2], label=f"Mean {var3_title}")
        axs[0, 2].set_title(f"Mean {var3_title}")
        axs[0, 2].set_xlabel(x_label)
        axs[0, 2].set_ylabel(y_label)

        # Bottom right: stdev of var3
        c4 = axs[1, 2].contourf(x_mesh, y_mesh, std3_grid, levels=100, cmap='viridis')
        fig.colorbar(c4, ax=axs[1, 2], label=f"Stdev {var3_title}")
        axs[1, 2].set_title(f"Stdev {var3_title}")
        axs[1, 2].set_xlabel(x_label)
        axs[1, 2].set_ylabel(y_label)

        plt.tight_layout()
        plt.show()

