//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Routine
//-----------------------------------------------------------
// History :
// Rev.01 2023.11.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2023 M.Maruyama
//===========================================================

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "csr.h"
#include "gpio.h"
#include "i2c.h"
#include "interrupt.h"
#include "spi.h"
#include "system.h"
#include "tictactoe.h"
#include "touchlcd_tft.h"
#include "touchlcd_res.h"
#include "touchlcd_cap.h"
#include "uart.h"
#include "xprintf.h"

//-----------------
// Main Routine
//-----------------
void main(void)
{
    uint32_t found_panel_tft = 0;
    uint32_t found_touch_res = 0;
    uint32_t found_touch_cap = 0;
    uint32_t touch_dev = TOUCH_NONE;
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
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
    //------------------
    // Play Games!
    //------------------
    // if you do not have LCD, play it on Terminal
    if (found_panel_tft == 0)
        TicTacToe_on_Terminal();
    // if you have LCD, play it on Touch LCD Panal
    else
        TicTacToe_on_TouchLCD(touch_dev);
}

//===========================================================
// End of Program
//===========================================================
