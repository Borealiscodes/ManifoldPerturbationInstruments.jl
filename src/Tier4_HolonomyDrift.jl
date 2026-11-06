module Tier4_HolonomyDrift

using LinearAlgebra

export HolonomyDriftEngine, evaluate_connection_form, compute_loop_holonomy

struct HolonomyDriftEngine
    steps::Int
    radius::Float64
end

function HolonomyDriftEngine()
    return HolonomyDriftEngine(100, 1.0)
end

function evaluate_connection_form(engine::HolonomyDriftEngine, state::Vector{Float64})::Matrix{Float64}
    dim = length(state)
    connection_matrix = zeros(dim, dim)
    for i in 1:dim
        for j in 1:dim
            if i != j
                connection_matrix[i, j] = (state[mod1(i, dim)] - state[mod1(j, dim)]) * 0.05
            end
        end
    end
    return connection_matrix - connection_matrix'
end

function compute_loop_holonomy(engine::HolonomyDriftEngine, dim::Int)::Matrix{Float64}
    if dim < 2
        throw(ArgumentError("Holonomy loop tracking requires a space dimension >= 2."))
    end
    
    H = Matrix{Float64}(I, dim, dim)
    thetas = range(0, stop=2*pi, length=engine.steps)
    dt = 2*pi / engine.steps
    
    for t in thetas
        x = engine.radius * cos(t)
        y = engine.radius * sin(t)
        
        current_state = zeros(dim)
        current_state[1] = x
        current_state[2] = y
        
        dx = -engine.radius * sin(t) * dt
        dy = engine.radius * cos(t) * dt
        
        Gamma_matrix = evaluate_connection_form(engine, current_state)
        differential_operator = Gamma_matrix .* (dx + dy)
        H = exp_matrix_taylor(differential_operator) * H
    end
    return H
end

function exp_matrix_taylor(A::Matrix{Float64})::Matrix{Float64}
    dim = size(A, 1)
    I_mat = Matrix{Float64}(I, dim, dim)
    term = copy(I_mat)
    result = copy(I_mat)
    for i in 1:5
        term = (term * A) ./ i
        result += term
    end
    return result
end

end # module
