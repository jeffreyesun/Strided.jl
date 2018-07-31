using Test
using LinearAlgebra
using Random
using Strided

@testset "multiplication" begin
    @testset for T1 in (Float32, Float64, Complex{Float32}, Complex{Float64})
        d = 20
        A1 = rand(T1, (d,d))
        B1 = StridedView(copy(A1))
        for op1 in (identity, conj, transpose, adjoint)
            @test op1(A1) == op1(B1)
        end
        for T2 in (Float32, Float64, Complex{Float32}, Complex{Float64})
            A2 = rand(T2, (d,d))
            T3 = promote_type(T1,T2)
            A3 = rand(T3, (d,d))
            B2 = StridedView(copy(A2))
            B3 = StridedView(copy(A3))

            for op1 in (identity, conj, transpose, adjoint)
                for op2 in (identity, conj, transpose, adjoint)
                    @test op1(A1)*op2(A2) ≈ op1(B1)*op2(B2)
                    for op3 in (identity, conj, transpose, adjoint)
                        mul!(op3(B3), op1(B1), op2(B2))
                        @test B3 ≈ op3(op1(A1)*op2(A2)) # op3 is its own inverse
                    end
                end
            end
        end
    end

    let T = Complex{Int}
        d = 10
        A1 = map(complex, rand(-100:100, (d,d)), rand(-100:100, (d,d)))
        A2 = map(complex, rand(-100:100, (d,d)), rand(-100:100, (d,d)))
        A3 = map(complex, rand(-100:100, (d,d)), rand(-100:100, (d,d)))
        B1 = StridedView(copy(A1))
        B2 = StridedView(copy(A2))
        B3 = StridedView(copy(A3))

        for op1 in (identity, conj, transpose, adjoint)
            @test op1(A1) == op1(B1)
            for op2 in (identity, conj, transpose, adjoint)
                @test op1(A1)*op2(A2) ≈ op1(B1)*op2(B2)
                for op3 in (identity, conj, transpose, adjoint)
                    Strided.mul!(op3(B3), op1(B1), op2(B2))
                    @test B3 ≈ op3(op1(A1)*op2(A2)) # op3 is its own inverse
                end
            end
        end
    end

    let T = Rational{Int}
        d = 10
        A1 = map(//, rand(-10:10, (d,d)), rand(1:10, (d,d)))
        A2 = map(//, rand(-10:10, (d,d)), rand(1:10, (d,d)))
        A3 = map(//, rand(-10:10, (d,d)), rand(1:10, (d,d)))
        B1 = StridedView(copy(A1))
        B2 = StridedView(copy(A2))
        B3 = StridedView(copy(A3))

        for op1 in (identity, conj, transpose, adjoint)
            @test op1(A1) == op1(B1)
            for op2 in (identity, conj, transpose, adjoint)
                @test op1(A1)*op2(A2) ≈ op1(B1)*op2(B2)
                for op3 in (identity, conj, transpose, adjoint)
                    mul!(op3(B3), op1(B1), op2(B2))
                    @test B3 ≈ op3(op1(A1)*op2(A2)) # op3 is its own inverse
                end
            end
        end
    end
end

@testset "reshape and permutedims" begin
    @testset for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
        @testset for N = 2:6
            dims = ntuple(n->rand(1:10), N)
            A = rand(T, dims)
            B = StridedView(copy(A))
            @test conj(A) == conj(B)
            p = randperm(N)
            B2 = permutedims(B, p)
            A2 = permutedims(A, p)
            @test B2 == A2
            @test copy(B2) == A2
            @test convert(Array, B2) == A2

            dims = ntuple(n->10, N)
            A = rand(T, dims)
            B = StridedView(copy(A))
            @test conj(A) == conj(B)
            p = randperm(N)
            B2 = permutedims(B, p)
            A2 = permutedims(A, p)
            @test B2 == A2
            @test copy(B2) == A2
            @test convert(Array, B2) == A2

            B2 = reshape(B, (2, 5, ntuple(n->10, N-2)..., 5, 2))
            A2 = reshape(A, (2, 5, ntuple(n->10, N-2)..., 5, 2))
            A3 = reshape(copy(A), size(A2))
            @test B2 == A3
            @test B2 == A2
            p = randperm(N+2)
            @test conj(permutedims(B2, p)) == conj(permutedims(A3, p))
        end
    end
end

@testset "map!, scale!, axpy! and axpby!" begin
    @testset for T in (Float32, Float64, ComplexF32, ComplexF64)
        @testset for N = 2:6
            dims = ntuple(n->div(60,N), N)
            B1 = permutedims(StridedView(rand(T, dims)), randperm(N))
            B2 = permutedims(StridedView(rand(T, dims)), randperm(N))
            B3 = permutedims(StridedView(rand(T, dims)), randperm(N))
            A1 = convert(Array, B1)
            A2 = convert(Array, B2)
            A3 = convert(Array, B3)

            @test rmul!(B1, 1//2) ≈ rmul!(A1, 1//2)
            @test axpy!(1//3, B1, B2) ≈ axpy!(1//3, A1, A2)
            @test axpby!(1//3, B1, 1//2, B3) ≈ axpby!(1//3, A1, 1//2, A3)
            @test map((x,y,z)->sin(x)+y/exp(-abs(z)), B1, B2, B3) ≈ map((x,y,z)->sin(x)+y/exp(-abs(z)), A1, A2, A3)
        end
    end
end
