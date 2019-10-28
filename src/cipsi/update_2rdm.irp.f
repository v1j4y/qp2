use bitmasks

subroutine give_2rdm_pert_contrib(det,coef,psi_det_connection,psi_coef_connection_reverse,n_det_connection,nkeys,keys,values,nkeys_1e,keys_1e,values_1e,sze_buff)
 implicit none
 integer, intent(in) :: n_det_connection,sze_buff
 double precision, intent(in) :: coef(N_states)
 integer(bit_kind), intent(in) :: det(N_int,2)
 integer(bit_kind), intent(in) :: psi_det_connection(N_int,2,n_det_connection) 
 double precision, intent(in)  :: psi_coef_connection_reverse(N_states,n_det_connection)
 integer,           intent(inout) :: keys(4,sze_buff),nkeys
 double precision,  intent(inout) :: values(sze_buff)
 integer,           intent(inout) :: keys_1e(2,sze_buff),nkeys_1e
 double precision,  intent(inout) :: values_1e(sze_buff)
 integer :: i,j
 integer                        :: exc(0:2,2,2)
 integer                        :: degree
 double precision               :: phase, contrib
 do i = 1, n_det_connection
  call get_excitation_degree(det,psi_det_connection(1,1,i),degree,N_int)
  if(degree.gt.2)cycle
  call get_excitation(det,psi_det_connection(1,1,i),exc,degree,phase,N_int) 
  call decode_exc(exc,degree,h1,p1,h2,p2,s1,s2)
  integer :: h1,p1,h2,p2,s1,s2
! print*,''
! print*,''
! print*,''
! print*,''
! print*,'n_det_connection = ',n_det_connection

!  call debug_det(det,N_int)
!  call debug_det(psi_det_connection(1,1,i),N_int)
!  print*,'degree = ',degree
!  print*,'h1,p1,s1',h1,p1,s1
!  print*,'h2,p2,s2',h2,p2,s2

  contrib = 0.d0
  do j = 1, N_states
   contrib += state_average_weight(j) * psi_coef_connection_reverse(j,i)  * coef(j)
  enddo
  ! case of single excitations 
  if(degree == 1)then  ! check for the length of buffer for the ONE BODY DM
   if(nkeys_1e + 2 .ge. sze_buff)then
    call update_keys_values_1e(keys_1e,values_1e,nkeys_1e,n_orb_pert_rdm,pert_1rdm_provider,pert_1rdm_lock)
   endif
  endif
  if(degree == 1)then ! check for the length of buffer for the TWO BODY DM
   if (nkeys + 6 * elec_alpha_num .ge. sze_buff)then
    call update_keys_values(keys,values,nkeys,n_orb_pert_rdm,pert_2rdm_provider,pert_2rdm_lock)
    nkeys = 0
   endif
   call update_buffer_single_exc_rdm(det,psi_det_connection(1,1,i),exc,phase,contrib,nkeys,keys,values,keys_1e,values_1e,nkeys_1e,sze_buff)
  else 
  ! case of double excitations 
   if (nkeys + 4 .ge. sze_buff)then! check for the length of buffer for the TWO BODY DM
    call update_keys_values(keys,values,nkeys,n_orb_pert_rdm,pert_2rdm_provider,pert_2rdm_lock)
    nkeys = 0
   endif
   call update_buffer_double_exc_rdm(exc,phase,contrib,nkeys,keys,values,sze_buff)
  endif
 enddo
 call update_keys_values(keys,values,nkeys,n_orb_pert_rdm,pert_2rdm_provider,pert_2rdm_lock)
 nkeys = 0
 call update_keys_values_1e(keys_1e,values_1e,nkeys_1e,n_orb_pert_rdm,pert_1rdm_provider,pert_1rdm_lock)
 nkeys_1e = 0

end

subroutine update_buffer_single_exc_rdm(det1,det2,exc,phase,contrib,nkeys,keys,values,keys_1e,values_1e,nkeys_1e,sze_buff)
 implicit none
 integer, intent(in) :: sze_buff
 integer(bit_kind), intent(in) :: det1(N_int,2)
 integer(bit_kind), intent(in) :: det2(N_int,2)
 integer,intent(in)             :: exc(0:2,2,2)
 double precision,intent(in)    :: phase, contrib
 integer, intent(inout)         :: nkeys, keys(4,sze_buff)
 double precision, intent(inout):: values(sze_buff)
 integer, intent(inout)         :: nkeys_1e, keys_1e(2,sze_buff)
 double precision, intent(inout):: values_1e(sze_buff)
 
 integer                        :: occ(N_int*bit_kind_size,2)
 integer                        :: n_occ_ab(2),ispin,other_spin
 integer :: h1,h2,p1,p2,i
 call bitstring_to_list_ab(det1, occ, n_occ_ab, N_int)
  
 if (exc(0,1,1) == 1) then
  ! Mono alpha
  h1 = exc(1,1,1)
  p1 = exc(1,2,1)
  ispin = 1
  other_spin = 2
 else
  ! Mono beta
  h1 = exc(1,1,2)
  p1 = exc(1,2,2)
  ispin = 2
  other_spin = 1
 endif
 if(list_orb_reverse_pert_rdm(h1).le.0)return
 h1 = list_orb_reverse_pert_rdm(h1)
 if(list_orb_reverse_pert_rdm(p1).le.0)return
