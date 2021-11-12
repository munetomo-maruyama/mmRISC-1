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
#include "dhry.h"
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

	char *argv[1] = {"dhrystone"};
	int  argc = 1;
    main_dhry(argc, argv);

    // Stop
    while(1)
    {
        mem_wr32(0xfffffffc, 0xdeaddead);
    }
}

// 2021.05.23 : RV32IMC
// GCC -O2
// Time: begin= 55447312, end= 55637364, diff= 190052
// Microseconds for one run through Dhrystone: 19.005
// Dhrystones per Second:                      52617
// DMIPS = 52617/1757 = 29.95MIPS
// DMIPS/MHz = 52617/1757/20 = 1.50DMIPS

// 2021.05.23 : RV32IMC
// GCC -O3
// Time: begin= 115947002, end= 116130554, diff= 183552
// Microseconds for one run through Dhrystone: 18.355
// Dhrystones per Second:                      54480
// DMIPS = 54480/1757 = 31MIPS
// DMIPS/MHz = 54480/1757/20 = 1.55DMIPS
//
// 2021.05.23 : RV32IMC
// GCC -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
// Time: begin= 78199455, end= 78325518, diff= 126063
// Microseconds for one run through Dhrystone: 12.606
// Dhrystones per Second:                      79325
// DMIPS = 79325/1757 = 45MIPS
// DMIPS/MHz = 79325/1757/20 = 2.26DMIPS

//===========================================================
// End of Program
//===========================================================
