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

// 2021.11.18 : RV32IMC
// GCC -O2
// Time: begin= 6289046, end= 6479597, diff= 190551
// Microseconds for one run through Dhrystone: 19.055
// Dhrystones per Second:                      52479
// DMIPS = 52479/1757 = 30MIPS
// DMIPS/MHz = 52479/1757/20 = 1.49DMIPS
//
// 2021.11.18 : RV32IMC
// GCC -O3
// Time: begin= 6187333, end= 6370884, diff= 183551
// Microseconds for one run through Dhrystone: 18.355
// Dhrystones per Second:                      54480
// DMIPS = 54480/1757 = 31MIPS
// DMIPS/MHz = 54480/1757/20 = 1.55DMIPS
//
// 2021.11.18 : RV32IMC
// GCC -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
// Time: begin= 6365035, end= 6445095, diff= 80060
// Microseconds for one run through Dhrystone: 8.006
// Dhrystones per Second:                      124906
// DMIPS = 124906/1757 = 71MIPS
// DMIPS/MHz = 124906/1757/20 = 3.55DMIPS
//
// 2021.11.18 : RV32IMFC
// GCC -O2
// Time: begin= 5311933, end= 5502484, diff= 190551
// Microseconds for one run through Dhrystone: 22.866
// Dhrystones per Second:                      43732
// DMIPS = 43732/1757 = 25MIPS
// DMIPS/MHz = 43732/1757/16.67 = 1.49DMIPS
//
// 2021.11.18 : RV32IMFC
// GCC -O3
// Time: begin= 5162051, end= 5345602, diff= 183551
// Microseconds for one run through Dhrystone: 22.026
// Dhrystones per Second:                      45400
// DMIPS = 45400/1757 = 26MIPS
// DMIPS/MHz = 45400/1757/16.67 = 1.55DMIPS
//
// 2021.11.18 : RV32IMFC
// GCC -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
// Time: begin= 5066582, end= 5146642, diff= 80060
// Microseconds for one run through Dhrystone: 9.607
// Dhrystones per Second:                      104088
// DMIPS = 104088/1757 = 59MIPS
// DMIPS/MHz = 104088/1757/16.67 = 3.55DMIPS
//
//
// 2023.07.23 : RV32IMAFC
// GCC 12.2.0
// GCC -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
// Time: begin= 85922504, end= 86010050, diff= 87546
// Microseconds for one run through Dhrystone: 10.505
// Dhrystones per Second:                      95188
// DMIPS = 95188/1757 = 54.2MIPS
// DMIPS/MHz = 95188/1757/16.67 = 3.25DMIPS

// 2024.08.11 : RV32IMAC @16.66MHz
// IAR Embedded Workbench IDE - RISC-V 3.30.1
// Optimization = High-Speed, no size constraints
// Time: begin= 403130, end= 650639, diff= 247509
// Microseconds for one run through Dhrystone: 29.701
// Dhrystones per Second:                      33668
// DMIPS = 33668/1757 = 19.16MIPS
// DMIPS/MHz = 19.16/16.66 = 1.15DMIPS

//===========================================================
// End of Program
//===========================================================
