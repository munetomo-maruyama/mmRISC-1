//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : touchlcd_tft.h
// Description : Touch LCD / LCD Graphic Control Header
// for Adafruit-2-8-tft-touch-shield-v2 with Resistive/Capacitive Touch
// Part No.=1651/1947 (ILI9341)
//-----------------------------------------------------------
// History :
// Rev.01 2022.03.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#ifndef TOUCHLCD_TFT_H
#define TOUCHLCD_TFT_H

#include <stdint.h>
#include "common.h"
#include "font.h"

//------------------------
// Extract HI/LO Byte
//------------------------
#define HI(x) ((x >> 8) & 0x0ff)
#define LO(x) ((x >> 0) & 0x0ff)

//----------------------------------------------
// Define Registers of LCD Controller ILI9341
//----------------------------------------------
#define ILI9341_TFTWIDTH  240 // ILI9341 max TFT width
#define ILI9341_TFTHEIGHT 320 // ILI9341 max TFT height
//
#define ILI9341_NOP     0x00 // No-op register
#define ILI9341_SWRESET 0x01 // Software reset register
#define ILI9341_RDDID   0x04 // Read display identification information
#define ILI9341_RDDST   0x09 // Read Display Status
//
#define ILI9341_RDMODE     0x0a // Read Display Power Mode
#define ILI9341_RDMADCTL   0x0b // Read Display MADCTL
#define ILI9341_RDPIXFMT   0x0c // Read Display Pixel Format
#define ILI9341_RDIMGFMT   0x0d // Read Display Image Format
#define ILI9341_RDSIGMODE  0x0e // Read Display Signal Mode
#define ILI9341_RDSELFDIAG 0x0f // Read Display Self-Diagnostic Result
//
#define ILI9341_SLPIN  0x10 // Enter Sleep Mode
#define ILI9341_SLPOUT 0x11 // Sleep Out
#define ILI9341_PTLON  0x12 // Partial Mode ON
#define ILI9341_NORON  0x13 // Normal Display Mode ON
//
#define ILI9341_INVOFF   0x20 // Display Inversion OFF
#define ILI9341_INVON    0x21 // Display Inversion ON
#define ILI9341_GAMMASET 0x26 // Gamma Set
#define ILI9341_DISPOFF  0x28 // Display OFF
#define ILI9341_DISPON   0x29 // Display ON
//
#define ILI9341_CASET    0x2a // Column Address Set
#define ILI9341_PASET    0x2b // Page Address Set
#define ILI9341_RAMWR    0x2c // Memory Write
#define ILI9341_COLORSET 0x2d // Color Set
#define ILI9341_RAMRD    0x2e // Memory Read
//
#define ILI9341_PTLAR    0x30 // Partial Area
#define ILI9341_VSCRDEF  0x33 // Vertical Scrolling Definition
#define ILI9341_TELOFF   0x34 // Tearing Effect Line OFF
#define ILI9341_TELON    0x35 // Tearing Effect Line ON
#define ILI9341_MADCTL   0x36 // Memory Access Control
#define ILI9341_VSCRSADD 0x37 // Vertical Scrolling Start Address
#define ILI9341_IDLEOFF  0x38 // IDLE Mode OFF
#define ILI9341_IDLEON   0x39 // IDLE Mode ON
#define ILI9341_PIXFMT 0x3a   // COLMOD: Pixel Format Set
//
#define ILI9341_RAMWRCONT 0x3c // Write Memory Continue
#define ILI9341_RAMRDCONT 0x3e // Read Memory Continue
//
#define ILI9341_SETTEARSCANLINE 0x44 // Set Tear Scan Line
#define ILI9341_GETSCANLINE     0x45 // Get Scan Line
#define ILI9341_WRDISPBRIGHT    0x51 // Write Display Brightness
#define ILI9341_RDDISPBRIGHT    0x52 // Read Display Brightness
#define ILI9341_WRCONTDISP      0x53 // Write Control Display
#define ILI9341_RDCONTDISP      0x54 // Read Control Display
#define ILI9341_WRADPTBRIGHT    0x55 // Write Content Adaptive Brightness
#define ILI9341_RDADPTBRIGHT    0x56 // Read Content Adaptive Brightness
#define ILI9341_WRCABCMINBRIGHT 0x5e // Write CABC Min Brightness
#define ILI9341_RDCABCMINBRIGHT 0x5f // Read CABC Min Brightness
//
#define ILI9341_RGBIFSIGCTL 0xb0 // RGB Interface Signal Control
#define ILI9341_FRMCTR1     0xb1 // Frame Rate Control (In Normal Mode/Full Colors)
#define ILI9341_FRMCTR2     0xb2 // Frame Rate Control (In Idle Mode/8 colors)
#define ILI9341_FRMCTR3     0xb3 // Frame Rate control (In Partial Mode/Full Colors)
#define ILI9341_INVCTR      0xb4 // Display Inversion Control
#define ILI9341_BLANKPORCH  0xb5 // Blanking Porch Control
#define ILI9341_DFUNCTR     0xb6 // Display Function Control
#define ILI9341_ENTRYMODE   0xb7 // Entry Mode Set
#define ILI9341_BACKLIGHT1  0xb8 // Back Light Control 1
#define ILI9341_BACKLIGHT2  0xb9 // Back Light Control 2
#define ILI9341_BACKLIGHT3  0xba // Back Light Control 3
#define ILI9341_BACKLIGHT4  0xbd // Back Light Control 4
#define ILI9341_BACKLIGHT5  0xbc // Back Light Control 5
#define ILI9341_BACKLIGHT7  0xbe // Back Light Control 7
#define ILI9341_BACKLIGHT8  0xbf // Back Light Control 8
//
#define ILI9341_PWCTR1 0xC0 // Power Control 1
#define ILI9341_PWCTR2 0xC1 // Power Control 2
#define ILI9341_PWCTR3 0xC2 // Power Control 3
#define ILI9341_PWCTR4 0xC3 // Power Control 4
#define ILI9341_PWCTR5 0xC4 // Power Control 5
#define ILI9341_VMCTR1 0xC5 // VCOM Control 1
#define ILI9341_VMCTR2 0xC7 // VCOM Control 2
//
#define ILI9341_NVMEMWR     0xd0 // NV Memory Write
#define ILI9341_NVMEMKEY    0xd1 // NV Memory Protect Key
#define ILI9341_NVMEMRDSTAT 0xd2 // NV Memory Status Read
//
#define ILI9341_RDID1 0xda // Read ID 1
#define ILI9341_RDID2 0xdb // Read ID 2
#define ILI9341_RDID3 0xdc // Read ID 3
#define ILI9341_RDID4 0xdd // Read ID 4
//
#define ILI9341_GMCTRP1 0xe0 // Positive Gamma Correction
#define ILI9341_GMCTRN1 0xe1 // Negative Gamma Correction
#define ILI9341_DGCTL1  0xe2 // Digital Gamma Control 1
#define ILI9341_DGCTL2  0xe3 // Digital Gamma Control 2
#define ILI9341_IFCTL   0xf6 // Interface Control

