# low_rank_benchmark.jl
# Subspace Projection (QR Isometric vs. Gaussian Random), Pull-Back Metric & Holonomy Benchmark + Tests
# Usage: julia --project=. low_rank_benchmark.jl

using LinearAlgebra
using Random
using Printf
using StaticArrays
using Test

"""
    build_isometric_basis(D::Int, k::Int; seed::Int=42) -> Matrix{Float64}

Constructs a deterministic D x k orthonormal basis P (P' * P = I_k) via QR decomposition
so ambient inner products and Riemannian distances are preserved exactly in the k-subspace.
"""
function build_isometric_basis(D::Int, k::Int; seed::Int=42)
    @assert 1 <= k <= D "Subspace rank k ($k) must satisfy 1 <= k <= D ($D)"
    rng = MersenneTwister(seed)
    raw = randn(rng, D, k)
    F = qr(raw)
    Q = Matrix(F.Q)
    for j in 1:k
        if F.R[j, j] < 0
            Q[:, j] .= -Q[:, j]
        end
    end
    return Q
end

"""
    build_gaussian_basis(D::Int, k::Int; seed::Int=42) -> Matrix{Float64}

Constructs a Johnson-Lindenstrauss Gaussian random projection matrix P ~ N(0, 1/k)
without QR orthonormalization, illustrating finite-sample metric distortion.
"""
function build_gaussian_basis(D::Int, k::Int; seed::Int=42)
    @assert 1 <= k <= D "Subspace rank k ($k) must satisfy 1 <= k <= D ($D)"
    rng = MersenneTwister(seed)
    return randn(rng, D, k) ./ sqrt(k)
end

