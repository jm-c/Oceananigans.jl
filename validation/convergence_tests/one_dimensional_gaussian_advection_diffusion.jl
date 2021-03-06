if haskey(ENV, "CI") && ENV["CI"] == "true"
    ENV["PYTHON"] = ""
    using Pkg
    Pkg.build("PyCall")
end

using Test
using CUDA
using PyPlot
using Oceananigans

using ConvergenceTests
using ConvergenceTests.OneDimensionalGaussianAdvectionDiffusion: run_test
using ConvergenceTests.OneDimensionalUtils: plot_solutions!, plot_error_convergence!, unpack_errors

""" Run advection-diffusion test for all Nx in resolutions. """
function run_convergence_test(κ, U, resolutions, arch)

    # Determine safe time-step
           Lx = 2.5
    stop_time = 0.25
            h = Lx / maximum(resolutions)
           Δt = min(0.1 * h / U, 0.01 * h^2 / κ)

    # Adjust time-step
    stop_iteration = round(Int, stop_time / Δt)
                Δt = stop_time / stop_iteration

    # Run the tests
    results = [run_test(architecture=arch, Nx=Nx, Δt=Δt, stop_iteration=stop_iteration, U=U, κ=κ, width=0.1)
               for Nx in resolutions]

    return results
end

#####
##### Run test
#####

arch = CUDA.has_cuda() ? GPU() : CPU()

Nx = 2 .^ (6:8) # N = 64 through N = 256
diffusion_results = run_convergence_test(1e-1, 0, Nx, arch)
advection_results = run_convergence_test(1e-6, 3, Nx, arch)
advection_diffusion_results = run_convergence_test(1e-2, 1, Nx, arch)

#####
##### Plot solution and error profile
#####

all_results = (diffusion_results, advection_results, advection_diffusion_results)
names = ("diffusion only", "advection only", "advection-diffusion")
linestyles = ("-", "--", ":")
specialcolors = ("xkcd:black", "xkcd:indigo", "xkcd:wine red")

# Solutions
close("all")

fig, axs = subplots(nrows=2, figsize=(12, 6), sharex=true)

legends = plot_solutions!(axs, all_results, names, linestyles, specialcolors)

filename = "gaussian_advection_diffusion_solutions_$(typeof(arch)).png"
filepath = joinpath(@__DIR__, "figs", filename)
mkpath(dirname(filepath))
savefig(filepath, dpi=480, bbox_extra_artists=legends, bbox_inches="tight")

# Error profile
fig, axs = subplots()

legend = plot_error_convergence!(axs, Nx, all_results, names)

filename = "gaussian_advection_diffusion_error_convergence_$(typeof(arch)).png"
filepath = joinpath(@__DIR__, "figs", filename)
mkpath(dirname(filepath))
savefig(filepath, dpi=480, bbox_extra_artists=(legend,), bbox_inches="tight")

# Test rate of convergence
for (results, name) in zip(all_results, names)
    atol_L₁, atol_L∞ =
        name == "diffusion only" ? (0.06, 0.01) :
        name == "advection only" ? (0.02, 0.10) :
        name == "advection-diffusion" ? (0.01, 0.02) : nothing

    name = "1D Gaussian " * name
    @info "Testing rate of convergence for $name..."

    cx_L₁, cy_L₁, cz_L₁,
           uy_L₁, uz_L₁,
    vx_L₁,        vz_L₁,
    wx_L₁, wy_L₁,
    cx_L∞, cy_L∞, cz_L∞,
           uy_L∞, uz_L∞,
    vx_L∞,        vz_L∞,
    wx_L∞, wy_L∞         = unpack_errors(results)

    test_rate_of_convergence(uy_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" ux_L₁")
    test_rate_of_convergence(uz_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" uz_L₁")
    test_rate_of_convergence(vx_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" vx_L₁")
    test_rate_of_convergence(vz_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" vz_L₁")
    test_rate_of_convergence(wx_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" wx_L₁")
    test_rate_of_convergence(wy_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" wy_L₁")
    test_rate_of_convergence(cx_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" cx_L₁")
    test_rate_of_convergence(cy_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" cy_L₁")
    test_rate_of_convergence(cz_L₁, Nx, expected=-2.0, atol=atol_L₁, name=name*" cz_L₁")

    test_rate_of_convergence(uy_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" ux_L∞")
    test_rate_of_convergence(uz_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" uz_L∞")
    test_rate_of_convergence(vx_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" vx_L∞")
    test_rate_of_convergence(vz_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" vz_L∞")
    test_rate_of_convergence(wx_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" wx_L∞")
    test_rate_of_convergence(wy_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" wy_L∞")
    test_rate_of_convergence(cx_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" cx_L∞")
    test_rate_of_convergence(cy_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" cy_L∞")
    test_rate_of_convergence(cz_L∞, Nx, expected=-2.0, atol=atol_L∞, name=name*" cz_L∞")

    @test uy_L₁ ≈ uz_L₁ ≈ vx_L₁ ≈ vz_L₁ ≈ wx_L₁ ≈ wy_L₁ ≈ cx_L₁ ≈ cy_L₁ ≈ cz_L₁
    @test uy_L∞ ≈ uz_L∞ ≈ vx_L∞ ≈ vz_L∞ ≈ wx_L∞ ≈ wy_L∞ ≈ cx_L∞ ≈ cy_L∞ ≈ cz_L∞
end