!write(*,'(100(I3,X))')list_orb_reverse_pert_rdm(:)
 p1 = list_orb_reverse_pert_rdm(p1)
 pert_1rdm_provider_bis(h1,p1) += 0.5d0 * contrib * phase
 pert_1rdm_provider_bis(p1,h1) += 0.5d0 * contrib * phase
 nkeys_1e += 1
 values_1e(nkeys_1e) = 0.5d0 * contrib * phase
 keys_1e(1,nkeys_1e) = h1
 keys_1e(2,nkeys_1e) = p1
 nkeys_1e += 1
 values_1e(nkeys_1e) = 0.5d0 * contrib * phase
 keys_1e(1,nkeys_1e) = p1
 keys_1e(2,nkeys_1e) = h1
 !update the alpha/beta part
 do i = 1, n_occ_ab(other_spin)
  h2 = occ(i,other_spin)
  if(list_orb_reverse_pert_rdm(h2).le.0)cycle
  h2 = list_orb_reverse_pert_rdm(h2)

  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = p1
  keys(4,nkeys) = h2
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h2
  keys(2,nkeys) = h1
  keys(3,nkeys) = h2
  keys(4,nkeys) = p1
 enddo 
 !update the same spin part 
 do i = 1, n_occ_ab(ispin)
  h2 = occ(i,ispin)
  if(list_orb_reverse_pert_rdm(h2).le.0)cycle
  h2 = list_orb_reverse_pert_rdm(h2)

  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = p1
  keys(4,nkeys) = h2

  nkeys += 1
  values(nkeys) = - 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = h2
  keys(4,nkeys) = p1
 
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h2
  keys(2,nkeys) = h1
  keys(3,nkeys) = h2
  keys(4,nkeys) = p1

  nkeys += 1
  values(nkeys) = - 0.5d0 * contrib * phase
  keys(1,nkeys) = h2
  keys(2,nkeys) = h1
  keys(3,nkeys) = p1
  keys(4,nkeys) = h2
 enddo 
 call update_keys_values(keys,values,nkeys,n_orb_pert_rdm,pert_2rdm_provider,pert_2rdm_lock)
 nkeys = 0
 call update_keys_values_1e(keys_1e,values_1e,nkeys_1e,n_orb_pert_rdm,pert_1rdm_provider,pert_1rdm_lock)
 nkeys_1e = 0

end

subroutine update_buffer_double_exc_rdm(exc,phase,contrib,nkeys,keys,values,sze_buff)
 implicit none
 integer, intent(in) :: sze_buff
 integer,intent(in)             :: exc(0:2,2,2)
 double precision,intent(in)    :: phase, contrib
 integer, intent(inout)         :: nkeys, keys(4,sze_buff)
 double precision, intent(inout):: values(sze_buff)
 integer :: h1,h2,p1,p2

 if (exc(0,1,1) == 1) then
  ! Double alpha/beta
  h1 = exc(1,1,1) 
  h2 = exc(1,1,2) 
  p1 = exc(1,2,1)
  p2 = exc(1,2,2)
  ! check if the orbitals involved are within the orbital range
  if(list_orb_reverse_pert_rdm(h1).le.0)return
  h1 = list_orb_reverse_pert_rdm(h1)
  if(list_orb_reverse_pert_rdm(h2).le.0)return
  h2 = list_orb_reverse_pert_rdm(h2)
  if(list_orb_reverse_pert_rdm(p1).le.0)return
  p1 = list_orb_reverse_pert_rdm(p1)
  if(list_orb_reverse_pert_rdm(p2).le.0)return
  p2 = list_orb_reverse_pert_rdm(p2)
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = p1
  keys(4,nkeys) = p2
! print*,contrib 
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = p1
  keys(2,nkeys) = p2
  keys(3,nkeys) = h1
  keys(4,nkeys) = h2 
! print*,contrib 

 else 
  if (exc(0,1,1) == 2) then
    ! Double alpha/alpha
   h1 =  exc(1,1,1)
   h2 =  exc(2,1,1)
   p1 =  exc(1,2,1)
   p2 =  exc(2,2,1)
  else if (exc(0,1,2) == 2) then
   ! Double beta
   h1 = exc(1,1,2)
   h2 = exc(2,1,2)
   p1 = exc(1,2,2)
   p2 = exc(2,2,2)
  endif
  ! check if the orbitals involved are within the orbital range
 !print*,'h1 = ',h1
  if(list_orb_reverse_pert_rdm(h1).le.0)return
  h1 = list_orb_reverse_pert_rdm(h1)
  if(list_orb_reverse_pert_rdm(h2).le.0)return
  h2 = list_orb_reverse_pert_rdm(h2)
  if(list_orb_reverse_pert_rdm(p1).le.0)return
  p1 = list_orb_reverse_pert_rdm(p1)
  if(list_orb_reverse_pert_rdm(p2).le.0)return
  p2 = list_orb_reverse_pert_rdm(p2)
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = p1
  keys(4,nkeys) = p2
 
  nkeys += 1
  values(nkeys) = - 0.5d0 * contrib * phase
  keys(1,nkeys) = h1
  keys(2,nkeys) = h2
  keys(3,nkeys) = p2
  keys(4,nkeys) = p1
                                        
  nkeys += 1
  values(nkeys) = 0.5d0 * contrib * phase
  keys(1,nkeys) = h2
  keys(2,nkeys) = h1
  keys(3,nkeys) = p2
  keys(4,nkeys) = p1
 
  nkeys += 1
  values(nkeys) = - 0.5d0 * contrib * phase
  keys(1,nkeys) = h2
  keys(2,nkeys) = h1
  keys(3,nkeys) = p1
  keys(4,nkeys) = p2
 endif
 call update_keys_values(keys,values,nkeys,n_orb_pert_rdm,pert_2rdm_provider,pert_2rdm_lock)
 nkeys = 0
 
end


