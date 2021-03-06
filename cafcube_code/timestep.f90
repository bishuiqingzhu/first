subroutine timestep
use variables
implicit none
save
integer ntemp,i_images
real ra,da_1,da_2,dt_e,a_checkpoint

its=its+1
dt_old=dt

sync all

if (head) then

  print*,''
  print*,'timestep'

  dt_e=dt_max
  ntemp=0
  do
    ntemp=ntemp+1
    call expansion(a,dt_e,da_1,da_2)
    da=da_1+da_2
    ra=da/(a+da)
    if (ra>ra_max) then
      dt_e=dt_e*(ra_max/ra)
    else
      exit
    endif
    if (ntemp>10) exit
  enddo
  
  dt=min(dt_e,dt_fine(1),dt_coarse(1),dt_pp(1),dt_vmax(1))
  call expansion(a,dt,da_1,da_2)

  da=da_1+da_2

  ! check if checkpointing is needed
  checkpoint_step=.false.

  
  a_checkpoint=1.0/(1+z_checkpoint(cur_checkpoint))
  !if (a+da>a_checkpoint) then
  !  checkpoint_step=.true.
  !  dt=dt*(a_checkpoint-a)/da
  !  call expansion(a,dt,da_1,da_2)
  !  if (cur_checkpoint==n_checkpoint) final_step=.true.
  !  da=da_1+da_2
  !endif

  if (da>=a_checkpoint-a) then
    checkpoint_step=.true.
    if (cur_checkpoint==n_checkpoint) final_step=.true.
    do while (abs((a+da)/a_checkpoint-1)>=1e-6)
      dt=dt*(a_checkpoint-a)/da
      call expansion(a,dt,da_1,da_2)
      da=da_1+da_2
      print*, 'a+da, dt, z+dz, err_a', a+da, dt, 1.0/(a+da)-1.0, (a+da)/a_checkpoint-1
    enddo
  endif

  ra=da/(a+da)
  a_mid=a+(da/2)
  print*, '-------------------------------------------------------'
  print*, 'timestep    :',its
  print*, 'tau         :',tau,tau+dt
  print*, 'redshift    :',1.0/a-1.0,1.0/(a+da)-1.0
  print*, 'scale factor:',a,a_mid,a+da
  print*, 'expansion   :',ra
  print*, 'dt          :',dt
  print*, 'dt_e        :',dt_e
  print*, 'dt_fine     :',dt_fine(1)
  print*, 'dt_pp       :',dt_pp(1)
  print*, 'dt_coarse   :',dt_coarse(1)
  print*, 'dt_vmax     :',dt_vmax(1)
  print*, ''
  tau=tau+dt
  t=t+dt
  a=a+da
endif
sync all

! broadcast timestep variables
a=a[1]
a_mid=a_mid[1]
dt=dt[1]
checkpoint_step=checkpoint_step[1]
final_step=final_step[1]
sync all

endsubroutine timestep






subroutine expansion(a0,dt0,da1,da2)
!! Expansion subroutine :: Hy Trac -- trac@cita.utoronto.ca
!! Added Equation of State for Dark Energy :: Pat McDonald -- pmcdonal@cita.utoronto.ca
use variables
implicit none
save
real(4) :: a0,dt0,dt_x,da1,da2
real(8) :: a_x,adot,addot,atdot,arkm,a3rlm,omHsq
real(8), parameter :: e = 2.718281828459046
!! Expand Friedman equation to third order and integrate
dt_x=dt0/2
a_x=a0
omHsq=4.0/9.0
a3rlm=a_x**(-3*wde)*omega_l/omega_m
!a3rlm=a_x**(-3*wde - 3*w_a)*(omega_l/omega_m)*e**(3*w_a*(a_x - 1))
arkm=a_x*(1.0-omega_m-omega_l)/omega_m

adot=sqrt(omHsq*a_x**3*(1.0+arkm+a3rlm))
!    addot=a_x**2*omHsq*(1.5+2.0*arkm+3.0*a3rlm)
addot=a_x**2*omHsq*(1.5+2.0*arkm+1.5*(1.0-wde)*a3rlm)
!    addot=a_x**2*omHsq*(1.5+2.0*arkm+1.5*(1.0-wde + w_a*(a_x - 1))*a3rlm)
!    atdot=a_x*adot*omHsq*(3.0+6.0*arkm+15.0*a3rlm)
atdot=a_x*adot*omHsq*(3.0+6.0*arkm+1.5*(2.0-3.0*wde)*(1.0-wde)*a3rlm)
!    atdot=a_x*adot*omHsq*(3.0+6.0*arkm+1.5*(3*w_a**2*a_x**2 + 6*w_a*(1-wde-w_a)+ (2.0-3.0*(wde+w_a))*(1.0-(wde+w_a)))*a3rlm)

da1=adot*dt_x+(addot*dt_x**2)/2.0+(atdot*dt_x**3)/6.0

a_x=a0+da1
omHsq=4.0/9.0
!    a3rlm=a_x**3*omega_l/omega_m
a3rlm=a_x**(-3*wde)*omega_l/omega_m
!    a3rlm=a_x**(-3*wde - 3*w_a)*(omega_l/omega_m)*e**(3*w_a*(a_x - 1))
arkm=a_x*(1.0-omega_m-omega_l)/omega_m

adot=sqrt(omHsq*a_x**3*(1.0+arkm+a3rlm))
!    addot=a_x**2*omHsq*(1.5+2.0*arkm+3.0*a3rlm)
addot=a_x**2*omHsq*(1.5+2.0*arkm+1.5*(1.0-wde)*a3rlm)
!    addot=a_x**2*omHsq*(1.5+2.0*arkm+1.5*(1.0-wde + w_a*(a_x - 1))*a3rlm)
!    atdot=a_x*adot*omHsq*(3.0+6.0*arkm+15.0*a3rlm)
atdot=a_x*adot*omHsq*(3.0+6.0*arkm+1.5*(2.0-3.0*wde)*(1.0-wde)*a3rlm)
!    atdot=a_x*adot*omHsq*(3.0+6.0*arkm+1.5*(3*w_a**2*a_x**2 + 6*w_a*(1-wde-w_a)+ (2.0-3.0*(wde+w_a))*(1.0-(wde+w_a)))*a3rlm)

da2=adot*dt_x+(addot*dt_x**2)/2.0+(atdot*dt_x**3)/6.0

endsubroutine expansion
