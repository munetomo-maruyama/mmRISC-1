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
#define MTVEC      0x305
#define MIE        0x304
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

//---------------
// Prototype
//---------------
void INT_Init(void);
void INT_Timer_Handler(void);

#endif
//===========================================================
// End of Program
//===========================================================
