module metis

  ! For Archer2 metis install test
  ! (c) The University of Edinburgh (2020)
  
  use iso_c_binding
  use iso_fortran_env

  implicit none
  public

  ! METIS "interface"
  integer, parameter :: idx_t = int32
  integer, parameter :: real_t = real32
  integer, parameter :: METIS_OK = 1

  integer, external :: METIS_PartGraphRecursive
  integer, external :: METIS_PartGraphKway

contains

  function metis_test_kway(kway) result(ierr)

    ! Test METIS_PartGraphKway()      (kway = .true.)
    ! or   METIS_PartGraphRecursive() (kway = .false.)
    
    ! The test problem is from the Metis manual using default options
    
    logical, intent(in) :: kway
    integer             :: ierr
    
    ! Parameters (and auxiliary quantities)
    ! This is the graph in Figure 3 of the Metis manual.
  
    integer (kind = idx_t), parameter               :: nvtxs = 15
    integer (kind = idx_t), parameter               :: ncon = 1
    integer (kind = idx_t), parameter               :: medges = 22
    integer (kind = idx_t), parameter               :: nparts = 2
  
    integer (kind = idx_t), dimension(nvtxs+1)      :: xadj
    integer (kind = idx_t), dimension(2*medges)     :: adjncy

    ! Can be null(), be here provide a value

    integer (kind = idx_t), dimension(nvtxs)        :: vwgt
    integer (kind = idx_t), dimension(nvtxs)        :: vsize
  
    integer (kind = idx_t), dimension(2*medges)     :: adjwgt
    
    real    (kind = real_t), dimension(nparts*ncon) :: tpwgts
    real    (kind = real_t), dimension(ncon)        :: ubvec

    ! Options are unset (default).
    integer (kind = idx_t), pointer                 :: options => null()
  
    ! Output: 

    integer (kind = idx_t) :: objval
    integer (kind = idx_t) :: part(nvtxs)
  
    ! Here is the CSR description

    xadj(:)   = (/ 0, 2, 5, 8, 11, 13, 16, 20, 24, 28, 31, 33, 36, 39, 42, 44/)
    adjncy(:) = (/ 1, 5, 0, 2, 6, 1, 3, 7, 2, 4, 8, 3, 9, 0, 6, 10, 1, 5, 7, &
         11, 2, 6, 8, 12, 3, 7, 9, 13, 4, 8, 14, 5, 11, 6, 10, 12, &
         7, 11, 13, 8, 12, 14, 9, 13 /)

    vwgt(:)   = 1
    vsize(:)  = 1
    tpwgts(:) = 1.0/nparts
    ubvec(:)  = 1.001

    if (kway) then
       ierr = METIS_PartGraphKway(nvtxs, ncon, xadj, adjncy, &
            vwgt, vsize, adjwgt, nparts, tpwgts, &
            ubvec, options, objval, part)
    else
       ierr = METIS_PartGraphRecursive(nvtxs, ncon, xadj, adjncy, &
            vwgt, vsize, adjwgt, nparts, tpwgts, &
            ubvec, options, objval, part)
    end if

  end function metis_test_kway
  
end module metis
