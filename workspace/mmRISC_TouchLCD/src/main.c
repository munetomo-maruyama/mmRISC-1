//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Routine
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "csr.h"
#include "gsensor.h"
#include "gpio.h"
#include "i2c.h"
#include "interrupt.h"
#include "spi.h"
#include "system.h"
#include "touchlcd_tft.h"
#include "touchlcd_res.h"
#include "touchlcd_cap.h"
#include "uart.h"
#include "xprintf.h"

//----------------------
// Image to draw
//----------------------
#include "logo.h"

//-----------------------
// Global Variable
//-----------------------
extern uint32_t uart_rxd_data;

//-----------------------
// Macro for Ball Demo
//-----------------------
#define SXMIN 200 // screen xmin
#define SYMIN 120 // screen ymin
#define SXWID 120 // screen xwidth
#define SYWID 120 // screen ywidth
#define SXMAX (SXMIN+SXWID) // screen xmax
#define SYMAX (SYMIN+SYWID) // screen ymax
#define BALLSIZE  6
#define WALLWIDTH 2
#define XMIN (SXMIN + WALLWIDTH)
#define XMAX ((SXMAX) - (WALLWIDTH) - (BALLSIZE))
#define YMIN (SYMIN + WALLWIDTH)
#define YMAX ((SYMAX) - (WALLWIDTH) - (BALLSIZE))
#define REFLEX(v) (-0.75 * v) // -75%

//--------------------------------------------------------
// Touch Panel Control for both Resistive and Capacitive
//--------------------------------------------------------
enum TOUCH_DEVICE {TOUCH_NONE, TOUCH_RESISTIVE, TOUCH_CAPACITIVE};
//
uint32_t TOUCH_Touched(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) return TOUCH_RES_Touched();
    if (touch_dev == TOUCH_CAPACITIVE) return TOUCH_CAP_Touched();
    return 0;
}
//
uint32_t TOUCH_Buffer_Empty(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE)  return TOUCH_RES_Buffer_Empty();
    if (touch_dev == TOUCH_CAPACITIVE) return 0;
    return 0;
}
//
void TOUCH_Get_Point(TS_Point *point, uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) TOUCH_RES_Get_Point(point);
    if (touch_dev == TOUCH_CAPACITIVE) TOUCH_CAP_Get_Point(point);
}
//
void TOUCH_Buffer_Clear(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) TOUCH_RES_Buffer_Clear();
    if (touch_dev == TOUCH_CAPACITIVE) return;
}

