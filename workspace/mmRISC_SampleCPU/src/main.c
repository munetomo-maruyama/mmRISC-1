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
#include "gpio.h"
#include "gsensor.h"
#include "i2c.h"
#include "interrupt.h"
#include "system.h"
#include "uart.h"
#include "xprintf.h"

//-----------------------
// Global Variable
//-----------------------
extern uint32_t uart_rxd_data;

//-----------------
// Main Routine
//-----------------
void main(void)
{
    uint32_t i;
    uint64_t cyclel, cycleh;
    int16_t gX, gY, gZ;
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    GSENSOR_Init();
    INT_Init();
    //
    // Message
    printf("======== mmRISC-1 ========\n");
    //
    // Wait for Interrupt
    printf("Input any Character:\n");
    //
    // Forever Loop
    i = 0;
    while(1)
    {
        cyclel = (uint64_t) read_csr(mcycle);
        cycleh = (uint64_t) read_csr(mcycleh);
        //
        GSENSOR_ReadXYZ(&gX, &gY, &gZ);
        //
        printf("CYCLE = 0x%08x%08x  (gX,gY,gZ)=(%4d,%4d,%4d)\n",
               (int)cycleh, (int)cyclel, (int)gX, (int)gY, (int)gZ);
        //
        uint32_t seg;
        seg = (uart_rxd_data << 16) + (i & 0x0ffff);
        GPIO_SetSEG(seg);
        //
        mem_wr32(0xfffffffc, 0xdeaddead); // Simulation Stop
        //
        i = i + 1;
        //
        Wait_mSec(100);
    }
}

//===========================================================
// End of Program
//===========================================================
