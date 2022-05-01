//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_cap.c
// Description : Touch LCD / Capacitive Touch Control Header
// for Adafruit-2-8-tft-touch-shield-v2 with Capacitive Touch
// Part No.=1947 (FT6206)
//-----------------------------------------------------------
// History :
// Rev.01 2022.04.30 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include <stdlib.h>
#include "common.h"
#include "i2c.h"
#include "system.h"
#include "touchlcd_cap.h"

//------------------------------------
// Capacitive Touch Initialization
//------------------------------------
uint32_t TOUCH_CAP_Init(void)
{
    I2C_Init(I2C1, FT62XX_ADDR);

    uint8_t devid;
    //
    // Check Device
    devid = I2C_ReadByte(I2C1, FT62XX_REG_CHIPID);
    if (devid != FT6206_CHIPID) return 0;
    //
    // Set Threshold
    I2C_WriteByte(I2C1, FT62XX_REG_THRESHHOLD, FT62XX_DEFAULT_THRESHOLD);
    //
    return 1;
}

//----------------------------------
// Capacitive Touch Check if Touched
//----------------------------------
uint32_t TOUCH_CAP_Touched(void)
{
    uint8_t n = I2C_ReadByte(I2C1, FT62XX_REG_NUMTOUCHES);
    n = (n > 2)? 0 : n;
    return n;
}

//----------------------------------
// Capacitive Touch Get Touch Point
//----------------------------------
void TOUCH_CAP_Get_Point(TS_Point *point)
{
    uint8_t data[16];
    I2C_ReadMultiBytes(I2C1, FT62XX_REG_MODE, 16, data);
    point->x = 320 - (((data[5] & 0x0f) << 8) + data[6]);
    point->y = ((data[3] & 0x0f) << 8) + data[4];
    point->z = 1;
}

//===========================================================
// End of Program
//===========================================================
