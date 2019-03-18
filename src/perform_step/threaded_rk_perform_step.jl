function initialize!(integrator, cache::DP5ThreadedCache)
  integrator.kshortsize = 4
  resize!(integrator.k, integrator.kshortsize)
  integrator.k .= [cache.update,cache.bspl,cache.dense_tmp3,cache.dense_tmp4]
  integrator.fsalfirst = cache.k1; integrator.fsallast = cache.k7
  integrator.f(integrator.fsalfirst, integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.destats.nf += 1
end

@muladd function perform_step!(integrator, cache::DP5ThreadedCache, repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  uidx = eachindex(integrator.uprev)
  @unpack a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a73,a74,a75,a76,btilde1,btilde3,btilde4,btilde5,btilde6,btilde7,c1,c2,c3,c4,c5,c6 = cache.tab
  @unpack k1,k2,k3,k4,k5,k6,k7,dense_tmp3,dense_tmp4,update,bspl,utilde,tmp,atmp = cache
  @unpack d1,d3,d4,d5,d6,d7 = cache.tab
  dp5threaded_loop1(dt,tmp,uprev,a21,k1,uidx)
  f(k2, tmp, p, t+c1*dt)
  dp5threaded_loop2(dt,tmp,uprev,a31,k1,a32,k2,uidx)
  f(k3, tmp, p, t+c2*dt)
  dp5threaded_loop3(dt,tmp,uprev,a41,k1,a42,k2,a43,k3,uidx)
  f(k4, tmp, p, t+c3*dt)
  dp5threaded_loop4(dt,tmp,uprev,a51,k1,a52,k2,a53,k3,a54,k4,uidx)
  f(k5, tmp, p, t+c4*dt)
  dp5threaded_loop5(dt,tmp,uprev,a61,k1,a62,k2,a63,k3,a64,k4,a65,k5,uidx)
  f(k6, tmp, p, t+dt)
  dp5threaded_loop6(dt,u,uprev,a71,k1,a73,k3,a74,k4,a75,k5,a76,k6,update,uidx)
  f(integrator.fsallast,u,p,t+dt)
  integrator.destats.nf += 6
  if integrator.opts.adaptive
    dp5threaded_adaptiveloop(dt,utilde,btilde1,k1,btilde3,k3,btilde4,k4,btilde5,k5,btilde6,k6,btilde7,k7,uidx)
    calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm,t)
    integrator.EEst = integrator.opts.internalnorm(atmp,t)
  end
  dp5threaded_denseloop(bspl,update,k1,k3,k4,k5,k6,k7,integrator.k,d1,d3,d4,d5,d6,d7,uidx)
end

@noinline @muladd function dp5threaded_denseloop(bspl,update,k1,k3,k4,k5,k6,k7,k,d1,d3,d4,d5,d6,d7,uidx)
  Threads.@threads for i in uidx
    bspl[i] = k1[i] - update[i]
    k[3][i] = update[i] - k7[i] - bspl[i]
    k[4][i] = d1*k1[i]+d3*k3[i]+d4*k4[i]+d5*k5[i]+d6*k6[i]+d7*k7[i]
  end
end

@noinline @muladd function dp5threaded_loop1(dt,tmp,uprev,a21,k1,uidx)
  a = dt*a21
  Threads.@threads for i in uidx
    tmp[i] = uprev[i]+a*k1[i]
  end
end

@noinline @muladd function dp5threaded_loop2(dt,tmp,uprev,a31,k1,a32,k2,uidx)
  Threads.@threads for i in uidx
    tmp[i] = uprev[i]+dt*(a31*k1[i]+a32*k2[i])
  end
end

@noinline @muladd function dp5threaded_loop3(dt,tmp,uprev,a41,k1,a42,k2,a43,k3,uidx)
  Threads.@threads for i in uidx
    tmp[i] = uprev[i]+dt*(a41*k1[i]+a42*k2[i]+a43*k3[i])
  end
end

@noinline @muladd function dp5threaded_loop4(dt,tmp,uprev,a51,k1,a52,k2,a53,k3,a54,k4,uidx)
  Threads.@threads for i in uidx
    tmp[i] = uprev[i]+dt*(a51*k1[i]+a52*k2[i]+a53*k3[i]+a54*k4[i])
  end
end

@noinline @muladd function dp5threaded_loop5(dt,tmp,uprev,a61,k1,a62,k2,a63,k3,a64,k4,a65,k5,uidx)
  Threads.@threads for i in uidx
    tmp[i] = uprev[i]+dt*(a61*k1[i]+a62*k2[i]+a63*k3[i]+a64*k4[i]+a65*k5[i])
  end
end

@noinline @muladd function dp5threaded_loop6(dt,u,uprev,a71,k1,a73,k3,a74,k4,a75,k5,a76,k6,update,uidx)
  Threads.@threads for i in uidx
    update[i] = a71*k1[i]+a73*k3[i]+a74*k4[i]+a75*k5[i]+a76*k6[i]
    u[i] = uprev[i]+dt*update[i]
  end
end

@noinline @muladd function dp5threaded_adaptiveloop(dt,utilde,btilde1,k1,btilde3,k3,btilde4,k4,btilde5,k5,btilde6,k6,btilde7,k7,uidx)
  Threads.@threads for i in uidx
    utilde[i] = dt*(btilde1*k1[i] + btilde3*k3[i] + btilde4*k4[i] + btilde5*k5[i] + btilde6*k6[i] + btilde7*k7[i])
  end
end
