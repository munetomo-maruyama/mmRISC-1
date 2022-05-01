//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_tft.c
// Description : Touch LCD / LCD Graphic Control Header
// for Adafruit-2-8-tft-touch-shield-v2 with Resistive/Capacitive Touch
// Part No.=1651/1947 (ILI9341)
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
#include "touchlcd_tft.h"

//------------------------------
// Swap Macro
//------------------------------
#define SWAP(a, b) ((a != b) && (a += b, b = a - b, a -= b))

//---------------------
// Globals
//---------------------
uint32_t LCD_WIDTH;
uint32_t LCD_HEIGHT;

//---------------------------------
// LCD Initialization Data
// (reference : Adafruit_ILI9341)
//---------------------------------
static const uint8_t LCD_INIT[] =
{
    0xef, 3, 0x03, 0x80, 0x02,
    0xcf, 3, 0x00, 0xc1, 0x30,
    0xed, 4, 0x64, 0x03, 0x12, 0x81,
    0xe8, 3, 0x85, 0x00, 0x78,
    0xcb, 5, 0x39, 0x2c, 0x00, 0x34, 0x02,
    0xf7, 1, 0x20,
    0xea, 2, 0x00, 0x00,
    ILI9341_PWCTR1  , 1, 0x23,             // Power control VRH[5:0]
    ILI9341_PWCTR2  , 1, 0x10,             // Power control SAP[2:0];BT[3:0]
    ILI9341_VMCTR1  , 2, 0x3e, 0x28,       // VCM control
    ILI9341_VMCTR2  , 1, 0x86,             // VCM control2
    ILI9341_MADCTL  , 1, (ILI9341_MADCTL_MV | ILI9341_MADCTL_BGR), // Memory Access Control
    ILI9341_VSCRSADD, 1, 0x00,             // Vertical scroll zero
    ILI9341_PIXFMT  , 1, 0x55,
    ILI9341_FRMCTR1 , 2, 0x00, 0x18,
    ILI9341_DFUNCTR , 3, 0x08, 0x82, 0x27, // Display Function Control
    0xF2, 1, 0x00,                         // 3Gamma Function Disable
    ILI9341_GAMMASET, 1, 0x01,             // Gamma curve selected
    ILI9341_GMCTRP1 , 15, 0x0F, 0x31, 0x2b, 0x0C, 0x0e, // Set Gamma
                          0x08, 0x4e, 0xf1, 0x37, 0x07,
                          0x10, 0x03, 0x0e, 0x09, 0x00,
    ILI9341_GMCTRN1 , 15, 0x00, 0x0e, 0x14, 0x03, 0x11, // Set Gamma
                          0x07, 0x31, 0xc1, 0x48, 0x08,
                          0x0f, 0x0c, 0x31, 0x36, 0x0f,
    ILI9341_SLPOUT  , 0x80,                // Exit Sleep
//  ILI9341_DISPON  , 0x80,                // Display on
    0x00                                   // End of list
};

//--------------------------
// LCD  Initialization
//--------------------------
uint32_t LCD_Init(void)
{
    LCD_TXCMD(ILI9341_SWRESET, NULL, 0, CS_OFF);
    Wait_mSec(150);
    //
    // Check if exists or not?
    uint8_t resp[3] = {0xff, 0xff, 0xff};
    LCD_TXCMD_RXRES(ILI9341_RDDID, NULL, 0, resp, 3, CS_OFF);
    //
    // Found LCD Controller
    if ((resp[0] == 0) && (resp[1] == 0) && (resp[2] == 0))
    {
        uint8_t cmd, x, numArgs;
        const uint8_t *addr = LCD_INIT;
        while ((cmd = *addr++) > 0)
        {
            x = *addr++;
            numArgs = x & 0x7F;
            LCD_TXCMD(cmd, addr, numArgs, CS_OFF);
            addr = addr + numArgs;
            if (x & 0x80) Wait_mSec(150);
        }
        //
        LCD_WIDTH  = ILI9341_TFTHEIGHT;
        LCD_HEIGHT = ILI9341_TFTWIDTH;
        //
        // Clear Screen and DIsplay ON
        LCD_Fill_Rect(0, 0, LCD_WIDTH, LCD_HEIGHT, COLOR_BLACK);
        LCD_TXCMD(ILI9341_DISPON, NULL, 0, CS_OFF);
        //
        return 1;
    }
    //
    // Not Found
    return 0;
}

