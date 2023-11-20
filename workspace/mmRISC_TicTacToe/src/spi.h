//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : spi.h
// Description : SPI Header
//-----------------------------------------------------------
// History :
// Rev.01 2022.03.22 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"

//-------------------------
// Define Registers
//-------------------------
#define SPI_SPCR  0xe0000000 // byte
#define SPI_SPSR  0xe0000004 // byte
#define SPI_SPDR  0xe0000008 // byte
#define SPI_SPER  0xe000000c // byte
#define SPI_SPCS  0xe0000010 // byte
//
#define SPI_SPCS_IDLE    0xff
#define SPI_SPCS_TFT_CMD 0xfc // TFT Command
#define SPI_SPCS_TFT_DAT 0xfe // TFT Data/Parameter
#define SPI_SPCS_TOUCH   0xfb // Resistive Touch
#define SPI_SPCS_SDCARD  0xf7 // SDCARD
//
#define SPI_SCK_LO 0 //  1MHz
#define SPI_SCK_HI 1 // 10MHz

//----------------------
// SPI CS Tail Control
//----------------------
#define CS_OFF  0
#define CS_KEEP 1


//---------------
// Prototype
//---------------
void SPI_Init(void);
uint8_t SPI_TxRx(uint8_t txd);
void SPI_Set_Chip_Select(uint8_t cs);
void SPI_Set_SCK_Speed(uint32_t speed);

//===========================================================
// End of Program
//===========================================================
