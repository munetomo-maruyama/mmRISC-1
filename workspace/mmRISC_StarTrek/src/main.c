//===========================================================
// mmRISC-0 Project
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
#include "gpio.h"
#include "interrupt.h"
#include "startrek.h"
#include "uart.h"
#include "xprintf.h"

//-----------------
// Main Routine
//-----------------
void main(void)
{
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    INT_Init();

    // Program Body
    main_startrek();
}

//===========================================================
// End of Program
//===========================================================
