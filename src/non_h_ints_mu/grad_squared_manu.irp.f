
BEGIN_PROVIDER [double precision, tc_grad_square_ao_test, (ao_num, ao_num, ao_num, ao_num)]

  BEGIN_DOC
  !
  ! tc_grad_square_ao_test(k,i,l,j) = -1/2 <kl | |\grad_1 u(r1,r2)|^2 + |\grad_1 u(r1,r2)|^2 | ij>
  !
  END_DOC

  implicit none
  integer                       :: ipoint, i, j, k, l
  double precision              :: weight1, ao_ik_r, ao_i_r,contrib,contrib2
  double precision              :: time0, time1
  double precision, allocatable :: b_mat(:,:,:), tmp(:,:,:)

  print*, ' providing tc_grad_square_ao_test ...'
  call wall_time(time0)

  if(read_tc_integ) then

    open(unit=11, form="unformatted", file=trim(ezfio_filename)//'/work/tc_grad_square_ao_test', action="read")
    read(11) tc_grad_square_ao_test
    close(11)

  else

    provide u12sq_j1bsq_test u12_grad1_u12_j1b_grad1_j1b_test grad12_j12_test

    allocate(b_mat(n_points_final_grid,ao_num,ao_num), tmp(ao_num,ao_num,n_points_final_grid))

    b_mat = 0.d0
   !$OMP PARALLEL               &
   !$OMP DEFAULT (NONE)         &
   !$OMP PRIVATE (i, k, ipoint) &
   !$OMP SHARED (aos_in_r_array_transp, b_mat, ao_num, n_points_final_grid, final_weight_at_r_vector)
   !$OMP DO SCHEDULE (static)
    do i = 1, ao_num
      do k = 1, ao_num
        do ipoint = 1, n_points_final_grid
          b_mat(ipoint,k,i) = final_weight_at_r_vector(ipoint) * aos_in_r_array_transp(ipoint,i) * aos_in_r_array_transp(ipoint,k)
        enddo
      enddo
    enddo
   !$OMP END DO
   !$OMP END PARALLEL

    tmp = 0.d0
   !$OMP PARALLEL               &
   !$OMP DEFAULT (NONE)         &
   !$OMP PRIVATE (j, l, ipoint) &
   !$OMP SHARED (tmp, ao_num, n_points_final_grid, u12sq_j1bsq_test, u12_grad1_u12_j1b_grad1_j1b_test, grad12_j12_test)
   !$OMP DO SCHEDULE (static)
    do ipoint = 1, n_points_final_grid
      do j = 1, ao_num
        do l = 1, ao_num
          tmp(l,j,ipoint) = u12sq_j1bsq_test(l,j,ipoint) + u12_grad1_u12_j1b_grad1_j1b_test(l,j,ipoint) + 0.5d0 * grad12_j12_test(l,j,ipoint)
        enddo
      enddo
    enddo
   !$OMP END DO
   !$OMP END PARALLEL

    tc_grad_square_ao_test = 0.d0
    call dgemm( "N", "N", ao_num*ao_num, ao_num*ao_num, n_points_final_grid, 1.d0 &
              , tmp(1,1,1), ao_num*ao_num, b_mat(1,1,1), n_points_final_grid      &
              , 1.d0, tc_grad_square_ao_test, ao_num*ao_num)
    deallocate(tmp, b_mat)

    call sum_A_At(tc_grad_square_ao_test(1,1,1,1), ao_num*ao_num)
    !do i = 1, ao_num
    !  do j = 1, ao_num
    !    do k = i, ao_num

    !      do l = max(j,k), ao_num
    !        tc_grad_square_ao_test(i,j,k,l) = 0.5d0 * (tc_grad_square_ao_test(i,j,k,l) + tc_grad_square_ao_test(k,l,i,j))
    !        tc_grad_square_ao_test(k,l,i,j) = tc_grad_square_ao_test(i,j,k,l)
    !      end do

    !      !if (j.eq.k) then
    !      !  do l = j+1, ao_num
    !      !    tc_grad_square_ao_test(i,j,k,l) = 0.5d0 * (tc_grad_square_ao_test(i,j,k,l) + tc_grad_square_ao_test(k,l,i,j))
    !      !    tc_grad_square_ao_test(k,l,i,j) = tc_grad_square_ao_test(i,j,k,l)
    !      !  end do
    !      !else
    !      !  do l = j, ao_num
    !      !    tc_grad_square_ao_test(i,j,k,l) = 0.5d0 * (tc_grad_square_ao_test(i,j,k,l) + tc_grad_square_ao_test(k,l,i,j))
    !      !    tc_grad_square_ao_test(k,l,i,j) = tc_grad_square_ao_test(i,j,k,l)
    !      !  enddo
    !      !endif

    !    enddo
    !  enddo
    !enddo
    !tc_grad_square_ao_test = 2.d0 * tc_grad_square_ao_test
  ! !$OMP PARALLEL             &
  ! !$OMP DEFAULT (NONE)       &
  ! !$OMP PRIVATE (i, j, k, l) &
  ! !$OMP SHARED (tc_grad_square_ao_test, ao_num)
  ! !$OMP DO SCHEDULE (static)
  !  integer :: ii
  !  ii = 0
  !  do j = 1, ao_num
  !    do l = 1, ao_num
  !      do i = 1, ao_num
  !        do k = 1, ao_num
  !          if((i.lt.j) .and. (k.lt.l)) cycle
  !          ii = ii + 1
  !          tc_grad_square_ao_test(k,i,l,j) = tc_grad_square_ao_test(k,i,l,j) + tc_grad_square_ao_test(l,j,k,i)
  !        enddo
  !      enddo
  !    enddo
  !  enddo
  !  print *, ' ii =', ii
  ! !$OMP END DO
  ! !$OMP END PARALLEL

  ! !$OMP PARALLEL             &
  ! !$OMP DEFAULT (NONE)       &
  ! !$OMP PRIVATE (i, j, k, l) &
  ! !$OMP SHARED (tc_grad_square_ao_test, ao_num)
  ! !$OMP DO SCHEDULE (static)
  !  do j = 1, ao_num
  !    do l = 1, ao_num
  !      do i = 1, j-1
  !        do k = 1, l-1
  !          ii = ii + 1
  !          tc_grad_square_ao_test(k,i,l,j) = tc_grad_square_ao_test(l,j,k,i)
  !        enddo
  !      enddo
  !    enddo
  !  enddo
  !  print *, ' ii =', ii
  !  print *, ao_num * ao_num * ao_num * ao_num
  ! !$OMP END DO
  ! !$OMP END PARALLEL

  endif

  if(write_tc_integ.and.mpi_master) then
    open(unit=11, form="unformatted", file=trim(ezfio_filename)//'/work/tc_grad_square_ao_test', action="write")
    call ezfio_set_work_empty(.False.)
    write(11) tc_grad_square_ao_test
    close(11)
    call ezfio_set_tc_keywords_io_tc_integ('Read')
  endif

  call wall_time(time1)
  print*, ' Wall time for tc_grad_square_ao_test = ', time1 - time0

END_PROVIDER

! ---

BEGIN_PROVIDER [double precision, tc_grad_square_ao_test_ref, (ao_num, ao_num, ao_num, ao_num)]

  BEGIN_DOC
  !
  ! tc_grad_square_ao_test_ref(k,i,l,j) = -1/2 <kl | |\grad_1 u(r1,r2)|^2 + |\grad_1 u(r1,r2)|^2 | ij>
  !
  END_DOC

  implicit none
  integer                       :: ipoint, i, j, k, l
  double precision              :: weight1, ao_ik_r, ao_i_r,contrib,contrib2
  double precision              :: time0, time1
  double precision, allocatable :: ac_mat(:,:,:,:), b_mat(:,:,:), tmp(:,:,:)

  print*, ' providing tc_grad_square_ao_test_ref ...'
  call wall_time(time0)

  provide u12sq_j1bsq_test u12_grad1_u12_j1b_grad1_j1b_test grad12_j12_test

  allocate(ac_mat(ao_num,ao_num,ao_num,ao_num), b_mat(n_points_final_grid,ao_num,ao_num), tmp(ao_num,ao_num,n_points_final_grid))

  b_mat = 0.d0
 !$OMP PARALLEL               &
 !$OMP DEFAULT (NONE)         &
 !$OMP PRIVATE (i, k, ipoint) &
 !$OMP SHARED (aos_in_r_array_transp, b_mat, ao_num, n_points_final_grid, final_weight_at_r_vector)
 !$OMP DO SCHEDULE (static)
  do i = 1, ao_num
    do k = 1, ao_num
      do ipoint = 1, n_points_final_grid
        b_mat(ipoint,k,i) = final_weight_at_r_vector(ipoint) * aos_in_r_array_transp(ipoint,i) * aos_in_r_array_transp(ipoint,k)
      enddo
    enddo
  enddo
 !$OMP END DO
 !$OMP END PARALLEL

  tmp = 0.d0
 !$OMP PARALLEL               &
 !$OMP DEFAULT (NONE)         &
 !$OMP PRIVATE (j, l, ipoint) &
 !$OMP SHARED (tmp, ao_num, n_points_final_grid, u12sq_j1bsq_test, u12_grad1_u12_j1b_grad1_j1b_test, grad12_j12_test)
 !$OMP DO SCHEDULE (static)
  do ipoint = 1, n_points_final_grid
    do j = 1, ao_num
      do l = 1, ao_num
        tmp(l,j,ipoint) = u12sq_j1bsq_test(l,j,ipoint) + u12_grad1_u12_j1b_grad1_j1b_test(l,j,ipoint) + 0.5d0 * grad12_j12_test(l,j,ipoint)
      enddo
    enddo
  enddo
 !$OMP END DO
 !$OMP END PARALLEL

  ac_mat = 0.d0
  call dgemm( "N", "N", ao_num*ao_num, ao_num*ao_num, n_points_final_grid, 1.d0 &
            , tmp(1,1,1), ao_num*ao_num, b_mat(1,1,1), n_points_final_grid      &
            , 1.d0, ac_mat, ao_num*ao_num)
  deallocate(tmp, b_mat)

 !$OMP PARALLEL             &
 !$OMP DEFAULT (NONE)       &
 !$OMP PRIVATE (i, j, k, l) &
 !$OMP SHARED (ac_mat, tc_grad_square_ao_test_ref, ao_num)
 !$OMP DO SCHEDULE (static)
  do j = 1, ao_num
    do l = 1, ao_num
      do i = 1, ao_num
        do k = 1, ao_num
          tc_grad_square_ao_test_ref(k,i,l,j) = ac_mat(k,i,l,j) + ac_mat(l,j,k,i)
        enddo
      enddo
    enddo
  enddo
 !$OMP END DO
 !$OMP END PARALLEL

  deallocate(ac_mat)

  call wall_time(time1)
  print*, ' Wall time for tc_grad_square_ao_test_ref = ', time1 - time0

END_PROVIDER

! ---

BEGIN_PROVIDER [ double precision, u12sq_j1bsq_test, (ao_num, ao_num, n_points_final_grid) ]

  implicit none
  integer                    :: ipoint, i, j
  double precision           :: tmp_x, tmp_y, tmp_z
  double precision           :: tmp1
  double precision           :: time0, time1

  print*, ' providing u12sq_j1bsq_test ...'
  call wall_time(time0)

  do ipoint = 1, n_points_final_grid
    tmp_x = v_1b_grad(1,ipoint)
    tmp_y = v_1b_grad(2,ipoint)
    tmp_z = v_1b_grad(3,ipoint)
    tmp1  = -0.5d0 * (tmp_x * tmp_x + tmp_y * tmp_y + tmp_z * tmp_z)
    do j = 1, ao_num
      do i = 1, ao_num
        u12sq_j1bsq_test(i,j,ipoint) = tmp1 * int2_u2_j1b2_test(i,j,ipoint)
      enddo
    enddo
  enddo

  call wall_time(time1)
  print*, ' Wall time for u12sq_j1bsq_test = ', time1 - time0

END_PROVIDER

! ---

BEGIN_PROVIDER [ double precision, u12_grad1_u12_j1b_grad1_j1b_test, (ao_num, ao_num, n_points_final_grid) ]

  implicit none
  integer                    :: ipoint, i, j, m, igauss
  double precision           :: x, y, z
  double precision           :: tmp_v, tmp_x, tmp_y, tmp_z
  double precision           :: tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9
  double precision           :: time0, time1
  double precision, external :: overlap_gauss_r12_ao

  print*, ' providing u12_grad1_u12_j1b_grad1_j1b_test ...'

  provide int2_u_grad1u_x_j1b2_test
  call wall_time(time0)

  do ipoint = 1, n_points_final_grid

    x     = final_grid_points(1,ipoint)
    y     = final_grid_points(2,ipoint)
    z     = final_grid_points(3,ipoint)
    tmp_v = v_1b       (ipoint)
    tmp_x = v_1b_grad(1,ipoint)
    tmp_y = v_1b_grad(2,ipoint)
    tmp_z = v_1b_grad(3,ipoint)

    tmp3 = tmp_v * tmp_x
    tmp4 = tmp_v * tmp_y
    tmp5 = tmp_v * tmp_z

    tmp6 = -x * tmp3
    tmp7 = -y * tmp4
    tmp8 = -z * tmp5

    do j = 1, ao_num
      do i = 1, ao_num

        tmp9 = int2_u_grad1u_j1b2_test(i,j,ipoint)

        u12_grad1_u12_j1b_grad1_j1b_test(i,j,ipoint) = tmp6 * tmp9 + tmp3 * int2_u_grad1u_x_j1b2_test(i,j,ipoint,1) &
                                                     + tmp7 * tmp9 + tmp4 * int2_u_grad1u_x_j1b2_test(i,j,ipoint,2) &
                                                     + tmp8 * tmp9 + tmp5 * int2_u_grad1u_x_j1b2_test(i,j,ipoint,3)
      enddo
    enddo
  enddo

  call wall_time(time1)
  print*, ' Wall time for u12_grad1_u12_j1b_grad1_j1b_test = ', time1 - time0

END_PROVIDER

! ---

BEGIN_PROVIDER [ double precision, grad12_j12_test, (ao_num, ao_num, n_points_final_grid) ]

  implicit none
  integer                    :: ipoint, i, j, m, igauss
  double precision           :: r(3), delta, coef
  double precision           :: tmp1
  double precision           :: time0, time1
  double precision, external :: overlap_gauss_r12_ao
  provide int2_grad1u2_grad2u2_j1b2_test
  print*, ' providing grad12_j12_test ...'
  call wall_time(time0)

  PROVIDE j1b_type

  if(j1b_type .eq. 3) then

    do ipoint = 1, n_points_final_grid
      tmp1 = v_1b(ipoint)
      tmp1 = tmp1 * tmp1
      do j = 1, ao_num
        do i = 1, ao_num
          grad12_j12_test(i,j,ipoint) = tmp1 * int2_grad1u2_grad2u2_j1b2_test(i,j,ipoint)
        enddo
      enddo
    enddo

  else

    grad12_j12_test = 0.d0
    do ipoint = 1, n_points_final_grid
      r(1) = final_grid_points(1,ipoint)
      r(2) = final_grid_points(2,ipoint)
      r(3) = final_grid_points(3,ipoint)
      do j = 1, ao_num
        do i = 1, ao_num
          do igauss = 1, n_max_fit_slat
            delta = expo_gauss_1_erf_x_2(igauss)
            coef  = coef_gauss_1_erf_x_2(igauss)
            grad12_j12_test(i,j,ipoint) += -0.25d0 * coef * overlap_gauss_r12_ao(r, delta, i, j)
          enddo
        enddo
      enddo
    enddo

  endif

  call wall_time(time1)
  print*, ' Wall time for grad12_j12_test = ', time1 - time0

END_PROVIDER

! ---

