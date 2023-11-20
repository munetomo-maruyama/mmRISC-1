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

//-----------------------
// Wait mSec
//-----------------------
void Wait_mSec(uint32_t mSec)
{
    uint64_t cyclel, cycleh, cycle_prev, cycle_now;
    uint32_t freq;
    //
    freq = Get_System_Freq();
    cyclel = (uint64_t) read_csr(mcycle);
    cycleh = (uint64_t) read_csr(mcycleh);
    cycle_prev = (cycleh << 32) + (cyclel);
    //
    while (1)
    {
        cyclel = (uint64_t) read_csr(mcycle);
        cycleh = (uint64_t) read_csr(mcycleh);
        cycle_now = (cycleh << 32) + (cyclel);
        if (cycle_now >= cycle_prev + (mSec * freq / 1000)) break;
    }
}

//===========================================================
// End of Program
//===========================================================
