//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : gpio.h
// Description : GPIO Header
//-----------------------------------------------------------
// History :
// Rev.01 2021.05.08 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#ifndef GPIO_H_
#define GPIO_H_

#include <stdint.h>
#include "common.h"

//-------------------------
// Define Registers
//-------------------------
#define GPIO_PDR0 0xa0000000
#define GPIO_PDR1 0xa0000004
#define GPIO_PDR2 0xa0000008
#define GPIO_PDD0 0xa0000010
#define GPIO_PDD1 0xa0000014
#define GPIO_PDD2 0xa0000018

//---------------
// 7-segment LED
//---------------
#define LED_0  (~(0x3f))
#define LED_1  (~(0x06))
#define LED_2  (~(0x5b))
#define LED_3  (~(0x4f))
#define LED_4  (~(0x66))
#define LED_5  (~(0x6d))
#define LED_6  (~(0x7d))
#define LED_7  (~(0x07))
#define LED_8  (~(0x7f))
#define LED_9  (~(0x6f))
#define LED_A  (~(0x77))
#define LED_B  (~(0x7c))
#define LED_C  (~(0x39))
#define LED_D  (~(0x5e))
#define LED_E  (~(0x79))
#define LED_F  (~(0x71))
#define LED_DP (~(0x80))
static const uint8_t LED7SEG[]
    = {LED_0, LED_1, LED_2, LED_3, LED_4, LED_5, LED_6, LED_7,
       LED_8, LED_9, LED_A, LED_B, LED_C, LED_D, LED_E, LED_F};

//---------------
// Prototype
//---------------
void GPIO_Init(void);
void GPIO_SetSEG(uint32_t num);
void GPIO_SetLED(uint32_t bit);
uint32_t GPIO_GetKEY(void);
uint32_t GPIO_GetSW10(void);

#endif
//===========================================================
// End of Program
//===========================================================
