module ManifoldPerturbationInstruments

using LinearAlgebra
using StaticArrays
using Plots

export BoundedVectorFieldPerturber, generate_directional_perturbation
export SymmetricLieEvolutionEngine, compute_metric_evolution_step
export GateauxSusceptibilityEngine, compute_susceptibility_tensor
export HolonomyDriftEngine, compute_loop_holonomy
export render_manifold_mesh

# Include separate structural module files
include("Tier1_VectorFields.jl")
include("Tier2_LieEvolution.jl")
include("Tier3_GateauxVariation.jl")
include("Tier4_HolonomyDrift.jl")
include("Visualizer.jl")

end # module
