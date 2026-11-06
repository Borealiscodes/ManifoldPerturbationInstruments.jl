using LinearAlgebra

struct SymmetricLieEvolutionEngine
    alpha::Float64
    beta::Float64
end

function SymmetricLieEvolutionEngine()
    return SymmetricLieEvolutionEngine(0.5, 0.1)
end

function enforce_metric_symmetry(matrix::Matrix{Float64})::Matrix{Float64}
    return 0.5 .* (matrix + matrix')
end

function compute_metric_evolution_step(
    engine::SymmetricLieEvolutionEngine,
    base_metric::Matrix{Float64},
    ricci_tensor::Matrix{Float64},
    covariant_gradient_V::Matrix{Float64},
    forcing_tensor::Matrix{Float64},
    dt::Float64 = 0.01
)::Matrix{Float64}
    
    if size(base_metric) != size(ricci_tensor) || size(base_metric) != size(covariant_gradient_V)
        throw(DimensionMismatch("All input tensors must share uniform dimensionality."))
    end

    g_symmetric = enforce_metric_symmetry(base_metric)
    R_symmetric = enforce_metric_symmetry(ricci_tensor)
    F_symmetric = enforce_metric_symmetry(forcing_tensor)
    
    lie_derivative_g = covariant_gradient_V + covariant_gradient_V'
    
    dg_dt = -2.0 .* R_symmetric + engine.alpha .* lie_derivative_g + engine.beta .* F_symmetric
    evolved_metric = g_symmetric + dg_dt .* dt
    
    return enforce_metric_symmetry(evolved_metric)
end
