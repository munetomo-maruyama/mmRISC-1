//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : gsensor.c
// Description : G Sensor Routine (ADXL345 Analog Devices)
//-----------------------------------------------------------
// History :
// Rev.01 2022.02.14 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "gsensor.h"
#include "i2c.h"

//--------------------------
// G Sensor Initialization
//--------------------------
void GSENSOR_Init(void)
{
    I2C_Init(I2C0, ADXL345_DEV_ADDR7);
    I2C_WriteByte(I2C0, ADXL345_POWER_CTL, 0x08);
}

//--------------------------
// G Sensor Read XYZ
//--------------------------
void GSENSOR_ReadXYZ(int16_t *datax, int16_t *datay, int16_t *dataz)
{
    uint8_t data[6];
    //
    I2C_ReadMultiBytes(I2C0, ADXL345_DATAX0, 6, data);
    *datax = (int16_t)((uint16_t)data[0] + (((uint16_t)data[1]) << 8));
    *datay = (int16_t)((uint16_t)data[2] + (((uint16_t)data[3]) << 8));
    *dataz = (int16_t)((uint16_t)data[4] + (((uint16_t)data[5]) << 8));
}

//===========================================================
// End of Program
//===========================================================
