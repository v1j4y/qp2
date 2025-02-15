! Apply MO rotation
! Subroutine to apply the rotation matrix to the coefficients of the
! MOs.

! New MOs = Old MOs . Rotation matrix

! *Compute the new MOs with the previous MOs and a rotation matrix*

! Provided:
! | mo_num                 | integer          | number of MOs           |
! | ao_num                 | integer          | number of AOs           |
! | mo_coef(ao_num,mo_num) | double precision | coefficients of the MOs |

! Intent in:
! | R(mo_num,mo_num) | double precision | rotation matrix |

! Intent out:
! | prev_mos(ao_num,mo_num) | double precision | MOs before the rotation |

! Internal:
! | new_mos(ao_num,mo_num) | double precision | MOs after the rotation |
! | i,j                    | integer          | indexes                      |

subroutine apply_mo_rotation(R,prev_mos)
  
  include 'pi.h'

  BEGIN_DOC
  ! Compute the new MOs knowing the rotation matrix
  END_DOC

  implicit none

  ! Variables

  ! in
  double precision, intent(in)  :: R(mo_num,mo_num)

  ! out 
  double precision, intent(out) :: prev_mos(ao_num,mo_num)
  
  ! internal
  double precision, allocatable :: new_mos(:,:)
  integer                       :: i,j
  double precision              :: t1,t2,t3

  print*,''
  print*,'---apply_mo_rotation---'

  call wall_time(t1)  

  ! Allocation
  allocate(new_mos(ao_num,mo_num))
  
  ! Calculation

  ! Product of old MOs (mo_coef) by Rotation matrix (R) 
  call dgemm('N','N',ao_num,mo_num,mo_num,1d0,mo_coef,size(mo_coef,1),R,size(R,1),0d0,new_mos,size(new_mos,1))

  prev_mos = mo_coef
  mo_coef = new_mos

  !if (debug) then  
  !  print*,'New mo_coef : '
  !  do i = 1, mo_num
  !    write(*,'(100(F10.5))') mo_coef(i,:)
  !  enddo
  !endif

  ! Save the new MOs and change the label
  mo_label = 'MCSCF'
  !call save_mos
  call ezfio_set_determinants_mo_label(mo_label)
  
  !print*,'Done, MOs saved'

  ! Deallocation, end
  deallocate(new_mos)

  call wall_time(t2)
  t3 = t2 - t1
  print*,'Time in apply mo rotation:', t3
  print*,'---End apply_mo_rotation---'

end subroutine
