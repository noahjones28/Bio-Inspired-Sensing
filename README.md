# 🧠 Bio-Inspired Force Estimation in Tendon-Driven Continuum Robots

This repository contains the simulation, optimization, and analysis code for my research on **force and contact‐location estimation in concentric-tube / tendon-driven continuum robots (CTR)**. The work is inspired by **biological whisker sensing**, where geometry (taper, curvature, stiffness gradients) plays a critical role in ensuring **injective, noise-robust mappings** between applied distal forces and measured proximal wrenches.

The goal of this project is to design robot geometries that **maximize the uniqueness and robustness** of the forward map
```
F = [F, s, θ] → W = [Fx, Fy, Fz, Tx, Ty, Tz]
```
leading to more accurate inverse estimates of force magnitude and contact position.

---

## 🚀 Project Overview

### 🔍 Research Focus

* Real-time **force and contact-location estimation** for CTRs.
* Studying how geometry (taper, oscillation, stiffness gradients) changes the injectivity of the forward map.
* Evaluating **noise-robustness** using tendon perturbations, proximal wrench differences, and Lipschitz/α-based metrics.
* Physics-based forward modeling using **Cosserat rod theory** (PyElastica or custom solvers).
* Optimization of multi-segment geometries (20-element radius arrays) under noise.

### 🧪 Key Contributions

* Demonstrated that **tapered geometries** significantly reduce non-uniqueness ("degeneracies") present in cylindrical beams.
* Showed **43% reduction** in mean contact-location error and **49% reduction** in STD vs cylindrical designs (p ≈ 0.096).
* Identified why tapered designs are **sensitive to measurement noise** and methods to mitigate this.
* Developed global injectivity testing via:
  * Pairwise distance maps (r_ij)
  * Local Jacobian singular values (α = σ_min(J))
  * Multi-force (two-contact) mapping tests

---

## 📂 Repository Structure

```
/src
    /forward_model        # Cosserat rod + tendon actuation model
    /inverse_estimation   # Nonlinear least-squares solvers
    /geometry             # Radius arrays, taper patterns, oscillations
    /optimization         # r_array optimization, multi-start solvers
    /analysis             # Injectivity tests (r_ij, Jacobians), noise studies
    /visualization        # Plots, heatmaps, 3D force mapping visualizations
/notebooks
    Exploration.ipynb     # Quick prototyping + visualization
/results
    figures/              # Plots for paper
    data/                 # Saved simulation outputs
README.md
```

---

## 🧩 Methods

### 🦴 Forward Modeling

* 3D Cosserat rod formulation
* Tendon actuation forces applied as distributed loads
* Geometry specified by a **20-segment radius array**

### 🎯 Inverse Estimation

* Nonlinear least squares (MATLAB or Python)
* Residuals include:
  * ΔW directions (normalized)
  * Force magnitude residuals
  * Perturbation-based differential signals

### 🧬 Injectivity & Conditioning

* Pairwise test:
  ```
  r_ij = |W_i - W_j| / |F_i - F_j|
  ```
* Local sensitivity:
  ```
  α = σ_min(∂W/∂F)
  ```

### 🧼 Noise-Robustness Studies

* Gaussian noise on proximal wrenches
* Tendon perturbation symmetry studies
* Degeneracy detection (proximal vs distal force equivalence)

---

## 📈 Key Results (Summary)

### ✔️ What Works Well

* Tapers eliminate fold-back degeneracies found in cylinders
* Unique mapping for a wider range of contact positions
* Strong improvement in position estimation

### ⚠️ What Still Needs Work

* Taper designs can be **highly noise-sensitive** at small s
* ΔW normalization amplifies noise when signals are small
* Cylinder sometimes matches taper performance when noise dominates

---

## 🧭 Roadmap

* [ ] Integrate JAX-FEM for faster differentiation
* [ ] Add GPU-accelerated multi-force estimation
* [ ] Implement helical/twisted geometries
* [ ] Create a unified surrogate-model pipeline
* [ ] Release dataset + benchmark suite

---

## 📝 Citation

If you use this repository in academic work, please cite:

```bibtex
@article{jones2025forceestimation,
  title={Bio-Inspired Force Estimation in Tendon-Driven Continuum Robots},
  author={Jones, Noah Loïc},
  journal={Under Review},
  year={2025}
}
```

---

## 💬 Contact

**Noah Loïc Jones**  
UC San Diego — Morimoto Lab  
📧 noahloicjones (at) gmail (dot) com  
🔗 GitHub: *your-username*  
🔗 LinkedIn: *your-linkedin-profile*

---

## 📄 License

[Add your license information here - e.g., MIT, Apache 2.0, etc.]
