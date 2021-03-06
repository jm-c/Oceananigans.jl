struct FFTBasedPoissonSolver{A, G, E, S, B, T}
    architecture :: A
            grid :: G
     eigenvalues :: E
         storage :: S
          buffer :: B
      transforms :: T
end

function FFTBasedPoissonSolver(arch, grid, planner_flag=FFTW.PATIENT)
    topo = (TX, TY, TZ) =  topology(grid)

    λx = poisson_eigenvalues(grid.Nx, grid.Lx, 1, TX())
    λy = poisson_eigenvalues(grid.Ny, grid.Ly, 2, TY())
    λz = poisson_eigenvalues(grid.Nz, grid.Lz, 3, TZ())

    eigenvalues = (
        λx = arch_array(arch, λx),
        λy = arch_array(arch, λy),
        λz = arch_array(arch, λz)
    )

    storage = arch_array(arch, zeros(complex(eltype(grid)), size(grid)...))

    transforms = plan_transforms(arch, grid, storage, planner_flag)

    # Need buffer for index permutations and transposes.
    buffer_needed = arch isa GPU && Bounded in topo ? true : false
    buffer = buffer_needed ? similar(storage) : nothing

    return FFTBasedPoissonSolver(arch, grid, eigenvalues, storage, buffer, transforms)
end
