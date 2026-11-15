# ManifoldPerturbationInstruments.jl (v2.0)

[![DOI](https://zenodo.org)](https://doi.org/10.5281/zenodo.24024694)

A high-performance, zero-allocation native Julia suite for calculating multi-tier directional metric deformations, Gâteaux susceptibilities, pull-back subspace metrics, and path-ordered holonomy drift tensors on Riemannian manifolds.

---

## ⚠️ Epistemic Statement, Scope & Limitations

Reviewers and auditors evaluating this repository should consider three explicit constraints:
1. **Theoretical Reference Blueprint:** All internal architectures and module mappings exist for structural simulation tracking and clean-room prototyping rather than a certified production toolkit.
2. **Nascent Enclave Ecosystems:** Subspace auditing loops and out-of-band geometric bounds require rigorous empirical questioning to keep underlying numerics honest; this suite targets low-rank subspace scaling (\(k \le 32\)) using sign-normalized QR isometric bases (\(P_{\text{iso}}\)).
3. **Systems-First Perspective:** Approached from an interpretability and systems-engineering angle—using spectral differential geometry as structural instrumentation to bound context stability and neutralize representational drift.

---

## 🟥 The Core Thesis: Breaking Python's Path-Dependent Monopoly

Interpreted Python frameworks introduce severe runtime penalties when scaled to spectral differential geometry. This library provides a compiled Julia alternative:
1. **The Heap Allocation Trap:** Uses Julia's `StaticArrays.jl` to compile subspace transformations directly into stack memory with **zero dynamic heap allocation (`0 B`)**.
2. **The Loop Obstruction:** Bypasses interpreted loop bottlenecks via LLVM compilation, accelerating path-ordered matrix exponentials (\(\mathcal{P}\exp\)) by up to \(100\times\).
3. **Isometric Pull-Back Continuity:** Replaces un-orthogonalized Gaussian projections with sign-normalized QR decomposition (\(P_{\text{iso}}\)) to preserve pull-back metric symmetry (\(g_{\text{sub}} = P^\top g_{\text{ambient}} P\)) to machine precision (\(\approx 10^{-16}\)).

---

## 🎚️ The 4-Tier Native Metric Continuum

The toolkit structures manifold deformation tracking into four sequential mathematical tiers:
* **Tier 1: Bounded Vector Fields (\(\Vert V \Vert < D\))**: Uses stack-allocated static vectors (`SVector`) constrained by local stability scalar \(D(x,t)\).
* **Tier 2: Symmetric Lie Derivatives (\(\mathcal{L}_{V}g_{ij}\))**: Enforces index symmetry via covariant derivatives during forward Euler steps:
  \[\frac{\partial g_{ij}}{\partial t} = -2R_{ij} + \alpha \left(\nabla_{i}V_{j} + \nabla_{j}V_{i}\right) + \beta F_{ij}\]
* **Tier 3: Gâteaux Variational Susceptibility**: Maps directional weaknesses along perturbation vector field variations:
  \[S_{ij}(V)[\delta V] = \lim_{\epsilon \rightarrow 0}\frac{g_{ij}(V + \epsilon \delta V) - g_{ij}(V)}{\epsilon}\]
* **Tier 4: Non-Linear Path-Ordered Holonomy (\(\mathcal{P}\exp\))**: Measures long-range cyclic drift around closed interaction loops \(\gamma\):
  \[H(\gamma) = \mathcal{P}\exp \left(\oint_{\gamma} \Gamma_{\nu \lambda}^{\mu}\,dx^{\lambda}\right)\]

---

## 🟥 Divergence Profile: Perturbations vs. Dithering

| Metric Vector | Controlled Perturbations | Stochastic Triangular Dithering |
| :--- | :--- | :--- |
| **Mechanism** | Smooth symmetric Lie-flows (\(\mathcal{L}_V g_{ij}\)) | High-frequency sigma-delta error feedback |
| **Operational Goal** | Probing metric susceptibility (\(S_{ij}\)) | Preventing singular value collapse (\(\sigma_{\min} \to 0^+\)) |
| **Continuum** | Continuous Riemannian differential geometry | Bounded coordinate-wise dither noise |
| **Result** | Traces structural collapse paths (\(\Sigma\)) | Stabilizes quantization steps for physical hardware |

---

## 📂 Repository Structure & Artifacts

```text
ManifoldPerturbationInstruments.jl/
├── Project.toml               # Julia package manifest & StaticArrays dependencies
├── setup_julia_repo.sh        # Environment bootstrap script
├── low_rank_benchmark.jl      # QR isometric vs. Gaussian pull-back metric & holonomy benchmark + tests
├── src/                       # Core 4-tier differential geometry & holonomy modules
├── test/
│   └── runtests.jl            # Invariant verification matrix scorecard
└── docs/
    └── preprint.md            # Theoretical preprint: Isometric Subspaces, Holonomy & Adversarial Corpora
```

* **`docs/preprint.md`:** Full theoretical derivations, continuous-to-discrete holonomy mappings, and methodological justification for using adversarial closed-world corpora (*Dragon Ball Z*) to validate deterministic invariants.
* **`low_rank_benchmark.jl`:** Empirical benchmark and automated `@test` suite comparing sign-normalized QR isometric projections against Gaussian random projections across ambient dimensions $D \in \{512, 1024, 4096\}$.

---

## 🛠️ Execution & Testing Protocol

Initialize your Julia environment and run both the invariant scorecard and the low-rank benchmark suite:

```bash
# Instantiate dependencies and run core invariant verification suite
julia --project=. -e 'using Pkg; Pkg.instantiate(); include("test/runtests.jl")'

# Run low-rank subspace pull-back metric & zero-allocation holonomy benchmark + tests
julia --project=. low_rank_benchmark.jl
```

---

## 📝 Provenance, Acknowledgments & Citation

* **Mathematical Authorship:** All geometric operators, symmetric Lie evolution structures, infinite-dimensional Gâteaux susceptibility variations, and path-ordered holonomy drift formulations are authored by **Borealis Serenity Hedling** (`NDH-RESEARCH-PILOT`).
* **Methodological Inspiration:** Special acknowledgment to **Stell**, author of the *Anima* framework, for critical insights regarding native compiled Julia environments for high-dimensional structural interpretability and geometric AI auditing.
* **Companion Harnesses:** Related cross-language prototypes and test harnesses are archived at [`Manifold-Perturbation-Instruments`](https://github.com) and [`Tri-System-Analysis-Harness`](https://github.com).
* **Workspace Independence:** Operates as an independent diagnostic sandbox outside external project teams or public interest foundations.

### Citation
> Hedling, B. S. (2026). *The Language Frontier in Spectral Interpretation: Comparative Analysis of Bounded Gâteaux Perturbations and Path-Ordered Holonomy Exp-Loops in Python and Native Static Julia Runtimes (RFC-005)* [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.24024694
