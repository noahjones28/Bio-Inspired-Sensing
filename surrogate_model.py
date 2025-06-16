import numpy as np
from smt.surrogate_models import KRG, RBF, KPLSK
from smt.sampling_methods import LHS
from joblib import Parallel, delayed
import glob, os

class MySurrogateModel:
    def __init__(self, method):
            # Initialize the RBF model
            if method == "RBF":
                self.model = RBF(d0=2, poly_degree=1, reg=1e-25)
            elif method == "KRG":
                self.model = KRG()
            elif method == "KPLSK":
                self.model = KPLSK(
                    n_comp=8,  # Improves speed & generalization
                    nugget=1e-4,
                    theta0=[1e-1],  # Better than 0.01
                    hyper_opt="Cobyla",  # Faster and more stable for high-D problems
                )
            else:
                 raise ValueError("Invalid surrogate model type!")
            
    def get_training_data(self, F_limits, s_limits, tendon_displacement_limits, n_training_samples, elastica_model, wrist_model, radii_limits=None,):
        # LIMITS AND SAMPLING
        # Base limits: F, s, and tendon displacement
        limits = [[F_limits[0], F_limits[-1]], [s_limits[0], s_limits[-1]], [tendon_displacement_limits[0], tendon_displacement_limits[-1]]]
        # If radii_limits is provided, append 20 copies of the same range
        if radii_limits is not None:
            if len(radii_limits) != 2:
                raise ValueError("radii_limits must be a 1x2 array-like: [min, max].")
            limits.extend([radii_limits] * 20)  # Add same bounds for all 20 radii
        limits = np.array(limits)
        n_testing_samples = int(np.round(0.2*n_training_samples))
        sampling = LHS(xlimits=limits, criterion='maximin')

        # TRAINING SAMPLES
        training_samples = sampling(n_training_samples)
        F_training_samples = training_samples[:, 0]
        s_training_samples = training_samples[:, 1]
        tendon_displacement_training_samples = training_samples[:, 2]
        # Extract radii if applicable
        if radii_limits is not None:
            radii_training_samples = training_samples[:, 3:]
        else:
            radii_training_samples = [None] * n_training_samples
        # Get training data
        y_train = np.column_stack((F_training_samples, s_training_samples))
        x_train = Parallel(n_jobs=-1)(
            delayed(lambda idx, row: (
                print(f"Processing training sample {idx + 1} of {len(y_train)}"),  # First do the print
                elastica_model.getProximalValues(F=row[0], s=row[1], tendon_displacement=tendon_displacement_training_samples[idx], # Then compute proximal values
                    wrist_model=wrist_model, new_radii=radii_training_samples[idx] if radii_limits is not None else None)
            )[1])(idx, row)  # Return only the second part of the tuple
            for idx, row in enumerate(y_train)
        )
        # Append tendon displacement and to each x_train sample as a parameter
        x_train = np.column_stack((x_train, tendon_displacement_training_samples))
        # Append radii if applicable
        if radii_limits is not None:
            x_train = np.column_stack((x_train, radii_training_samples))

        # TESTING SAMPLES
        testing_samples = sampling(n_testing_samples)
        F_testing_samples = testing_samples[:, 0]
        s_testing_samples = testing_samples[:, 1]
        tendon_displacement_testing_samples = testing_samples[:, 2]
        # Extract radii if applicable
        if radii_limits is not None:
            radii_testing_samples = testing_samples[:, 3:]
        else:
            radii_testing_samples = [None] * n_testing_samples
        # Get testing data
        y_test = np.column_stack((F_testing_samples, s_testing_samples))
        x_test = Parallel(n_jobs=-1)(
            delayed(lambda idx, row: (
                print(f"Processing testing sample {idx + 1} of {len(y_test)}"),  # First do the print
                elastica_model.getProximalValues(F=row[0], s=row[1], tendon_displacement=tendon_displacement_testing_samples[idx], # Then compute proximal values
                    wrist_model=wrist_model, new_radii=radii_testing_samples[idx] if radii_limits is not None else None)
            )[1])(idx, row)  # Return only the second part of the tuple
            for idx, row in enumerate(y_test)
        )
        # Append tendon displacement and to each x_test sample as a parameter
        x_test = np.column_stack((x_test, tendon_displacement_testing_samples))
        # Append radii if applicable
        if radii_limits is not None:
            x_test = np.column_stack((x_test, radii_testing_samples))


        # Save the scaled train and test sets as .npy
        os.makedirs("distal_to_proximal_training_data", exist_ok=True)
        np.save("distal_to_proximal_training_data/x_train.npy", x_train)
        np.save("distal_to_proximal_training_data/y_train.npy", y_train)
        np.save("distal_to_proximal_training_data/x_test.npy", x_test)
        np.save("distal_to_proximal_training_data/y_test.npy", y_test)
        raise ValueError("Sampling calculations complete! Please re-run code")
    
    def train_model(self):
        # Load training data
        x_train = np.load("distal_to_proximal_training_data/x_train.npy")
        y_train = np.load("distal_to_proximal_training_data/y_train.npy")

        # Load testing data
        x_test = np.load("distal_to_proximal_training_data/x_test.npy")
        y_test = np.load("distal_to_proximal_training_data/y_test.npy")
        
        # Train the model
        self.model.set_training_values(x_train, y_train)
        self.model.train()

        # Train set error
        y_train_pred, y_train_std = self.model.predict_values(x_train), self.model.predict_variances(x_train)
        train_error = np.linalg.norm(y_train - y_train_pred) / np.linalg.norm(y_train)
        print("\ntrain error:", train_error)
        
        # Test set error
        y_test_pred, y_test_std = self.model.predict_values(x_test), self.model.predict_variances(x_test)
        test_error = np.linalg.norm(y_test - y_test_pred) / np.linalg.norm(y_test)
        print("\ntest error:", test_error)
    
    def predict(self, x):
        prediction = self.model.predict_values(x)
        return prediction