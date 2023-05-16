! ! A small program to break the spatial symmetry of the MOs.

! ! You have to defined your MO classes or set security_mo_class to false
! ! with:
! ! qp set orbital_optimization security_mo_class false

! ! The default angle for the rotations is too big for this kind of
! ! application, a value between 1e-3 and 1e-6 should break the spatial
! ! symmetry with just a small change in the energy. 


program break_spatial_sym

  !BEGIN_DOC
  ! Break the symmetry of the MOs with a rotation
  !END_DOC

  implicit none

  kick_in_mos = .True.
  TOUCH kick_in_mos

  call set_classes_loc 
  call apply_pre_rotation
  call unset_classes_loc 
  
end
