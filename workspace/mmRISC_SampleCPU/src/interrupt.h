//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : interrupt.h
// Description : Interrupt Service Header
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#ifndef INTERRUPT_H_
#define INTERRUPT_H_

#include <stdint.h>
#include "common.h"

//--------------
// CSR
//--------------
#define MSTATUS    0x300
#define MIE        0x304
#define MTVEC      0x305
#define MEPC       0x341
#define MCAUSE     0x342

//-------------------------
// Interrupt Controller
//-------------------------
#define MINTCURLVL       0xbf0
#define MINTPRELVL       0xbf1
#define MINTCFGENABLE0   0xbf2
#define MINTCFGENABLE1   0xbf3
#define MINTCFGSENSE0    0xbf4
#define MINTCFGSENSE1    0xbf5
#define MINTPENDING0     0xbf6
#define MINTPENDING1     0xbf7
#define MINTCFGPRIORITY0 0xbf8
#define MINTCFGPRIORITY1 0xbf9
#define MINTCFGPRIORITY2 0xbfa
#define MINTCFGPRIORITY3 0xbfb
#define MINTCFGPRIORITY4 0xbfc
#define MINTCFGPRIORITY5 0xbfd
#define MINTCFGPRIORITY6 0xbfe
#define MINTCFGPRIORITY7 0xbff

//-------------------
// MTIME
//-------------------
#define MTIME_CTRL 0x49000000
#define MTIME_DIV  0x49000004
#define MTIME      0x49000008
#define MTIMEH     0x4900000c
#define MTIMECMP   0x49000010
#define MTIMECMPH  0x49000014
#define MSOFTIRQ   0x49000018

//-------------------
// INTGEN
//-------------------
#define INTGEN_IRQ_EXT 0xc0000000
#define INTGEN_IRQ0    0xc0000004
#define INTGEN_IRQ1    0xc0000008

//---------------
// Prototype
//---------------
void IRQ_Config
(
    uint32_t irqnum,   // IRQ Number : 0 ~ 63
    uint32_t enable,   // IRQ Enable : 0=Disable, 1=Enable
    uint32_t sense,    // IRQ Sense  : 0=Level  , 1=Edge
    uint32_t priority  // IRQ Level  : 0 ~ 15
);
//
void INT_Config
(
    uint32_t ena_intext,   // Enable External Interrupt
    uint32_t ena_intmtime, // Enable MTIME Interrupt
    uint32_t ena_intmsoft, // Enable SOFTWARE Interrupt
    uint32_t ena_irq,      // Enable IRQ Interrupts
    uint32_t cur_irqlvl    // Current IRQ Level
);
//
void INT_Generate(uint32_t intext, uint32_t intsoft, uint64_t irq);
//
void MTIME_Init(uint32_t enable, uint32_t div_plus_one, uint64_t intena,
                uint64_t mtime_count, uint64_t mtime_compa);
//
void INT_Init(void);

#endif
//===========================================================
// End of Program
//===========================================================
