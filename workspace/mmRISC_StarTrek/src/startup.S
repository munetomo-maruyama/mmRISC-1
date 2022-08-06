//===========================================================
// mmRISC-0 Project
//-----------------------------------------------------------
// File Name   : startup.S
// Description : Startup Routine
//-----------------------------------------------------------
// History :
// Rev.01 2017.11.09 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

    .globl _start
    .globl main
    .globl INT_TIM_Handler
    .globl INT_EXT_Handler

// Reset Vector
    .text
    .section ".vectors"
    .align 4
_reset:
    j    _start
_vector_base:
    j    _trap_exception // 00:Exception
    j    _trap_illegal   // 01:Reserved
    j    _trap_illegal   // 02:Reserved
    j    _trap_illegal   // 03:Reserved
    j    _trap_illegal   // 04:Reserved
    j    _trap_illegal   // 05:Reserved
    j    _trap_illegal   // 06:Reserved
    j    _trap_int_timer // 07:Machine Timer Interrupt
    j    _trap_illegal   // 08:Reserved
    j    _trap_illegal   // 09:Reserved
    j    _trap_illegal   // 10:Reserved
    j    _trap_int_ext   // 11:Machine External Interrupt
    j    _trap_illegal   // 12:Reserved
    j    _trap_illegal   // 13:Reserved
    j    _trap_illegal   // 14:Reserved
    j    _trap_illegal   // 15:Reserved

//-----------------------------------
// Trap Entry
//-----------------------------------
    .text
    .section ".trap"
    .align 4
//
_trap_exception:
    csrrw x1, mscratch, x1  // swap ra and mscratch
    jal   _trap_handler_save
    //
    // mepc = mepc + 4
    csrr ra, mepc
    addi ra, ra, 4
    csrw mepc, ra
    //
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_int_timer:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    //
    call  INT_TIM_Handler
    //
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_int_ext:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    //
    call  INT_EXT_Handler
    //
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_illegal:
   j     .

_trap_handler_save:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    addi  sp, sp, -124
    sw    x1,    0(sp) // ra
    sw    x2,    4(sp) // sp
    sw    x3,    8(sp)
    sw    x4,   12(sp)
    sw    x5,   16(sp)
    sw    x6,   20(sp)
    sw    x7,   24(sp)
    sw    x8,   28(sp)
    sw    x9,   32(sp)
    sw    x10,  36(sp)
    sw    x11,  40(sp)
    sw    x12,  44(sp)
    sw    x13,  48(sp)
    sw    x14,  52(sp)
    sw    x15,  56(sp)
    sw    x16,  60(sp)
    sw    x17,  64(sp)
    sw    x18,  68(sp)
    sw    x19,  72(sp)
    sw    x20,  76(sp)
    sw    x21,  80(sp)
    sw    x22,  84(sp)
    sw    x23,  88(sp)
    sw    x24,  92(sp)
    sw    x25,  96(sp)
    sw    x26, 100(sp)
    sw    x27, 104(sp)
    sw    x28, 108(sp)
    sw    x29, 112(sp)
    sw    x30, 116(sp)
    sw    x31, 120(sp)
    csrrw ra, mscratch, ra  // swap ra and mscratch
    ret

_trap_handler_load:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    lw    x1,    0(sp) // ra
    lw    x2,    4(sp) // sp
    lw    x3,    8(sp)
    lw    x4,   12(sp)
    lw    x5,   16(sp)
    lw    x6,   20(sp)
    lw    x7,   24(sp)
    lw    x8,   28(sp)
    lw    x9,   32(sp)
    lw    x10,  36(sp)
    lw    x11,  40(sp)
    lw    x12,  44(sp)
    lw    x13,  48(sp)
    lw    x14,  52(sp)
    lw    x15,  56(sp)
    lw    x16,  60(sp)
    lw    x17,  64(sp)
    lw    x18,  68(sp)
    lw    x19,  72(sp)
    lw    x20,  76(sp)
    lw    x21,  80(sp)
    lw    x22,  84(sp)
    lw    x23,  88(sp)
    lw    x24,  92(sp)
    lw    x25,  96(sp)
    lw    x26, 100(sp)
    lw    x27, 104(sp)
    lw    x28, 108(sp)
    lw    x29, 112(sp)
    lw    x30, 116(sp)
    lw    x31, 120(sp)
    addi  sp, sp, 124
    csrrw ra, mscratch, ra  // swap ra and mscratch
    ret

//--------------------------------
// Startup
//--------------------------------
    .text
    .section ".startup"
_start:
    //
    // Init GP and SP
    la  gp, __GLOBAL_PTR__
    la  sp, __STACK_TOP__
    //
    // Copy Initial Data
    la  a0, __ROM_INIT_BGN__
    la  a1, __RAM_INIT_BGN__
    la  a2, __RAM_INIT_END__
    bgeu a1, a2, 2f
1:
    lw t0, (a0)
    sw t0, (a1)
    addi a0, a0, 4
    addi a1, a1, 4
    bltu a1, a2, 1b
2:
    //
    // Clear BSS
    la a0, __BSS_BGN__
    la a1, __BSS_END__
    bgeu a0, a1, 2f
1:
    sw zero, (a0)
    addi a0, a0, 4
    bltu a0, a1, 1b
2:
    //
    // Setup MTVEC
    la   t0, _vector_base
    ori  t0, t0, 0x01 // vectored
    csrw mtvec, t0
    //
    // Goto Main
    call main
    //
    // Forever Loop
    la   a0, 0xfffffffc
    la   t0, 0xdeaddead
3:  sw   t0, 0(a0)
    j    3b

//===========================================================
// End of Program
//===========================================================
