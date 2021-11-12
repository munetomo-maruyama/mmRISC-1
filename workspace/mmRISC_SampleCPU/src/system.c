//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : system.c
// Description : System Control
//-----------------------------------------------------------
// History :
// Rev.01 2021.10.23 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "csr.h"

//---------------------------------
// Get System Clock Frequency
//---------------------------------
uint32_t Get_System_Freq(void)
{
    // If FPGA Configured with Floating Point, 16.7MHz, else 20.0MHz
    uint32_t isa = read_csr(misa);
    uint32_t freq = (isa & 0x20)? 16666667 : 20000000;
    return freq;
}

//===========================================================
// End of Program
//===========================================================
