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
}

//===========================================================
// End of Program
//===========================================================