"""
    build_ambient_metric(D::Int; seed::Int=7) -> Matrix{Float64}

Constructs a deterministic, curved Symmetric Positive-Definite (SPD) ambient metric tensor g_ambient.
"""
function build_ambient_metric(D::Int; seed::Int=7)
    rng = MersenneTwister(seed)
    M = randn(rng, D, D) ./ sqrt(D)
    g = I + 0.15 * (M' * M)
    return 0.5 * (g + g')
end

"""
    analyze_pullback_metric(P::Matrix{Float64}, g_ambient::Matrix{Float64}; strict_iso::Bool=true)

Computes the pull-back metric g_sub = P' * g_ambient * P as a static SMatrix{K,K}
and evaluates isometry error, index symmetry, and minimum eigenvalue λ_min(g_sub).
"""
function analyze_pullback_metric(P::Matrix{Float64}, g_ambient::Matrix{Float64}; strict_iso::Bool=true)
    _, k = size(P)
    iso_err = opnorm(P' * P - I(k))
    if strict_iso
        @assert iso_err < 1e-12 "Isometric basis P failed orthonormality check (err = $iso_err)"
    end

    g_sub_dyn = P' * g_ambient * P
    sym_err = opnorm(g_sub_dyn - g_sub_dyn')
    @assert sym_err < 1e-12 "Pull-back metric violated index symmetry (err = $sym_err)"

    g_sub_exact = 0.5 * (g_sub_dyn + g_sub_dyn')
    g_sub = SMatrix{k,k,Float64}(g_sub_exact)
    min_eig = eigmin(Symmetric(Matrix(g_sub)))
    @assert min_eig > 0.0 "Pull-back metric lost positive-definiteness (λ_min = $min_eig)"

    return (g_sub = g_sub, iso_err = iso_err, sym_err = sym_err, min_eig = min_eig)
end

"""
    connection_contraction_static(x::SVector{K,Float64}, dx::SVector{K,Float64}, g_sub::SMatrix{K,K,Float64}) -> SMatrix{K,K,Float64}

Zero-allocation metric-weighted Christoffel contraction Γ^μ_{νλ} dx^λ evaluated on stack-allocated SVectors.
"""
@inline function connection_contraction_static(
    x::SVector{K,Float64},
    dx::SVector{K,Float64},
    g_sub::SMatrix{K,K,Float64}
) where {K}
    g_dx = g_sub * dx
    s = dot(x, g_dx) * 0.05
    return SMatrix{K,K,Float64}(
        (i == j ? 0.0 : 0.01 * (x[i] * g_dx[j] - x[j] * g_dx[i]) + 0.002 * s * (dx[i] - dx[j]))
        for i in 1:K, j in 1:K
    )
end

"""
    holonomy_loop_static(trajectory::Vector{SVector{K,Float64}}, g_sub::SMatrix{K,K,Float64}) -> SMatrix{K,K,Float64}

Evaluates path-ordered holonomy H(γ) = P exp(∮ Γ^μ_{νλ} dx^λ) under the pull-back metric g_sub
with zero heap allocations.
"""
function holonomy_loop_static(
    trajectory::Vector{SVector{K,Float64}},
    g_sub::SMatrix{K,K,Float64}
) where {K}
    H = one(SMatrix{K,K,Float64})
    n = length(trajectory)
    @inbounds for idx in 1:n
        x0 = trajectory[idx]
        x1 = trajectory[idx == n ? 1 : idx + 1]
        dx = x1 - x0
        x_mid = 0.5 * (x0 + x1)
        A_mid = connection_contraction_static(x_mid, dx, g_sub)
        step_exp = one(SMatrix{K,K,Float64}) + A_mid + 0.5 * (A_mid * A_mid)
        H = step_exp * H
    end
    return H
end

"""
    holonomy_loop_dynamic(trajectory::Vector{Vector{Float64}}, g_sub_dyn::Matrix{Float64}) -> Matrix{Float64}

Heap-allocated baseline implementation using standard Julia Matrix/Vector buffers.
"""
function holonomy_loop_dynamic(trajectory::Vector{Vector{Float64}}, g_sub_dyn::Matrix{Float64})
    K = length(trajectory[1])
    H = Matrix{Float64}(I, K, K)
    A_mid = zeros(Float64, K, K)
    A_sq = zeros(Float64, K, K)
    step_exp = zeros(Float64, K, K)
    x_mid = zeros(Float64, K)
    dx = zeros(Float64, K)
    g_dx = zeros(Float64, K)

    n = length(trajectory)
    for idx in 1:n
        x0 = trajectory[idx]
        x1 = trajectory[idx == n ? 1 : idx + 1]
        @. dx = x1 - x0
        @. x_mid = 0.5 * (x0 + x1)
        mul!(g_dx, g_sub_dyn, dx)
        s = dot(x_mid, g_dx) * 0.05

        @inbounds for j in 1:K, i in 1:K
            if i == j
                A_mid[i, j] = 0.0
            else
                A_mid[i, j] = 0.01 * (x_mid[i] * g_dx[j] - x_mid[j] * g_dx[i]) + 0.002 * s * (dx[i] - dx[j])
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

function run_benchmark_and_tests()
    println("=== ManifoldPerturbationInstruments.jl: Pull-Back Metric & Holonomy Verification ===")
    ambient_dims = [512, 1024, 4096]
    subspace_ranks = [4, 8, 16, 32]
    n_segments = 64

    @testset "Low-Rank Subspace Projection & Holonomy Invariants" begin
        for D in ambient_dims
            println("\nAmbient Dimension D = $D | Loop Segments = $n_segments")
            @printf("%-6s | %-10s | %-11s | %-11s | %-11s | %-11s | %-11s | %-8s\n",
                    "Rank k", "QR IsoErr", "Gaus IsoErr", "λ_min(QR)", "λ_min(Gaus)", "Static (ns)", "Speedup", "Alloc")
            println("-"^102)

            rng = MersenneTwister(101)
            ambient_loop = [randn(rng, D) for _ in 1:n_segments]
            g_ambient = build_ambient_metric(D; seed=7)

            @testset "Ambient D = $D" begin
                for k in subspace_ranks
                    P_iso = build_isometric_basis(D, k; seed=42)
                    pb_iso = analyze_pullback_metric(P_iso, g_ambient; strict_iso=true)

                    P_gaus = build_gaussian_basis(D, k; seed=42)
                    pb_gaus = analyze_pullback_metric(P_gaus, g_ambient; strict_iso=false)

                    # 1. Isometric & Spectral Invariant Assertions
                    @test pb_iso.iso_err < 1e-12
                    @test pb_iso.sym_err < 1e-12
                    @test pb_iso.min_eig > 0.0
                    @test pb_gaus.iso_err > pb_iso.iso_err
                    @test pb_gaus.min_eig < pb_iso.min_eig

                    dyn_loop_iso = [P_iso' * v for v in ambient_loop]
                    stat_loop_iso = [SVector{k,Float64}(v) for v in dyn_loop_iso]
                    stat_loop_gaus = [SVector{k,Float64}(P_gaus' * v) for v in ambient_loop]

                    # 2. Static vs. Dynamic Holonomy Parity & Finite Stability
                    H_stat_iso = holonomy_loop_static(stat_loop_iso, pb_iso.g_sub)
                    H_dyn_iso = holonomy_loop_dynamic(dyn_loop_iso, Matrix(pb_iso.g_sub))
                    H_stat_gaus = holonomy_loop_static(stat_loop_gaus, pb_gaus.g_sub)

                    @test isapprox(Matrix(H_stat_iso), H_dyn_iso; atol=1e-11)
                    @test all(isfinite, H_stat_gaus)
                    @test opnorm(Matrix(H_stat_gaus) - Matrix(H_stat_iso)) > 0.0

                    # 3. Zero Heap Allocation Invariant
                    alloc_bytes = @allocated holonomy_loop_static(stat_loop_iso, pb_iso.g_sub)
                    @test alloc_bytes == 0

                    best_stat_ns = typemax(UInt64)
                    best_dyn_ns = typemax(UInt64)
                    for _ in 1:500
                        t0 = time_ns()
                        holonomy_loop_static(stat_loop_iso, pb_iso.g_sub)
                        dt_s = time_ns() - t0
                        if dt_s < best_stat_ns
                            best_stat_ns = dt_s
                        end

                        t1 = time_ns()
                        holonomy_loop_dynamic(dyn_loop_iso, Matrix(pb_iso.g_sub))
                        dt_d = time_ns() - t1
                        if dt_d < best_dyn_ns
                            best_dyn_ns = dt_d
                        end
                    end

                    speedup = best_dyn_ns / max(best_stat_ns, 1)
                    @printf("%-6d | %-10.2e | %-11.4f | %-11.4f | %-11.4f | %-11d | %-10.2fx | %d B\n",
                            k, pb_iso.iso_err, pb_gaus.iso_err, pb_iso.min_eig, pb_gaus.min_eig,
                            best_stat_ns, speedup, alloc_bytes)
                end
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmark_and_tests()
end
