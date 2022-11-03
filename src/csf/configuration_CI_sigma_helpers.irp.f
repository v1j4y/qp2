use bitmasks

 BEGIN_PROVIDER [ integer(bit_kind), alphasIcfg_list , (N_int,2,N_configuration,mo_num*(mo_num))]
&BEGIN_PROVIDER [ integer, NalphaIcfg_list, (N_configuration) ]
  implicit none
  !use bitmasks
  BEGIN_DOC
  ! Documentation for alphasI
  ! Returns the associated alpha's for
  ! the input configuration Icfg.
  END_DOC

  integer                        :: idxI ! The id of the Ith CFG
  integer(bit_kind)              :: Icfg(N_int,2)
  integer(bit_kind)              :: Jcfg(N_int,2)
  integer                        :: NalphaIcfg
  logical,dimension(:,:),allocatable :: tableUniqueAlphas
  integer                        :: listholes(mo_num)
  integer                        :: holetype(mo_num) ! 1-> SOMO 2->DOMO
  integer                        :: nholes
  integer                        :: nvmos
  integer                        :: listvmos(mo_num)
  integer                        :: vmotype(mo_num) ! 1 -> VMO 2 -> SOMO
  integer*8                      :: Idomo, Idomop, Idomoq 
  integer*8                      :: Isomo, Isomop, Isomoq
  integer*8                      :: Jdomo, Jdomop, Jdomoq
  integer*8                      :: Jsomo, Jsomop, Jsomoq
  integer*8                      :: diffSOMO
  integer*8                      :: diffDOMO
  integer*8                      :: xordiffSOMODOMO
  integer                        :: ndiffSOMO
  integer                        :: ndiffDOMO
  integer                        :: nxordiffSOMODOMO
  integer                        :: ndiffAll
  integer                        :: i,ii,iii
  integer                        :: j,jj, i_s, i_d
  integer                        :: k,kk
  integer                        :: kstart
  integer                        :: kend
  integer                        :: Nsomo_I, Nsomo_J
  integer                        :: hole, n_core_orb_64
  integer                        :: p, pp, p_s
  integer                        :: q, qq, q_s
  integer                        :: countalphas
  logical                        :: pqAlreadyGenQ
  logical                        :: pqExistsQ
  logical                        :: ppExistsQ
  integer*8                      :: MS
  integer :: listall(N_int*bit_kind_size), nelall

  double precision               :: t0, t1
  call wall_time(t0)

  MS = elec_alpha_num-elec_beta_num

  allocate(tableUniqueAlphas(mo_num,mo_num))
  NalphaIcfg_list = 0

  do idxI = 1, N_configuration

    Icfg  = psi_configuration(:,:,idxI)
    Jcfg  = psi_configuration(:,:,idxI)
    !print *," Jcfg somo=",Jcfg(1,1), " ", Jcfg(2,1)
    !print *," Jcfg domo=",Jcfg(1,2), " ", Jcfg(2,2)

    Isomo = iand(act_bitmask(1,1),Icfg(1,1))
    Idomo = iand(act_bitmask(1,1),Icfg(1,2))

    ! find out all pq holes possible
    nholes = 0
    ! holes in SOMO
    !do ii = 1,n_act_orb
    !  i = list_act(ii)
    !  if(POPCNT(IAND(Isomo,IBSET(0_8,i-1))) .EQ. 1) then
    !    nholes += 1
    !    listholes(nholes) = i
    !    holetype(nholes) = 1
    !  endif
    !end do
        call bitstring_to_list(psi_configuration(1,1,idxI),listall,nelall,N_int)

        !print *,'list somo'
        do iii=1,nelall
          nholes += 1
          listholes(nholes) = listall(iii)
            !print *,listall(iii)
          holetype(nholes) = 1
        end do

        Nsomo_I = nelall

    ! holes in DOMO
    !do ii = 1,n_act_orb
    !  i = list_act(ii)
    !  if(POPCNT(IAND(Idomo,IBSET(0_8,i-1))) .EQ. 1) then
    !    nholes += 1
    !    listholes(nholes) = i
    !    holetype(nholes) = 2
    !  endif
    !end do

    !do iii=1,N_int
    !  print *,' iii=',iii, psi_configuration(iii,2,idxI), ' idxI=',idxI
    !end do
        call bitstring_to_list(psi_configuration(1,2,idxI),listall,nelall,N_int)

        !print *,'list domo ncore=',n_core_orb, ' nelall=',nelall
        do iii=1,nelall
          if(listall(iii) .gt. n_core_orb)then
            nholes += 1
            listholes(nholes) = listall(iii)
            !print *,listall(iii)
            holetype(nholes) = 2
          endif
        end do

    ! find vmos
    listvmos = -1
    vmotype = -1
    nvmos = 0
    !do ii = 1,n_act_orb
    !  i = list_act(ii)
    !  if(IAND(Idomo,(IBSET(0_8,i-1))) .EQ. 0) then
    !    if(IAND(Isomo,(IBSET(0_8,i-1))) .EQ. 0) then
    !      nvmos += 1
    !      listvmos(nvmos) = i
    !      print *,'1 i=',i
    !      vmotype(nvmos) = 1
    !    else if(POPCNT(IAND(Isomo,(IBSET(0_8,i-1)))) .EQ. 1) then
    !      nvmos += 1
    !      listvmos(nvmos) = i
    !      print *,'2 i=',i
    !      vmotype(nvmos) = 2
    !    end if
    !  end if
    !end do
    !print *,'-----------'

    ! Take into account N_int
    do ii = 1, n_act_orb
      iii = list_act(ii)
      i_s = (1+((iii-1)/63))
      i = iii - ( i_s -1 )*63 
      Isomo = iand(act_bitmask(i_s,1),Icfg(i_s,1))
      Idomo = iand(act_bitmask(i_s,1),Icfg(i_s,2))

      if(IAND(Idomo,(IBSET(0_8,i-1))) .EQ. 0) then
        if(IAND(Isomo,(IBSET(0_8,i-1))) .EQ. 0) then
          nvmos += 1
          listvmos(nvmos) = iii
          vmotype(nvmos) = 1
        else if(POPCNT(IAND(Isomo,(IBSET(0_8,i-1)))) .EQ. 1) then
          nvmos += 1
          listvmos(nvmos) = iii
          vmotype(nvmos) = 2
        end if
      end if
    end do

    tableUniqueAlphas = .FALSE.

    ! Now find the allowed (p,q) excitations
    Isomo = iand(act_bitmask(1,1),Icfg(1,1))
    Idomo = iand(act_bitmask(1,1),Icfg(1,2))
    !Nsomo_I = POPCNT(Isomo)
    if(Nsomo_I .EQ. 0) then
      kstart = 1
    else
      kstart = cfg_seniority_index(max(NSOMOMin,Nsomo_I-2))
    endif
    kend = idxI-1

    do i = 1,nholes
      pp  = listholes(i)
      p_s = (1+((pp-1)/63))
      p   = pp - (p_s - 1)*63
      !print *,' pp=',pp, ' p_s=',p_s, ' p=',p
      do j = 1,nvmos
        qq  = listvmos(j)
        q_s = (1+((qq-1)/63))
        q   = qq - (q_s - 1)*63
        !print *,' qq=',qq, ' q_s=',q_s, ' q=',q
        Isomop = iand(act_bitmask(i_s,1),Icfg(p_s,1))
        Idomop = iand(act_bitmask(i_s,1),Icfg(p_s,2))
        Isomop = iand(act_bitmask(i_s,1),Icfg(q_s,1))
        Idomop = iand(act_bitmask(i_s,1),Icfg(q_s,2))
        if(p .EQ. q) cycle
        if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 1) then
          ! SOMO -> VMO
          !print *,'SOMO -> VMO'
          if (p_s .eq. q_s) then
            Jsomop = IBCLR(Isomop,p-1)
            Jsomop = IBSET(Jsomop,q-1)
            Jsomoq = Jsomop
          else
            Jsomop = IBCLR(Isomop,p-1)
            Jsomoq = IBSET(Isomoq,q-1)
          endif

          ! Domo remains the same
          Jdomop = Idomop
          Jdomoq = Idomoq

          kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-2)))
          kend = idxI-1
        else if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 2) then
          ! SOMO -> SOMO
          !print *,'SOMO -> SOMO'
          if(p_s .eq. q_s) then
            Jsomop = IBCLR(Isomop,p-1)
            Jsomop = IBCLR(Jsomop,q-1)
            Jsomoq = Jsomop
          else
            Jsomop = IBCLR(Isomop,p-1)
            Jsomoq = IBCLR(Isomoq,q-1)
          endif

          Jdomoq = IBSET(Idomoq,q-1)

          ! Check for Minimal alpha electrons (MS)
          if(POPCNT(Jsomoq).ge.MS)then
            kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-4)))
            kend = idxI-1
          else
            cycle
          endif
        else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 1) then
          ! DOMO -> VMO
          !print *,'DOMO -> VMO', Isomop, p, q, Jsomop
          if(p_s .eq. q_s) then
            Jsomop = IBSET(Isomop,p-1)
            Jsomop = IBSET(Jsomop,q-1)
            Jsomoq = Jsomop
          else
            Jsomop = IBSET(Isomop,p-1)
            Jsomoq = IBSET(Jsomoq,q-1)
          endif
          !print *, 'Jsomop=', Jsomop

          Jdomop = IBCLR(Idomop,p-1)

          kstart = cfg_seniority_index(Nsomo_I)
          kend = idxI-1
        else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 2) then
          ! DOMO -> SOMO
          !print *,'DOMO -> SOMO'
          if(p_s .eq. q_s) then
            Jsomop = IBSET(Isomop,p-1)
            Jsomop = IBCLR(Jsomop,q-1)
            Jsomoq = Jsomop

            Jdomop = IBCLR(Idomop,p-1)
            Jdomop = IBSET(Jdomop,q-1)
            Jdomoq = Jdomop
          else
            Jsomop = IBSET(Isomop,p-1)
            Jsomoq = IBCLR(Jsomoq,q-1)

            Jdomop = IBCLR(Idomop,p-1)
            Jdomoq = IBSET(Jdomoq,q-1)
          endif

          kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-2)))
          kend = idxI-1
        else
          print*,"Something went wrong in obtain_associated_alphaI"
        endif

        ! Save it to Jcfg
        !print *,i,j,"0| nalpha=",NalphaIcfg, " somo=",Jcfg(1,1),Jcfg(2,1)
        Jcfg(p_s,1) = Jsomop
        Jcfg(q_s,1) = Jsomoq
        Jcfg(p_s,2) = Jdomop
        Jcfg(q_s,2) = Jdomoq
        !print *,'p_s=',p_s,' q_s=', q_s
        !print *,'Jsomop=',Jsomop, ' Jsomoq=', Jsomoq, ' Jdomop=', Jdomop, ' Jdomoq=', Jdomo
        !print *,i,j,"1| nalpha=",NalphaIcfg, " somo=",Jcfg(1,1),Jcfg(2,1)
        call bitstring_to_list(Jcfg(1,1),listall,nelall,N_int)
        Nsomo_J = nelall

        ! Check for Minimal alpha electrons (MS)
        if(Nsomo_J.lt.MS)then
          cycle
        endif

        ! Again, we don't have to search from 1
        ! we just use seniority to find the
        ! first index with NSOMO - 2 to NSOMO + 2
        ! this is what is done in kstart, kend

        pqAlreadyGenQ = .FALSE.
        ! First check if it can be generated before
        do k = kstart, kend
          !diffSOMO = IEOR(Jsomo,iand(reunion_of_act_virt_bitmask(1,1),psi_configuration(1,1,k)))
          !ndiffSOMO = POPCNT(diffSOMO)
          !if((ndiffSOMO .NE. 0) .AND. (ndiffSOMO .NE. 2)) cycle
          !diffDOMO = IEOR(Jdomo,iand(reunion_of_act_virt_bitmask(1,1),psi_configuration(1,2,k)))
          !xordiffSOMODOMO = IEOR(diffSOMO,diffDOMO)
          !ndiffDOMO = POPCNT(diffDOMO)
          !nxordiffSOMODOMO = POPCNT(xordiffSOMODOMO)
          !nxordiffSOMODOMO += ndiffSOMO + ndiffDOMO

          ndiffSOMO = 0
          ndiffDOMO = 0
          nxordiffSOMODOMO = 0
          do ii = 1, N_int
            Jsomo = Jcfg(ii,1)
            Jdomo = Jcfg(ii,2)
            diffSOMO = IEOR(Jsomo,iand(reunion_of_act_virt_bitmask(ii,1),psi_configuration(ii,1,k)))
            ndiffSOMO += POPCNT(diffSOMO)
            diffDOMO = IEOR(Jdomo,iand(reunion_of_act_virt_bitmask(ii,2),psi_configuration(ii,2,k)))
            xordiffSOMODOMO = IEOR(diffSOMO,diffDOMO)
            ndiffDOMO += POPCNT(diffDOMO)
            nxordiffSOMODOMO += POPCNT(xordiffSOMODOMO)
            nxordiffSOMODOMO += ndiffSOMO + ndiffDOMO
          end do

          if((ndiffSOMO .ne. 0) .and. (ndiffSOMO .ne. 2)) cycle

          if((ndiffSOMO+ndiffDOMO) .EQ. 0) then
            pqAlreadyGenQ = .TRUE.
            ppExistsQ = .TRUE.
            EXIT
          endif
          if((nxordiffSOMODOMO .EQ. 4) .AND. ndiffSOMO .EQ. 2) then
            pqAlreadyGenQ = .TRUE.
            EXIT
          endif
        end do

        if(pqAlreadyGenQ) cycle

        pqExistsQ = .FALSE.

        if(.NOT. pqExistsQ) then
          tableUniqueAlphas(p,q) = .TRUE.
        endif
      end do
    end do

    !print *,tableUniqueAlphas(:,:)

    ! prune list of alphas
    Isomo = Icfg(1,1)
    Idomo = Icfg(1,2)
    Jsomo = Icfg(1,1)
    Jdomo = Icfg(1,2)
    NalphaIcfg = 0
    do i = 1, nholes
      !p = listholes(i)
      pp  = listholes(i)
      p_s = (1+((pp-1)/63))
      p   = pp - (p_s - 1)*63
      do j = 1, nvmos
        !q = listvmos(j)
        qq  = listvmos(j)
        q_s = (1+((qq-1)/63))
        q   = qq - (q_s - 1)*63
        Isomop = iand(act_bitmask(i_s,1),Icfg(p_s,1))
        Idomop = iand(act_bitmask(i_s,1),Icfg(p_s,2))
        Isomoq = iand(act_bitmask(i_s,1),Icfg(q_s,1))
        Idomoq = iand(act_bitmask(i_s,1),Icfg(q_s,2))
        if(p .EQ. q) cycle
        if(tableUniqueAlphas(p,q)) then
          if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 1) then
            ! SOMO -> VMO
            !Jsomo = IBCLR(Isomo,p-1)
            !Jsomo = IBSET(Jsomo,q-1)
            !Jdomo = Idomo
            if (p_s .eq. q_s) then
              Jsomop = IBCLR(Isomop,p-1)
              Jsomop = IBSET(Jsomop,q-1)
              Jsomoq = Jsomop
            else
              Jsomop = IBCLR(Isomop,p-1)
              Jsomoq = IBSET(Isomoq,q-1)
            endif

            ! Domo remains the same
            Jdomop = Idomop
            Jdomoq = Idomoq

          else if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 2) then
            ! SOMO -> SOMO
            !Jsomo = IBCLR(Isomo,p-1)
            !Jsomo = IBCLR(Jsomo,q-1)
            !Jdomo = IBSET(Idomo,q-1)

            if(p_s .eq. q_s) then
              Jsomop = IBCLR(Isomop,p-1)
              Jsomop = IBCLR(Jsomop,q-1)
              Jsomoq = Jsomop
            else
              Jsomop = IBCLR(Isomop,p-1)
              Jsomoq = IBCLR(Isomoq,q-1)
            endif

            Jdomoq = IBSET(Idomoq,q-1)

            if(POPCNT(Jsomoq).ge.MS)then
              kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-4)))
              kend = idxI-1
            else
              cycle
            endif
          else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 1) then
            ! DOMO -> VMO
            !Jsomo = IBSET(Isomo,p-1)
            !Jsomo = IBSET(Jsomo,q-1)
            !Jdomo = IBCLR(Idomo,p-1)

            if(p_s .eq. q_s) then
              Jsomop = IBSET(Isomop,p-1)
              Jsomop = IBSET(Jsomop,q-1)
              Jsomoq = Jsomop
            else
              Jsomop = IBSET(Isomop,p-1)
              Jsomoq = IBSET(Jsomoq,q-1)
            endif

            Jdomop = IBCLR(Idomop,p-1)

          else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 2) then
            ! DOMO -> SOMO
            !Jsomo = IBSET(Isomo,p-1)
            !Jsomo = IBCLR(Jsomo,q-1)
            !Jdomo = IBCLR(Idomo,p-1)
            !Jdomo = IBSET(Jdomo,q-1)
            if(p_s .eq. q_s) then
              Jsomop = IBSET(Isomop,p-1)
              Jsomop = IBCLR(Jsomop,q-1)
              Jsomoq = Jsomop

              Jdomop = IBCLR(Idomop,p-1)
              Jdomop = IBSET(Jdomop,q-1)
              Jdomoq = Jdomop
            else
              Jsomop = IBSET(Isomop,p-1)
              Jsomoq = IBCLR(Jsomoq,q-1)

              Jdomop = IBCLR(Idomop,p-1)
              Jdomoq = IBSET(Jdomoq,q-1)
            endif

          else
            print*,"Something went wrong in obtain_associated_alphaI"
          endif

          ! Save it to Jcfg
          Jcfg(p_s,1) = Jsomop
          Jcfg(q_s,1) = Jsomoq
          Jcfg(p_s,2) = Jdomop
          Jcfg(q_s,2) = Jdomoq

          ! SOMO
          !print *,i,j,"|",NalphaIcfg, Jsomo, IOR(Jdomo,ISHFT(1_8,n_core_orb)-1)
          if(POPCNT(Jsomo) .ge. NSOMOMin) then
            NalphaIcfg += 1
            alphasIcfg_list(:,1,idxI,NalphaIcfg) = Jcfg(:,1)
            !alphasIcfg_list(:,2,idxI,NalphaIcfg) = IOR(Jdomo,ISHFT(1_8,n_core_orb)-1)
            if(n_core_orb .le. 63)then
              alphasIcfg_list(1,2,idxI,NalphaIcfg) = IOR(Jcfg(1,2),ISHFT(1_8,n_core_orb)-1)
            else
              n_core_orb_64 = n_core_orb
              do ii=1,N_int
                if(n_core_orb_64 .gt. 0)then
                  alphasIcfg_list(ii,2,idxI,NalphaIcfg) = IOR(Jcfg(ii,2),ISHFT(1_8,n_core_orb_64)-1)
                else
                  alphasIcfg_list(ii,2,idxI,NalphaIcfg) = Jcfg(ii,2)
                endif
                n_core_orb_64 = ISHFT(n_core_orb_64,-6)
              end do
            endif
            NalphaIcfg_list(idxI) = NalphaIcfg
            !print *,i,j,"2| nalpha=",NalphaIcfg, " somo=",Jcfg(1,1),Jcfg(2,1)
          endif
        endif
      end do
    end do

    ! Check if this Icfg has been previously generated as a mono
    ppExistsQ = .False.
    Isomo = iand(reunion_of_act_virt_bitmask(1,1),Icfg(1,1))
    Idomo = iand(reunion_of_act_virt_bitmask(1,1),Icfg(1,2))
    kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-2)))
    ndiffDOMO = 0
    do k = kstart, idxI-1
      do ii=1,N_int
        diffSOMO = IEOR(Icfg(ii,1),iand(act_bitmask(ii,1),psi_configuration(ii,1,k)))
        ndiffSOMO += POPCNT(diffSOMO)
      end do
      ! ndiffSOMO cannot be 0 (I /= k)
      ! if ndiffSOMO /= 2 then it has to be greater than 2 and hense
      ! this Icfg could not have been generated before.
      if (ndiffSOMO /= 2) cycle
      ndiffDOMO = 0
      nxordiffSOMODOMO = 0
      do ii=1,N_int
        diffDOMO = IEOR(Icfg(ii,2),iand(act_bitmask(ii,1),psi_configuration(ii,2,k)))
        xordiffSOMODOMO = IEOR(diffSOMO,diffDOMO)
        ndiffDOMO += POPCNT(diffDOMO)
        nxordiffSOMODOMO += POPCNT(xordiffSOMODOMO)
      end do
      if((ndiffSOMO+ndiffDOMO+nxordiffSOMODOMO .EQ. 4)) then
        ppExistsQ = .TRUE.
        EXIT
      endif
    end do
    ! Diagonal part (pp,qq)
    if(nholes > 0 .AND. (.NOT. ppExistsQ))then
      ! SOMO
      if(POPCNT(Jsomo) .ge. NSOMOMin) then
        NalphaIcfg += 1
        alphasIcfg_list(:,1,idxI,NalphaIcfg) = Icfg(:,1)
        alphasIcfg_list(:,2,idxI,NalphaIcfg) = Icfg(:,2)
        NalphaIcfg_list(idxI) = NalphaIcfg
      endif
    endif

    NalphaIcfg = 0
  enddo ! end loop idxI
  call wall_time(t1)
  print *, 'Preparation : ', t1 - t0

