//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_res.h
// Description : Touch LCD / Resistive Touch Control Header
// for Adafruit-2-8-tft-touch-shield-v2 with Resistive Touch
// Part No.=1651 (STMPE610)
//-----------------------------------------------------------
// History :
// Rev.01 2022.03.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#ifndef TOUCHLCD_RES_H
#define TOUCHLCD_RES_H

#include <stdint.h>
#include "common.h"
#include "touchlcd_tft.h"

//-----------------------------------------------------------
// Define Registers of Resistive Touch Controller STMPE610
//-----------------------------------------------------------
// ID
#define STMPE_CHIPID 0x00
#define STMPE_IDVER  0x02
// Reset Control
#define STMPE_SYS_CTRL1       0x03
#define STMPE_SYS_CTRL1_RESET 0x02
// Clock Contrl
#define STMPE_SYS_CTRL2 0x04
// Touch Screen controller setup
#define STMPE_TSC_CTRL     0x40
#define STMPE_TSC_CTRL_EN  0x01
#define STMPE_TSC_CTRL_XYZ 0x00
#define STMPE_TSC_CTRL_XY  0x02
// Interrupt control
#define STMPE_INT_CTRL          0x09
#define STMPE_INT_CTRL_POL_HIGH 0x04
#define STMPE_INT_CTRL_POL_LOW  0x00
#define STMPE_INT_CTRL_EDGE     0x02
#define STMPE_INT_CTRL_LEVEL    0x00
#define STMPE_INT_CTRL_ENABLE   0x01
#define STMPE_INT_CTRL_DISABLE  0x00
// Interrupt enable
#define STMPE_INT_EN           0x0a
#define STMPE_INT_EN_TOUCHDET  0x01
#define STMPE_INT_EN_FIFOTH    0x02
#define STMPE_INT_EN_FIFOOF    0x04
#define STMPE_INT_EN_FIFOFULL  0x08
#define STMPE_INT_EN_FIFOEMPTY 0x10
#define STMPE_INT_EN_ADC       0x40
#define STMPE_INT_EN_GPIO      0x80
// Interrupt status
#define STMPE_INT_STA          0x0b
#define STMPE_INT_STA_TOUCHDET 0x01
// ADC control
#define STMPE_ADC_CTRL1       0x20
#define STMPE_ADC_CTRL1_12BIT 0x08
#define STMPE_ADC_CTRL1_10BIT 0x00
// ADC control
#define STMPE_ADC_CTRL2          0x21
#define STMPE_ADC_CTRL2_1_625MHZ 0x00
#define STMPE_ADC_CTRL2_3_25MHZ  0x01
#define STMPE_ADC_CTRL2_6_5MHZ   0x02
//  Touchscreen controller configuration
#define STMPE_TSC_CFG 0x41
#define STMPE_TSC_CFG_1SAMPLE      0x00
#define STMPE_TSC_CFG_2SAMPLE      0x40
#define STMPE_TSC_CFG_4SAMPLE      0x80
#define STMPE_TSC_CFG_8SAMPLE      0xC0
#define STMPE_TSC_CFG_DELAY_10US   0x00
#define STMPE_TSC_CFG_DELAY_50US   0x08
#define STMPE_TSC_CFG_DELAY_100US  0x10
#define STMPE_TSC_CFG_DELAY_500US  0x18
#define STMPE_TSC_CFG_DELAY_1MS    0x20
#define STMPE_TSC_CFG_DELAY_5MS    0x28
#define STMPE_TSC_CFG_DELAY_10MS   0x30
#define STMPE_TSC_CFG_DELAY_50MS   0x38
#define STMPE_TSC_CFG_SETTLE_10US  0x00
#define STMPE_TSC_CFG_SETTLE_100US 0x01
#define STMPE_TSC_CFG_SETTLE_500US 0x02
#define STMPE_TSC_CFG_SETTLE_1MS   0x03
#define STMPE_TSC_CFG_SETTLE_5MS   0x04
#define STMPE_TSC_CFG_SETTLE_10MS  0x05
#define STMPE_TSC_CFG_SETTLE_50MS  0x06
#define STMPE_TSC_CFG_SETTLE_100MS 0x07
// FIFO level to generate interrupt
#define STMPE_FIFO_TH 0x4a
// Current filled level of FIFO
#define STMPE_FIFO_SIZE 0x4c
// Current status of FIFO
#define STMPE_FIFO_STA        0x4b
#define STMPE_FIFO_STA_RESET  0x01
#define STMPE_FIFO_STA_OFLOW  0x80
#define STMPE_FIFO_STA_FULL   0x40
#define STMPE_FIFO_STA_EMPTY  0x20
#define STMPE_FIFO_STA_THTRIG 0x10
// Touchscreen controller drive I
#define STMPE_TSC_I_DRIVE      0x58
#define STMPE_TSC_I_DRIVE_20MA 0x00
#define STMPE_TSC_I_DRIVE_50MA 0x01
// Data port for TSC data address
#define STMPE_TSC_DATA_X     0x4d
#define STMPE_TSC_DATA_Y     0x4f
#define STMPE_TSC_FRACTION_Z 0x56
#define STMPE_TSC_DATA_AINC  0x57
#define STMPE_TSC_DATA_NINC  0xd7
// GPIO
#define STMPE_GPIO_SET_PIN   0x10
#define STMPE_GPIO_CLR_PIN   0x11
#define STMPE_GPIO_DIR       0x13
#define STMPE_GPIO_ALT_FUNCT 0x17

//----------------------
// SPI CS Tail Control
//----------------------
#define TOUCH_RES_CS_OFF  0
#define TOUCH_RES_CS_KEEP 1

//--------------------------
// TOUCH Point Structure
//--------------------------
typedef struct
{
    uint16_t x;
    uint16_t y;
    uint16_t z;
} TS_Point;

//---------------
// Prototype
//---------------
void TOUCH_RES_Read_Regs(uint8_t addr, uint8_t *data, uint32_t len);
void TOUCH_RES_Write_Regs(uint8_t addr, uint8_t *data, uint32_t len);
uint8_t TOUCH_RES_Read_Reg8(uint8_t addr);
void TOUCH_RES_Write_Reg8(uint8_t addr, uint8_t data);
uint32_t TOUCH_RES_Init(void);
uint32_t TOUCH_RES_Buffer_Empty(void);
void TOUCH_RES_Buffer_Clear(void);
uint32_t TOUCH_RES_Touched(void);
void TOUCH_RES_Read_Data(uint16_t *x, uint16_t *y, uint16_t *z);
void TOUCH_RES_Get_Point_without_Calib(TS_Point *point);
void TOUCH_RES_Get_Point(TS_Point *point);
void TOUCH_RES_Calibration(void);
void TOUCH_RES_Convert_Calibration(TS_Point *point);

#endif // TOUCHLCD_RES_H
//===========================================================
// End of Program
//===========================================================
