using OrdinaryDiffEq, Test, LinearAlgebra, Statistics

@testset "Mass Matrix Accuracy Tests" begin

  # create mass matrix problems
  function make_mm_probs(mm_A, ::Type{Val{iip}}) where iip
    # iip
    mm_b = vec(sum(mm_A; dims=2))
    function mm_f(du,u,p,t)
      mul!(du,mm_A,u)
      du .+= t * mm_b
      nothing
    end
    mm_g(du,u,p,t) = (@. du = u + t; nothing)

    # oop
    mm_f(u,p,t) = mm_A * (u .+ t)
    mm_g(u,p,t) = u .+ t

    mm_analytic(u0, p, t) = @. 2 * u0 * exp(t) - t - 1

    u0 = ones(3)
    tspan = (0.0, 1.0)

    prob = ODEProblem(ODEFunction{iip,true}(mm_f, analytic=mm_analytic, mass_matrix=mm_A), u0, tspan)
    prob2 = ODEProblem(ODEFunction{iip,true}(mm_g, analytic=mm_analytic), u0, tspan)

    prob, prob2
  end

  # test each method for exactness
  for iip in (false, true)
    mm_A = Float64[-2 1 4; 4 -2 1; 2 1 3]
    prob, prob2 = make_mm_probs(mm_A, Val{iip})

    sol = solve(prob,  ImplicitEuler(),dt=1/10,adaptive=false)
    sol2 = solve(prob2,ImplicitEuler(),dt=1/10,adaptive=false)

    @test norm(sol .- sol2) ≈ 0 atol=1e-7

    sol = solve(prob,  RadauIIA5(),dt=1/10,adaptive=false)
    sol2 = solve(prob2,RadauIIA5(),dt=1/10,adaptive=false)

    @test norm(sol .- sol2) ≈ 0 atol=1e-12

    sol = solve(prob,  ImplicitMidpoint(extrapolant = :constant),dt=1/10)
    sol2 = solve(prob2,ImplicitMidpoint(extrapolant = :constant),dt=1/10)

    if iip
      sol = solve(prob  ,Rosenbrock23())
      sol2 = solve(prob2,Rosenbrock23())

      @test norm(sol .- sol2) ≈ 0 atol=1e-11

      sol = solve(prob, Rosenbrock32())
      sol2 = solve(prob2,Rosenbrock32())

      @test norm(sol .- sol2) ≈ 0 atol=1e-11

      sol = solve(prob,  ROS3P())
      sol2 = solve(prob2,ROS3P())

      @test norm(sol .- sol2) ≈ 0 atol=1e-11

      sol = solve(prob,  Rodas3())
      sol2 = solve(prob2,Rodas3())

      @test norm(sol .- sol2) ≈ 0 atol=1e-11

      sol = solve(prob,  RosShamp4())
      sol2 = solve(prob2,RosShamp4())

      @test norm(sol .- sol2) ≈ 0 atol=1e-10

      sol = solve(prob,  Rodas4())
      sol2 = solve(prob2,Rodas4())

      @test norm(sol .- sol2) ≈ 0 atol=1e-9

      sol = solve(prob,  Rodas5())
      sol2 = solve(prob2,Rodas5())

      @test norm(sol .- sol2) ≈ 0 atol=1e-7
    end
  end

  # test functional iteration
  for iip in (false, true)
    prob, prob2 = make_mm_probs(Matrix{Float64}(1.01I, 3, 3), Val{iip})

    sol = solve(prob,ImplicitEuler(
                          nlsolve=NLFunctional(tol=1e-7)),dt=1/10,adaptive=false)
    sol2 = solve(prob2,ImplicitEuler(nlsolve=NLFunctional(tol=1e-7)),dt=1/10,adaptive=false)
    @test norm(sol .- sol2) ≈ 0 atol=1e-7

    sol = solve(prob, ImplicitMidpoint(extrapolant = :constant,
                          nlsolve=NLFunctional(tol=1e-7)),dt=1/10)
    sol2 = solve(prob2,ImplicitMidpoint(extrapolant = :constant, nlsolve=NLFunctional(tol=1e-7)),dt=1/10)
    @test norm(sol .- sol2) ≈ 0 atol=1e-7

    sol = solve(prob,ImplicitEuler(nlsolve=NLAnderson()),dt=1/10,adaptive=false)
    sol2 = solve(prob2,ImplicitEuler(nlsolve=NLAnderson()),dt=1/10,adaptive=false)
    @test norm(sol .- sol2) ≈ 0 atol=1e-7
    @test norm(sol[end] .- sol2[end]) ≈ 0 atol=1e-7

    sol = solve(prob, ImplicitMidpoint(extrapolant = :constant, nlsolve=NLAnderson(tol=1e-6)),dt=1/10)
    sol2 = solve(prob2,ImplicitMidpoint(extrapolant = :constant, nlsolve=NLAnderson(tol=1e-6)),dt=1/10)
    @test norm(sol .- sol2) ≈ 0 atol=1e-7
    @test norm(sol[end] .- sol2[end]) ≈ 0 atol=1e-7
  end
end

# Singular mass matrices

@testset "Mass Matrix Tests with Singular Mass Matrices" begin
  function f!(du, u, p, t)
      du[1] = u[2]
      du[2] = u[2] - 1.
      return
  end

  u0 = [0.,1.]
  tspan = (0.0, 1.0)

  M = fill(0., 2,2)
  M[1,1] = 1.

  m_ode_prob = ODEProblem(ODEFunction(f!;mass_matrix=M), u0, tspan)
  @test_nowarn sol = solve(m_ode_prob, Rosenbrock23())

  M = [0.637947  0.637947
       0.637947  0.637947]

  inv(M) # not caught as singular

  function f2!(du, u, p, t)
      du[1] = u[2]
      du[2] = u[1]
      return
  end
  u0 = zeros(2)

  m_ode_prob = ODEProblem(ODEFunction(f2!;mass_matrix=M), u0, tspan)
  @test_nowarn sol = solve(m_ode_prob, Rosenbrock23())
end