//--------------------------------
// Define Memory Access Control
//--------------------------------
#define ILI9341_MADCTL_MY 0x80  // Bottom to top
#define ILI9341_MADCTL_MX 0x40  // Right to left
#define ILI9341_MADCTL_MV 0x20  // Reverse Mode
#define ILI9341_MADCTL_ML 0x10  // LCD refresh Bottom to top
#define ILI9341_MADCTL_RGB 0x00 // Red-Green-Blue pixel order
#define ILI9341_MADCTL_BGR 0x08 // Blue-Green-Red pixel order
#define ILI9341_MADCTL_MH 0x04  // LCD refresh right to left

//-----------------
// Font Parameters
//-----------------
#define FONT_XSIZE 8
#define FONT_YSIZE 8
#define FONT_SMALL  0
#define FONT_MEDIUM 1
#define FONT_LARGE  2

//-------------------------
// Define Colors
//-------------------------
#define COLOR16(r, g, b) (((r>>3)<<11)+((g>>2)<<5)+((b>>3)<<0))
#define COLOR_BLACK       COLOR16(  0,   0,   0)
#define COLOR_NAVY        COLOR16(  0,   0, 123)
#define COLOR_DARKGREEN   COLOR16(  0, 125,   0)
#define COLOR_DARKCYAN    COLOR16(  0, 125, 123)
#define COLOR_MAROON      COLOR16(123,   0,   0)
#define COLOR_PURPLE      COLOR16(123,   0, 123)
#define COLOR_OLIVE       COLOR16(123, 125,   0)
#define COLOR_LIGHTGREY   COLOR16(198, 195, 198)
#define COLOR_DARKGREY    COLOR16(123, 125, 123)
#define COLOR_BLUE        COLOR16(  0,   0, 255)
#define COLOR_GREEN       COLOR16(  0, 255,   0)
#define COLOR_CYAN        COLOR16(  0, 255, 255)
#define COLOR_RED         COLOR16(255,   0,   0)
#define COLOR_MAGENTA     COLOR16(255,   0, 255)
#define COLOR_YELLOW      COLOR16(255, 255,   0)
#define COLOR_WHITE       COLOR16(255, 255, 255)
#define COLOR_ORANGE      COLOR16(255, 165,   0)
#define COLOR_GREENYELLOW COLOR16(173, 255,  41)
#define COLOR_PINK        COLOR16(255, 130, 198)

