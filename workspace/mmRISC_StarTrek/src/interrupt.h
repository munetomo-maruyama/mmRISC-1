//===========================================================
// mmRISC-0 Project
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

//-------------------
// MTIME
//-------------------
#define MTIME_CTRL 0x49000000
#define MTIME_DIV  0x49000004
#define MTIME      0x49000008
#define MTIMECMP   0x49000010

//---------------
// Prototype
//---------------
void INT_Init(void);
void INT_EXT_Handler(void);
void INT_TIM_Handler(void);

#endif
//===========================================================
// End of Program
//===========================================================
