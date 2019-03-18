@cache mutable struct AitkenNevilleCache{uType,rateType,arrayType,dtType,uNoUnitsType} <: OrdinaryDiffEqMutableCache
  u::uType
  uprev::uType
  tmp::uType
  k::rateType
  utilde::uType
  atmp::uNoUnitsType
  fsalfirst::rateType
  dtpropose::dtType
  T::arrayType
  cur_order::Int
  work::dtType
  A::Int
  step_no::Int
end

@cache mutable struct AitkenNevilleConstantCache{dtType,arrayType} <: OrdinaryDiffEqConstantCache
  dtpropose::dtType
  T::arrayType
  cur_order::Int
  work::dtType
  A::Int
  step_no::Int
end

function alg_cache(alg::AitkenNeville,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  tmp = similar(u)
  utilde = similar(u)
  k = zero(rate_prototype)
  fsalfirst = zero(rate_prototype)
  cur_order = max(alg.init_order, alg.min_order)
  dtpropose = zero(dt)
  T = fill(zeros(eltype(u), size(u)), (alg.max_order, alg.max_order))
  work = zero(dt)
  A = one(Int)
  atmp = similar(u,uEltypeNoUnits)
  step_no = zero(Int)
  AitkenNevilleCache(u,uprev,tmp,k,utilde,atmp,fsalfirst,dtpropose,T,cur_order,work,A,step_no)
end

function alg_cache(alg::AitkenNeville,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  dtpropose = zero(dt)
  cur_order = max(alg.init_order, alg.min_order)
  T = fill(zero(eltype(u)), (alg.max_order, alg.max_order))
  work = zero(dt)
  A = one(Int)
  step_no = zero(Int)
  AitkenNevilleConstantCache(dtpropose,T,cur_order,work,A,step_no)
end
