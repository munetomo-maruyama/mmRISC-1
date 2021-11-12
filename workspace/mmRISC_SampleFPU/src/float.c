//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : float.c
// Description : Floating Point Arithmetic Routine
//-----------------------------------------------------------
// History :
// Rev.01 2021.07.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdio.h>
#include <math.h>
#include "common.h"
#include "csr.h"
#include "float.h"
#include "gpio.h"
#include "uart.h"
#include "xprintf.h"

#define STRING(frn) #frn

//--------------------------------
// Read FRx
//--------------------------------
#define read_fr(frn)                         \
({                                           \
    unsigned long __tmp;                     \
    asm volatile ("fmv.x.w %0, " STRING(frn) \
        : "=r"(__tmp));                      \
    __tmp;                                   \
})

//--------------------------------
// Write FRx
//--------------------------------
#define write_fr(frn, val)                       \
({                                               \
    asm volatile ("fmv.w.x " STRING(frn) ", %0"  \
        :: "r"(val));                            \
})

//--------------------------------
// Write XRx
//--------------------------------
#define write_xr(xrn, val)                       \
({                                               \
    asm volatile ("c.mv " STRING(xrn) ", %0"  \
        :: "r"(val));                            \
})

//--------------------------
// Floating Main
//--------------------------
void main_floating(void)
{
    uint32_t i;
    uint32_t bcd1000, bcd100, bcd10, bcd1, bcd;
    uint64_t cyclel, cycleh, cycle_prev, cycle_now;
    //
    while(1)
    {
        for (i = 0; i < 360; i++)
        {
            float fth  = 2 * M_PI / 360.0 * (float)i;
            float fsin = sinf(fth);
            float    fsin_disp = fsin  * 10000.0;
            int32_t  isin_disp = (int32_t) fsin_disp;
            GPIO_SetSEG_SignedDecimal(isin_disp);
            //
            cyclel = (uint64_t) read_csr(mcycle);
            cycleh = (uint64_t) read_csr(mcycleh);
            cycle_prev = (cycleh << 32) + (cyclel);
            while (1)
            {
                cyclel = (uint64_t) read_csr(mcycle);
                cycleh = (uint64_t) read_csr(mcycleh);
                cycle_now = (cycleh << 32) + (cyclel);
                if (cycle_now >= cycle_prev + 1666666) break;
            }
        }
    }
}

//===========================================================
// End of Program
//===========================================================
