using LinearAlgebra

struct GateauxSusceptibilityEngine
    epsilon::Float64
    stability_floor::Float64
end

function GateauxSusceptibilityEngine()
    return GateauxSusceptibilityEngine(1e-6, 1e-5)
end

function evaluate_parameterized_metric(engine::GateauxSusceptibilityEngine, base_metric::Matrix{Float64}, V::Vector{Float64})::Matrix{Float64}
    magnitude_sq = dot(V, V)
    warp_factor = 1.0 / (1.0 + exp(-magnitude_sq))
    return base_metric .* max(warp_factor, engine.stability_floor)
end

function compute_susceptibility_tensor(
    engine::GateauxSusceptibilityEngine,
    base_metric::Matrix{Float64},
    V::Vector{Float64},
    delta_V::Vector{Float64}
)::Matrix{Float64}
    
    if size(base_metric, 1) != length(V) || length(V) != length(delta_V)
        throw(DimensionMismatch("Vector tracking parameters must match metric tensor dimensions."))
    end
    
    perturbed_V = V + engine.epsilon .* delta_V
    g_perturbed = evaluate_parameterized_metric(engine, base_metric, perturbed_V)
    g_base = evaluate_parameterized_metric(engine, base_metric, V)
    
    return (g_perturbed - g_base) ./ engine.epsilon
end
