//===========================================================
// mmRISC Project
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
    // Configure Interrupt Controller
    // IRQ00 : UART
    write_csr(MINTCFGPRIORITY0, 0x00000001); // IRQ00
    write_csr(MINTCURLVL      , 0x00000000); // LVL=0
    write_csr(MINTCFGSENSE0   , 0x00000001); // Edge Sense
    write_csr(MINTCFGENABLE0  , 0x00000001); // IRQ00
    // Enable Interrupt
    write_csr(MIE, read_csr(MIE) | (1<<7)); // MTIME Interrupt
    write_csr(MSTATUS, read_csr(MSTATUS) | (1<<3));
    // Start MTIME
    mem_wr32(MTIME_DIV , 9);
    mem_wr32(MTIME     , 0);
    mem_wr32(MTIMEH    , 0);
    mem_wr32(MTIMECMP  , 200000);
    mem_wr32(MTIMECMPH , 0);
    mem_wr32(MTIME_CTRL, 0x00000005);
}

//-------------------------
// Interrupt Handler Timer
//-------------------------
void INT_Timer_Handler(void)
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
// Interrupt Handler IRQ
//-------------------------
void INT_IRQ_Handler(void)
{
    uint32_t irq_pend;
    irq_pend = read_csr(MINTPENDING0);
    //
    // IRQ00 (UART)
    if (irq_pend & 0x00000001)
    {
        INT_UART_Handler();
        write_csr(MINTPENDING0, 0x00000001); // Clear Pending
    }
}

//===========================================================
// End of Program
//===========================================================
