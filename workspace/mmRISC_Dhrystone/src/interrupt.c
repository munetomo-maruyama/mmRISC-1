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
#include "system.h"
#include "uart.h"
#include "interrupt.h"

//--------------------------
// Interrupt Initialization
//--------------------------
void INT_Init(void)
{
    uint32_t irq;
    uint32_t level;
    //
    // Configure IRQ00 as UART RXD Interrupt
    IRQ_Config(0, 1, 1, 1);
    //
    // Enable MTIME to make periodic interrupt
    MTIME_Init(1, 10, 1, 0, Get_System_Freq()/10/10); // 100ms
    //
    // Enable MTIME and IRQ Interrupts
    INT_Config(0, 1, 0, 1, 0x0);
}

//--------------------------
// IRQ Configuration
//--------------------------
void IRQ_Config
(
    uint32_t irqnum,   // IRQ Number : 0 ~ 63
    uint32_t enable,   // IRQ Enable : 0=Disable, 1=Enable
    uint32_t sense,    // IRQ Sense  : 0=Level  , 1=Edge
    uint32_t level     // IRQ Level  : 0 ~ 15
)
{
    uint32_t pos1, pos4;
    uint32_t data;
    //
    enable = enable & 0x01;
    sense  = sense  & 0x01;
    level  = level & 0x0f;
    //
    // Set Priority
    if (irqnum < 8)
    {
        pos4 = (irqnum - 0) * 4;
        //
        data = read_csr(MINTCFGPRIORITY0);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY0, data);
    }
    else if (irqnum < 16)
    {
        pos4 = (irqnum - 8) * 4;
        //
        data = read_csr(MINTCFGPRIORITY1);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY1, data);
    }
    else if (irqnum < 24)
    {
        pos4 = (irqnum - 16) * 4;
        //
        data = read_csr(MINTCFGPRIORITY2);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY2, data);
    }
    else if (irqnum < 32)
    {
        pos4 = (irqnum - 24) * 4;
        //
        data = read_csr(MINTCFGPRIORITY3);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY3, data);
    }
    else if (irqnum < 40)
    {
        pos4 = (irqnum - 32) * 4;
        //
        data = read_csr(MINTCFGPRIORITY4);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY4, data);
    }
    else if (irqnum < 48)
    {
        pos4 = (irqnum - 40) * 4;
        //
        data = read_csr(MINTCFGPRIORITY5);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY5, data);
    }
    else if (irqnum < 56)
    {
        pos4 = (irqnum - 48) * 4;
        //
        data = read_csr(MINTCFGPRIORITY6);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY6, data);
    }
    else if (irqnum < 64)
    {
        pos4 = (irqnum - 56) * 4;
        //
        data = read_csr(MINTCFGPRIORITY7);
        data = (data & ~(0x0f << pos4)) | (level << pos4);
        write_csr(MINTCFGPRIORITY7, data);
    }
    //
    // Set Sense and Enable
    if (irqnum < 32)
    {
        pos1 = (irqnum - 0);
        //
        data = read_csr(MINTCFGSENSE0);
        data = (data & ~(0x01 << pos1)) | (sense << pos1);
        write_csr(MINTCFGSENSE0, data);
        //
        data = read_csr(MINTCFGENABLE0);
        data = (data & ~(0x01 << pos1)) | (enable << pos1);
        write_csr(MINTCFGENABLE0, data);
    }
    else if (irqnum < 64)
    {
        pos1 = (irqnum - 32);
        //
        data = read_csr(MINTCFGSENSE1);
        data = (data & ~(0x01 << pos1)) | (sense << pos1);
        write_csr(MINTCFGSENSE1, data);
        //
        data = read_csr(MINTCFGENABLE1);
        data = (data & ~(0x01 << pos1)) | (enable << pos1);
        write_csr(MINTCFGENABLE1, data);
    }
}

//--------------------------
// Interrupt Configuration
//--------------------------
void INT_Config
(
    uint32_t ena_intext,   // Enable External Interrupt
    uint32_t ena_intmtime, // Enable MTIME Interrupt
    uint32_t ena_intmsoft, // Enable SOFTWARE Interrupt
    uint32_t ena_irq,      // Enable IRQ Interrupts
    uint32_t cur_irqlvl    // Current IRQ Level
)
{
    uint32_t data;
    //
    ena_intext   = ena_intext & 0x01;
    ena_intmtime = ena_intmtime & 0x01;
    ena_intmsoft = ena_intmsoft & 0x01;
    ena_irq      = ena_irq & 0x01;
    cur_irqlvl   = cur_irqlvl & 0x0f;
    //
    // Interrupt Current Level
    write_csr(MINTCURLVL, cur_irqlvl);
    //
    // Enable Interrupt
    data = read_csr(MIE);
    data = (data & ~((1<<11) | (1<<7)| (1<<3)))
         | (ena_intext << 11) | (ena_intmtime << 7) | (ena_intmsoft << 3);
    write_csr(MIE, data);
    //
    data = read_csr(MSTATUS);
    data = (data & ~(0x01 << 3))
         | ((ena_intext | ena_intmtime | ena_intmsoft | ena_irq) << 3);
    write_csr(MSTATUS, data);
}

