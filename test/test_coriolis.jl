function instantiate_fplane_1(FT)
    coriolis = FPlane(FT, f=π)
    return coriolis.f == FT(π)
end

function instantiate_fplane_2(FT)
    coriolis = FPlane(FT, rotation_rate=2, latitude=30)
    return coriolis.f == FT(2)
end

function instantiate_ntfplane_1(FT)
    coriolis = NonTraditionalFPlane(FT, fz=π, fy=π)
    @test coriolis.fz == FT(π)
    @test coriolis.fy == FT(π)
end

function instantiate_ntfplane_2(FT)
    coriolis = NonTraditionalFPlane(FT, rotation_rate=2, latitude=30)
    @test coriolis.fz == FT(2)
    @test coriolis.fy == FT(2*√3)
end

function instantiate_betaplane_1(FT)
    coriolis = BetaPlane(FT, f₀=π, β=2π)
    @test coriolis.f₀ == FT(π)
    @test coriolis.β  == FT(2π)
end

function instantiate_betaplane_2(FT)
    coriolis = BetaPlane(FT, latitude=70, radius=2π, rotation_rate=3π)
    @test coriolis.f₀ == FT(6π * sind(70))
    @test coriolis.β  == FT(6π * cosd(70) / 2π)
end

function instantiate_ntbetaplane_1(FT)
    coriolis = NonTraditionalBetaPlane(FT, fz=π, fy=ℯ, β=1//7, γ=5)
    @test coriolis.fz == FT(π)
    @test coriolis.fy == FT(ℯ)
    @test coriolis.β  == FT(1//7)
    @test coriolis.γ  == FT(5)
end

function instantiate_ntbetaplane_2(FT)
    Ω, φ, R = π, 17, ℯ
    coriolis = NonTraditionalBetaPlane(FT, rotation_rate=Ω, latitude=φ, radius=R)
    @test coriolis.fz == FT(+2Ω*sind(φ))
    @test coriolis.fy == FT(+2Ω*cosd(φ))
    @test coriolis.β  == FT(+2Ω*cosd(φ)/R)
    @test coriolis.γ  == FT(-4Ω*sind(φ)/R)
end

@testset "Coriolis" begin
    @info "Testing Coriolis..."

    @testset "Coriolis" begin
        for FT in float_types
            @test instantiate_fplane_1(FT)
            @test instantiate_fplane_2(FT)

            instantiate_ntfplane_1(FT)
            instantiate_ntfplane_2(FT)
            instantiate_betaplane_1(FT)
            instantiate_betaplane_2(FT)

            # Test that FPlane throws an ArgumentError
            @test_throws ArgumentError FPlane(FT)
            @test_throws ArgumentError FPlane(FT, rotation_rate=7e-5)
            @test_throws ArgumentError FPlane(FT, f=1, latitude=40)
            @test_throws ArgumentError FPlane(FT, f=1, rotation_rate=7e-5, latitude=40)

            # Test that NonTraditionalFPlane throws an ArgumentError
            @test_throws ArgumentError NonTraditionalFPlane(FT)
            @test_throws ArgumentError NonTraditionalFPlane(FT, rotation_rate=7e-5)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fz=1, latitude=40)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fz=1, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fy=1, latitude=40)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fy=1, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fz=1, fy=2, latitude=40)
            @test_throws ArgumentError NonTraditionalFPlane(FT, fz=1, fy=2, rotation_rate=7e-5, latitude=40)

            # Non-exhaustively test that BetaPlane throws an ArgumentError
            @test_throws ArgumentError BetaPlane(FT)
            @test_throws ArgumentError BetaPlane(FT, f₀=1)
            @test_throws ArgumentError BetaPlane(FT, β=1)
            @test_throws ArgumentError BetaPlane(FT, f₀=1e-4, β=1e-11, latitude=70)

            # Test that NonTraditionalBetaPlane throws an ArgumentError
            @test_throws ArgumentError NonTraditionalBetaPlane(FT)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, rotation_rate=7e-5)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fy=1, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fy=1, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, β=3, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, β=3, rotation_rate=7e-5, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, β=3, γ=4, latitude=40)
            @test_throws ArgumentError NonTraditionalBetaPlane(FT, fz=1, fy=2, β=3, γ=4, rotation_rate=7e-5, latitude=40)

            # Test show functions
            ✈ = FPlane(FT, latitude=45)
            show(✈); println()
            @test ✈ isa FPlane{FT}

            ✈ = NonTraditionalFPlane(FT, latitude=45)
            show(✈); println()
            @test ✈ isa NonTraditionalFPlane{FT}

            ✈ = BetaPlane(FT, latitude=45)
            show(✈); println()
            @test ✈ isa BetaPlane{FT}

            ✈ = NonTraditionalBetaPlane(FT, latitude=45)
            show(✈); println()
            @test ✈ isa NonTraditionalBetaPlane{FT}
        end
    end
end
