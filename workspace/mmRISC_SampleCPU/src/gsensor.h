//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : gsensor.h
// Description : G Sensor Header (ADXL345 Analog Devices)
//-----------------------------------------------------------
// History :
// Rev.01 2022.02.14 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "i2c.h"

//-------------------------
// Device Address (7bit)
//-------------------------
#define ADXL345_DEV_ADDR7 0x53

//-------------------------
// Define Registers
//-------------------------
#define ADXL345_DEVID          0x00
#define ADXL345_TAP_THRESH     0x1d
#define ADXL345_OFSX           0x1e
#define ADXL345_OFSY           0x1f
#define ADXL345_OFSZ           0x20
#define ADXL345_TAP_DUR        0x21
#define ADXL345_TAP_LATENT     0x22
#define ADXL345_TAP_WINDOW     0x23
#define ADXL345_ACT_THRESH     0x24
#define ADXL345_INACT_THRESH   0x25
#define ADXL345_INACT_TIME     0x26
#define ADXL345_ACT_INACT_CTL  0x27
#define ADXL345_FF_THRESH      0x28
#define ADXL345_FF_TIME        0x29
#define ADXL345_TAP_AXIS       0x2a
#define ADXL345_ACT_TAP_STATUS 0x2b
#define ADXL345_BW_RATE        0x2c
#define ADXL345_POWER_CTL      0x2d
#define ADXL345_INT_ENABLE     0x2e
#define ADXL345_INT_MAP        0x2f
#define ADXL345_INT_SOURCE     0x30
#define ADXL345_DATA_FORMAT    0x31
#define ADXL345_DATAX0         0x32
#define ADXL345_DATAX1         0x33
#define ADXL345_DATAY0         0x34
#define ADXL345_DATAY1         0x35
#define ADXL345_DATAZ0         0x36
#define ADXL345_DATAZ1         0x37
#define ADXL345_FIFO_CTL       0x38
#define ADXL345_FIFO_STATUS    0x39

//---------------
// Prototype
//---------------
void GSENSOR_Init(void);
void GSENSOR_ReadXYZ(int16_t *datax, int16_t *datay, int16_t *dataz);


//===========================================================
// End of Program
//===========================================================
