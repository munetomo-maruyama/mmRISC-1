//===========================================================
// mmRISC-0 Project
//-----------------------------------------------------------
// File Name   : gpio.c
// Description : GPIO Routine
//-----------------------------------------------------------
// History :
// Rev.01 2021.05.08 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "gpio.h"

//-----------------------
// Initialize PORT
//-----------------------
void GPIO_Init(void)
{
	mem_wr32(GPIO_PDR0, 0x00000000);
    mem_wr32(GPIO_PDR1, 0x00000000);
    mem_wr32(GPIO_PDR2, 0x00000000);
	mem_wr32(GPIO_PDD0, 0xffffffff);
    mem_wr32(GPIO_PDD1, 0x03ffffff);
    mem_wr32(GPIO_PDD2, 0x00000000);
	GPIO_SetLED(0);
	GPIO_SetSEG(0);
}

//------------------------
// Set 7-Segment LED
//------------------------
void GPIO_SetSEG(uint32_t num)
{
    uint8_t num0 = (num >>  0) & 0x0f;
    uint8_t num1 = (num >>  4) & 0x0f;
    uint8_t num2 = (num >>  8) & 0x0f;
    uint8_t num3 = (num >> 12) & 0x0f;
    uint8_t num4 = (num >> 16) & 0x0f;
    uint8_t num5 = (num >> 20) & 0x0f;
    num0 = LED7SEG[num0];
    num1 = LED7SEG[num1];
    num2 = LED7SEG[num2];
    num3 = LED7SEG[num3];
    num4 = LED7SEG[num4];
    num5 = LED7SEG[num5];
    //
    uint32_t out;
    out = (num3 << 24) | (num2 << 16) | (num1 << 8) | (num0 << 0);
    mem_wr32(GPIO_PDR0, out);
    out = mem_rd32(GPIO_PDR1);
    out = out & 0xffff0000;
    out = out | (num5 << 8) | (num4 << 0);
    mem_wr32(GPIO_PDR1, out);
}

//-----------------
// Set Single LED
//-----------------
void GPIO_SetLED(uint32_t bit)
{
	bit = bit & 0x3ff;
    uint32_t out;
    out = mem_rd32(GPIO_PDR1);
    out = out & 0xfc00ffff;
    out = out | (bit << 16);
    mem_wr32(GPIO_PDR1, out);
}

//----------------
// Get KEY
//----------------
uint32_t GPIO_GetKEY(void)
{
    uint32_t in = mem_rd32(GPIO_PDR2);
    in = ((~in) >> 10) & 0x01; // KEY1
    return in;
}

//----------------
// Get SW 10bit
//----------------
uint32_t GPIO_GetSW10(void)
{
    uint32_t in = mem_rd32(GPIO_PDR2);
	in = in & 0x3ff;
	return in;
}

//===========================================================
// End of Program
//===========================================================
