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
    write_csr(MINTCURLVL      , 0x00000000); // CURLVL=0
    // IRQ00 : UART
    // IRQ01-IRQ31 : INTGEN
    write_csr(MINTCFGPRIORITY0, 0x87654321); // IRQ07-IRQ00 Priority
    write_csr(MINTCFGPRIORITY1, 0x1fedcba9); // IRQ15-IRQ08 Priority
    write_csr(MINTCFGPRIORITY2, 0x98765432); // IRQ23-IRQ16 Priority
    write_csr(MINTCFGPRIORITY3, 0x21fedcba); // IRQ31-IRQ24 Priority
    write_csr(MINTCFGSENSE0   , 0xffffffff); // IRQ31-IRQ00 Edge Sense
    write_csr(MINTCFGENABLE0  , 0xffffffff); // IRQ31-IRQ00 Enable
    //
    // IRQ48-IRQ63 : INTGEN
    write_csr(MINTCFGPRIORITY4, 0xa9876543); // IRQ39-IRQ32 Priority
    write_csr(MINTCFGPRIORITY5, 0x321fedcb); // IRQ47-IRQ48 Priority
    write_csr(MINTCFGPRIORITY6, 0xba987654); // IRQ55-IRQ48 Priority
    write_csr(MINTCFGPRIORITY7, 0x4321fedc); // IRQ63-IRQ56 Priority
    write_csr(MINTCFGSENSE1   , 0xffffffff); // IRQ63-IRQ56 Edge Sense
    write_csr(MINTCFGENABLE1  , 0xffffffff); // IRQ63-IRQ48
    //
    // Enable Interrupt
    write_csr(MIE, read_csr(MIE) | (1<<7)); // MTIME Interrupt
    write_csr(MSTATUS, read_csr(MSTATUS) | (1<<3));
    //
    // Start MTIME
    mem_wr32(MTIME_DIV , 9);
    mem_wr32(MTIME     , 0);
    mem_wr32(MTIMEH    , 0);
    mem_wr32(MTIMECMP  , 200000);
    mem_wr32(MTIMECMPH , 0);
    mem_wr32(MTIME_CTRL, 0x00000005);
    //
    // Pulse IRQ00
    mem_wr32(INTGEN_IRQ0, 0x00000001);
    mem_wr32(INTGEN_IRQ0, 0x00000000);
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

//----------------------------
// Interrupt Nesting Debug
//----------------------------
void Interrupt_Nesting_Debug(uint32_t irq_level)
{
    const uint32_t irq_class[16][5]
    = {{99, 99, 99, 99, 99},
       { 0, 15, 30, 45, 60},
       { 1, 16, 31, 46, 61},
       { 2, 17, 32, 47, 62},
       { 3, 18, 33, 48, 63},
       { 4, 19, 34, 49, 99},
       { 5, 20, 35, 50, 99},
       { 6, 21, 36, 51, 99},
       { 7, 22, 37, 52, 99},
       { 8, 23, 38, 53, 99},
       { 9, 24, 39, 54, 99},
       {10, 25, 40, 55, 99},
       {11, 26, 41, 56, 99},
       {12, 27, 42, 57, 99},
       {13, 28, 43, 58, 99},
       {14, 29, 44, 59, 99}};
    //
    uint32_t irq_join = (irq_level < 5)? 5 : 4;
    uint32_t i;
    //
    for (i = 0; i < irq_join; i = i + 1)
    {
        uint32_t irq = irq_class[irq_level][i];
        uint32_t irq_next = irq + 1;
        //
        if (irq < 32)
        {
            if (read_csr(MINTPENDING0) & (1 << irq))
            {
                if (irq_next < 32)
                {
                    // Pulse next IRQ
                    mem_wr32(INTGEN_IRQ0, (1 << irq_next));
                    mem_wr32(INTGEN_IRQ0, 0);
                }
                else
                {
                    // Pulse next IRQ
                    mem_wr32(INTGEN_IRQ1, (1 << (irq_next - 32)));
                    mem_wr32(INTGEN_IRQ1, 0);
                }
                //
                // Clear Pending
                write_csr(MINTPENDING0, (1 << irq));
            }
        }
        else
        {
            if (read_csr(MINTPENDING1) & (1 << (irq - 32)))
            {
                if (irq != 63)
                {
                    // Pulse next IRQ
                    mem_wr32(INTGEN_IRQ1, (1 << (irq_next - 32)));
                    mem_wr32(INTGEN_IRQ1, 0);

                }
            }
            //
            // Clear Pending
            write_csr(MINTPENDING1, (1 << (irq - 32)));
        }
    }
}

//-------------------------
// Interrupt Handler IRQ
//-------------------------
void INT_IRQ_Handler(void)
{
    uint32_t irq_pend0;
    uint32_t irq_pend1;
    uint32_t irq_level;
    //
    irq_pend0 = read_csr(MINTPENDING0);
    irq_pend1 = read_csr(MINTPENDING1);
    irq_level = read_csr(MINTCURLVL);
    //
    // Dispatch
    switch(irq_level)
    {
        // Group Priority Level 1
        case 1 :
        {
            // IRQ00 (UART)
            if (irq_pend0 & 0x00000001)
            {
                if ((mem_rd8(UART_CSR) & 0x01))
                {
                    INT_UART_Handler();
                    write_csr(MINTPENDING0, 0x00000001); // Clear Pending

                }
                else
                {
                    Interrupt_Nesting_Debug(irq_level);
                }
            }
            break;
        }
        // Group Priority 2-15
        default :
        {
            Interrupt_Nesting_Debug(irq_level);
            break;
        }
       //// Group Priority Level 2
      //case 2 :
      //{
      //    // ...
      //    break;
      //}
      //// ...
      //// ...
      //// Group Priority Level 15
      //case 15 :
      //{
      //    // ...
      //    break;
      //}
    }
}

//===========================================================
// End of Program
//===========================================================
