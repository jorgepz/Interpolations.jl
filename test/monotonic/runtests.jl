
using Test
using Interpolations
using Unitful
@testset "Monotonic" begin
    xa = [[0.0, 0.2, 0.5, 0.6, 0.9, 1.0],
          [0.0, 0.2, 0.5, 0.6, 0.9, 1.0]u"s"]
    y = [(true, [-3.0, 0.0, 5.0, 10.0, 18.0, 22.0]),
         (false, [10.0, 0.0, -5.0, 10.0, -8.0, -2.0]),
         (false, [10.0, 0.0, -5.0, 10.0, -8.0, -2.0]u"m"),
         (true, [-3.0, 0.0, 5.0, 10.0, 18.0, 22.0]u"m")]

    # second item indicates if interpolating function can overshoot
    # for non-monotonic data
    itypes = [(LinearMonotonicInterpolation(), false),
        (FiniteDifferenceMonotonicInterpolation(), true),
        (CardinalMonotonicInterpolation(0.0), true),
        (CardinalMonotonicInterpolation(0.5), true),
        (CardinalMonotonicInterpolation(1.0), false),
        (AkimaMonotonicInterpolation(), true),
        (FritschCarlsonMonotonicInterpolation(), true),
        (FritschButlandMonotonicInterpolation(), false),
        (SteffenMonotonicInterpolation(), false)]

    for (it, overshoot) in itypes
        for yi in 1:length(y), x in xa
            monotonic, ys = y[yi]
            itp = interpolate(x, ys, it)
            for j in 1:6
                # checking values at nodes
                @test itp(x[j]) ≈ ys[j] rtol = 1.e-15 atol = 1.e-14*unit(first(ys))

                # checking overshoot for non-monotonic data
                # and monotonicity for monotonic data
                if !monotonic && overshoot
                    continue
                end
                if j < 6
                    r = range(x[j], stop = x[j+1], length = 100)
                    for k in 1:length(r)-1
                        @test (ys[j+1] - ys[j]) * (itp(r[k+1]) - itp(r[k])) >= zero(first(ys)^2)
                    end
                end
            end
            extFlatItp = extrapolate(itp, Flat())
            @test extFlatItp(x[1]-oneunit(x[1])) ≈ itp(x[1])
            @test extFlatItp(x[end]+oneunit(x[1])) ≈ itp(x[end])
            extThrowItp = extrapolate(itp, Throw())
            @test_throws BoundsError extThrowItp(x[1]-oneunit(x[1]))
            @test_throws BoundsError extThrowItp(x[end]+oneunit(x[1]))
            extLineItp = extrapolate(itp, Line())
            @test extLineItp(x[1]-oneunit(x[1])) ≈ itp(x[1]) - Interpolations.gradient1(itp, x[1])*oneunit(x[1])
            @test extLineItp(x[end]+oneunit(x[1])) ≈ itp(x[end]) + Interpolations.gradient1(itp, x[end])*oneunit(x[1])
            extReflectItp = extrapolate(itp, Reflect())
            @test extReflectItp(x[1]-0.1*oneunit(x[1])) ≈ itp(x[1]+0.1*oneunit(x[1]))
            @test extReflectItp(x[end]+0.1*oneunit(x[1])) ≈ itp(x[end]-0.1*oneunit(x[1]))
            extPeriodicItp = extrapolate(itp, Periodic())
            @test extPeriodicItp(x[1]-0.1*oneunit(x[1])) ≈ itp(x[end]-0.1*oneunit(x[1]))
            @test extPeriodicItp(x[end]+0.1*oneunit(x[1])) ≈ itp(x[1]+0.1*oneunit(x[1]))
        end
    end

    # fail tests
    xWrong = [0.0, 1.0, -5.0, 3.0]
    y2 = [1.0, 2.0, 3.0, 4.0]
    y3 = [-3.0 0.0 5.0 10.0 18.0 22.0]

    for (it, overshoot) in itypes, x in xa
        @test_throws ErrorException interpolate(xWrong, y2, it)
        @test_throws DimensionMismatch interpolate(x, y2, it)
        @test_throws MethodError interpolate(x, y3, it)
    end
end
