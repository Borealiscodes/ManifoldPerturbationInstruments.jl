using Test
using StaticArrays
using LinearAlgebra
using ManifoldPerturbationInstruments

@testset "Manifold Invariant Verification Suite" begin

    @testset "Tier 1: Bounded Vector Fields" begin
        perturber = BoundedVectorFieldPerturber(4)
        base = SVector{4, Float64}(0.0, 0.0, 0.0, 0.0)
        dir = SVector{4, Float64}(0.5, 0.5, 0.5, 0.5)
        
        state, intact = generate_directional_perturbation(perturber, base, dir, 0.1)
        @test intact == true
        @test norm(state) > 0.0
    end

    @testset "Tier 2: Symmetric Lie Derivatives" begin
        engine = SymmetricLieEvolutionEngine()
        g0 = [1.0 0.0; 0.0 1.0]
        R  = [0.1 0.2; 0.4 0.1] 
        grad = [0.05 0.1; 0.2 0.05]
        F  = [1.0 0.0; 0.0 1.0]
        
        g_next = compute_metric_evolution_step(engine, g0, R, grad, F, 0.01)
        @test g_next == g_next' # Enforces exact symmetry preservation
    end

    @testset "Tier 3: Gâteaux Variations" begin
        engine = GateauxSusceptibilityEngine()
        g0 = [1.0 0.0; 0.0 1.0]
        V = [1.0, -0.5]
        dV = [0.1, 0.2] # Truncation vulnerability permanently patched
        
        S = compute_susceptibility_tensor(engine, g0, V, dV)
        @test size(S) == (2, 2)
    end

    @testset "Tier 4: Path-Ordered Holonomy" begin
        engine = HolonomyDriftEngine()
        H = compute_loop_holonomy(engine, 3)
        @test det(H) > 0.0
    end
end