//-----------------
// Main Routine
//-----------------
void main(void)
{
    uint32_t i;
    uint64_t cyclel, cycleh;
    int16_t gX, gY, gZ;
    //
    uint32_t found_panel_tft = 0;
    uint32_t found_touch_res = 0;
    uint32_t found_touch_cap = 0;
    uint32_t touch_dev = TOUCH_NONE;
    uint32_t touched;
    TS_Point point;
    TS_Point point_prev;
    uint16_t color;
    uint32_t first_touch;
    //
    float fX, fY;
    float fX_prev, fY_prev;
    float fVX, fVY; // velocity
    float fAX, fAY; // acceleration
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    GSENSOR_Init();
    SPI_Init();
    INT_Init();
    //
    // Check LCD Touch Panel
    found_panel_tft = LCD_Init();
    if (found_panel_tft)
    {
        found_touch_res = TOUCH_RES_Init();
        if (found_touch_res == 0) found_touch_cap = TOUCH_CAP_Init();
        touch_dev = (found_touch_cap)? TOUCH_CAPACITIVE :
                    (found_touch_res)? TOUCH_RESISTIVE : TOUCH_NONE;
        found_panel_tft = (touch_dev == TOUCH_NONE)? 0 : found_panel_tft;
    }
    //
    // Message
    printf("======== mmRISC-1 ========\n");
    //
    // Wait for Interrupt
    printf("Input any Character:\n");
    //
    if (found_panel_tft)
    {
        char str1[] = "mmRISC-1";
        char str2[] = "A RISC-V compliant CPU core with RV32IM[A][F]C ISA for MCU. The mmRISC stands for Much More RISC. It contains multiple CPU Harts and a JTAG Debug Module.";
        LCD_Draw_Image(0, 0, logo_BODY, logo_WIDTH, logo_HEIGHT);
        LCD_Draw_String(str1, 0,  4, COLOR_GREEN, COLOR_BLACK, FONT_MEDIUM);
        LCD_Draw_String(str2, 0, 10, COLOR_WHITE, COLOR_BLACK, FONT_SMALL);
        //
        // Color Pallet
        LCD_Fill_Rect(  0, 120,  30,  30, COLOR_BLACK);
        LCD_Fill_Rect(  0, 150,  30,  30, COLOR_BLUE);
        LCD_Fill_Rect(  0, 180,  30,  30, COLOR_GREEN);
        LCD_Fill_Rect(  0, 210,  30,  30, COLOR_CYAN);
        LCD_Fill_Rect( 30, 120,  30,  30, COLOR_RED);
        LCD_Fill_Rect( 30, 150,  30,  30, COLOR_MAGENTA);
        LCD_Fill_Rect( 30, 180,  30,  30, COLOR_YELLOW);
        LCD_Fill_Rect( 30, 210,  30,  30, COLOR_WHITE);
        LCD_Draw_Rect(  0, 120,  60, 118, COLOR_LIGHTGRAY, 2);
        //
        // Paint Campus
        LCD_Draw_Rect( 60, 120, 128, 118, COLOR_LIGHTGRAY, 2);
        first_touch = 1;
        color = COLOR_WHITE;
        //
        // Gravity Ball Area
        LCD_Draw_Rect(SXMIN, SYMIN,
                      SXWID-WALLWIDTH, SYWID-WALLWIDTH,
                      COLOR_YELLOW, WALLWIDTH);
        fX = (float)(SXMIN + SXWID / 2);
        fY = (float)(SYMIN + SYWID / 2);
        fX_prev = fX;
        fY_prev = fY;
        fVX = 0; fVY = 0;
        fAX = 0; fAY = 0;
        //
        // Draw Test
        /*
        LCD_Draw_Line(10,10,310,230, COLOR_YELLOW, 2);
        LCD_Draw_Line(10,230,310,10, COLOR_YELLOW, 2);
        LCD_Fill_Circle(160, 120, 50, COLOR_PINK);
        LCD_Draw_Circle(160, 120, 50, COLOR_CYAN, 2);
        LCD_Fill_Rect(160-20, 120-20, 40, 40, COLOR_BLUE);
        LCD_Draw_Rect(160-20, 120-20, 40, 40, COLOR_WHITE, 4);
        LCD_Fill_Round_Rect(160, 10, 80, 40, 20, COLOR_LIGHTGRAY);
        LCD_Draw_Round_Rect(160, 10, 80, 40, 20, COLOR_GREENYELLOW, 2);
        LCD_Fill_Triangle(50, 50, 70, 10, 80, 60, COLOR_GREENYELLOW);
        LCD_Draw_Triangle(50, 50, 70, 10, 80, 60, COLOR_RED, 4);
        */
    }
    //
    // Forever Loop
    i = 0;
    //
    while(1)
    {
        // Get Cycle
        cyclel = (uint64_t) read_csr(mcycle);
        cycleh = (uint64_t) read_csr(mcycleh);
        //
        // Get G-Sensor
        GSENSOR_ReadXYZ(&gX, &gY, &gZ);
        if (found_panel_tft == 0) printf("(gX,gY,gZ)=(%4d,%4d,%4d)\n", (int)gX, (int)gY, (int)gZ);
        //
        // Set 7-segment LED
        uint32_t seg;
        seg = (uart_rxd_data << 16) + (i & 0x0ffff);
        GPIO_SetSEG(seg);
        i = i + 1;
        //---------------------------------
        // Touch LCD Panel Demo
        //---------------------------------
        if (found_panel_tft)
        {
            //---------------------------------
            // Touch Paint Demo
            //---------------------------------
            touched = TOUCH_Touched(touch_dev);
            if (touched)
            {
                if (TOUCH_Buffer_Empty(touch_dev) == 0)
                {
                    TOUCH_Get_Point(&point, touch_dev);
                    //
                    // Erase Paint Campus
                    if ((point.x >=   0) && (point.x <  30)
                     && (point.y >= 120) && (point.y < 150))
                    {
                        LCD_Fill_Rect( 62, 122, 126, 116, COLOR_BLACK);
                        LCD_Draw_Rect( 60, 120, 128, 118, COLOR_LIGHTGRAY, 2);
                        first_touch = 1;
                        TOUCH_Buffer_Clear(touch_dev);
                    }
                    // Pallet Blue
                    else if ((point.x >=   0) && (point.x <  30)
                          && (point.y >= 150) && (point.y < 180))
                    {
                        color = COLOR_BLUE;
                        first_touch = 1;
                    }
                    // Pallet Green
                    else if ((point.x >=   0) && (point.x <  30)
                          && (point.y >= 180) && (point.y < 210))
                    {
                        color = COLOR_GREEN;
                        first_touch = 1;
                    }
                    // Pallet Cyan
                    else if ((point.x >=   0) && (point.x <  30)
                          && (point.y >= 210) && (point.y < 240))
                    {
                        color = COLOR_CYAN;
                        first_touch = 1;
                    }
                    // Pallet Green
                    else if ((point.x >=  30) && (point.x <  60)
                          && (point.y >= 120) && (point.y < 150))
                    {
                        color = COLOR_RED;
                        first_touch = 1;
                    }
                    // Pallet Magenta
                    else if ((point.x >=  30) && (point.x <  60)
                          && (point.y >= 150) && (point.y < 180))
                    {
                        color = COLOR_MAGENTA;
                        first_touch = 1;
                    }
                    // Pallet Yellow
                    else if ((point.x >=  30) && (point.x <  60)
                          && (point.y >= 180) && (point.y < 210))
                    {
                        color = COLOR_YELLOW;
                        first_touch = 1;
                    }
                    // Pallet White
                    else if ((point.x >=  30) && (point.x <  60)
                          && (point.y >= 210) && (point.y < 240))
                    {
                        color = COLOR_WHITE;
                        first_touch = 1;
                    }
                    // Paint Campus
                    else if ((point.x >=  62) && (point.x <= 185)
                          && (point.y >= 122) && (point.y <= 235))
                    {
                        if (first_touch)
                        {
                            LCD_Draw_Pixel(point.x, point.y, color, 3);
                            first_touch = 0;
                        }
                        else
                        {
                            LCD_Draw_Line(point_prev.x, point_prev.y, point.x, point.y, color, 3);
                        }
                        point_prev.x = point.x;
                        point_prev.y = point.y;
                    }
                    else // out
                    {
                        first_touch = 1;
                    }
                  //printf("TOUCHED=(%5d, %5d)\n", point.x, point.y);
                }
            }
            else // not touched
            {
                first_touch = 1;
            }
            //---------------------------------
            // Gravity Ball Demo
            //---------------------------------
            //
            // Redraw Ball
            if (((int16_t)(fX_prev) != (int16_t)(fX))
             || ((int16_t)(fY_prev) != (int16_t)(fY)))
            {
                LCD_Fill_Rect((int16_t)(fX_prev), (int16_t)(fY_prev), BALLSIZE, BALLSIZE, COLOR_BLACK);
                LCD_Fill_Rect((int16_t)(fX),      (int16_t)(fY),      BALLSIZE, BALLSIZE, COLOR_CYAN);
                fX_prev = fX;
                fY_prev = fY;
            }
            //
            // Simply Physics
            fAX = -(float)(gX) * 0.00001;
            fAY = +(float)(gY) * 0.00001;
            fVX = fVX + fAX;
            fVY = fVY + fAY;
            fX = fX + fVX;
            fY = fY + fVY;
            //
            if (fX < (float)(XMIN))
            {
                fX = (float)(XMIN) - (fX - (float)(XMIN));
                fVX = REFLEX(fVX);
            }
            if (fX > (float)(XMAX))
            {
                fX = (float)(XMAX) - (fX - (float)(XMAX));
                fVX = REFLEX(fVX);
            }
            if (fY < (float)(YMIN))
            {
                fY = (float)(YMIN) - (fY - (float)(YMIN));
                fVY = REFLEX(fVY);
            }
            if (fY > (float)(YMAX))
            {
                fY = (float)(YMAX) - (fY - (float)(YMAX));
                fVY = REFLEX(fVY);
            }
        }
        //
        mem_wr32(0xfffffffc, 0xdeaddead); // Simulation Stop
    }
}

//===========================================================
// End of Program
//===========================================================
