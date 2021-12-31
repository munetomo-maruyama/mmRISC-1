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

//-----------------------
// Global Variable
//-----------------------
uint32_t uart_rxd_data;

//------------------------
// UART Interrupt Handler
//------------------------
void INT_UART_Handler(void)
{
    /*
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
    */
    uart_rxd_data = (uint32_t) UART_RxD(); // RXD
    UART_TxD(uart_rxd_data);
    if (uart_rxd_data == '\r') UART_TxD((uint8_t)'\n');
}

//----------------------
// UART Initialization
//----------------------
void UART_Init(void)
{
#ifdef FPGA
    // Baud Rate = (fCLK/4) / ((BG0+2)*(BG1))
    //   20.00MHz, 9600bps, BG0=20-2=18, BG1=26
    //   20.00MHz, 115200bps, BG0=7-2=5, BG1= 6
    //   16.67MHz, 9600bps, BG0=87-2=85, BG1= 5
    //   16.66MHz, 115200bps, BG0=6-2=4, BG1= 6
    uint32_t freq = Get_System_Freq();
    if (freq == 20000000) // without RV32F 20.00MHz
    {
        mem_wr8(UART_BG0, 18);
        mem_wr8(UART_BG1, 26);
      //mem_wr8(UART_BG0,  5);
      //mem_wr8(UART_BG1,  6);
    }
    else // with RV32F 16.66.00MHz
    {
        mem_wr8(UART_BG0, 85);
        mem_wr8(UART_BG1,  5);
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
