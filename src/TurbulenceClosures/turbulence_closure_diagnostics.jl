# Timescale for diffusion across one cell
min_Δxyz(grid) = min(grid.Δx, grid.Δy, grid.Δz)
min_Δxy(grid) = min(grid.Δx, grid.Δy)

min_Δx(grid) = grid.Δx
min_Δy(grid) = grid.Δy
min_Δz(grid) = grid.Δz

cell_diffusion_timescale(model) = cell_diffusion_timescale(model.closure, model.diffusivities, model.grid)
cell_diffusion_timescale(::Nothing, diffusivities, grid) = Inf

maximum_numeric_diffusivity(κ::Number) = κ
maximum_numeric_diffusivity(κ::NamedTuple) = maximum(κ)
maximum_numeric_diffusivity(κ::NamedTuple{()}) = 0 # tracers=nothing means empty diffusivity tuples

# As the name suggests, we give up in the case of a function diffusivity
maximum_numeric_diffusivity(κ::Function) = 0


function cell_diffusion_timescale(closure::IsotropicDiffusivity, diffusivities, grid)
    Δ = min_Δxyz(grid)
    max_κ = maximum_numeric_diffusivity(closure.κ)
    max_ν = maximum_numeric_diffusivity(closure.ν)
    return min(Δ^2 / max_ν, Δ^2 / max_κ)
end

function cell_diffusion_timescale(closure::AnisotropicDiffusivity, diffusivities, grid)

    Δx = min_Δx(grid)
    Δy = min_Δy(grid)
    Δz = min_Δz(grid)

    max_νx = maximum_numeric_diffusivity(closure.νx)
    max_νy = maximum_numeric_diffusivity(closure.νy)
    max_νz = maximum_numeric_diffusivity(closure.νz)

    max_κx = maximum_numeric_diffusivity(closure.κx)
    max_κy = maximum_numeric_diffusivity(closure.κy)
    max_κz = maximum_numeric_diffusivity(closure.κz)

    return min(Δx^2 / max_νx,
               Δy^2 / max_νy,
               Δz^2 / max_νz,
               Δx^2 / max_κx,
               Δy^2 / max_κy,
               Δz^2 / max_κz)
end

function cell_diffusion_timescale(closure::AnisotropicBiharmonicDiffusivity, diffusivities, grid)
    Δx = min_Δx(grid)
    Δy = min_Δy(grid)
    Δz = min_Δz(grid)

    max_νx = maximum_numeric_diffusivity(closure.νx)
    max_νy = maximum_numeric_diffusivity(closure.νy)
    max_νz = maximum_numeric_diffusivity(closure.νz)

    max_κx = maximum_numeric_diffusivity(closure.κx)
    max_κy = maximum_numeric_diffusivity(closure.κy)
    max_κz = maximum_numeric_diffusivity(closure.κz)

    return min(Δx^2 / max_νx,
               Δy^2 / max_νy,
               Δz^2 / max_νz,
               Δx^2 / max_κx,
               Δy^2 / max_κy,
               Δz^2 / max_κz)
end

function cell_diffusion_timescale(closure::SmagorinskyLilly{FT, P, <:NamedTuple{()}},
                                  diffusivities, grid) where {FT, P}
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    return Δ^2 / max_ν
end

function cell_diffusion_timescale(closure::BlasiusSmagorinsky{ML, FT, P, <:NamedTuple{()}},
                                  diffusivities, grid) where {ML, FT, P}
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    return Δ^2 / max_ν
end

function cell_diffusion_timescale(closure::AbstractSmagorinsky, diffusivities, grid)
    Δ = min_Δxyz(grid)
    min_Pr = minimum(closure.Pr)
    max_κ = maximum(closure.κ)
    max_νκ = maximum(diffusivities.νₑ.data.parent) * max(1, 1/min_Pr)
    return min(Δ^2 / max_νκ, Δ^2 / max_κ)
end

function cell_diffusion_timescale(closure::RozemaAnisotropicMinimumDissipation{FT, <:NamedTuple{()}},
                                  diffusivities, grid) where FT
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    return Δ^2 / max_ν
end

function cell_diffusion_timescale(closure::VerstappenAnisotropicMinimumDissipation{FT, PK, PN, <:NamedTuple{()}},
                                  diffusivities, grid) where {FT, PK, PN}
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    return Δ^2 / max_ν
end

function cell_diffusion_timescale(closure::AbstractAnisotropicMinimumDissipation, diffusivities, grid)
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    max_κ = max(Tuple(maximum(κₑ.data.parent) for κₑ in diffusivities.κₑ)...)
    return min(Δ^2 / max_ν, Δ^2 / max_κ)
end

function cell_diffusion_timescale(closure::AbstractLeith, diffusivities, grid)
    Δ = min_Δxyz(grid)
    max_ν = maximum(diffusivities.νₑ.data.parent)
    return Δ^2 / max_ν
end

cell_diffusion_timescale(closure::Tuple, diffusivities, grid) =
    min(Tuple(cell_diffusion_timescale(c, diffusivities, grid) for c in closure)...)
