@cache mutable struct ABDF2ConstantCache{F,N,dtType,rate_prototype} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolver::N
  eulercache::ImplicitEulerConstantCache
  dtₙ₋₁::dtType
  fsalfirstprev::rate_prototype
end

function alg_cache(alg::ABDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,
                   uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = 1//1, 1
  @oopnlsolve
  eulercache = ImplicitEulerConstantCache(uf,nlsolver)

  nlsolver.γ = 2//3
  nlsolver.c = 1

  dtₙ₋₁ = one(dt)
  fsalfirstprev = rate_prototype

  ABDF2ConstantCache(uf, nlsolver, eulercache, dtₙ₋₁, fsalfirstprev)
end

@cache mutable struct ABDF2Cache{uType,rateType,uNoUnitsType,JType,WType,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uₙ::uType
  uₙ₋₁::uType
  uₙ₋₂::uType
  du1::rateType
  fsalfirst::rateType
  fsalfirstprev::rateType
  k::rateType
  z::uType
  zₙ₋₁::uType
  dz::uType
  b::uType
  tmp::uType
  atmp::uNoUnitsType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
  eulercache::ImplicitEulerCache
  dtₙ₋₁::dtType
end

function alg_cache(alg::ABDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,
                   tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = 1//1, 1
  @iipnlsolve

  fsalfirstprev = zero(rate_prototype)
  atmp = similar(u,uEltypeNoUnits)

  eulercache = ImplicitEulerCache(u,uprev,uprev2,du1,fsalfirst,k,z,dz,b,tmp,atmp,J,W,uf,jac_config,linsolve,nlsolver)

  nlsolver.γ = 2//3
  nlsolver.c = 1

  dtₙ₋₁ = one(dt)
  zₙ₋₁ = zero(u)

  ABDF2Cache(u,uprev,uprev2,du1,fsalfirst,fsalfirstprev,k,z,zₙ₋₁,dz,b,tmp,atmp,J,
              W,uf,jac_config,linsolve,nlsolver,eulercache,dtₙ₋₁)
end

# SBDF

@cache mutable struct SBDFConstantCache{rateType,F,N,uType} <: OrdinaryDiffEqConstantCache
  cnt::Int
  k2::rateType
  uf::F
  nlsolver::N
  uprev2::uType
  uprev4::uType
  uprev3::uType
  k₁::rateType
  k₂::rateType
  k₃::rateType
  du₁::rateType
  du₂::rateType
end

@cache mutable struct SBDFCache{uType,rateType,JType,WType,UF,JC,N,F} <: OrdinaryDiffEqMutableCache
  cnt::Int
  u::uType
  uprev::uType
  fsalfirst::rateType
  k::rateType
  du1::rateType
  z::uType
  dz::uType
  b::uType
  tmp::uType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
  uprev2::uType
  uprev3::uType
  uprev4::uType
  k₁::rateType
  k₂::rateType
  k₃::rateType
  du₁::rateType
  du₂::rateType
end

function alg_cache(alg::SBDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = 1//1, 1
  @oopnlsolve

  k2 = rate_prototype
  k₁ = rate_prototype; k₂ = rate_prototype; k₃ = rate_prototype
  du₁ = rate_prototype; du₂ = rate_prototype

  uprev2 = u; uprev3 = u; uprev4 = u

  SBDFConstantCache(1,k2,uf,nlsolver,uprev2,uprev3,uprev4,k₁,k₂,k₃,du₁,du₂)
end

function alg_cache(alg::SBDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = 1//1, 1
  @iipnlsolve

  order = alg.order

  k₁ = zero(rate_prototype)
  k₂ = order >= 3 ? zero(rate_prototype) : k₁
  k₃ = order == 4 ? zero(rate_prototype) : k₁
  du₁ = zero(rate_prototype)
  du₂ = zero(rate_prototype)

  uprev2 = zero(u)
  uprev3 = order >= 3 ? zero(u) : uprev2
  uprev4 = order == 4 ? zero(u) : uprev2

  SBDFCache(1,u,uprev,fsalfirst,k,du1,z,dz,b,tmp,J,W,uf,jac_config,linsolve,nlsolver,uprev2,uprev3,uprev4,k₁,k₂,k₃,du₁,du₂)
end

# QNDF1

@cache mutable struct QNDF1ConstantCache{F,N,coefType,coefType1,dtType,uType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolver::N
  D::coefType
  D2::coefType1
  R::coefType
  U::coefType
  uprev2::uType
  dtₙ₋₁::dtType
end

@cache mutable struct QNDF1Cache{uType,rateType,coefType,coefType1,coefType2,uNoUnitsType,JType,WType,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uprev2::uType
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType1
  D2::coefType2
  R::coefType
  U::coefType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
  dtₙ₋₁::dtType
end

function alg_cache(alg::QNDF1,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = zero(inv((1-alg.kappa))), 1
  @oopnlsolve

  uprev2 = u
  dtₙ₋₁ = t

  D = fill(zero(u), 1, 1)
  D2 = fill(zero(u), 1, 2)
  R = fill(zero(t), 1, 1)
  U = fill(zero(t), 1, 1)

  U!(1,U)

  QNDF1ConstantCache(uf,nlsolver,D,D2,R,U,uprev2,dtₙ₋₁)
end

function alg_cache(alg::QNDF1,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = zero(inv((1-alg.kappa))), 1
  @iipnlsolve

  D = Array{typeof(u)}(undef, 1, 1)
  D2 = Array{typeof(u)}(undef, 1, 2)
  R = fill(zero(t), 1, 1)
  U = fill(zero(t), 1, 1)

  D[1] = similar(u)
  D2[1] = similar(u); D2[2] = similar(u)

  U!(1,U)

  atmp = similar(u,uEltypeNoUnits)
  utilde = similar(u)
  uprev2 = zero(u)
  dtₙ₋₁ = one(dt)

  QNDF1Cache(uprev2,du1,fsalfirst,k,z,dz,b,D,D2,R,U,tmp,atmp,utilde,J,
              W,uf,jac_config,linsolve,nlsolver,dtₙ₋₁)
end

# QNDF2

@cache mutable struct QNDF2ConstantCache{F,N,coefType,coefType1,uType,dtType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolver::N
  D::coefType
  D2::coefType
  R::coefType1
  U::coefType1
  uprev2::uType
  uprev3::uType
  dtₙ₋₁::dtType
  dtₙ₋₂::dtType
end

@cache mutable struct QNDF2Cache{uType,rateType,coefType,coefType1,coefType2,uNoUnitsType,JType,WType,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uprev2::uType
  uprev3::uType
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType1
  D2::coefType2
  R::coefType
  U::coefType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
  dtₙ₋₁::dtType
  dtₙ₋₂::dtType
end

function alg_cache(alg::QNDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = zero(inv((1-alg.kappa))), 1
  @oopnlsolve

  uprev2 = u
  uprev3 = u
  dtₙ₋₁ = zero(t)
  dtₙ₋₂ = zero(t)

  D = fill(zero(u), 1, 2)
  D2 = fill(zero(u), 1, 3)
  R = fill(zero(t), 2, 2)
  U = fill(zero(t), 2, 2)

  U!(2,U)

  QNDF2ConstantCache(uf,nlsolver,D,D2,R,U,uprev2,uprev3,dtₙ₋₁,dtₙ₋₂)
end

function alg_cache(alg::QNDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = zero(inv((1-alg.kappa))), 1
  @iipnlsolve

  D = Array{typeof(u)}(undef, 1, 2)
  D2 = Array{typeof(u)}(undef, 1, 3)
  R = fill(zero(t), 2, 2)
  U = fill(zero(t), 2, 2)

  D[1] = similar(u); D[2] = similar(u)
  D2[1] = similar(u);  D2[2] = similar(u); D2[3] = similar(u)

  U!(2,U)

  atmp = similar(u,uEltypeNoUnits)
  utilde = similar(u)
  uprev2 = zero(u)
  uprev3 = zero(u)
  dtₙ₋₁ = zero(dt)
  dtₙ₋₂ = zero(dt)

  QNDF2Cache(uprev2,uprev3,du1,fsalfirst,k,z,dz,b,D,D2,R,U,tmp,atmp,utilde,J,
             W,uf,jac_config,linsolve,nlsolver,dtₙ₋₁,dtₙ₋₂)
end

@cache mutable struct QNDFConstantCache{F,N,coefType1,coefType2,coefType3,uType,dtType,dtsType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolver::N
  D::coefType3
  D2::coefType2
  R::coefType1
  U::coefType1
  order::Int64
  max_order::Int64
  udiff::uType
  dts::dtsType
  h::dtType
  c::Int64
end

@cache mutable struct QNDFCache{uType,rateType,coefType1,coefType,coefType2,coefType3,dtType,dtsType,uNoUnitsType,JType,WType,UF,JC,N,F} <: OrdinaryDiffEqMutableCache
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType3
  D2::coefType2
  R::coefType1
  U::coefType1
  order::Int64
  max_order::Int64
  udiff::coefType
  dts::dtsType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
  h::dtType
  c::Int64
end

function alg_cache(alg::QNDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = one(eltype(alg.kappa)), 1
  @oopnlsolve

  udiff = fill(zero(u), 1, 6)
  dts = fill(zero(dt), 1, 6)
  h = zero(dt)

  D = fill(zero(u), 1, 5)
  D2 = fill(zero(u), 6, 6)
  R = fill(zero(t), 5, 5)
  U = fill(zero(t), 5, 5)

  max_order = 5

  QNDFConstantCache(uf,nlsolver,D,D2,R,U,1,max_order,udiff,dts,h,0)
end

function alg_cache(alg::QNDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = one(eltype(alg.kappa)), 1
  @iipnlsolve

  udiff = Array{typeof(u)}(undef, 1, 6)
  dts = fill(zero(dt), 1, 6)
  h = zero(dt)

  D = Array{typeof(u)}(undef, 1, 5)
  D2 = Array{typeof(u)}(undef, 6, 6)
  R = fill(zero(t), 5, 5)
  U = fill(zero(t), 5, 5)

  for i = 1:5
    D[i] = zero(u)
    udiff[i] = zero(u)
  end
  udiff[6] = zero(u)

  for i = 1:6, j = 1:6
      D2[i,j] = zero(u)
  end

  max_order = 5
  atmp = similar(u,uEltypeNoUnits)
  utilde = tmp

  QNDFCache(du1,fsalfirst,k,z,dz,b,D,D2,R,U,1,max_order,udiff,dts,tmp,atmp,utilde,J,
            W,uf,jac_config,linsolve,nlsolver,h,0)
end


@cache mutable struct MEBDF2Cache{uType,rateType,uNoUnitsType,JType,WType,UF,JC,F,N} <: OrdinaryDiffEqMutableCache
  u::uType
  uprev::uType
  uprev2::uType
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  z₁::uType
  z₂::uType
  tmp2::uType
  dz::uType
  b::uType
  tmp::uType
  atmp::uNoUnitsType
  J::JType
  W::WType
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolver::N
end

function alg_cache(alg::MEBDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,
                   tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  γ, c = 1, 1
  @iipnlsolve

  z₁ = zero(u); z₂ = zero(u); z₃ = zero(u); tmp2 = zero(u)
  atmp = similar(u,uEltypeNoUnits)

  MEBDF2Cache(u,uprev,uprev2,du1,fsalfirst,k,z,z₁,z₂,tmp2,dz,b,tmp,atmp,J,W,uf,jac_config,linsolve,nlsolver)
end

mutable struct MEBDF2ConstantCache{F,N} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolver::N
end

function alg_cache(alg::MEBDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,
                   tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  γ, c = 1, 1
  @oopnlsolve
  MEBDF2ConstantCache(uf,nlsolver)
end
