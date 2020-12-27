program metis_install_test

  ! Archer2 Metis installation smoke test
  ! (c) The University of Edinburgh (2020)
  
  use metis
  implicit none

  integer :: ierr

  ierr = metis_test_kway(kway = .true.)
  if (ierr /= METIS_OK) error stop "METIS_PartGraphKway failed"

  ierr = metis_test_kway(kway = .false.)
  if (ierr /= METIS_OK) error stop "METIS_PartGraphRecursive failed"
  
end program metis_install_test
