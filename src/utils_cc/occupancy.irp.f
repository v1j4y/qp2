! N spin orb

subroutine extract_n_spin(det,n)

  implicit none

  BEGIN_DOC
  ! Returns the number of occupied alpha, occupied beta, virtual alpha, virtual beta spin orbitals
  ! in det without counting the core and deleted orbitals in the format n(nOa,nOb,nVa,nVb)
  END_DOC

  integer(bit_kind), intent(in) :: det(N_int,2)
  
  integer, intent(out)          :: n(4)
  
  integer(bit_kind)             :: res(N_int,2)
  integer                       :: i, si
  logical                       :: ok, is_core, is_del

  ! Init
  n = 0

  ! Loop over the spin
  do si = 1, 2
    do i = 1, mo_num
      call apply_hole(det, si, i, res, ok, N_int)
      
      ! in core ?
      if (is_core(i)) cycle
      ! in del ?
      if (is_del(i)) cycle
      
      if (ok) then
        ! particle
        n(si) = n(si) + 1
      else
        ! hole
        n(si+2) = n(si+2) + 1
      endif
    enddo
  enddo

  !print*,n(1),n(2),n(3),n(4)

end

! Spin

subroutine extract_list_orb_spin(det,nO_m,nV_m,list_occ,list_vir)

  implicit none

  BEGIN_DOC
  ! Returns the the list of occupied alpha/beta, virtual alpha/beta spin orbitals
  ! size(nO_m,1) must be max(nOa,nOb) and size(nV_m,1) must be max(nVa,nVb)
  END_DOC
  
  integer, intent(in)           :: nO_m, nV_m
  integer(bit_kind), intent(in) :: det(N_int,2)
  
  integer, intent(out)          :: list_occ(nO_m,2), list_vir(nV_m,2)
  
  integer(bit_kind)             :: res(N_int,2)
  integer                       :: i, si, idx_o, idx_v, idx_i, idx_b
  logical                       :: ok, is_core, is_del

  list_occ = 0
  list_vir = 0

  ! List of occ/vir alpha/beta

  ! occ alpha -> list_occ(:,1)
  ! occ beta -> list_occ(:,2)
  ! vir alpha -> list_vir(:,1)
  ! vir beta -> list_vir(:,2)

  ! Loop over the spin 
  do si = 1, 2
    ! tmp idx
    idx_o = 1
    idx_v = 1
    do i = 1, mo_num
      call apply_hole(det, si, i, res, ok, N_int)

      ! in core ?
      if (is_core(i)) cycle
      ! in del ?
      if (is_del(i)) cycle
            
      if (ok) then
        ! particle
        list_occ(idx_o,si) = i
        idx_o = idx_o + 1
      else
        ! hole
        list_vir(idx_v,si) = i
        idx_v = idx_v + 1
      endif
    enddo
  enddo

end

! Space

subroutine extract_list_orb_space(det,nO,nV,list_occ,list_vir)

  implicit none

  BEGIN_DOC
  ! Returns the the list of occupied and virtual alpha spin orbitals
  END_DOC
  
  integer, intent(in)           :: nO, nV
  integer(bit_kind), intent(in) :: det(N_int,2)
  
  integer, intent(out)          :: list_occ(nO), list_vir(nV)
  
  integer(bit_kind)             :: res(N_int,2)
  integer                       :: i, si, idx_o, idx_v, idx_i, idx_b
  logical                       :: ok, is_core, is_del
  
  if (elec_alpha_num /= elec_beta_num) then
    print*,'Error elec_alpha_num /= elec_beta_num, impossible to create cc_list_occ and cc_list_vir, abort'
    call abort
  endif

  list_occ = 0
  list_vir = 0

  ! List of occ/vir alpha

  ! occ alpha -> list_occ(:,1)
  ! vir alpha -> list_vir(:,1)

  ! tmp idx
  idx_o = 1
  idx_v = 1
  do i = 1, mo_num
    call apply_hole(det, 1, i, res, ok, N_int)

    ! in core ?
    if (is_core(i)) cycle
    ! in del ?
    if (is_del(i)) cycle

    if (ok) then
      ! particle
      list_occ(idx_o) = i
      idx_o = idx_o + 1
    else
      ! hole
      list_vir(idx_v) = i
      idx_v = idx_v + 1
    endif
  enddo

end

! is_core

function is_core(i)

  implicit none

  BEGIN_DOC
  ! True if the orbital i is a core orbital
  END_DOC

  integer, intent(in) :: i
  logical             :: is_core

  integer             :: j

  ! Init
  is_core = .False.

  ! Search
  do j = 1, dim_list_core_orb
    if (list_core(j) == i) then
      is_core = .True.
      exit
    endif
  enddo

