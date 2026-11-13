! Compile the UNMODIFIED upstream update_waq_lateral_fluxes.f90 with stubs.
! This tests accumulator semantics, not the full nonlinear solver.
program waq_retry_driver
  use waq
  use m_flowtimes
  use m_flowgeom
  use m_laterals
  use m_update_waq_lateral_fluxes
  implicit none
  real(kind=8), parameter :: q=5.0d0, previous=100.0d0
  real(kind=8) :: no_rollback, correct
  allocate(waqpar%ilaggr(1),kmxn(1),kbot(1),ktop(1))
  allocate(n1latsg(1),n2latsg(1),nnlat(1),qqlat(1,1),qlatwaq(1))
  waqpar%ilaggr=1
  kmxn=1
  kbot=1
  ktop=1
  n1latsg=1
  n2latsg=1
  nnlat=1
  qqlat=q
  qlatwaq=previous
  dts=20.0d0
  call update_waq_lateral_fluxes() ! rejected attempt
  dts=10.0d0
  call update_waq_lateral_fluxes() ! accepted retry without rollback
  no_rollback=qlatwaq(1)
  qlatwaq=previous                 ! explicit restore seen in alternate error path
  call update_waq_lateral_fluxes()
  correct=qlatwaq(1)
  print '(a,f8.1)', 'without_rollback=',no_rollback
  print '(a,f8.1)', 'with_rollback=',correct
  if (abs(no_rollback - 250.0d0) > 1.0d-10) stop 1
  if (abs(correct - 150.0d0) > 1.0d-10) stop 2
  print '(a)', 'PASS: original WAQ function accumulates each invocation; no implicit clear'
end program
