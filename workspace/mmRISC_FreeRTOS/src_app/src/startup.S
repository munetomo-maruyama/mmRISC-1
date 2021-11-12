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
