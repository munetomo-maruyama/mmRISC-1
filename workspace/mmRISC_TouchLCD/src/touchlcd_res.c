//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_res.c
// Description : Touch LCD / Resistive Touch Control Routine
// for Adafruit-2-8-tft-touch-shield-v2 with Resistive Touch
// Part No.=1651 (STMPE610)
//-----------------------------------------------------------
// History :
// Rev.01 2022.03.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include <stdlib.h>
#include "common.h"
#include "gpio.h"
#include "spi.h"
#include "system.h"
#include "touchlcd_res.h"

//---------------------
// Globals
//---------------------
uint16_t TOUCH_RES_MX0; // Measured X of top    edge
uint16_t TOUCH_RES_MX1; // Measured X of bottom edge
uint16_t TOUCH_RES_MY0; // Measured Y of left   edge
uint16_t TOUCH_RES_MY1; // Measured Y of right  edge

//--------------------------------
// Resistive Touch Read Registers
//--------------------------------
void TOUCH_RES_Read_Regs(uint8_t addr, uint8_t *data, uint32_t len)
{
    uint32_t i;
    //
    SPI_Set_SCK_Speed(SPI_SCK_LO);
    SPI_Set_Chip_Select(SPI_SPCS_TOUCH);
    //
    SPI_TxRx((addr++) | 0x80);
    for (i = 0; i < len; i++)
    {
        *data++ = SPI_TxRx((addr++) | 0x80);
    }
    SPI_TxRx(0x00); // stop
    //
    SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//--------------------------------
// Resistive Touch Write Registers
//--------------------------------
void TOUCH_RES_Write_Regs(uint8_t addr, uint8_t *data, uint32_t len)
{
    uint32_t i;
    //
    SPI_Set_SCK_Speed(SPI_SCK_LO);
    SPI_Set_Chip_Select(SPI_SPCS_TOUCH);
    //
    SPI_TxRx(addr++);
    for (i = 0; i < len; i++)
    {
        SPI_TxRx(*data++);
    }
    //
    SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//------------------------------------
// Resistive Touch Read Register 8bit
//------------------------------------
uint8_t TOUCH_RES_Read_Reg8(uint8_t addr)
{
    uint8_t buf[1];
    TOUCH_RES_Read_Regs(addr, buf, 1);
    return buf[0];
}

//-------------------------------------
// Resistive Touch Write Register 8bit
//-------------------------------------
void TOUCH_RES_Write_Reg8(uint8_t addr, uint8_t data)
{
    uint8_t buf[1];
    buf[0] = data;
    TOUCH_RES_Write_Regs(addr, buf, 1);
}

//---------------------------------
// Resistive Touch Initialization
//---------------------------------
uint32_t TOUCH_RES_Init(void)
{
    uint32_t i;
    //
    // Check if exists or not?
    uint8_t resp[2];
    TOUCH_RES_Read_Regs(STMPE_CHIPID, resp, 2);
    //
    // Found Resistive Touch Controller
    if ((resp[0] == 0x08) && (resp[1] == 0x11))
    {
        // Reset
        TOUCH_RES_Write_Reg8(STMPE_SYS_CTRL1, STMPE_SYS_CTRL1_RESET);
        Wait_mSec(10);
        for (i = 0; i < 65; i++) TOUCH_RES_Read_Reg8((uint8_t)i);
        //
        // Turn on Clocks
        TOUCH_RES_Write_Reg8(STMPE_SYS_CTRL2, 0x0);
        //
        // XYZ and enable
        TOUCH_RES_Write_Reg8(STMPE_TSC_CTRL, STMPE_TSC_CTRL_XYZ | STMPE_TSC_CTRL_EN);
        //
        // Interrupt Enable (but disconnected on the board)
        TOUCH_RES_Write_Reg8(STMPE_INT_EN, STMPE_INT_EN_TOUCHDET);
        //
        // ADC Control (96 clocks per conversion)
        TOUCH_RES_Write_Reg8(STMPE_ADC_CTRL1, STMPE_ADC_CTRL1_10BIT | (0x6 << 4));
        TOUCH_RES_Write_Reg8(STMPE_ADC_CTRL2, STMPE_ADC_CTRL2_6_5MHZ);
        //
        // Touch Screen Control
        TOUCH_RES_Write_Reg8(STMPE_TSC_CFG, STMPE_TSC_CFG_4SAMPLE   |
                                        STMPE_TSC_CFG_DELAY_1MS |
                                        STMPE_TSC_CFG_SETTLE_5MS);
        TOUCH_RES_Write_Reg8(STMPE_TSC_FRACTION_Z, 0x6);
        TOUCH_RES_Write_Reg8(STMPE_FIFO_TH, 1);
        TOUCH_RES_Write_Reg8(STMPE_FIFO_STA, STMPE_FIFO_STA_RESET);
        TOUCH_RES_Write_Reg8(STMPE_FIFO_STA, 0); // unreset
        TOUCH_RES_Write_Reg8(STMPE_TSC_I_DRIVE, STMPE_TSC_I_DRIVE_50MA);
        TOUCH_RES_Write_Reg8(STMPE_INT_STA, 0xFF); // reset all ints
        TOUCH_RES_Write_Reg8(STMPE_INT_CTRL,
                         STMPE_INT_CTRL_POL_HIGH | STMPE_INT_CTRL_ENABLE);
        //
        // Default Calibration Data
        TOUCH_RES_MX0 = 3600; // Measured X of top    edge
        TOUCH_RES_MX1 =  320; // Measured X of bottom edge
        TOUCH_RES_MY0 =  270; // Measured Y of left   edge
        TOUCH_RES_MY1 = 3600; // Measured Y of right  edge
        //
        // Touch Calibration, if any
        TOUCH_RES_Calibration();
        //
        return 1;
    }
    //
    // Not Found
    return 0;
}

//-------------------------------
// Resistive Touch Buffer Empty
//-------------------------------
uint32_t TOUCH_RES_Buffer_Empty(void)
{
    uint32_t result;
    result = (TOUCH_RES_Read_Reg8(STMPE_FIFO_STA) & STMPE_FIFO_STA_EMPTY)? 1 : 0;
    return result;
}

//-------------------------------
// Resistive Touch Buffer Clear
//-------------------------------
void TOUCH_RES_Buffer_Clear(void)
{
    uint16_t x, y, z;
    while (TOUCH_RES_Buffer_Empty() == 0)
    {
        TOUCH_RES_Read_Data(&x, &y, &z);
    }
}

//----------------------------------
// Resistive Touch Check if Touched
//----------------------------------
uint32_t TOUCH_RES_Touched(void)
{
    uint32_t result;
    result = (TOUCH_RES_Read_Reg8(STMPE_TSC_CTRL) & 0x80)? 1 : 0;
    return result;
}

//---------------------------
// Resistive Touch Read Data
//---------------------------
void TOUCH_RES_Read_Data(uint16_t *x, uint16_t *y, uint16_t *z)
{
    uint32_t i;
    uint8_t data[4];
    //
    for (i = 0; i < 4; i++)
    {
        data[i] = TOUCH_RES_Read_Reg8(STMPE_TSC_DATA_NINC);
    }
    *x = data[0];
    *x = *x << 4;
    *x = *x | (data[1] >> 4);
    *y = data[1] & 0x0f;
    *y = *y << 8;
    *y = *y | data[2];
    *z = data[3];
}

//-------------------------------------------------
// Resistive Touch Get Point without Calibration
//-------------------------------------------------
void TOUCH_RES_Get_Point_without_Calib(TS_Point *point)
{
    uint16_t x, y, z;
    x = 0; y = 0; z = 0;
    //
    TOUCH_RES_Read_Data(&x, &y, &z);
    TOUCH_RES_Write_Reg8(STMPE_INT_STA, 0xff); // Clear Interrupt
    //
    point->x = x;
    point->y = y;
    point->z = z;
}

//---------------------------------------------
// Resistive Touch Get Point with Calibration
//---------------------------------------------
void TOUCH_RES_Get_Point(TS_Point *point)
{
    TOUCH_RES_Get_Point_without_Calib(point);
    TOUCH_RES_Convert_Calibration(point);
}

//----------------------------
// Resistive Touch Calibration
//----------------------------
void TOUCH_RES_Calibration(void)
{
    TS_Point point0; // measured (X,Y) at ( 10,  10)
    TS_Point point1; // measured (X,Y) at ( 10, 230)
    TS_Point point2; // measured (X,Y) at (310, 230)
    TS_Point point3; // measured (X,Y) at (310,  10)
    //
    // if KEY in (bottom push switch), do calibrate
    if (GPIO_GetKEY() == 0) return;
    //
    // Get Measured Value M0 at ( 10,  10)
    LCD_Fill_Rect(  0,   9,  20,  3, COLOR_WHITE); //( 10, 10)
    LCD_Fill_Rect(  9,   0,   3, 20, COLOR_WHITE); //( 10, 10)
    while(TOUCH_RES_Touched()); // wait for release
    TOUCH_RES_Buffer_Clear();
    while(TOUCH_RES_Touched() == 0); // wait for touch
    while(1)
    {
        if (TOUCH_RES_Buffer_Empty() == 0)
        {
            TOUCH_RES_Get_Point_without_Calib(&point0);
            break;
        }
    }
    LCD_Fill_Rect(  0,   9,  20,  3, COLOR_BLACK); //( 10, 10)
    LCD_Fill_Rect(  9,   0,   3, 20, COLOR_BLACK); //( 10, 10)
    //
    // Get Measured Value M1 at ( 10, 230)
    LCD_Fill_Rect(  0, 229,  20,  3, COLOR_WHITE); //( 10,230)
    LCD_Fill_Rect(  9, 220,   3, 20, COLOR_WHITE); //( 10,230)
    while(TOUCH_RES_Touched()); // wait for release
    TOUCH_RES_Buffer_Clear();
    while(TOUCH_RES_Touched() == 0); // wait for touch
    while(1)
    {
        if (TOUCH_RES_Buffer_Empty() == 0)
        {
            TOUCH_RES_Get_Point_without_Calib(&point1);
            break;
        }
    }
    LCD_Fill_Rect(  0, 229,  20,  3, COLOR_BLACK); //( 10,230)
    LCD_Fill_Rect(  9, 220,   3, 20, COLOR_BLACK); //( 10,230)
    //
    // Get Measured Value M2 at (310, 230)
    LCD_Fill_Rect(300, 229,  20,  3, COLOR_WHITE); //(310,230)
    LCD_Fill_Rect(309, 220,   3, 20, COLOR_WHITE); //(310,230)
    while(TOUCH_RES_Touched()); // wait for release
    TOUCH_RES_Buffer_Clear();
    while(TOUCH_RES_Touched() == 0); // wait for touch
    while(1)
    {
        if (TOUCH_RES_Buffer_Empty() == 0)
        {
            TOUCH_RES_Get_Point_without_Calib(&point2);
            break;
        }
    }
    LCD_Fill_Rect(300, 229,  20,  3, COLOR_BLACK); //(310,230)
    LCD_Fill_Rect(309, 220,   3, 20, COLOR_BLACK); //(310,230)
    //
    // Get Measured Value M3 at (310,  10)
    LCD_Fill_Rect(300,   9,  20,  3, COLOR_WHITE); //(310, 10)
    LCD_Fill_Rect(309,   0,   3, 20, COLOR_WHITE); //(310, 10)
    while(TOUCH_RES_Touched()); // wait for release
    TOUCH_RES_Buffer_Clear();
    while(TOUCH_RES_Touched() == 0); // wait for touch
    while(1)
    {
        if (TOUCH_RES_Buffer_Empty() == 0)
        {
            TOUCH_RES_Get_Point_without_Calib(&point3);
            break;
        }
    }
    LCD_Fill_Rect(300,   9,  20,  3, COLOR_BLACK); //(310, 10)
    LCD_Fill_Rect(309,   0,   3, 20, COLOR_BLACK); //(310, 10)
    //
    while(TOUCH_RES_Touched()); // wait for release
    TOUCH_RES_Buffer_Clear();
    //
    // Store Measured Data
    TOUCH_RES_MX0 = (point3.x + point0.x) / 2; // Measured X of top    edge
    TOUCH_RES_MX1 = (point1.x + point2.x) / 2; // Measured X of bottom edge
    TOUCH_RES_MY0 = (point0.y + point1.y) / 2; // Measured Y of left   edge
    TOUCH_RES_MY1 = (point2.y + point3.y) / 2; // Measured Y of right  edge
}

//----------------------------------------
// Resistive Touch Convert by Calibration
//----------------------------------------
// Measured        Calibrated
// ( MX , MY ) --> ( CX,  CY)
// ( 320, 270) --> ( 10, 230)
// (3600, 270) --> ( 10,  10)
// ( 320,3600) --> (310, 230)
// (3600,3600) --> (310,  10)
// CX = (MY -  270)*(300/3330)+10
// CY = (3600 - MX)*(220/3280)+10
//
// CX = (MY - MY0)*(dCX/dMY)+CX0
// CY = (MX0 - MX)*(dCY/dMX)+CY0
//
void TOUCH_RES_Convert_Calibration(TS_Point *point)
{
    float MX  = (float)(point->x);
    float MY  = (float)(point->y);
    float MX0 = (float)(TOUCH_RES_MX0);
    float MY0 = (float)(TOUCH_RES_MY0);
    float dCX = (float)(310 - 10);
    float dCY = (float)(230 - 10);
    float dMX = (float)(TOUCH_RES_MX1) - (float)(TOUCH_RES_MX0);
    float dMY = (float)(TOUCH_RES_MY1) - (float)(TOUCH_RES_MY0);
    float CX0 = 10;
    float CY0 = 10;
    float CX = (MY - MY0)*(dCX/dMY)+CX0;
    float CY = (MX - MX0)*(dCY/dMX)+CY0;
    point->x = (CX < 0)? 0 : (CX >=320)? 319 : (uint16_t)CX;
    point->y = (CY < 0)? 0 : (CY >=240)? 239 : (uint16_t)CY;
}

//===========================================================
// End of Program
//===========================================================
