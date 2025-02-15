#!/usr/bin/env bats

source $QP_ROOT/tests/bats/common.bats.sh
source $QP_ROOT/quantum_package.rc


function run_Ne() {
  qp set_file Ne_tc_scf 
  qp run cisd 
  qp run tc_bi_ortho | tee Ne_tc_scf.cisd_tc_bi_ortho.out  
  eref=-128.77020441279302
  energy="$(grep "eigval_right_tc_bi_orth =" Ne_tc_scf.cisd_tc_bi_ortho.out)"
  eq $energy $eref 1e-6
}


@test "Ne" {
 run_Ne 
}


function run_C() {
  qp set_file C_tc_scf 
  qp run cisd 
  qp run tc_bi_ortho | tee C_tc_scf.cisd_tc_bi_ortho.out  
  eref=-37.757536149952514
  energy="$(grep "eigval_right_tc_bi_orth =" C_tc_scf.cisd_tc_bi_ortho.out)"
  eq $energy $eref 1e-6
}


@test "C" {
 run_C 
}

function run_O() {
  qp set_file C_tc_scf 
  qp run cisd 
  qp run tc_bi_ortho | tee O_tc_scf.cisd_tc_bi_ortho.out  
  eref=-74.908518517716161
  energy="$(grep "eigval_right_tc_bi_orth =" O_tc_scf.cisd_tc_bi_ortho.out)"
  eq $energy $eref 1e-6
}


@test "O" {
 run_O 
}

