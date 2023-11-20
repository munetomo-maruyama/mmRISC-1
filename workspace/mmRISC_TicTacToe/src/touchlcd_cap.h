//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_cap.h
// Description : Touch LCD / Capacitive Touch Control Header
// for Adafruit-2-8-tft-touch-shield-v2 with Capacitive Touch
// Part No.=1947 (FT6206)
//-----------------------------------------------------------
// History :
// Rev.01 2022.04.30 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#ifndef TOUCHLCD_CAP_H
#define TOUCHLCD_CAP_H

#include <stdint.h>
#include "common.h"
#include "touchlcd_tft.h"
#include "touchlcd_res.h"

//-----------------------------------------------------------
// Define Registers of Resistive Touch Controller FT6206
//-----------------------------------------------------------
#define FT62XX_ADDR           0x38 // I2C address
#define FT62XX_G_FT5201ID     0xA8 // FocalTech's panel ID
#define FT62XX_REG_NUMTOUCHES 0x02 // Number of touch points

#define FT62XX_NUM_X 0x33 //  Touch X position
#define FT62XX_NUM_Y 0x34 //  Touch Y position

#define FT62XX_REG_MODE        0x00 // Device mode, either WORKING or FACTORY
#define FT62XX_REG_CALIBRATE   0x02 // Calibrate mode
#define FT62XX_REG_WORKMODE    0x00 // Work mode
#define FT62XX_REG_FACTORYMODE 0x40 // Factory mode
#define FT62XX_REG_THRESHHOLD  0x80 // Threshold for touch detection
#define FT62XX_REG_POINTRATE   0x88 // Point rate
#define FT62XX_REG_FIRMVERS    0xA6 // Firmware version
#define FT62XX_REG_CHIPID      0xA3 // Chip selecting
#define FT62XX_REG_VENDID      0xA8 // FocalTech's panel ID

#define FT62XX_VENDID  0x11 // FocalTech's panel ID
#define FT6206_CHIPID  0x06 // Chip selecting
#define FT6236_CHIPID  0x36 // Chip selecting
#define FT6236U_CHIPID 0x64 // Chip selecting

// calibrated for Adafruit 2.8" ctp screen
#define FT62XX_DEFAULT_THRESHOLD 128 // Default threshold for touch detection


//----------------------
// SPI CS Tail Control
//----------------------
#define TOUCH_CAP_CS_OFF  0
#define TOUCH_CAP_CS_KEEP 1

//--------------------------
// TOUCH Point Structure
//--------------------------
//typedef struct
//{
//    uint16_t x;
//    uint16_t y;
//    uint16_t z;
//} TS_Point;

//---------------
// Prototype
//---------------
uint32_t TOUCH_CAP_Init(void);
uint32_t TOUCH_CAP_Touched(void);
void TOUCH_CAP_Get_Point(TS_Point *point);

#endif // TOUCHLCD_CAP_H
//===========================================================
// End of Program
//===========================================================
