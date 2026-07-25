# See LICENSE for license details.

#*****************************************************************************
# frm.S
#-----------------------------------------------------------------------------
#
# Test the reserved floating point rounding modes.
#
# Encodings 5 and 6 are reserved, and the dynamic encoding is reserved while
# frm itself holds 5, 6 or 7. An instruction that carries such a rounding mode
# raises an illegal instruction. The three funct3 bits mean something else
# entirely in FSGNJ, FMIN/FMAX, the comparisons, FCLASS and the moves, so those
# must keep working whatever frm holds.
#
# This test is not part of upstream riscv-tests.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32UF
RVTEST_CODE_BEGIN

  .align 2
  .option norvc

  # The handler below sets a0 when it has taken an illegal instruction trap
  # and steps over the faulting instruction. Every case here is 32 bit, so it
  # always advances mepc by four.

  li a1, 0x3f800000     # 1.0
  fmv.w.x ft0, a1
  li a1, 0x40000000     # 2.0
  fmv.w.x ft1, a1
  fmv.w.x ft2, a1

  #-------------------------------------------------------------
  # A reserved static rounding mode traps
  #-------------------------------------------------------------

  li TESTNUM, 2
  li a0, 0
  .word 0x00105153      # fadd.s   ft2, ft0, ft1, rm=5
  beqz a0, fail

  li TESTNUM, 3
  li a0, 0
  .word 0x00106153      # fadd.s   ft2, ft0, ft1, rm=6
  beqz a0, fail

  li TESTNUM, 4
  li a0, 0
  .word 0x10105153      # fmul.s   ft2, ft0, ft1, rm=5
  beqz a0, fail

  li TESTNUM, 5
  li a0, 0
  .word 0x58006153      # fsqrt.s  ft2, ft0, rm=6
  beqz a0, fail

  li TESTNUM, 6
  li a0, 0
  .word 0xc00055d3      # fcvt.w.s a1, ft0, rm=5
  beqz a0, fail

  li TESTNUM, 7
  li a0, 0
  .word 0xd005e153      # fcvt.s.w ft2, a1, rm=6
  beqz a0, fail

  li TESTNUM, 8
  li a0, 0
  .word 0x101051c3      # fmadd.s  ft3, ft0, ft1, ft2, rm=5
  beqz a0, fail

  li TESTNUM, 9
  li a0, 0
  .word 0x101061cf      # fnmadd.s ft3, ft0, ft1, ft2, rm=6
  beqz a0, fail

  #-------------------------------------------------------------
  # The dynamic mode traps exactly when frm is reserved
  #-------------------------------------------------------------

  li TESTNUM, 10
  csrwi frm, 5
  li a0, 0
  fadd.s ft2, ft0, ft1, dyn
  beqz a0, fail

  li TESTNUM, 11
  csrwi frm, 6
  li a0, 0
  fadd.s ft2, ft0, ft1, dyn
  beqz a0, fail

  li TESTNUM, 12
  csrwi frm, 7
  li a0, 0
  fadd.s ft2, ft0, ft1, dyn
  beqz a0, fail

  li TESTNUM, 13
  csrwi frm, 4              # round to nearest, ties to max magnitude
  li a0, 0
  fadd.s ft2, ft0, ft1, dyn
  bnez a0, fail

  #-------------------------------------------------------------
  # Instructions without a rounding mode field are never affected
  #-------------------------------------------------------------

  csrwi frm, 7

  li TESTNUM, 14
  li a0, 0
  fsgnj.s ft3, ft0, ft1
  bnez a0, fail

  li TESTNUM, 15
  li a0, 0
  feq.s a1, ft0, ft1
  bnez a0, fail

  li TESTNUM, 16
  li a0, 0
  fmin.s ft3, ft0, ft1
  bnez a0, fail

  li TESTNUM, 17
  li a0, 0
  fclass.s a1, ft0
  bnez a0, fail

  li TESTNUM, 18
  li a0, 0
  fmv.x.w a1, ft0
  fmv.w.x ft3, a1
  bnez a0, fail

  li TESTNUM, 19
  la a1, scratch
  li a0, 0
  fsw ft0, 0(a1)
  flw ft3, 0(a1)
  bnez a0, fail

  #-------------------------------------------------------------
  # A legal dynamic mode still computes
  #-------------------------------------------------------------

  li TESTNUM, 20
  csrwi frm, 0              # round to nearest, ties to even
  li a0, 0
  fadd.s ft2, ft0, ft1, dyn
  bnez a0, fail
  fmv.x.w a1, ft2
  li a2, 0x40400000         # 3.0
  bne a1, a2, fail

  TEST_PASSFAIL

  .align 2
  .global mtvec_handler
mtvec_handler:
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  csrr t0, mcause
  bne t0, t1, fail
  li a0, 1
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA
scratch:
  .word 0

RVTEST_DATA_END
