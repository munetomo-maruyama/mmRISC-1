//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : spi.c
// Description : SPI Routine
//-----------------------------------------------------------
// History :
// Rev.01 2022.03.22 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "spi.h"

//--------------------------
// SPI Initialization
//--------------------------
void SPI_Init(void)
{
    // Chip Select
    mem_wr8(SPI_SPCS, SPI_SPCS_IDLE);
    //
    // CPOL=0, CPHA=0, Interrupt Disable, SPI Enable
    // SCK Frequency, so far low speed (CLK/32)
    // 16.6MHz --> SCK=0.521MHz
    // 20.0MHz --> SCK=0.625MHz
    mem_wr8(SPI_SPCR, 0x53);
    mem_wr8(SPI_SPER, 0x00);
}

//------------------------
// SPI Send & Receive Byte
//------------------------
uint8_t SPI_TxRx(uint8_t txd)
{
    // FIFO should be Empty here
  //while((mem_rd8(SPI_SPSR) & 0x04) == 0);
    //
    // Send a Byte
    mem_wr8(SPI_SPDR, txd);
    //
    // Wait for Read FIFO not Empty
    while((mem_rd8(SPI_SPSR) & 0x01) != 0);
    //
    // Receive a Byte
    uint8_t rxd = mem_rd8(SPI_SPDR);
    return rxd;
}

//-------------------------
// SPI Set Chip Select
//-------------------------
void SPI_Set_Chip_Select(uint8_t cs)
{
    mem_wr8(SPI_SPCS, cs);
}

//-------------------------
// SPI Set SCK Speed
//-------------------------
void SPI_Set_SCK_Speed(uint32_t speed)
{
    if (speed == SPI_SCK_LO)
    {
        // CPOL=0, CPHA=0, Interrupt Disable, SPI Enable
        // Clock LO Speed (CLK/32)
        // 16.6MHz --> SCK=0.521MHz
        // 20.0MHz --> SCK=0.625MHz
        mem_wr8(SPI_SPCR, 0x53);
    }
    else // if (speed = SPI_SCK_HI)
    {
        // CPOL=0, CPHA=0, Interrupt Disable, SPI Enable
        // Clock Hi Speed (CLK/2)
        // 16.6MHz --> SCK=8.333MHz
        // 20.0MHz --> SCK=10.00MHz
        mem_wr8(SPI_SPCR, 0x50);
    }
}

//===========================================================
// End of Program
//===========================================================
