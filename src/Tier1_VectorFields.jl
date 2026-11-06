module Tier1_VectorFields

using StaticArrays
using LinearAlgebra

export BoundedVectorFieldPerturber, calculate_stability_scalar, generate_directional_perturbation

struct BoundedVectorFieldPerturber{N}
    stability_floor::Float64
    clamping_envelope::Float64
end

function BoundedVectorFieldPerturber(N::Int)
    return BoundedVectorFieldPerturber{N}(1e-5, 1e-12)
end

function calculate_stability_scalar(p::BoundedVectorFieldPerturber{N}, base_state::SVector{N, Float64}) where N
    magnitude = norm(base_state)
    D = 10.0 / (1.0 + magnitude)
    return max(D, p.stability_floor)
end

function generate_directional_perturbation(
    p::BoundedVectorFieldPerturber{N}, 
    base_state::SVector{N, Float64}, 
    target_direction::SVector{N, Float64}, 
    alpha::Float64
) where N
    raw_V_perturb = alpha .* target_direction
    perturb_magnitude = norm(raw_V_perturb)
    D = calculate_stability_scalar(p, base_state)
    
    if perturb_magnitude < D
        perturbed_state = base_state + raw_V_perturb
        boundary_intact = true
    else
        clamping_factor = (D - p.stability_floor) / (perturb_magnitude + p.clamping_envelope)
        sanitized_V_perturb = raw_V_perturb .* clamping_factor
        perturbed_state = base_state + sanitized_V_perturb
        boundary_intact = false
    end
    
    return perturbed_state, boundary_intact
end

end # module
