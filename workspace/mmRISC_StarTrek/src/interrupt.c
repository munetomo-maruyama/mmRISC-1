//===========================================================
// mmRISC-0 Project
//-----------------------------------------------------------
// File Name   : interrupt.c
// Description : Interrupt Service Routine
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "csr.h"
#include "gpio.h"
#include "uart.h"
#include "interrupt.h"

//--------------------------
// Interrupt Initialization
//--------------------------
void INT_Init(void)
{
    // Enable Interrupt
    write_csr(MIE, read_csr(MIE) | (1<<11) | (1<<7)); // enable EXT and TIM
    write_csr(MSTATUS, read_csr(MSTATUS) | (1<<3));
    // Start MTIME
    mem_wr32(MTIME_DIV , 9);
    mem_wr32(MTIME     , 0);
    mem_wr32(MTIMECMP  , 200000);
  //mem_wr32(MTIME_CTRL, 0x00000005);
}

//-------------------------
// Interrupt TIM Handler
//-------------------------
void INT_TIM_Handler(void)
{
    uint64_t lsb, msb;
    uint64_t time;
    static uint32_t num = 0;
    //
    GPIO_SetLED(num);
    //
    if (GPIO_GetKEY() == 0)
        num = num + GPIO_GetSW10();
    else
        num = num - GPIO_GetSW10();
    //
    mem_wr32(MTIME_CTRL, mem_rd32(MTIME_CTRL));
    return;
}

//-------------------------
// Interrupt EXT Handler
//-------------------------
void INT_EXT_Handler(void)
{
    INT_UART_Handler();
}

//===========================================================
// End of Program
//===========================================================