end

! is_del

function is_del(i)

  implicit none

  BEGIN_DOC
  ! True if the orbital i is a deleted orbital
  END_DOC

  integer, intent(in) :: i
  logical             :: is_del

  integer             :: j

  ! Init
  is_del = .False.

  ! Search
  do j = 1, dim_list_core_orb
    if (list_core(j) == i) then
      is_del = .True.
      exit
    endif
  enddo

end

! N orb

BEGIN_PROVIDER [integer, cc_nO_m]
&BEGIN_PROVIDER [integer, cc_nOa]
&BEGIN_PROVIDER [integer, cc_nOb]
&BEGIN_PROVIDER [integer, cc_nOab]
&BEGIN_PROVIDER [integer, cc_nV_m]
&BEGIN_PROVIDER [integer, cc_nVa]
&BEGIN_PROVIDER [integer, cc_nVb]
&BEGIN_PROVIDER [integer, cc_nVab]
&BEGIN_PROVIDER [integer, cc_n_mo]
&BEGIN_PROVIDER [integer, cc_nO_S, (2)]
&BEGIN_PROVIDER [integer, cc_nV_S, (2)]

  implicit none

  BEGIN_DOC
  ! Number of orbitals without core and deleted ones of the cc_ref det in psi_det
  ! a: alpha, b: beta
  ! nO_m: max(a,b) occupied 
  ! nOa: nb a occupied 
  ! nOb: nb b occupied 
  ! nOab: nb a+b occupied 
  ! nV_m: max(a,b) virtual 
  ! nVa: nb a virtual 
  ! nVb: nb b virtual 
  ! nVab: nb a+b virtual 
  END_DOC

  integer :: n_spin(4)

  ! Extract number of occ/vir alpha/beta spin orbitals
  call extract_n_spin(psi_det(1,1,cc_ref),n_spin)

  cc_nOa  = n_spin(1)
  cc_nOb  = n_spin(2)
  cc_nOab = cc_nOa + cc_nOb    !n_spin(1) + n_spin(2)
  cc_nO_m = max(cc_nOa,cc_nOb) !max(n_spin(1), n_spin(2))
  cc_nVa  = n_spin(3)
  cc_nVb  = n_spin(4)
  cc_nVab = cc_nVa + cc_nVb    !n_spin(3) + n_spin(4)
  cc_nV_m = max(cc_nVa,cc_nVb) !max(n_spin(3), n_spin(4))
  cc_n_mo = cc_nVa + cc_nVb    !n_spin(1) + n_spin(3)
  cc_nO_S = (/cc_nOa,cc_nOb/)
  cc_nV_S = (/cc_nVa,cc_nVb/)

END_PROVIDER

! General

BEGIN_PROVIDER [integer, cc_list_gen, (cc_n_mo)]

  implicit none

  BEGIN_DOC
  ! List of general orbitals without core and deleted ones
  END_DOC

  integer :: i,j
  logical :: is_core, is_del
  
  j = 1
  do i = 1, mo_num
    ! in core ?
    if (is_core(i)) cycle
    ! in del ?
    if (is_del(i)) cycle
    cc_list_gen(j) = i
    j = j+1
  enddo

END_PROVIDER

! Space

BEGIN_PROVIDER [integer, cc_list_occ, (cc_nOa)]
&BEGIN_PROVIDER [integer, cc_list_vir, (cc_nVa)]

  implicit none

  BEGIN_DOC
  ! List of occupied and virtual spatial orbitals without core and deleted ones
  END_DOC

  call extract_list_orb_space(psi_det(1,1,cc_ref),cc_nOa,cc_nVa,cc_list_occ,cc_list_vir)

END_PROVIDER

! Spin

BEGIN_PROVIDER [integer, cc_list_occ_spin, (cc_nO_m,2)]
&BEGIN_PROVIDER [integer, cc_list_vir_spin, (cc_nV_m,2)]
&BEGIN_PROVIDER [logical, cc_ref_is_open_shell]

  implicit none

  BEGIN_DOC
  ! List of occupied and virtual spin orbitals without core and deleted ones
  END_DOC

  integer :: i

  call extract_list_orb_spin(psi_det(1,1,cc_ref),cc_nO_m,cc_nV_m,cc_list_occ_spin,cc_list_vir_spin)

  cc_ref_is_open_shell = .False.
  do i = 1, cc_nO_m
    if (cc_list_occ_spin(i,1) /= cc_list_occ_spin(i,2)) then
       cc_ref_is_open_shell = .True.
    endif
  enddo


END_PROVIDER
