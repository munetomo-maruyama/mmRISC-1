//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : startup.S
// Description : Startup Routine
//-----------------------------------------------------------
// History :
// Rev.01 2017.11.09 M.Maruyama First Release
// Rev.02 2024.08.13 M.Maruyama Use attribute for interrupt
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

    .globl _start
    .globl main
    .globl INT_Handler_EXT
    .globl INT_Handler_MSOFT
    .globl INT_Handler_MTIME
    .globl INT_Handler_IRQ

// Reset Vector
    .text
    .section ".vectors"
    .align 4
_reset:
    j    _start
_vector_base:
    j    _trap_exception       // 00:Exception
    j    _trap_illegal         // 01:Supervisor Software Interrupt
    j    _trap_illegal         // 02:Reserved
    j    INT_Handler_MSOFT     // 03:Machine Software Interrupt
    j    _trap_illegal         // 04:Reserved
    j    _trap_illegal         // 05:Reserved
    j    _trap_illegal         // 06:Reserved
    j    INT_Handler_MTIME     // 07:Machine Timer Interrupt
    j    _trap_illegal         // 08:Reserved
    j    _trap_illegal         // 09:Reserved
    j    _trap_illegal         // 10:Reserved
    j    INT_Handler_EXT       // 11:Machine External Interrupt
    j    _trap_illegal         // 12:Reserved
    j    _trap_illegal         // 13:Reserved
    j    _trap_illegal         // 14:Reserved
    j    _trap_illegal         // 15:Reserved
    j    INT_Handler_IRQ       // 16:IRQ00
    j    INT_Handler_IRQ       // 17:IRQ01
    j    INT_Handler_IRQ       // 18:IRQ02
    j    INT_Handler_IRQ       // 19:IRQ03
    j    INT_Handler_IRQ       // 20:IRQ04
    j    INT_Handler_IRQ       // 21:IRQ05
    j    INT_Handler_IRQ       // 22:IRQ06
    j    INT_Handler_IRQ       // 23:IRQ07
    j    INT_Handler_IRQ       // 24:IRQ08
    j    INT_Handler_IRQ       // 25:IRQ09
    j    INT_Handler_IRQ       // 26:IRQ10
    j    INT_Handler_IRQ       // 27:IRQ11
    j    INT_Handler_IRQ       // 28:IRQ12
    j    INT_Handler_IRQ       // 29:IRQ13
    j    INT_Handler_IRQ       // 30:IRQ14
    j    INT_Handler_IRQ       // 31:IRQ15
    j    INT_Handler_IRQ       // 32:IRQ16
    j    INT_Handler_IRQ       // 33:IRQ17
    j    INT_Handler_IRQ       // 34:IRQ18
    j    INT_Handler_IRQ       // 35:IRQ19
    j    INT_Handler_IRQ       // 36:IRQ20
    j    INT_Handler_IRQ       // 37:IRQ21
    j    INT_Handler_IRQ       // 38:IRQ22
    j    INT_Handler_IRQ       // 39:IRQ23
    j    INT_Handler_IRQ       // 40:IRQ24
    j    INT_Handler_IRQ       // 41:IRQ25
    j    INT_Handler_IRQ       // 42:IRQ26
    j    INT_Handler_IRQ       // 43:IRQ27
    j    INT_Handler_IRQ       // 44:IRQ28
    j    INT_Handler_IRQ       // 45:IRQ29
    j    INT_Handler_IRQ       // 46:IRQ30
    j    INT_Handler_IRQ       // 47:IRQ31
    j    INT_Handler_IRQ       // 48:IRQ32
    j    INT_Handler_IRQ       // 49:IRQ33
    j    INT_Handler_IRQ       // 50:IRQ34
    j    INT_Handler_IRQ       // 51:IRQ35
    j    INT_Handler_IRQ       // 52:IRQ36
    j    INT_Handler_IRQ       // 53:IRQ37
    j    INT_Handler_IRQ       // 54:IRQ38
    j    INT_Handler_IRQ       // 55:IRQ39
    j    INT_Handler_IRQ       // 56:IRQ40
    j    INT_Handler_IRQ       // 57:IRQ41
    j    INT_Handler_IRQ       // 58:IRQ42
    j    INT_Handler_IRQ       // 59:IRQ43
    j    INT_Handler_IRQ       // 60:IRQ44
    j    INT_Handler_IRQ       // 61:IRQ45
    j    INT_Handler_IRQ       // 62:IRQ46
    j    INT_Handler_IRQ       // 63:IRQ47
    j    INT_Handler_IRQ       // 64:IRQ48
    j    INT_Handler_IRQ       // 65:IRQ49
    j    INT_Handler_IRQ       // 66:IRQ50
    j    INT_Handler_IRQ       // 67:IRQ51
    j    INT_Handler_IRQ       // 68:IRQ52
    j    INT_Handler_IRQ       // 69:IRQ53
    j    INT_Handler_IRQ       // 70:IRQ54
    j    INT_Handler_IRQ       // 71:IRQ55
    j    INT_Handler_IRQ       // 72:IRQ56
    j    INT_Handler_IRQ       // 73:IRQ57
    j    INT_Handler_IRQ       // 74:IRQ58
    j    INT_Handler_IRQ       // 75:IRQ59
    j    INT_Handler_IRQ       // 76:IRQ60
    j    INT_Handler_IRQ       // 77:IRQ61
    j    INT_Handler_IRQ       // 78:IRQ62
    j    INT_Handler_IRQ       // 79:IRQ63

//-----------------------------------
// Trap Entry
//-----------------------------------
    .text
    .section ".trap"
    .align 4
//
_trap_exception:
   // Do Nothing
    mret
//
_trap_illegal:
   // Forever Loop as a Trap
   j     .

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