//---------------------------
// Interrupt Generate
//---------------------------
void INT_Generate
(
    uint32_t intext,
    uint32_t intsoft,
    uint64_t irq
)
{
    mem_wr32(INTGEN_IRQ_EXT, intext  & 0x01);
    mem_wr32(MSOFTIRQ      , intsoft & 0x01);
    mem_wr32(INTGEN_IRQ1   , (uint32_t)(irq >> 32));
    mem_wr32(INTGEN_IRQ0   , (uint32_t)(irq & 0x0ffffffffUL));
}

//---------------------
// MTIME Initialization
//---------------------
void MTIME_Init
(
    uint32_t enable,
    uint32_t div_plus_one,
    uint64_t intena,
    uint64_t mtime_count,
    uint64_t mtime_compa
)
{
    uint32_t div;
    //
    enable = enable & 0x01;
    div    = (div_plus_one > 0)? div_plus_one - 1 : div_plus_one;
    div    = div & 0x3f;
    intena = intena & 0x01;
    //
    mem_wr32(MTIME_DIV , div);
    mem_wr32(MTIME     , (uint32_t)(mtime_count & 0x0ffffffffUL));
    mem_wr32(MTIMEH    , (uint32_t)(mtime_count >> 32          ));
    mem_wr32(MTIMECMP  , (uint32_t)(mtime_compa & 0x0ffffffffUL));
    mem_wr32(MTIMECMPH , (uint32_t)(mtime_compa >> 32          ));
    mem_wr32(MTIME_CTRL, (intena << 2) | (enable << 0));
}

//-----------------------------
// Interrupt Handler External
//-----------------------------
__attribute__ ((interrupt)) void INT_Handler_EXT(void)
{
    // Negate IRQ_EXT
    mem_wr32(INTGEN_IRQ_EXT, 0x00000000);
    //
    // Write your own code
}

//----------------------------
// Interrupt Handler MTIME
//----------------------------
__attribute__ ((interrupt)) void INT_Handler_MTIME(void)
{
    // Clear Interrupt Flag in MTIME
    mem_wr32(MTIME_CTRL, mem_rd32(MTIME_CTRL));
    //
    // Write your own code
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
}

//-----------------------------
// Interrupt Handler MSOFT
//-----------------------------
__attribute__ ((interrupt)) void INT_Handler_MSOFT(void)
{
    // Negate MSOFT
    mem_wr32(MSOFTIRQ, 0x00000000);
    //
    // Write your own code
}

//-------------------------
// Interrupt Handler IRQ
//-------------------------
__attribute__ ((interrupt)) void INT_Handler_IRQ(void)
{
    uint32_t irq_level;
    uint64_t irq_pend0;
    uint64_t irq_pend1;
    uint64_t irq_pend;
    uint32_t prev_mepc;
    uint32_t prev_mstatus;
    uint32_t prev_mintprelvl;
    //
    // Get Pending Status
    irq_level = read_csr(MINTCURLVL);
    irq_pend0 = (uint64_t)read_csr(MINTPENDING0);
    irq_pend1 = (uint64_t)read_csr(MINTPENDING1);
    irq_pend  = (irq_pend1 << 32) + (irq_pend0 << 0);
    //
    // Save Previous Status
    prev_mintprelvl = read_csr(MINTPRELVL);
    prev_mepc       = read_csr(MEPC);
    prev_mstatus    = read_csr(MSTATUS);
    //
    // Enable global interrupt (set mie)
    write_csr(MSTATUS, prev_mstatus | 0x08);
    //
    //-------------------------------------------------
    // Dispatch to each Priority Handler
    switch(irq_level)
    {
        // Group Priority Level 1
        case  1 :
        {
            // IRQ00
            if (irq_pend0 & 0x00000001)
            {
                INT_UART_Handler();
                write_csr(MINTPENDING0, 0x00000001); // Clear Pending
            }
            break;
        }
        //  Never reach here
        default :
        {
            break;
        }
    }
    //-------------------------------------------------
    //
    // Disable global interrupt, Save Previous Status
    write_csr(MSTATUS   , prev_mstatus); // mie=0
    write_csr(MEPC      , prev_mepc);
    write_csr(MINTCURLVL, prev_mintprelvl);
}

//===========================================================
// End of Program
//===========================================================
