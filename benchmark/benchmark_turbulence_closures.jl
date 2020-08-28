using Printf
using TimerOutputs
using Oceananigans
using Oceananigans.TurbulenceClosures
using Oceananigans.Utils

include("benchmark_utils.jl")

#####
##### Benchmark setup and parameters
#####

const timer = TimerOutput()

Nt = 10  # Number of iterations to use for benchmarking time stepping.

# Run benchmark across these parameters.
            Ns = [(32, 32, 32), (256, 256, 128)]
   float_types = [Float64]       # Float types to benchmark.
         archs = [CPU()]         # Architectures to benchmark on.
@hascuda archs = [CPU(), GPU()]  # Benchmark GPU on systems with CUDA-enabled GPUs.
      closures = [IsotropicDiffusivity, AnisotropicDiffusivity, SmagorinskyLilly,
	          VerstappenAnisotropicMinimumDissipation]

#####
##### Run benchmarks
#####

for arch in archs, FT in float_types, N in Ns, Closure in closures
	grid = RegularCartesianGrid(FT, size=N, extent=(1, 1, 1))
    model = IncompressibleModel(architecture=arch, float_type=FT, grid=grid, closure=Closure(FT))

    time_step!(model, 1)  # precompile

    bn =  benchmark_name(N, string(Closure), arch, FT)
    @printf("Running benchmark: %s...\n", bn)
    for i in 1:Nt
        @timeit timer bn time_step!(model, 1)
    end
end

#####
##### Print benchmark results
#####

println()
println(oceananigans_versioninfo())
println(versioninfo_with_gpu())
print_timer(timer, title="Turbulence closure benchmarks", sortby=:name)
println()
