//===========================================================
// mmRISC Project
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
    .globl INT_Timer_Handler
    .globl INT_IRQ_Handler

// Reset Vector
    .text
    .section ".vectors"
    .align 4
_reset:
    j    _start
_vector_base:
    j    _trap_exception // 00:Exception
    j    _trap_illegal   // 01:Supervisor Software Interrupt
    j    _trap_illegal   // 02:Reserved
    j    _trap_int_soft  // 03:Machine Software Interrupt
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
    j    _trap_irq       // 16:IRQ00
    j    _trap_irq       // 17:IRQ01
    j    _trap_irq       // 18:IRQ02
    j    _trap_irq       // 19:IRQ03
    j    _trap_irq       // 20:IRQ04
    j    _trap_irq       // 21:IRQ05
    j    _trap_irq       // 22:IRQ06
    j    _trap_irq       // 23:IRQ07
    j    _trap_irq       // 24:IRQ08
    j    _trap_irq       // 25:IRQ09
    j    _trap_irq       // 26:IRQ10
    j    _trap_irq       // 27:IRQ11
    j    _trap_irq       // 28:IRQ12
    j    _trap_irq       // 29:IRQ13
    j    _trap_irq       // 30:IRQ14
    j    _trap_irq       // 31:IRQ15
    j    _trap_irq       // 32:IRQ16
    j    _trap_irq       // 33:IRQ17
    j    _trap_irq       // 34:IRQ18
    j    _trap_irq       // 35:IRQ19
    j    _trap_irq       // 36:IRQ20
    j    _trap_irq       // 37:IRQ21
    j    _trap_irq       // 38:IRQ22
    j    _trap_irq       // 39:IRQ23
    j    _trap_irq       // 40:IRQ24
    j    _trap_irq       // 41:IRQ25
    j    _trap_irq       // 42:IRQ26
    j    _trap_irq       // 43:IRQ27
    j    _trap_irq       // 44:IRQ28
    j    _trap_irq       // 45:IRQ29
    j    _trap_irq       // 46:IRQ30
    j    _trap_irq       // 47:IRQ31
    j    _trap_irq       // 48:IRQ32
    j    _trap_irq       // 49:IRQ33
    j    _trap_irq       // 50:IRQ34
    j    _trap_irq       // 51:IRQ35
    j    _trap_irq       // 52:IRQ36
    j    _trap_irq       // 53:IRQ37
    j    _trap_irq       // 54:IRQ38
    j    _trap_irq       // 55:IRQ39
    j    _trap_irq       // 56:IRQ40
    j    _trap_irq       // 57:IRQ41
    j    _trap_irq       // 58:IRQ42
    j    _trap_irq       // 59:IRQ43
    j    _trap_irq       // 60:IRQ44
    j    _trap_irq       // 61:IRQ45
    j    _trap_irq       // 62:IRQ46
    j    _trap_irq       // 63:IRQ47
    j    _trap_irq       // 64:IRQ48
    j    _trap_irq       // 65:IRQ49
    j    _trap_irq       // 66:IRQ50
    j    _trap_irq       // 67:IRQ51
    j    _trap_irq       // 68:IRQ52
    j    _trap_irq       // 69:IRQ53
    j    _trap_irq       // 70:IRQ54
    j    _trap_irq       // 71:IRQ55
    j    _trap_irq       // 72:IRQ56
    j    _trap_irq       // 73:IRQ57
    j    _trap_irq       // 74:IRQ58
    j    _trap_irq       // 75:IRQ59
    j    _trap_irq       // 76:IRQ60
    j    _trap_irq       // 77:IRQ61
    j    _trap_irq       // 78:IRQ62
    j    _trap_irq       // 79:IRQ63

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
    jal   _trap_handler_exception
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_int_soft:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    jal   _trap_handler_int_soft
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_int_timer:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    call  INT_Timer_Handler
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_int_ext:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    jal   _trap_handler_int_ext
    jal   _trap_handler_load
    csrrw ra, mscratch, ra  // swap ra and mscratch
    mret
//
_trap_irq:
    csrrw ra, mscratch, ra  // swap ra and mscratch
    jal   _trap_handler_save
    jal   _trap_handler_irq
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

//-------------------------
// Trap Hander Body
//-------------------------
_trap_handler_exception:
    // Return
    ret
//
_trap_handler_int_soft:
    // Return
    ret

_trap_handler_int_timer:
    // Return
    ret

_trap_handler_int_ext:
    // Return
    ret

_trap_handler_irq:
    // save PC, MSTATUS,mintprelvl
    csrr  x8, mepc
    csrr  x9, mstatus
    csrr  x10, 0xbf1 //mintprelvl
    addi  sp, sp, -16
    sw    x1 , 0(sp)
    sw    x8 , 4(sp)
    sw    x9 , 8(sp)
    sw    x10,12(sp)
    // enable global interrupt (set mie)
    csrrsi x15, mstatus, 0x08
    // allow enested interrupt
    call   INT_IRQ_Handler
    // disable global interrupt (clear mie)
    csrrci x15, mstatus, 0x08
    // load MSTATUS, PC, mintcurlvl
    lw    x1 , 0(sp)
    lw    x8 , 4(sp)
    lw    x9 , 8(sp)
    lw    x10,12(sp)
    addi  sp, sp, 16
    csrw  0xbf0, x10 // mintcurlvl
    csrw  mstatus, x9
    csrw  mepc, x8
    // Return
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
