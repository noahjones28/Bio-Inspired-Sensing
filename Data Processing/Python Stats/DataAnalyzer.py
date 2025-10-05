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
    def collect_samples(self, F_limits=np.array([0.05, 1]), s_limits=np.array([0.05, 0.2]), el_limits=np.array([0, 0]), az_limits=np.array([np.pi/4, 3*np.pi/4]), tau_limits=np.array([0, 1.5]), n_samples=15):
        F_array = np.random.uniform(F_limits[0], F_limits[1], size=n_samples)
        #s_array = np.random.uniform(s_limits[0], s_limits[1], size=n_samples)
        s_array = np.random.choice(np.arange(0.02, 0.22, 0.02), size=n_samples)
        el_array = np.random.choice([-np.pi/4, -np.pi/3, -np.pi/2, np.pi/4, np.pi/3, np.pi/2], size=n_samples)
        #az_array = np.random.uniform(az_limits[0], az_limits[1], size=n_samples)
        az_array = np.random.choice([0, -np.pi], size=n_samples)
        tau1_array = np.random.uniform(tau_limits[0], tau_limits[1], size=n_samples)
        tau2_array = np.random.uniform(tau_limits[0], tau_limits[1], size=n_samples)
        tau3_array = np.random.uniform(tau_limits[0], tau_limits[1], size=n_samples)
        distal_values = np.stack((F_array, s_array, el_array, az_array, tau1_array, tau2_array, tau3_array), axis=1)
        proximal_values = matlab_eng.get_proximal_values(distal_values)
        np.save('proximal_values.npy', proximal_values)
        np.save('distal_values.npy', distal_values)
    
    def load_samples_from_array(self):
        proximal_values = np.array([
            [0.000, -0.085, -0.001, -0.069, 0.000, 0.000, 1.190, 0.000, 0.000],
            [0.000, -0.071,  0.000, -0.058, 0.000, 0.000, 0.000, 0.000, 0.950],
            [0.000, -0.129,  0.002, -0.187, 0.000, 0.000, 0.000, 0.694, 0.000],
            [0.000, -0.116,  0.001, -0.098, 0.000, 0.000, 0.000, 0.000, 1.286],
            [0.000, -0.085,  0.000, -0.107, 0.000, 0.000, 0.397, 0.000, 0.000],
            [0.000,  0.030, -0.005, -0.009, 0.000, 0.000, 1.106, 0.000, 0.000],
            [0.000,  0.024, -0.001,  0.003, 0.000, 0.000, 0.962, 0.000, 0.000],
            [0.000,  0.029,  0.000, -0.036, 0.000, 0.000, 0.000, 0.894, 0.000],
            [0.000,  0.043,  0.002, -0.053, 0.000, 0.000, 0.000, 0.871, 0.000],
            [0.000,  0.032,  0.009, -0.027, 0.000, 0.000, 0.000, 1.315, 0.000],
            [0.000, -0.244,  0.034,  2.340, 0.000, 0.000, 1.344, 0.000, 0.000],
        ])
        distal_values = np.array([
            [0.100,0.10,1.571,1.571,1.00,0.04,3.142,1.571,0.200,0.000,0.000],
            [0.100,0.10,4.712,1.571,0.30,0.08,3.927,1.571,0.200,0.000,0.000],
            [0.100,0.12,1.571,1.571,0.20,0.08,4.712,1.571,1.400,0.000,0.000],
            [0.100,0.14,3.927,1.571,1.00,0.08,3.142,1.571,1.000,0.000,0.000],
            [0.100,0.18,2.356,1.571,0.20,0.02,4.712,1.571,0.000,0.000,0.000],
            [0.100,0.20,1.571,1.571,0.10,0.08,3.142,1.571,0.200,0.000,0.000],
            [0.100,0.20,2.356,1.571,1.00,0.02,3.142,1.571,1.200,0.000,0.000],
            [0.100,0.20,4.712,1.571,0.80,0.06,4.712,1.571,1.000,0.000,0.000],
            [0.200,0.10,2.356,1.571,0.80,0.02,4.712,1.571,1.200,0.000,0.000],
            [0.200,0.10,4.712,1.571,0.70,0.04,3.142,1.571,1.400,0.000,0.000],
            [0.200,0.12,3.927,1.571,0.20,0.02,3.142,1.571,0.000,0.000,0.000],
            [0.200,0.12,4.712,1.571,1.00,0.02,4.712,1.571,0.200,0.000,0.000],
            [0.200,0.18,3.927,1.571,0.80,0.04,3.927,1.571,0.200,0.000,0.000],
            [0.200,0.18,4.712,1.571,0.10,0.08,3.142,1.571,1.400,0.000,0.000],
            [0.200,0.20,3.927,1.571,0.20,0.02,4.712,1.571,1.400,0.000,0.000],
            [0.300,0.12,1.571,1.571,0.10,0.02,3.927,1.571,0.600,0.000,0.000],
            [0.300,0.12,1.571,1.571,0.80,0.08,3.927,1.571,0.000,0.000,0.000],
            [0.300,0.18,1.571,1.571,0.40,0.06,3.142,1.571,1.000,0.000,0.000],
            [0.300,0.18,1.571,1.571,1.00,0.04,4.712,1.571,1.400,0.000,0.000],
            [0.300,0.20,2.356,1.571,0.30,0.08,4.712,1.571,0.400,0.000,0.000],
            [0.300,0.20,4.712,1.571,1.00,0.06,3.142,1.571,0.000,0.000,0.000],
            [0.400,0.10,2.356,1.571,0.10,0.08,3.142,1.571,1.200,0.000,0.000],
            [0.400,0.10,3.927,1.571,0.10,0.06,4.712,1.571,0.200,0.000,0.000],
            [0.400,0.14,3.142,1.571,0.80,0.06,3.927,1.571,1.000,0.000,0.000],
            [0.500,0.14,4.712,1.571,0.20,0.04,4.712,1.571,1.000,0.000,0.000],
            [0.600,0.10,4.712,1.571,1.00,0.08,4.712,1.571,1.400,0.000,0.000],
            [0.600,0.16,2.356,1.571,0.40,0.04,3.927,1.571,1.000,0.000,0.000],
            [0.700,0.18,3.927,1.571,0.30,0.08,3.927,1.571,1.000,0.000,0.000],
            [0.700,0.18,4.712,1.571,0.80,0.02,3.142,1.571,0.400,0.000,0.000],
            [0.800,0.12,2.356,1.571,0.40,0.06,3.927,1.571,0.200,0.000,0.000],
            [0.800,0.12,2.356,1.571,0.80,0.04,4.712,1.571,0.600,0.000,0.000],
            [0.800,0.20,1.571,1.571,1.00,0.06,4.712,1.571,0.000,0.000,0.000],
            [0.800,0.20,2.356,1.571,0.80,0.08,3.142,1.571,1.400,0.000,0.000],
            [0.800,0.20,3.927,1.571,0.30,0.04,3.142,1.571,0.400,0.000,0.000],
            [0.900,0.10,3.927,1.571,0.90,0.04,3.927,1.571,0.000,0.000,0.000],
            [0.900,0.10,4.712,1.571,0.10,0.02,3.927,1.571,1.200,0.000,0.000],
            [0.900,0.12,1.571,1.571,1.00,0.02,3.142,1.571,1.400,0.000,0.000],
            [0.900,0.16,1.571,1.571,0.10,0.08,3.142,1.571,0.000,0.000,0.000],
            [0.900,0.18,3.927,1.571,0.80,0.02,4.712,1.571,1.400,0.000,0.000],
            [0.900,0.20,1.571,1.571,0.10,0.06,4.712,1.571,1.200,0.000,0.000],
            [1.000,0.10,1.571,1.571,0.30,0.02,4.712,1.571,0.200,0.000,0.000],
            [1.000,0.10,1.571,1.571,0.90,0.08,4.712,1.571,1.000,0.000,0.000],
            [1.000,0.12,3.927,1.571,0.30,0.06,3.927,1.571,1.400,0.000,0.000],
            [1.000,0.12,4.712,1.571,0.70,0.08,3.142,1.571,0.400,0.000,0.000],
            [1.000,0.18,2.356,1.571,0.10,0.02,3.142,1.571,1.400,0.000,0.000],
            [1.000,0.18,2.356,1.571,1.00,0.06,3.927,1.571,0.400,0.000,0.000],
            [1.000,0.18,4.712,1.571,0.70,0.08,4.712,1.571,0.000,0.000,0.000],
            [1.000,0.20,1.571,1.571,0.80,0.02,3.142,1.571,0.000,0.000,0.000],
            [1.000,0.20,4.712,1.571,0.10,0.02,3.927,1.571,0.000,0.000,0.000],
            [1.000,0.20,4.712,1.571,1.00,0.04,3.142,1.571,1.200,0.000,0.000]
        ])

        

        np.save('proximal_values.npy', proximal_values)
        np.save('distal_values.npy', distal_values)

    def get_distal_values(self, proximal_values):
        distal_values = matlab_eng.get_distal_values(proximal_values)
        print(distal_values)
        return distal_values
    
    def get_proximal_values(self, distal_values):
        proximal_values = matlab_eng.get_proximal_values(distal_values)
        print(proximal_values)
        return proximal_values

    def validate_inverse_model(self, proximal_values, target_distal_values, mean_error=np.zeros(6), std_error=np.zeros(6), n_trials=1, plot_results=True):
        # Validate inverse model using knowm data
        delta_F_array = np.zeros((len(target_distal_values), n_trials))
        delta_s_array = np.zeros((len(target_distal_values), n_trials))
        delta_el_array = np.zeros((len(target_distal_values), n_trials))
        delta_az_array = np.zeros((len(target_distal_values), n_trials))
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
            az_hats = np.array(distal_values)[:,3]
            F_targets = target_distal_values[:,0]
            s_targets = target_distal_values[:,1]
            el_targets = target_distal_values[:,2]
            az_targets = target_distal_values[:,3]
            delta_F_array[:, j] = (F_hats - F_targets)
            delta_s_array[:, j] = (s_hats - s_targets)
            # signed smallest difference in (-pi, pi]
            delta_el_array[:, j] = np.arctan2(
                np.sin(el_hats - el_targets),
                np.cos(el_hats - el_targets)
            )
            delta_az_array[:, j] = np.arctan2(
                np.sin(az_hats - az_targets),
                np.cos(az_hats - az_targets)
            )

        # Mean and standard deviation per point across trials
        delta_F_mean = np.mean(delta_F_array, axis=1)
        delta_F_stdev = np.std(delta_F_array, axis=1, ddof=1) # ddof=1 → uses sample standard deviation (unbiased estimator).
        delta_s_mean = np.mean(delta_s_array, axis=1)
        delta_s_stdev = np.std(delta_s_array, axis=1, ddof=1)
        delta_el_mean = np.mean(delta_el_array, axis=1)
        delta_el_stdev = np.std(delta_el_array, axis=1, ddof=1)
        delta_az_mean = np.mean(delta_az_array, axis=1)
        delta_az_stdev = np.std(delta_az_array, axis=1, ddof=1)

        # Flatten arrays to combine all points and trials
        all_delta_F = delta_F_array.flatten()
        all_delta_s = delta_s_array.flatten()
        all_delta_el = delta_el_array.flatten()
        all_delta_az = delta_az_array.flatten()

        # Overall mean and standard deviation
        delta_F_mean_overall = np.mean(all_delta_F)
        delta_F_stdev_overall = np.std(all_delta_F, ddof=1)
        delta_s_mean_overall = np.mean(all_delta_s)
        delta_s_stdev_overall = np.std(all_delta_s, ddof=1)
        delta_el_mean_overall = np.mean(all_delta_el)
        delta_el_stdev_overall = np.std(all_delta_el, ddof=1)
        delta_az_mean_overall = np.mean(all_delta_az)
        delta_az_stdev_overall = np.std(all_delta_az, ddof=1)
         
        # Print results
        print("Validaition Results:\n")
        print("Overall Results:\n")
        print(f"Mean ΔF: {delta_F_mean_overall:.6f}")
        print(f"Standard Deviation ΔF: {delta_F_stdev_overall:.6f}")
        print(f"Mean Δs: {delta_s_mean_overall:.6f}")
        print(f"Standard Deviation Δs: {delta_s_stdev_overall:.6f}")
        print(f"Mean Δel: {delta_el_mean_overall:.6f}")
        print(f"Standard Deviation Δel: {delta_el_stdev_overall:.6f}")
        print(f"Mean Δaz: {delta_az_mean_overall:.6f}")
        print(f"Standard Deviation Δaz: {delta_az_stdev_overall:.6f}")
        # Create heatmaps
        if plot_results:
            F_array = target_distal_values[:, 0]
            s_array = target_distal_values[:, 1]
            self.plot_heatmap(x_array=s_array, y_array=F_array, var1_mean=delta_F_mean, var1_stdev=delta_F_stdev,
                              var2_mean=delta_s_mean, var2_stdev=delta_s_stdev, var3_mean=delta_el_mean,
                              var3_stdev=delta_el_stdev, var1_title="ΔF", var2_title="Δs", var3_title="Δel",
                              x_label="s (m)", y_label="F (N)")

        return delta_F_mean_overall, delta_s_mean_overall, delta_el_mean_overall, delta_az_mean_overall, delta_F_stdev_overall, delta_s_stdev_overall, delta_el_stdev_overall, delta_az_stdev_overall, 
        
        
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

