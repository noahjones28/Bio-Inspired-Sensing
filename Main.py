from DataAnalyzer import DataAnalyzer
import numpy as np

class Main:
    def __init__(self):
        pass

if __name__ == "__main__":
    DataAnalyzer = DataAnalyzer()
    #DataAnalyzer.collect_samples()
    proximal = np.load('proximal_values.npy')
    distal = np.load('distal_values.npy')
    std_error = np.array([5e-2, 5e-2, 5e-2, 5e-2, 5e-2,5e-2])
    DataAnalyzer.validate_inverse_model(proximal, distal, std_error=std_error)