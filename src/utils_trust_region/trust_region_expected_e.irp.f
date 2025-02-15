! Predicted energy : e_model

! *Compute the energy predicted by the Taylor series*

! The energy is predicted using a Taylor expansion truncated at te 2nd
! order :

! \begin{align*}
! E_{k+1} = E_{k} + \textbf{g}_k^{T} \cdot \textbf{x}_{k+1} + \frac{1}{2} \cdot \textbf{x}_{k+1}^T \cdot \textbf{H}_{k} \cdot \textbf{x}_{k+1} + \mathcal{O}(\textbf{x}_{k+1}^2)
! \end{align*}

! Input:
! | n           | integer          | m*(m-1)/2                |
! | v_grad(n)   | double precision | gradient                 |
! | H(n,n)      | double precision | hessian                  |
! | x(n)        | double precision | Step in the trust region |
! | prev_energy | double precision | previous energy          |

! Output:
! | e_model | double precision | predicted energy after the rotation of the MOs |

! Internal:
! | part_1  | double precision | v_grad^T.x    |
! | part_2  | double precision | 1/2 . x^T.H.x |
! | part_2a | double precision | H.x           |
! | i,j     | integer          | indexes       |

! Function:
! | ddot | double precision | dot product (Lapack) |


subroutine trust_region_expected_e(n,v_grad,H,x,prev_energy,e_model)
   
  include 'pi.h'

  BEGIN_DOC
  ! Compute the expected criterion/energy after the application of the step x
  END_DOC

  implicit none

  ! Variables

  ! in
  integer, intent(in)           :: n
  double precision, intent(in)  :: v_grad(n),H(n,n),x(n)
  double precision, intent(in)  :: prev_energy

  ! out
  double precision, intent(out) :: e_model

  ! internal
  double precision              :: part_1, part_2, t1,t2,t3
  double precision, allocatable :: part_2a(:)

  integer                       :: i,j

  !Function
  double precision              :: ddot

  print*,''
  print*,'---Trust_e_model---'

  call wall_time(t1)

  ! Allocation
  allocate(part_2a(n))

! Calculations

! part_1 corresponds to the product g.x
! part_2a corresponds to the product H.x
! part_2 corresponds to the product 0.5*(x^T.H.x)

! TODO: remove the dot products


! Product v_grad.x
  part_1 = ddot(n,v_grad,1,x,1)
 
  !if (debug) then
    print*,'g.x : ', part_1
  !endif  

  ! Product H.x
  call dgemv('N',n,n,1d0,H,size(H,1),x,1,0d0,part_2a,1)

  ! Product 1/2 . x^T.H.x
  part_2 = 0.5d0 * ddot(n,x,1,part_2a,1)

  !if (debug) then
    print*,'1/2*x^T.H.x : ', part_2 
  !endif

  print*,'prev_energy', prev_energy

  ! Sum
  e_model = prev_energy + part_1 + part_2

  ! Writing the predicted energy
  print*, 'Predicted energy after the rotation : ', e_model
  print*, 'Previous energy - predicted energy:', prev_energy - e_model
  
  ! Can be deleted, already in another subroutine
  if (DABS(prev_energy - e_model) < 1d-12 ) then 
    print*,'WARNING: ABS(prev_energy - e_model) < 1d-12'
  endif

  ! Deallocation
  deallocate(part_2a)

  call wall_time(t2)
  t3 = t2 - t1
  print*,'Time in trust e model:', t3

  print*,'---End trust_e_model---'
  print*,''
 
end subroutine