//---------------
// Prototype
//---------------
void LCD_TXCMD(uint8_t cmd, const uint8_t *pCmdParam, uint8_t numParam, uint32_t csTail);
void LCD_TXCMD_RXRES(uint8_t cmd, const uint8_t *pCmdParam, uint8_t numParam,
                          uint8_t *pCmdResp, uint8_t numResp, uint32_t csTail);
uint32_t LCD_Init(void);
void LCD_Set_Memory_Window(uint16_t x1, uint16_t y1, uint16_t w, uint16_t h);
//
void LCD_Draw_Pixel_1x1(uint16_t x, uint16_t y, uint16_t color);
void LCD_Fill_Rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);
void LCD_Draw_Pixel(uint16_t x, uint16_t y, uint16_t color, uint16_t pensize);
void LCD_Draw_Rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color, uint16_t pensize);
void LCD_Draw_Line(int16_t x0, int16_t y0,
                   int16_t x1, int16_t y1, uint16_t color, uint16_t pensize);
void LCD_Draw_Circle(int16_t x0, int16_t y0, int16_t r, uint16_t color, uint16_t pensize);
void LCD_Draw_Circle_Quadrant(int16_t x0, int16_t y0, int16_t r,
                              uint8_t cornername, uint16_t color, uint16_t pensize);
void LCD_Fill_Circle_Quadrant(int16_t x0, int16_t y0, int16_t r,
                              uint8_t corners, int16_t delta,
                              uint16_t color);
void LCD_Fill_Circle(int16_t x0, int16_t y0, int16_t r, uint16_t color);
void LCD_Draw_Round_Rect(int16_t x, int16_t y, int16_t w, int16_t h,
                         int16_t r, uint16_t color, uint16_t pensize);
void LCD_Fill_Round_Rect(int16_t x, int16_t y, int16_t w, int16_t h,
                         int16_t r, uint16_t color);
void LCD_Draw_Triangle(int16_t x0, int16_t y0, int16_t x1, int16_t y1,
                       int16_t x2, int16_t y2, uint16_t color, uint16_t pensize);
void LCD_Fill_Triangle(int16_t x0, int16_t y0, int16_t x1, int16_t y1,
                       int16_t x2, int16_t y2, uint16_t color);
void LCD_Draw_Char(char ch, uint16_t posx, uint16_t posy,
                   uint16_t color_f, uint16_t color_b, uint32_t scale);
void LCD_Draw_String(char *pStr, uint16_t posx, uint16_t posy,
                     uint16_t color_f, uint16_t color_b, uint32_t scale);
void LCD_Draw_Image(uint16_t posx, uint16_t posy,
                    const uint16_t *image, uint16_t width, uint16_t height);

#endif // TOUCHLCD_TFT_H
//===========================================================
// End of Program
//===========================================================
