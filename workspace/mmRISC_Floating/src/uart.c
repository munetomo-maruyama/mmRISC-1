//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : uart.c
// Description : UART Routine
//-----------------------------------------------------------
// History :
// Rev.01 2021.05.08 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "csr.h"
#include "gpio.h"
#include "system.h"
#include "uart.h"
#include "xprintf.h"

//----------------------
// UART Rx Buffer
//----------------------
#define RXD_BUF_SIZE (32*1024*1024)
//#define RXD_BUF_SIZE (256)
uint8_t  RxD_Buf[RXD_BUF_SIZE];
uint32_t RxD_Buf_WP = 0;
uint32_t RxD_Buf_RP = 0;
uint32_t RxD_Buf_DC = 0;

//-----------------------------------
// Get Data Count in UART Rx Buffer
//-----------------------------------
uint32_t Get_UART_RxD_Buffer_DC(void)
{
    return RxD_Buf_DC;
}

//-----------------------------------
// Get RxD Data in UART Rx Buffer
//-----------------------------------
uint8_t Get_UART_RxD_BUffer_Data(void)
{
    uint8_t rxd = 0;
    //
    if (RxD_Buf_DC > 0)
    {
        rxd = RxD_Buf[RxD_Buf_RP];
        RxD_Buf_RP = (RxD_Buf_RP + 1) % RXD_BUF_SIZE;
        RxD_Buf_DC = RxD_Buf_DC - 1;
    }
    // So far, do not send back CR/LF
    if ((rxd != '\r') && (rxd != '\n'))
    {
        UART_TxD(rxd); // Send Back to TXD
    }
    // Force to Upper Case for Hex Char
    rxd = ((rxd>='a') && (rxd<='f'))? rxd - 0x20 : rxd;
    return rxd;
}

//------------------------
// UART Interrupt Handler
//------------------------
void INT_UART_Handler(void)
{
    uint8_t rxd;
    //
    // Read a Received Data
    rxd = UART_RxD(); // RXD
    //
    // Buffer Overflow?
    if (RxD_Buf_DC >= RXD_BUF_SIZE)
    {
        UART_TxD('!'); // Send Alert
    }
    //
    // Store Receive Buffer
    else
    {
        RxD_Buf[RxD_Buf_WP] = rxd;
        RxD_Buf_WP = (RxD_Buf_WP + 1) % RXD_BUF_SIZE;
        RxD_Buf_DC = RxD_Buf_DC + 1;
        //
        // So far, do not send back CR/LF
      //if (rxd != '\r')
      //{
      //    UART_TxD(rxd); // TXD
      //}
    }

#if 0
    static uint32_t data0 = 0;;
    static uint32_t data1 = 0;;
    static uint32_t data2 = 0;;
    uint32_t data32;
    //
    data2 = data1;
    data1 = data0;
    data0 = (uint32_t) UART_RxD(); // RXD
    data32 = (data2 << 16) + (data1 << 8) + (data0 << 0);
    GPIO_SetSEG(data32);
    UART_TxD(data0);     // TXD
    if (data0 == '\r') UART_TxD((uint8_t)'\n');
#endif
}

//----------------------
// UART Initialization
//----------------------
void UART_Init(void)
{
#ifdef FPGA
    // Baud Rate = (fCLK/4) / ((BG0+2)*(BG1))
    //   20.00MHz,   9600bps, BG0=20-2=18, BG1=26
    //   20.00MHz,  57600bps, BG0=29-2=27, BG1= 3
    //   20.00MHz, 115200bps, BG0= 7-2= 5, BG1= 6
    //   16.67MHz,   9600bps, BG0=87-2=85, BG1= 5
    //   16.67MHz,  57600bps, BG0=12-2=10, BG1= 6
    //   16.66MHz, 115200bps, BG0=6-2=4, BG1= 6
    uint32_t freq = Get_System_Freq();
    if (freq == 20000000) // without RV32F 20.00MHz
    {
      //mem_wr8(UART_BG0, 18);
      //mem_wr8(UART_BG1, 26);
        mem_wr8(UART_BG0, 27);
        mem_wr8(UART_BG1,  3);
      //mem_wr8(UART_BG0,  5);
      //mem_wr8(UART_BG1,  6);
    }
    else // with RV32F 16.66.00MHz
    {
      //mem_wr8(UART_BG0, 85);
      //mem_wr8(UART_BG1,  5);
        mem_wr8(UART_BG0, 10);
        mem_wr8(UART_BG1,  6);
      //mem_wr8(UART_BG0,  4);
      //mem_wr8(UART_BG1,  6);
    }
    //
    mem_wr8(UART_CSR, 0x40); // IERX=1
#endif
#ifdef MODELSIM
    mem_wr8(UART_BG0, 1);
    mem_wr8(UART_BG1, 1);
    mem_wr8(UART_CSR, 0x40); // IERX=1
#endif
    //
    // for xprintf()
    xdev_out(UART_TxD);
    xdev_in (UART_RxD);
}

//-----------------
// UART TXD
//-----------------
void UART_TxD(uint8_t data)
{
    while ((mem_rd8(UART_CSR) & 0x02) == 0x00);
    mem_wr8(UART_TXD, data);
}

//-----------------
// UART RXD
//-----------------
uint8_t UART_RxD(void)
{
    while ((mem_rd8(UART_CSR) & 0x01) == 0x00);
    return mem_rd8(UART_RXD);
}

//---------------------------------
// UART Put String
//---------------------------------
void uart_puts(const char *s)
{
	while(*s)
	{
		UART_TxD((uint8_t)*s++);
	}
}

//---------------------------------
// UART Put Char
//---------------------------------
int putchar(int ch)
{
    if (ch == '\n')
    {
    	UART_TxD((uint8_t)'\r');
    }
    UART_TxD((uint8_t)ch);
    return ch;

}

//===========================================================
// End of Program
//===========================================================