END_PROVIDER

  subroutine obtain_associated_alphaI(idxI, Icfg, alphasIcfg, NalphaIcfg)
  implicit none
  use bitmasks
  BEGIN_DOC
  ! Documentation for alphasI
  ! Returns the associated alpha's for
  ! the input configuration Icfg.
  END_DOC

  integer,intent(in)                 :: idxI ! The id of the Ith CFG
  integer(bit_kind),intent(in)       :: Icfg(N_int,2)
  integer,intent(out)                :: NalphaIcfg
  integer(bit_kind),intent(out)      :: alphasIcfg(N_int,2,*)
  logical,dimension(:,:),allocatable :: tableUniqueAlphas
  integer                            :: listholes(mo_num)
  integer                            :: holetype(mo_num) ! 1-> SOMO 2->DOMO
  integer                            :: nholes
  integer                            :: nvmos
  integer                            :: listvmos(mo_num)
  integer                            :: vmotype(mo_num) ! 1 -> VMO 2 -> SOMO
  integer*8                          :: Idomo
  integer*8                          :: Isomo
  integer*8                          :: Jdomo
  integer*8                          :: Jsomo
  integer*8                          :: diffSOMO
  integer*8                          :: diffDOMO
  integer*8                          :: xordiffSOMODOMO
  integer                            :: ndiffSOMO
  integer                            :: ndiffDOMO
  integer                            :: nxordiffSOMODOMO
  integer                            :: ndiffAll
  integer                            :: i, ii
  integer                            :: j, jj
  integer                            :: k, kk
  integer                            :: kstart
  integer                            :: kend
  integer                            :: Nsomo_I
  integer                            :: hole
  integer                            :: p
  integer                            :: q
  integer                            :: countalphas
  logical                            :: pqAlreadyGenQ
  logical                            :: pqExistsQ
  logical                            :: ppExistsQ
  Isomo = iand(act_bitmask(1,1),Icfg(1,1))
  Idomo = iand(act_bitmask(1,1),Icfg(1,2))
  !print*,"Input cfg"
  !call debug_spindet(Isomo,1)
  !call debug_spindet(Idomo,1)

  ! find out all pq holes possible
  nholes = 0
  ! holes in SOMO
  do ii = 1,n_act_orb
    i = list_act(ii)
     if(POPCNT(IAND(Isomo,IBSET(0_8,i-1))) .EQ. 1) then
        nholes += 1
        listholes(nholes) = i
        holetype(nholes) = 1
     endif
  end do
  ! holes in DOMO
  do ii = 1,n_act_orb
    i = list_act(ii)
     if(POPCNT(IAND(Idomo,IBSET(0_8,i-1))) .EQ. 1) then
        nholes += 1
        listholes(nholes) = i
        holetype(nholes) = 2
     endif
  end do

  ! find vmos
  listvmos = -1
  vmotype = -1
  nvmos = 0
  do ii = 1,n_act_orb
    i = list_act(ii)
     !print *,i,IBSET(0,i-1),POPCNT(IAND(Isomo,(IBSET(0_8,i-1)))), POPCNT(IAND(Idomo,(IBSET(0_8,i-1))))
     if(POPCNT(IAND(Isomo,(IBSET(0_8,i-1)))) .EQ. 0 .AND. POPCNT(IAND(Idomo,(IBSET(0_8,i-1)))) .EQ. 0) then
        nvmos += 1
        listvmos(nvmos) = i
        vmotype(nvmos) = 1
     else if(POPCNT(IAND(Isomo,(IBSET(0_8,i-1)))) .EQ. 1 .AND. POPCNT(IAND(Idomo,(IBSET(0_8,i-1)))) .EQ. 0 ) then
        nvmos += 1
        listvmos(nvmos) = i
        vmotype(nvmos) = 2
     end if
  end do

  !print *,"Nvmo=",nvmos
  !print *,listvmos
  !print *,vmotype

  allocate(tableUniqueAlphas(mo_num,mo_num))
  tableUniqueAlphas = .FALSE.

  ! Now find the allowed (p,q) excitations
  Isomo = iand(act_bitmask(1,1),Icfg(1,1))
  Idomo = iand(act_bitmask(1,1),Icfg(1,2))
  Nsomo_I = POPCNT(Isomo)
  if(Nsomo_I .EQ. 0) then
    kstart = 1
  else
    kstart = cfg_seniority_index(max(NSOMOMin,Nsomo_I-2))
  endif
  kend = idxI-1
  !print *,"Isomo"
  !call debug_spindet(Isomo,1)
  !call debug_spindet(Idomo,1)

  !print *,"Nholes=",nholes," Nvmos=",nvmos, " idxi=",idxI
  !do i = 1,nholes
  !   print *,i,"->",listholes(i)
  !enddo
  !do i = 1,nvmos
  !   print *,i,"->",listvmos(i)
  !enddo

  do i = 1,nholes
     p = listholes(i)
     do j = 1,nvmos
        q = listvmos(j)
        if(p .EQ. q) cycle
        if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 1) then
           ! SOMO -> VMO
           Jsomo = IBCLR(Isomo,p-1)
           Jsomo = IBSET(Jsomo,q-1)
           Jdomo = Idomo
           kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-2)))
           kend = idxI-1
        else if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 2) then
           ! SOMO -> SOMO
           Jsomo = IBCLR(Isomo,p-1)
           Jsomo = IBCLR(Jsomo,q-1)
           Jdomo = IBSET(Idomo,q-1)
           kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-4)))
           kend = idxI-1
        else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 1) then
           ! DOMO -> VMO
           Jsomo = IBSET(Isomo,p-1)
           Jsomo = IBSET(Jsomo,q-1)
           Jdomo = IBCLR(Idomo,p-1)
           kstart = cfg_seniority_index(Nsomo_I)
           kend = idxI-1
        else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 2) then
           ! DOMO -> SOMO
           Jsomo = IBSET(Isomo,p-1)
           Jsomo = IBCLR(Jsomo,q-1)
           Jdomo = IBCLR(Idomo,p-1)
           Jdomo = IBSET(Jdomo,q-1)
           kstart = max(1,cfg_seniority_index(max(NSOMOMin,Nsomo_I-2)))
           kend = idxI-1
        else
           print*,"Something went wrong in obtain_associated_alphaI"
        endif

        ! Again, we don't have to search from 1
        ! we just use seniortiy to find the
        ! first index with NSOMO - 2 to NSOMO + 2
        ! this is what is done in kstart, kend

        pqAlreadyGenQ = .FALSE.
        ! First check if it can be generated before
        do k = kstart, kend
           diffSOMO = IEOR(Jsomo,iand(act_bitmask(1,1),psi_configuration(1,1,k)))
           ndiffSOMO = POPCNT(diffSOMO)
           if((ndiffSOMO .NE. 0) .AND. (ndiffSOMO .NE. 2)) cycle
           diffDOMO = IEOR(Jdomo,iand(act_bitmask(1,1),psi_configuration(1,2,k)))
           xordiffSOMODOMO = IEOR(diffSOMO,diffDOMO)
           ndiffDOMO = POPCNT(diffDOMO)
           nxordiffSOMODOMO = POPCNT(xordiffSOMODOMO)
           nxordiffSOMODOMO += ndiffSOMO + ndiffDOMO
           !if(POPCNT(IEOR(diffSOMO,diffDOMO)) .LE. 1 .AND. ndiffDOMO .LT. 3) then
           if((ndiffSOMO+ndiffDOMO) .EQ. 0) then
              pqAlreadyGenQ = .TRUE.
              ppExistsQ = .TRUE.
              EXIT
           endif
           if((nxordiffSOMODOMO .EQ. 4) .AND. ndiffSOMO .EQ. 2) then
              pqAlreadyGenQ = .TRUE.
              !EXIT
              !ppExistsQ = .TRUE.
              !print *,i,k,ndiffSOMO,ndiffDOMO
              !call debug_spindet(Jsomo,1)
              !call debug_spindet(Jdomo,1)
              !call debug_spindet(iand(reunion_of_act_virt_bitmask(1,1),psi_configuration(1,1,k)),1)
              !call debug_spindet(iand(reunion_of_act_virt_bitmask(1,1),psi_configuration(1,2,k)),1)
              EXIT
           endif
        end do

        !print *,"(,",p,",",q,")",pqAlreadyGenQ

        if(pqAlreadyGenQ) cycle

        pqExistsQ = .FALSE.
        ! now check if this exists in the selected list
        !do k = idxI+1, N_configuration
        !   diffSOMO = IEOR(OR(reunion_of_act_virt_bitmask(1,1),Jsomo),psi_configuration(1,1,k))
        !   diffDOMO = IEOR(OR(reunion_of_act_virt_bitmask(1,1),Jdomo),psi_configuration(1,2,k))
        !   ndiffSOMO = POPCNT(diffSOMO)
        !   ndiffDOMO = POPCNT(diffDOMO)
        !   if((ndiffSOMO + ndiffDOMO) .EQ. 0) then
        !      pqExistsQ = .TRUE.
        !      EXIT
        !   endif
        !end do

        if(.NOT. pqExistsQ) then
           tableUniqueAlphas(p,q) = .TRUE.
           !print *,p,q
           !call debug_spindet(Jsomo,1)
           !call debug_spindet(Jdomo,1)
        endif
     end do
  end do

  !print *,tableUniqueAlphas(:,:)

  ! prune list of alphas
  Isomo = Icfg(1,1)
  Idomo = Icfg(1,2)
  Jsomo = Icfg(1,1)
  Jdomo = Icfg(1,2)
  NalphaIcfg = 0
  do i = 1, nholes
     p = listholes(i)
     do j = 1, nvmos
        q = listvmos(j)
        if(p .EQ. q) cycle
        if(tableUniqueAlphas(p,q)) then
           if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 1) then
              ! SOMO -> VMO
              Jsomo = IBCLR(Isomo,p-1)
              Jsomo = IBSET(Jsomo,q-1)
              Jdomo = Idomo
           else if(holetype(i) .EQ. 1 .AND. vmotype(j) .EQ. 2) then
              ! SOMO -> SOMO
              Jsomo = IBCLR(Isomo,p-1)
              Jsomo = IBCLR(Jsomo,q-1)
              Jdomo = IBSET(Idomo,q-1)
           else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 1) then
              ! DOMO -> VMO
              Jsomo = IBSET(Isomo,p-1)
              Jsomo = IBSET(Jsomo,q-1)
              Jdomo = IBCLR(Idomo,p-1)
           else if(holetype(i) .EQ. 2 .AND. vmotype(j) .EQ. 2) then
              ! DOMO -> SOMO
              Jsomo = IBSET(Isomo,p-1)
              Jsomo = IBCLR(Jsomo,q-1)
              Jdomo = IBCLR(Idomo,p-1)
              Jdomo = IBSET(Jdomo,q-1)
           else
              print*,"Something went wrong in obtain_associated_alphaI"
           endif

           ! SOMO
           NalphaIcfg += 1
           !print *,i,j,"|",NalphaIcfg
           alphasIcfg(1,1,NalphaIcfg) = Jsomo
           alphasIcfg(1,2,NalphaIcfg) = IOR(Jdomo,ISHFT(1_8,n_core_orb)-1)
           !print *,"I = ",idxI, " Na=",NalphaIcfg," - ",Jsomo, IOR(Jdomo,ISHFT(1_8,n_core_orb)-1)
        endif
     end do
  end do

  ! Check if this Icfg has been previously generated as a mono
  ppExistsQ = .False.
  Isomo = iand(act_bitmask(1,1),Icfg(1,1))
  Idomo = iand(act_bitmask(1,1),Icfg(1,2))
  do k = 1, idxI-1
     diffSOMO = IEOR(Isomo,iand(act_bitmask(1,1),psi_configuration(1,1,k)))
     diffDOMO = IEOR(Idomo,iand(act_bitmask(1,1),psi_configuration(1,2,k)))
     xordiffSOMODOMO = IEOR(diffSOMO,diffDOMO)
     ndiffSOMO = POPCNT(diffSOMO)
     ndiffDOMO = POPCNT(diffDOMO)
     nxordiffSOMODOMO = POPCNT(xordiffSOMODOMO)
     if((ndiffSOMO+ndiffDOMO+nxordiffSOMODOMO .EQ. 4) .AND. ndiffSOMO .EQ. 2) then
        ppExistsQ = .TRUE.
        EXIT
     endif
  end do
  ! Diagonal part (pp,qq)
  if(nholes > 0 .AND. (.NOT. ppExistsQ))then
     ! SOMO
     NalphaIcfg += 1
     !print *,p,q,"|",holetype(i),vmotype(j),NalphaIcfg
     !call debug_spindet(Idomo,1)
     !call debug_spindet(Jdomo,1)
     alphasIcfg(1,1,NalphaIcfg) = Icfg(1,1)
     alphasIcfg(1,2,NalphaIcfg) = Icfg(1,2)
  endif

  end subroutine

  function getNSOMO(Icfg) result(NSOMO)
    implicit none
    integer(bit_kind),intent(in)   :: Icfg(N_int,2)
    integer                        :: NSOMO
    integer                        :: i
    NSOMO = 0
    do i = 1,N_int
       NSOMO += POPCNT(Icfg(i,1))
    enddo
  end function getNSOMO
