module ManifoldPerturbationInstruments

using LinearAlgebra
using StaticArrays
using Plots

export BoundedVectorFieldPerturber, calculate_stability_scalar, generate_directional_perturbation
export SymmetricLieEvolutionEngine, compute_metric_evolution_step, enforce_metric_symmetry
export GateauxSusceptibilityEngine, compute_susceptibility_tensor, evaluate_parameterized_metric
export HolonomyDriftEngine, evaluate_connection_form, compute_loop_holonomy
export render_manifold_mesh

# Load individual mathematical components
include("Tier1_VectorFields.jl")
include("Tier2_LieEvolution.jl")
include("Tier3_GateauxVariation.jl")
include("Tier4_HolonomyDrift.jl")
include("Visualizer.jl")

end # module
