module waq
  implicit none
  type waq_data
     integer, allocatable :: ilaggr(:)
     integer :: kmxnxa = 1
  end type
  type(waq_data) :: waqpar
end module

module m_partitioninfo
  implicit none
contains
  logical function is_ghost_node(k)
    integer, intent(in) :: k
    is_ghost_node = .false.
  end function
end module

module m_getkbotktopmax
  implicit none
end module

module m_flow
  implicit none
end module

module m_flowtimes
  implicit none
  real(kind=8) :: dts
end module

module m_flowgeom
  implicit none
  integer :: kmx=1
  integer, allocatable :: kmxn(:), kbot(:), ktop(:)
end module

module m_laterals
  implicit none
  integer :: num_layers=1,numlatsg=1
  integer, allocatable :: n1latsg(:), n2latsg(:), nnlat(:)
  real(kind=8), allocatable :: qqlat(:,:), qlatwaq(:)
end module
