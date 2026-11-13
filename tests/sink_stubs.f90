module precision
  implicit none
  integer, parameter :: dp=kind(1.0d0)
end module

module waq
  implicit none
  type waq_data
     integer :: kmxnxa=1
     integer, allocatable :: ilaggr(:)
  end type
  type(waq_data) :: waqpar
end module

module m_getkbotktopmax
  implicit none
contains
  subroutine getkbotktopmax(k,kb,kt,ktx)
    integer, intent(in) :: k
    integer, intent(out) :: kb,kt,ktx
    kb=1
    kt=1
    ktx=1
  end subroutine
end module

module m_flowtimes
  implicit none
  real(kind=8) :: dts
end module

module m_flowgeom
  implicit none
  integer :: kmx=1
end module

module m_flow
  implicit none
  real(kind=8), allocatable :: zws(:)
  real(kind=8), parameter :: epshs=1.0d-12
  interface realloc
     module procedure realloc_real
  end interface
contains
  subroutine realloc_real(a, n, keepExisting, fill)
    real(kind=8), allocatable, intent(inout) :: a(:)
    integer, intent(in) :: n
    logical, intent(in), optional :: keepExisting
    real(kind=8), intent(in), optional :: fill
    if (allocated(a)) deallocate(a)
    allocate(a(n))
    a=0.0d0
  end subroutine
end module

module m_source_sink
  implicit none
  integer, parameter :: FLOWCELL_SINK=1,BOTTOM_LAYER_SINK=2,TOP_LAYER_SINK=3
  integer, parameter :: FLOWCELL_SOURCE=4,BOTTOM_LAYER_SOURCE=5,TOP_LAYER_SOURCE=6
  type source_sink_type
    integer :: num_total=1
    integer, allocatable :: waq_index(:), indices(:,:)
    real(kind=8), allocatable :: discharge(:), cumulative_discharge_waq(:)
  end type
  type(source_sink_type) :: source_sinks
end module
