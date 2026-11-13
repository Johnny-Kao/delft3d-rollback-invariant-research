program source_sink_retry_driver
  use m_flowtimes
  use waq
  use m_source_sink
  use m_update_waq_sink_source_fluxes
  implicit none
  real(kind=8) :: without_restore,with_restore
  allocate(source_sinks%waq_index(1),source_sinks%indices(1,6))
  allocate(source_sinks%discharge(1),source_sinks%cumulative_discharge_waq(1))
  source_sinks%waq_index(1)=0
  source_sinks%indices=0
  source_sinks%discharge(1)=5d0
  source_sinks%cumulative_discharge_waq(1)=100d0
  dts=20d0
  call update_waq_sink_source_fluxes() ! rejected
  dts=10d0
  call update_waq_sink_source_fluxes() ! accepted
  without_restore=source_sinks%cumulative_discharge_waq(1)
  source_sinks%cumulative_discharge_waq(1)=100d0
  call update_waq_sink_source_fluxes()
  with_restore=source_sinks%cumulative_discharge_waq(1)
  print '(a,f8.1)', 'sink_without_restore=', without_restore
  print '(a,f8.1)', 'sink_with_restore=', with_restore
  if (abs(without_restore-250d0)>1d-10) stop 1
  if (abs(with_restore-150d0)>1d-10) stop 2
  print '(a)', 'PASS: unmodified upstream 2D source/sink updater retains rejected attempt'
end program
