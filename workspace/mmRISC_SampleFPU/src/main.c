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

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "csr.h"
#include "float.h"
#include "gpio.h"
#include "interrupt.h"
#include "uart.h"
#include "xprintf.h"

#define SXMIN 200 // screen xmin
#define SYMIN 120 // screen ymin
#define SXWID 120 // screen xwidth
#define SYWID 120 // screen ywidth
#define SXMAX (SXMIN+SXWID) // screen xmax
#define SYMAX (SYMIN+SYWID) // screen ymax
#define BALLSIZE  6
#define WALLWIDTH 2
#define XMIN (SXMIN + WALLWIDTH)
#define XMAX ((SXMAX) - (WALLWIDTH) - (BALLSIZE))
#define YMIN (SYMIN + WALLWIDTH)
#define YMAX ((SYMAX) - (WALLWIDTH) - (BALLSIZE))
#define REFLEX(v) (-0.75 * v) // -75%


//-----------------
// Main Routine
//-----------------
void main(void)
{
    int    i;
    double fth, fsin;
    int    ith, isin;
    char   buf[256];
    char   *pbuf;
    long   num;
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    INT_Init();
    //
    // Main Floating
    write_csr(0xbe0, 0x000000ff);
    main_floating();
    //
    // You will not reach here.
    //--------------------------------
    // Debug HBRK
    volatile uint32_t data;
    data = 0;
    while(1)
    {
        data = data + 1;
        data = data + 2;
        data = data + 3;
    }
    //--------------------------------
    // Debug C.FSWSP
    volatile float fdata;
    fdata = 2.0f;
    while(1)
    {
        fdata = fdata + 1.0f;
    }
    //-----------------------------------------------
    asm volatile ("flw fs0, 4(x2)");
    asm volatile ("li x10, 0xffffffff");
    asm volatile ("fmv.w.x fa0, x10");
    asm volatile ("li x10, 0x3f800000"); // 1.0
    asm volatile ("fmv.w.x fa1, x10");
    asm volatile ("li x10, 0x40000000"); // 2.0
    asm volatile ("mv x3, sp");
    asm volatile ("sw x10, 4(sp)");
    asm volatile ("sw x10, 4(x3)");
    //-----------------------------------------------
    asm volatile ("flw fa0, 4(sp)");
    asm volatile ("fadd.s fa0, fa0, fa1");
    asm volatile ("fsw fa0, 4(sp)");
    //
    asm volatile ("fmv.w.x fa0, x0");
    //
    asm volatile ("flw fa0, 4(sp)");
    asm volatile ("fadd.s fa0, fa0, fa1");
    asm volatile ("fsw fa0, 4(sp)");
    //
    asm volatile ("fmv.w.x fa0, x0");
    //
    asm volatile ("flw fa0, 4(sp)");
    asm volatile ("fadd.s fa0, fa0, fa1");
    asm volatile ("fsw fa0, 4(sp)");
    //-----------------------------------------------
    asm volatile ("fsw fs0, 4(x2)");
    //-----------------------------------------------
    asm volatile ("nop");
    asm volatile ("nop");
    asm volatile ("nop");
    asm volatile ("nop");
    mem_wr32(0xfffffffc, 0xdeaddead); // Simulation Stop
    //--------------------------------
}

//===========================================================
// End of Program
//===========================================================
