//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Routine
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include <stdio.h>
#include "common.h"
#include "coremark.h"
#include "interrupt.h"
#include "gpio.h"
#include "uart.h"
#include "xprintf.h"

//-----------------
// Main Routine
//-----------------
void main(void)
{
	int i;
	// Initialize Hardware
	GPIO_Init();
	UART_Init();
  //INT_Init();

    main_coremark();

    // Stop
    while(1)
    {
        mem_wr32(0xfffffffc, 0xdeaddead);
    }
}

// 2021.10.23 : RV32IMAFC Coremark=46/16.666=2.76 Coremark/MHz
// 2K performance run parameters for coremark.
// CoreMark Size    : 666
// Total ticks      : 232973426
// Total time (secs): 13
// Iterations/Sec   : 46
// Iterations       : 600
// Compiler version : GCC10.2.0
// Compiler flags   : -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las
// Memory location  : STACK
// seedcrc          : 0xe9f5
// [0]crclist       : 0xe714
// [0]crcmatrix     : 0x1fd7
// [0]crcstate      : 0x8e3a
// [0]crcfinal      : 0xbd59
// Correct operation validated. See README.md for run and reporting rules.

//===========================================================
// End of Program
//===========================================================
