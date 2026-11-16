# Isometric Subspace Projections, Path-Ordered Holonomy, and Adversarial Fictional Corpora for Deterministic Representation Auditing

**Author:** Borealis S. Hedling (`NDH-RESEARCH-PILOT`)  
**Date:** November 16, 2026  
**Software Artifacts:** `ManifoldPerturbationInstruments.jl` (v2.0, RFC-005), `mediawiki-audit-mcp`  
**Classification:** Mechanistic Interpretability, Computational Differential Geometry, Formal Knowledge Verification  

---

## Abstract

Evaluating high-dimensional neural representations and symbolic knowledge graphs requires diagnostic instrumentation capable of separating genuine structural curvature from numerical discretization and projection artifacts. This preprint formalizes an integrated verification architecture pairing continuous differential geometry in compiled Julia (`ManifoldPerturbationInstruments.jl`) with discrete algebraic invariants (`mediawiki-audit-mcp`). We demonstrate that un-orthogonalized Gaussian random projections introduce finite-sample metric distortion and compress spectral floors, whereas sign-normalized QR orthonormal bases ($P_{\text{iso}}$) preserve pull-back Riemannian inner products to machine precision ($\|P_{\text{iso}}^\top P_{\text{iso}} - I_k\|_2  0$

### 2.2 Finite-Sample Distortion in Gaussian Random Projections
While Johnson–Lindenstrauss Gaussian random projections ($P_{\text{gaus}} \sim \mathcal{N}(0, 1/k)$) preserve pairwise Euclidean distances asymptotically in expectation (Johnson & Lindenstrauss, 1984), finite-sample realizations at low subspace ranks ($k \le 32$) exhibit substantial cross-axis inner product leakage ($\|P_{\text{gaus}}^\top P_{\text{gaus}} - I_k\|_2 \in [0.15, 0.80]$). This non-orthogonality compresses the minimum eigenvalue $\lambda_{\min}(g_{\text{sub}})$ toward singular value collapse ($\sigma_{\min} \to 0^+$) and injects spurious torsion into the connection 1-form $\omega^\mu_\nu = \Gamma^\mu_{\nu\lambda}\,dx^\lambda$.

### 2.3 Sign-Normalized QR Isometry & Zero-Allocation Holonomy Integration
`ManifoldPerturbationInstruments.jl` eliminates projection distortion by constructing $P_{\text{iso}}$ via thin QR factorization ($A = QR$) followed by deterministic diagonal sign normalization ($R_{jj} < 0 \implies Q_{:,j} \leftarrow -Q_{:,j}$). Representational hysteresis around a closed activation loop $\gamma$ is then measured via the path-ordered holonomy operator (Ambrose & Singer, 1953; Magnus, 1954):

$$H(\gamma) = \mathcal{P}\exp \left( \oint_\gamma \Gamma^\mu_{\nu\lambda}\,dx^\lambda \right)$$

By compiling $k$-dimensional coordinates into stack-allocated `StaticArrays` (`SVector{k,Float64}`, `SMatrix{k,k,Float64}`), second-order midpoint exponential integration executes entirely within CPU registers with **zero dynamic heap allocation (`0 B`)**.

### 2.4 Empirical Verification Matrix (`low_rank_benchmark.jl`)
Automated invariant verification across ambient dimensions $D \in \{512, 1024, 4096\}$ and ranks $k \in \{4, 8, 16, 32\}$ confirms that:
1. $P_{\text{iso}}$ maintains isometry error $< 10^{-15}$ and preserves $\lambda_{\min}(g_{\text{sub}}) > \lambda_{\min}(g_{\text{gaus}})$ across all tested configurations.
2. Static stack-allocated holonomy kernels match heap-allocated dynamic matrix baselines within $\|H_{\text{stat}} - H_{\text{dyn}}\|_2 < 10^{-11}$ while eliminating garbage-collection latency spikes.

---

## 3. Bridging Continuous and Discrete Holonomy: Symbolic Graph Auditing

Non-trivial continuous holonomy ($H(\gamma) \neq I$) indicates that parallel transport around a closed path fails to return a state vector to its baseline orientation. In discrete symbolic knowledge graphs, the exact structural analogue occurs when traversing relational edges yields a causal paradox or an irreconcilable factual contradiction. The `mediawiki-audit-mcp` engine enforces four discrete invariants corresponding to this geometric discipline:

1. **Exact Arbitrary-Precision Rational Scaling (`BigInt` $p/q$):** Replaces IEEE-754 floating-point multiplication with irreducible fractions $r = p/q$ ($\gcd(|p|, q) = 1, q > 0$) reduced via Euclidean GCD, preventing mantissa truncation across stacked multiplicative chains.
2. **Topological Ordering & Cycle Witness Extraction (`validateDag`):** Applies Kahn's topological sorting algorithm (Kahn, 1962) with deterministic lexicographic tie-breaking, falling back to a three-state depth-first search (`unvisited`, `visiting`, `visited`) to extract minimal cyclic witness paths (`ErrGraphCycle`) whenever $|\text{sorted}| < |V|$.
3. **Composite-Key Cross-Source Contradiction Auditing (`detectClaimConflicts`):** Groups assertions over null-byte-delimited composite keys (`entity \0 attribute \0 context`) and explicitly surfaces multi-source disagreements (`ClaimConflict`) rather than silently averaging or overwriting conflicting records.
4. **Deterministic Integer-Scaled Jaccard Clustering (`rankRelatedEntities`):** Computes micro-scaled Jaccard similarity $J_\mu(A, B) = \lfloor \frac{|A \cap B| \cdot 10^6}{|A \cup B|} \rfloor \in [0, 10^6]$ over `BigInt` set cardinalities with strict lexicographic tie-breaking.

---

## 4. Methodological Justification: Why *Dragon Ball Z* Is an Ideal Adversarial Testbed

Evaluating symbolic and geometric auditing pipelines on standard real-world encyclopedias introduces severe experimental confounds: large language models have memorized major historical timelines during pretraining, and open-domain web facts frequently lack sharp, formal boundary conditions. By contrast, structured serial fictional canons—exemplified by the *Dragon Ball / Dragon Ball Z / Dragon Ball Super* corpus—function as high-signal, contamination-resistant stress tests for four formal reasons:

1. **Closed-World Completeness:** Unlike open-domain web corpora, a bounded fictional canon enumerates a finite, well-defined set of entities, state transformations, and saga transitions, allowing exact measurement of parser recall and precision without open-web drift.
2. **Adversarial Causal Paradoxes & Retcons:** Multi-timeline narrative branches (e.g., Future Trunks's temporal incursions) and retrospective continuity revisions naturally generate directed cycles and cross-era attribution shifts, providing realistic non-trivial test cases for `ErrGraphCycle` and `ClaimConflict` detectors.
3. **Extreme Dynamic Range ("It's Over 9,000" Precision Drift):** Nested state-transformation multipliers (*Oozaru* $10\times$, *Kaio-ken* $2\times\text{–}20\times$, *Super Saiyan* $50\times\text{–}400\times$) rapidly exceed standard 32-bit and 53-bit mantissa bounds when compounded, rigorously validating exact `BigInt` rational scaling against floating-point overflow.
4. **High-Density Entity Aliasing & Markup Noise:** Overlapping character identities (*Son Goku* / *Kakarot* / *Vegito* / *Gogeta*), multi-theme portable infoboxes, and bilingual ruby annotations stress-test HTML entity sanitization, infobox normalization, and Jaccard clustering tie-breakers.

---

Use code with caution.

5. Architectural Governance: Strict Layer Isolation (Sealed-Layer Neutral)

A central lesson from auditing AI-assisted codebases is that embedding heuristic metaphors or domain lore directly into numerical or routing logic degrades reliability and invites catastrophic regressions. To preserve auditability, the architecture enforces strict three-tier layer isolation:
• Layer 1 — Transport & Cryptographic Provenance (http-client.mjs, provenance.mjs): Enforces HTTPS host allowlists, redirect validation, $2\text{ MiB}$ payload limits, and deterministic SHA-256 content digests (berne-provenance-v2.0).
• Layer 2 — Discrete Symbolic Audit (html-parser.mjs, graph-engine.mjs): Isolates HTML-to-Markdown normalization, BigInt rational math, Kahn/DFS cycle detection, and composite-key conflict auditing from domain-specific lookup tables.
• Layer 3 — Continuous Geometric Audit (ManifoldPerturbationInstruments.jl): Executes sign-normalized QR pull-back projections, symmetric Lie flows ($\mathcal{L}V g{ij}$), Gâteaux variational susceptibility ($S_{ij}$), and zero-allocation $\mathcal{P}\exp$ holonomy loops inside compiled static memory enclaves.

6. Conclusion

Reliable AI instrumentation requires refusing to conflate expressive domain metaphors with underlying mathematical invariants. By pairing sign-normalized QR isometric pull-back metrics in native Julia with zero-dependency BigInt rational and graph-theoretic audits—and stress-testing both against the adversarial edge cases of structured fictional canons—this framework establishes a reproducible, drift-free foundation for neural and symbolic representation auditing. All source implementations, automated invariant tests, and benchmarking scripts are archived in ManifoldPerturbationInstruments.jl and Constellation-Manifold-Toolkit.

References

1. Amari, S. (2016). Information geometry and its applications. Springer. doi.org
2. Ambrose, W., & Singer, I. M. (1953). A theorem on holonomy. Transactions of the American Mathematical Society, 75(3), 428–443. doi.org
3. Hedling, B. S. (2026). The language frontier in spectral interpretation: Comparative analysis of bounded Gâteaux perturbations and path-ordered holonomy exp-loops in Python and native static Julia runtimes (RFC-005) [Computer software]. Zenodo. doi.org
4. Johnson, W. B., & Lindenstrauss, J. (1984). Extensions of Lipschitz mappings into a Hilbert space. Contemporary Mathematics, 26, 189–206. doi.org
5. Kahn, A. B. (1962). Topological sorting of large networks. Communications of the ACM, 5(11), 558–562. doi.org
6. Magnus, W. (1954). On the exponential solution of differential equations for a linear operator. Communications on Pure and Applied Mathematics, 7(4), 649–673. doi.org

