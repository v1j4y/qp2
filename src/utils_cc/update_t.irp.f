! T1

subroutine update_t1(nO,nV,f_o,f_v,r1,t1)

  implicit none

  BEGIN_DOC
  ! Update the T1 amplitudes for CC
  END_DOC

  ! in
  integer, intent(in)             :: nO, nV
  double precision, intent(in)    :: f_o(nO), f_v(nV), r1(nO, nV)

  ! inout
  double precision, intent(inout) :: t1(nO, nV)

  ! internal
  integer                         :: i,a

  !$OMP PARALLEL &
  !$OMP SHARED(nO,nV,t1,r1,cc_level_shift,f_o,f_v) &
  !$OMP PRIVATE(i,a) &
  !$OMP DEFAULT(NONE)
  !$OMP DO 
  do a = 1, nV
    do i = 1, nO
      t1(i,a) = t1(i,a) - r1(i,a) / (f_o(i) - f_v(a) - cc_level_shift)
    enddo
  enddo
  !$OMP END DO
  !$OMP END PARALLEL
  
end

! T2

subroutine update_t2(nO,nV,f_o,f_v,r2,t2)

  implicit none

  BEGIN_DOC
  ! Update the T2 amplitudes for CC
  END_DOC

  ! in
  integer, intent(in)             :: nO, nV
  double precision, intent(in)    :: f_o(nO), f_v(nV), r2(nO, nO, nV, nV)

  ! inout
  double precision, intent(inout) :: t2(nO, nO, nV, nV)

  ! internal
  integer                         :: i,j,a,b

  !$OMP PARALLEL &
  !$OMP SHARED(nO,nV,t2,r2,cc_level_shift,f_o,f_v) &
  !$OMP PRIVATE(i,j,a,b) &
  !$OMP DEFAULT(NONE)
  !$OMP DO 
  do b = 1, nV
    do a = 1, nV
      do j = 1, nO
        do i = 1, nO
          t2(i,j,a,b) = t2(i,j,a,b) - r2(i,j,a,b) / (f_o(i) + f_o(j) - f_v(a) - f_v(b) - cc_level_shift)
        enddo
      enddo
    enddo
  enddo
  !$OMP END DO
  !$OMP END PARALLEL
  
end
