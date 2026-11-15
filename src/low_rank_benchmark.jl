# low_rank_benchmark.jl
# Subspace Projection & Path-Ordered Holonomy Benchmark for ManifoldPerturbationInstruments.jl
# Usage: julia --project=. low_rank_benchmark.jl

using LinearAlgebra
using Random
using Printf
using StaticArrays

"""
    build_isometric_basis(D::Int, k::Int; seed::Int=42) -> Matrix{Float64}

Constructs a deterministic D x k orthonormal basis P (P' * P ≈ I_k) via QR decomposition
so ambient inner products and Riemannian distances are preserved in the k-dimensional subspace.
"""
function build_isometric_basis(D::Int, k::Int; seed::Int=42)
    @assert 1 <= k <= D "Subspace rank k ($k) must satisfy 1 <= k <= D ($D)"
    rng = MersenneTwister(seed)
    raw = randn(rng, D, k)
    F = qr(raw)
    Q = Matrix(F.Q)
    # Deterministic sign normalization so QR columns are unique across BLAS implementations
    for j in 1:k
        if F.R[j, j] < 0
            Q[:, j] .= -Q[:, j]
        end
    end
    return Q
end

"""
    connection_contraction_static(x::SVector{K,Float64}, dx::SVector{K,Float64}) -> SMatrix{K,K,Float64}

Zero-allocation synthetic Christoffel contraction Γ^μ_{νλ} dx^λ evaluated on stack-allocated SVectors.
"""
@inline function connection_contraction_static(x::SVector{K,Float64}, dx::SVector{K,Float64}) where {K}
    s = sum(x) * 0.05
    return SMatrix{K,K,Float64}(
        (i == j ? 0.0 : 0.01 * (x[i] * dx[j] - x[j] * dx[i]) + 0.002 * s * (dx[i] - dx[j]))
        for i in 1:K, j in 1:K
    )
end

"""
    holonomy_loop_static(trajectory::Vector{SVector{K,Float64}}) -> SMatrix{K,K,Float64}

Evaluates path-ordered holonomy H(γ) = P exp(∮ Γ^μ_{νλ} dx^λ) along a closed k-dimensional loop
using a second-order midpoint exponential step with zero heap allocations.
"""
function holonomy_loop_static(trajectory::Vector{SVector{K,Float64}}) where {K}
    H = one(SMatrix{K,K,Float64})
    n = length(trajectory)
    @inbounds for idx in 1:n
        x0 = trajectory[idx]
        x1 = trajectory[idx == n ? 1 : idx + 1]
        dx = x1 - x0
        x_mid = 0.5 * (x0 + x1)
        A_mid = connection_contraction_static(x_mid, dx)
        # 2nd-order Taylor step for exp(A_mid) to keep stack unrolling fast
        step_exp = one(SMatrix{K,K,Float64}) + A_mid + 0.5 * (A_mid * A_mid)
        H = step_exp * H
    end
    return H
end

"""
    holonomy_loop_dynamic(trajectory::Vector{Vector{Float64}}) -> Matrix{Float64}

Heap-allocated baseline implementation using standard Julia Matrix/Vector buffers.
"""
function holonomy_loop_dynamic(trajectory::Vector{Vector{Float64}})
    K = length(trajectory[1])
    H = Matrix{Float64}(I, K, K)
    A_mid = zeros(Float64, K, K)
    A_sq = zeros(Float64, K, K)
    step_exp = zeros(Float64, K, K)
    x_mid = zeros(Float64, K)
    dx = zeros(Float64, K)

    n = length(trajectory)
    for idx in 1:n
        x0 = trajectory[idx]
        x1 = trajectory[idx == n ? 1 : idx + 1]
        @. dx = x1 - x0
        @. x_mid = 0.5 * (x0 + x1)
        s = sum(x_mid) * 0.05

        @inbounds for j in 1:K, i in 1:K
            if i == j
                A_mid[i, j] = 0.0
            else
                A_mid[i, j] = 0.01 * (x_mid[i] * dx[j] - x_mid[j] * dx[i]) + 0.002 * s * (dx[i] - dx[j])
            end
        end

        mul!(A_sq, A_mid, A_mid)
        @inbounds for j in 1:K, i in 1:K
            step_exp[i, j] = (i == j ? 1.0 : 0.0) + A_mid[i, j] + 0.5 * A_sq[i, j]
        end
        H = step_exp * H
    end
    return H
end

function run_benchmark()
    println("=== ManifoldPerturbationInstruments.jl: Low-Rank Holonomy Benchmark ===")
    ambient_dims = [512, 4096]
    subspace_ranks = [4, 8, 16, 32]
    n_segments = 64

    for D in ambient_dims
        println("\nAmbient Transformer Dimension D = $D | Loop Segments = $n_segments")
        @printf("%-8s | %-14s | %-14s | %-14s | %-14s | %-10s\n",
                "Rank k", "Compile (ms)", "Static (ns)", "Dynamic (ns)", "Speedup", "Static Alloc")
        println("-"^88)

        rng = MersenneTwister(101)
        ambient_loop = [randn(rng, D) for _ in 1:n_segments]

        for k in subspace_ranks
            P = build_isometric_basis(D, k; seed=42)
            # Project D-dimensional ambient activations onto k-dimensional orthonormal enclave
            dyn_loop = [P' * v for v in ambient_loop]
            stat_loop = [SVector{k,Float64}(v) for v in dyn_loop]

            # Measure first-call LLVM compilation time for SVector{k}
            t_comp_start = time_ns()
            H_stat = holonomy_loop_static(stat_loop)
            compile_ms = (time_ns() - t_comp_start) / 1e6

            # Warmup dynamic
            H_dyn = holonomy_loop_dynamic(dyn_loop)
            @assert isapprox(Matrix(H_stat), H_dyn; atol=1e-11) "Static vs Dynamic holonomy mismatch!"

            # Measure steady-state allocations and minimum latency across 500 runs
            alloc_bytes = @allocated holonomy_loop_static(stat_loop)

            best_stat_ns = typemax(UInt64)
            best_dyn_ns = typemax(UInt64)
            for _ in 1:500
                t0 = time_ns()
                holonomy_loop_static(stat_loop)
                dt_s = time_ns() - t0
                if dt_s < best_stat_ns
                    best_stat_ns = dt_s
                end

                t1 = time_ns()
                holonomy_loop_dynamic(dyn_loop)
                dt_d = time_ns() - t1
                if dt_d < best_dyn_ns
                    best_dyn_ns = dt_d
                end
            end

            speedup = best_dyn_ns / max(best_stat_ns, 1)
            @printf("%-8d | %-14.2f | %-14d | %-14d | %-13.2fx | %d B\n",
                    k, compile_ms, best_stat_ns, best_dyn_ns, speedup, alloc_bytes)
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmark()
end
