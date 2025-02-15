! Agreement with the model: Rho

! *Compute the ratio : rho = (prev_energy - energy) / (prev_energy - e_model)*

! Rho represents the agreement between the model (the predicted energy
! by the Taylor expansion truncated at the 2nd order) and the real
! energy : 

! \begin{equation}
! \rho^{k+1} = \frac{E^{k} - E^{k+1}}{E^{k} - m^{k+1}}
! \end{equation}
! With :
! $E^{k}$ the energy at the previous iteration
! $E^{k+1}$ the energy at the actual iteration
! $m^{k+1}$ the predicted energy for the actual iteration
! (cf. trust_e_model)

! If $\rho \approx 1$, the agreement is good, contrary to $\rho \approx 0$.
! If $\rho \leq 0$ the previous energy is lower than the actual 
! energy. We have to cancel the last step and use a smaller trust
! region.
! Here we cancel the last step if $\rho < 0.1$, because even if
! the energy decreases, the agreement is bad, i.e., the Taylor expansion
! truncated at the second order doesn't represent correctly the energy
! landscape. So it's better to cancel the step and restart with a
! smaller trust region.

! Provided in qp_edit:
! | thresh_rho |

! Input:
! | prev_energy | double precision | previous energy (energy before the rotation) |
! | e_model     | double precision | predicted energy after the rotation          |

! Output:
! | rho         | double precision | the agreement between the model (predicted) and the real energy |
! | prev_energy | double precision | if rho >= 0.1 the actual energy becomes the previous energy     |
! |             |                  | else the previous energy doesn't change                         |

! Internal:
! | energy | double precision | energy (real) after the rotation |
! | i      | integer          | index                            |
! | t*     | double precision | time                             |


subroutine trust_region_rho(prev_energy, energy,e_model,rho)

  include 'pi.h'

  BEGIN_DOC
  ! Compute rho, the agreement between the predicted criterion/energy and the real one
  END_DOC

  implicit none
   
  ! Variables

  ! In
  double precision, intent(inout) :: prev_energy
  double precision, intent(in)    :: e_model, energy
  
  ! Out
  double precision, intent(out)   :: rho

  ! Internal
  double precision                :: t1, t2, t3
  integer                         :: i

  print*,''
  print*,'---Rho_model---'
  
  call wall_time(t1)

! Rho
! \begin{equation}
! \rho^{k+1} = \frac{E^{k} - E^{k+1}}{E^{k} - m^{k+1}}
! \end{equation}

! In function of $\rho$ th step can be accepted or cancelled.

! If we cancel the last step (k+1), the previous energy (k) doesn't
! change!
! If the step (k+1) is accepted, then the "previous energy" becomes E(k+1) 


! Already done in an other subroutine
  !if (ABS(prev_energy - e_model) < 1d-12) then
  !  print*,'WARNING: prev_energy - e_model < 1d-12'
  !  print*,'=> rho will tend toward infinity'
  !  print*,'Check you convergence criterion !'
  !endif

  rho = (prev_energy - energy) / (prev_energy - e_model)

  print*, 'previous energy, prev_energy :', prev_energy
  print*, 'predicted energy, e_model :', e_model
  print*, 'real energy, energy :', energy
  print*, 'prev_energy - energy :', prev_energy - energy
  print*, 'prev_energy - e_model :', prev_energy - e_model
  print*, 'Rho :', rho
  print*, 'Threshold for rho:', thresh_rho

  ! Modification of prev_energy in function of rho
  if (rho < thresh_rho) then !0.1) then
    ! the step is cancelled  
    print*, 'Rho <', thresh_rho,', the previous energy does not changed'
    print*, 'prev_energy :', prev_energy  
  else
    ! the step is accepted
    prev_energy = energy
    print*, 'Rho >=', thresh_rho,', energy -> prev_energy :', energy
  endif

  call wall_time(t2)
  t3 = t2 - t1
  print*,'Time in rho model:', t3

  print*,'---End rho_model---'
  print*,''

end subroutine
