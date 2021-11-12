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
#include "interrupt.h"

//--------------------------
// Interrupt Initialization
//--------------------------
void INT_Init(void)
{
    // Configure Interrupt Controller
    // IRQ00 : UART, so far disabled
    write_csr(MINTCFGPRIORITY0, 0x00000001); // IRQ00
    write_csr(MINTCURLVL      , 0x00000000); // LVL=0
    write_csr(MINTCFGSENSE0   , 0x00000001); // Edge Sense
    write_csr(MINTCFGENABLE0  , 0x00000001); // IRQ00
}

//===========================================================
// End of Program
//===========================================================