//--------------------------
// LCD Send Command
//--------------------------
void LCD_TXCMD(uint8_t cmd, const uint8_t *pCmdParam, uint8_t numParam, uint32_t csTail)
{
    uint32_t i;
    //
    SPI_Set_SCK_Speed(SPI_SCK_HI);
    //
    SPI_Set_Chip_Select(SPI_SPCS_TFT_CMD);
    SPI_TxRx(cmd);
    //
    SPI_Set_Chip_Select(SPI_SPCS_TFT_DAT);
    for (i = 0; i < numParam; i++)
    {
        SPI_TxRx(*pCmdParam++);
    }
    //
    if (csTail == CS_OFF) SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//----------------------------------------------
// LCD Send Command and Receive Response
//----------------------------------------------
void LCD_TXCMD_RXRES(uint8_t cmd, const uint8_t *pCmdParam, uint8_t numParam,
                     uint8_t *pCmdResp, uint8_t numResp, uint32_t csTail)
{
    uint32_t i;
    //
    SPI_Set_SCK_Speed(SPI_SCK_HI);
    //
    SPI_Set_Chip_Select(SPI_SPCS_TFT_CMD);
    SPI_TxRx(cmd);
    //
    SPI_Set_Chip_Select(SPI_SPCS_TFT_DAT);
    for (i = 0; i < numParam; i++)
    {
        SPI_TxRx(*pCmdParam++);
    }
    //
    for (i = 0; i < numResp; i++)
    {
        *pCmdResp++ = SPI_TxRx(0x00);
    }
    //
    if (csTail == CS_OFF) SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//--------------------------------
// LCD Set Memory Window
//--------------------------------
void LCD_Set_Memory_Window(uint16_t x0, uint16_t y0, uint16_t w, uint16_t h)
{
    uint16_t x1 = x0 + w -1;
    uint16_t y1 = y0 + h -1;
    uint8_t param[4];
    param[0] = (uint8_t)HI(x0);
    param[1] = (uint8_t)LO(x0);
    param[2] = (uint8_t)HI(x1);
    param[3] = (uint8_t)LO(x1);
    LCD_TXCMD(ILI9341_CASET, param, 4, CS_KEEP);
    param[0] = (uint8_t)HI(y0);
    param[1] = (uint8_t)LO(y0);
    param[2] = (uint8_t)HI(y1);
    param[3] = (uint8_t)LO(y1);
    LCD_TXCMD(ILI9341_PASET, param, 4, CS_OFF);
}

//--------------------------
// LCD Draw Pixel 1x1
//--------------------------
void LCD_Draw_Pixel_1x1(uint16_t x, uint16_t y, uint16_t color)
{
    if ((x >= LCD_WIDTH) || (y >= LCD_HEIGHT)) return;
    //
    LCD_Set_Memory_Window(x, y, 1, 1);
    LCD_TXCMD(ILI9341_RAMWR, NULL, 0, CS_KEEP);
    SPI_TxRx(HI(color));
    SPI_TxRx(LO(color));
    SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//--------------------------
// LCD Fill Rectangle
//--------------------------
void LCD_Fill_Rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color)
{
    uint32_t i;
    if (x >= LCD_WIDTH ) return;
    if (y >= LCD_HEIGHT) return;
    if ((x + w) >= LCD_WIDTH ) w = LCD_WIDTH  - x;
    if ((y + h) >= LCD_HEIGHT) h = LCD_HEIGHT - y;
    //
    LCD_Set_Memory_Window(x, y, w, h);
    LCD_TXCMD(ILI9341_RAMWR, NULL, 0, CS_KEEP);
    for (i = 0; i < w * h; i++)
    {
        SPI_TxRx(HI(color));
        SPI_TxRx(LO(color));
    }
    SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//--------------------------
// LCD Draw Pixel
//--------------------------
void LCD_Draw_Pixel(uint16_t x, uint16_t y, uint16_t color, uint16_t pensize)
{
    if (pensize == 1)
    {
        LCD_Draw_Pixel_1x1(x, y, color);
    }
    else
    {
        LCD_Fill_Rect(x, y, pensize, pensize, color);
    }
}

//--------------------------
// LCD Draw Rectangle
//--------------------------
void LCD_Draw_Rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color, uint16_t pensize)
{
    LCD_Draw_Line(x,   y,   x+w, y,   color, pensize);
    LCD_Draw_Line(x,   y+h, x+w, y+h, color, pensize);
    LCD_Draw_Line(x,   y,   x,   y+h, color, pensize);
    LCD_Draw_Line(x+w, y,   x+w, y+h, color, pensize);
}

//-----------------------------
// LCD Draw Line
//-----------------------------
void LCD_Draw_Line(int16_t x0, int16_t y0,
                   int16_t x1, int16_t y1, uint16_t color, uint16_t pensize)
{
    // Fast Horizontal Line
    if (y0 == y1)
    {
        if (x0 > x1) SWAP(x0, x1);
        LCD_Fill_Rect(x0, y0, x1-x0+pensize, pensize, color);
    }
    // Fast Vertical Line
    else if (x0 == x1)
    {
        if (y0 > y1) SWAP(y0, y1);
        LCD_Fill_Rect(x0, y0, pensize, y1-y0+pensize, color);
    }
    // Generic Line (Bresenham's algorithm)
    else
    {
        int16_t steep = abs(y1 - y0) > abs(x1 - x0);
        if (steep)
        {
            SWAP(x0, y0);
            SWAP(x1, y1);
        }
        if (x0 > x1)
        {
            SWAP(x0, x1);
            SWAP(y0, y1);
        }
        int16_t dx, dy;
        dx = x1 - x0;
        dy = abs(y1 - y0);
        int16_t err = dx / 2;
        int16_t ystep = (y0 < y1)? 1 : -1;
        int16_t x, y;
        y = y0;
        for (x = x0; x <= x1; x++)
        {
            if (steep)
            {
                LCD_Draw_Pixel(y, x, color, pensize);
            }
            else
            {
                LCD_Draw_Pixel(x, y, color, pensize);
            }
            err -= dy;
            if (err < 0)
            {
                y += ystep;
                err += dx;
            }
        }
    }
}

//-----------------------------
// LCD Draw Circle
//-----------------------------
void LCD_Draw_Circle(int16_t x0, int16_t y0, int16_t r, uint16_t color, uint16_t pensize)
{
    int16_t f = 1 - r;
    int16_t ddF_x = 1;
    int16_t ddF_y = -2 * r;
    int16_t x = 0;
    int16_t y = r;
    //
    LCD_Draw_Pixel(x0, y0 + r, color, pensize);
    LCD_Draw_Pixel(x0, y0 - r, color, pensize);
    LCD_Draw_Pixel(x0 + r, y0, color, pensize);
    LCD_Draw_Pixel(x0 - r, y0, color, pensize);
    //
    while (x < y)
    {
        if (f >= 0)
        {
            y = y - 1;
            ddF_y = ddF_y + 2;
            f = f + ddF_y;
        }
        x = x + 1;
        ddF_x = ddF_x + 2;
        f = f + ddF_x;
        //
        LCD_Draw_Pixel(x0 + x, y0 + y, color, pensize);
        LCD_Draw_Pixel(x0 - x, y0 + y, color, pensize);
        LCD_Draw_Pixel(x0 + x, y0 - y, color, pensize);
        LCD_Draw_Pixel(x0 - x, y0 - y, color, pensize);
        LCD_Draw_Pixel(x0 + y, y0 + x, color, pensize);
        LCD_Draw_Pixel(x0 - y, y0 + x, color, pensize);
        LCD_Draw_Pixel(x0 + y, y0 - x, color, pensize);
        LCD_Draw_Pixel(x0 - y, y0 - x, color, pensize);
  }
}

//---------------------------------
// LCD Draw Circle Quadrant
//---------------------------------
void LCD_Draw_Circle_Quadrant(int16_t x0, int16_t y0, int16_t r,
                              uint8_t cornername, uint16_t color, uint16_t pensize)
{
    int16_t f = 1 - r;
    int16_t ddF_x = 1;
    int16_t ddF_y = -2 * r;
    int16_t x = 0;
    int16_t y = r;
    //
    while (x < y)
    {
        if (f >= 0)
        {
            y = y - 1;
            ddF_y = ddF_y + 2;
            f = f + ddF_y;
        }
        x = x + 1;
        ddF_x = ddF_x + 2;
        f = f + ddF_x;
        //
        if (cornername & 0x4)
        {
            LCD_Draw_Pixel(x0 + x, y0 + y, color, pensize);
            LCD_Draw_Pixel(x0 + y, y0 + x, color, pensize);
        }
        if (cornername & 0x2)
        {
            LCD_Draw_Pixel(x0 + x, y0 - y, color, pensize);
            LCD_Draw_Pixel(x0 + y, y0 - x, color, pensize);
        }
        if (cornername & 0x8)
        {
            LCD_Draw_Pixel(x0 - y, y0 + x, color, pensize);
            LCD_Draw_Pixel(x0 - x, y0 + y, color, pensize);
        }
        if (cornername & 0x1)
        {
            LCD_Draw_Pixel(x0 - y, y0 - x, color, pensize);
            LCD_Draw_Pixel(x0 - x, y0 - y, color, pensize);
        }
    }
}

//---------------------------------
// LCD Fill Circle Quadrant
//---------------------------------
// delta : Offset from center-point, used for round-rects
void LCD_Fill_Circle_Quadrant(int16_t x0, int16_t y0, int16_t r,
                              uint8_t corners, int16_t delta,
                              uint16_t color)
{
    int16_t f = 1 - r;
    int16_t ddF_x = 1;
    int16_t ddF_y = -2 * r;
    int16_t x = 0;
    int16_t y = r;
    int16_t px = x;
    int16_t py = y;
    //
    delta++; // Avoid some +1's in the loop
    //
    while (x < y)
    {
        if (f >= 0)
        {
            y = y - 1;
            ddF_y = ddF_y + 2;
            f = f + ddF_y;
        }
        x = x + 1;
        ddF_x = ddF_x + 2;
        f = f + ddF_x;
        //
        // These checks avoid double-drawing certain lines.
        if (x < (y + 1))
        {
            if (corners & 1) // Vertical Line
                LCD_Draw_Line(x0+x, y0-y, x0+x, y0+y+delta-1, color, 1);
            if (corners & 2) // Vertical Line
                LCD_Draw_Line(x0-x, y0-y, x0-x, y0+y+delta-1, color, 1);
        }
        if (y != py)
        {
            if (corners & 1) // Vertical Line
                LCD_Draw_Line(x0+py, y0-px, x0+py, y0+px+delta-1, color, 1);
            if (corners & 2) // Vertical Line
                LCD_Draw_Line(x0-py, y0-px, x0-py, y0+px+delta-1, color, 1);
            py = y;
        }
        px = x;
    }
}

//----------------------------
// LCD Fill Circle
//----------------------------
void LCD_Fill_Circle(int16_t x0, int16_t y0, int16_t r, uint16_t color)
{
    LCD_Draw_Line(x0, y0-r, x0, y0+r, color, 1); // Vertical
    LCD_Fill_Circle_Quadrant(x0, y0, r, 3, 0, color);
}

//---------------------------
// LCD Draw Round Rectangle
//---------------------------
void LCD_Draw_Round_Rect(int16_t x, int16_t y, int16_t w, int16_t h,
                         int16_t r, uint16_t color, uint16_t pensize)
{
    int16_t max_radius = ((w < h) ? w : h) / 2; // 1/2 minor axis
    if (r > max_radius) r = max_radius;
    // Smarter version
    LCD_Draw_Line(x+r  , y,     x+w-r, y,     color, pensize); // Top
    LCD_Draw_Line(x+r  , y+h-1, x+w-r, y+h-1, color, pensize); // Bottom
    LCD_Draw_Line(x    , y+r,   x,     y+h-r, color, pensize); // Left
    LCD_Draw_Line(x+w-1, y+r,   x+w-1, y+h-r, color, pensize); // Right
    // Draw four corners
    LCD_Draw_Circle_Quadrant(x+r,     y+r,     r, 1, color, pensize);
    LCD_Draw_Circle_Quadrant(x+w-r-1, y+r,     r, 2, color, pensize);
    LCD_Draw_Circle_Quadrant(x+w-r-1, y+h-r-1, r, 4, color, pensize);
    LCD_Draw_Circle_Quadrant(x+r,     y+h-r-1, r, 8, color, pensize);
}

//-----------------------------
// LCD Fill Round Rect
//-----------------------------
void LCD_Fill_Round_Rect(int16_t x, int16_t y, int16_t w, int16_t h,
                         int16_t r, uint16_t color)
{
    int16_t max_radius = ((w < h) ? w : h) / 2; // 1/2 minor axis
    if (r > max_radius) r = max_radius;
    // Smarter version
    LCD_Fill_Rect(x+r, y, w-2*r, h, color);
    // Draw four corners
    LCD_Fill_Circle_Quadrant(x+w-r-1, y+r, r, 1, h-2*r-1, color);
    LCD_Fill_Circle_Quadrant(x+r,     y+r, r, 2, h-2*r-1, color);
}

//----------------------------
// LCD Draw Triangle
//----------------------------
void LCD_Draw_Triangle(int16_t x0, int16_t y0, int16_t x1, int16_t y1,
                       int16_t x2, int16_t y2, uint16_t color, uint16_t pensize)
{
    LCD_Draw_Line(x0, y0, x1, y1, color, pensize);
    LCD_Draw_Line(x1, y1, x2, y2, color, pensize);
    LCD_Draw_Line(x2, y2, x0, y0, color, pensize);
}

//----------------------------
// LCD Fill Triangle
//----------------------------
void LCD_Fill_Triangle(int16_t x0, int16_t y0, int16_t x1, int16_t y1,
                       int16_t x2, int16_t y2, uint16_t color)
{
    int16_t a, b, y, last;
    //
    // Sort coordinates by Y order (y2 >= y1 >= y0)
    if (y0 > y1)
    {
        SWAP(y0, y1);
        SWAP(x0, x1);
    }
    if (y1 > y2)
    {
        SWAP(y2, y1);
        SWAP(x2, x1);
    }
    if (y0 > y1)
    {
        SWAP(y0, y1);
        SWAP(x0, x1);
    }
    // Handle awkward all-on-same-line case as its own thing
    if (y0 == y2)
    {
        a = b = x0;
        if (x1 < a)
            a = x1;
        else if (x1 > b)
            b = x1;
        if (x2 < a)
            a = x2;
        else if (x2 > b)
            b = x2;
        LCD_Draw_Line(a, y0, b+1, y0, color, 1); // Horizontal
        return;
    }
    //
    int16_t dx01 = x1 - x0, dy01 = y1 - y0,
            dx02 = x2 - x0, dy02 = y2 - y0,
            dx12 = x2 - x1, dy12 = y2 - y1;
    int32_t sa = 0, sb = 0;
    //
    // For upper part of triangle, find scanline crossings for segments
    // 0-1 and 0-2.  If y1=y2 (flat-bottomed triangle), the scanline y1
    // is included here (and second loop will be skipped, avoiding a /0
    // error there), otherwise scanline y1 is skipped here and handled
    // in the second loop...which also avoids a /0 error here if y0=y1
    // (flat-topped triangle).
    if (y1 == y2)
        last = y1; // Include y1 scanline
    else
        last = y1 - 1; // Skip it
    //
    for (y = y0; y <= last; y++)
    {
        a = x0 + sa / dy01;
        b = x0 + sb / dy02;
        sa += dx01;
        sb += dx02;
        /* longhand:
        a = x0 + (x1 - x0) * (y - y0) / (y1 - y0);
        b = x0 + (x2 - x0) * (y - y0) / (y2 - y0);
        */
        if (a > b) SWAP(a, b);
        LCD_Draw_Line(a, y, b+1, y, color, 1); // Horizontal
    }
    //
    // For lower part of triangle, find scanline crossings for segments
    // 0-2 and 1-2.  This loop is skipped if y1=y2.
    sa = (int32_t)dx12 * (y - y1);
    sb = (int32_t)dx02 * (y - y0);
    for (; y <= y2; y++)
    {
        a = x1 + sa / dy12;
        b = x0 + sb / dy02;
        sa += dx12;
        sb += dx02;
        /* longhand:
        a = x1 + (x2 - x1) * (y - y1) / (y2 - y1);
        b = x0 + (x2 - x0) * (y - y0) / (y2 - y0);
        */
        if (a > b) SWAP(a, b);
        LCD_Draw_Line(a, y, b+1, y, color, 1); // Horizontal
    }
}

//-----------------------
// LCD Draw a Character
//-----------------------
// scale should be 0, 1 or 2
void LCD_Draw_Char(char ch, uint16_t posx, uint16_t posy,
                   uint16_t color_f, uint16_t color_b, uint32_t scale)
{
    uint16_t x0, y0;
    uint16_t xsize, ysize;
    uint16_t x, y;
    uint16_t xfont, yfont;
    uint16_t pixel;
    uint16_t color;

    ch = (ch < 0x20)? 0x20 : (ch > 0x7f)? 0x7f : ch;
    //
    x0 = posx * (FONT_XSIZE << scale);
    y0 = posy * (FONT_YSIZE << scale);
    //
    xsize = FONT_XSIZE * (1 << scale);
    ysize = FONT_YSIZE * (1 << scale);
    //
    if ((x0 <= (LCD_WIDTH - xsize)) && (y0 <= (LCD_HEIGHT - ysize)))
    {
        LCD_Set_Memory_Window(x0, y0, xsize, ysize);
        LCD_TXCMD(ILI9341_RAMWR, NULL, 0, CS_KEEP);
        //
        for (y = 0; y < ysize; y++)
        {
            for (x = 0; x < xsize; x++)
            {
                xfont = x >> scale;
                yfont = y >> scale;
                pixel = FONT[((uint32_t) ch - 0x20) * 8 + yfont];
                pixel = (pixel >> (FONT_XSIZE - 1 - xfont)) & 0x01;
                color = (pixel == 1)? color_f : color_b;
                SPI_TxRx(HI(color));
                SPI_TxRx(LO(color));
            }
        }
        SPI_Set_Chip_Select(SPI_SPCS_IDLE);
    }
}

//--------------------
// LCD_Draw_String
//--------------------
void LCD_Draw_String(char *pStr, uint16_t posx, uint16_t posy,
                     uint16_t color_f, uint16_t color_b, uint32_t scale)
{
    uint16_t x0, y0;
    uint16_t xsize, ysize;
    //
    xsize = FONT_XSIZE * (1 << scale);
    ysize = FONT_YSIZE * (1 << scale);
    //
    while(*pStr != '\0')
    {
        LCD_Draw_Char(*pStr, posx, posy, color_f, color_b, scale);
        pStr++;
        posx = posx + 1;
        if ((posx + 1) * xsize > LCD_WIDTH)
        {
            posx = 0;
            posy = posy + 1;
            if ((posy + 1) * ysize > LCD_HEIGHT)
            {
                posy = 0;
            }
        }
    }
}

//--------------------
// LCD_Draw_Image
//--------------------
void LCD_Draw_Image(uint16_t posx, uint16_t posy,
                    const uint16_t *image, uint16_t width, uint16_t height)
{
    uint16_t x, y;
    uint16_t color;
    //
    LCD_Set_Memory_Window(posx, posy, width, height);
    LCD_TXCMD(ILI9341_RAMWR, NULL, 0, CS_KEEP);
    //
    for (y = 0; y < height; y++)
    {
        for (x = 0; x < width; x++)
        {
            color = image[y * width + x];
            SPI_TxRx(HI(color));
            SPI_TxRx(LO(color));
        }
    }
    //
    SPI_Set_Chip_Select(SPI_SPCS_IDLE);
}

//===========================================================
// End of Program
//===========================================================
