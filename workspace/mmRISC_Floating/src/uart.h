//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : uart.h
// Description : UART Header
//-----------------------------------------------------------
// History :
// Rev.01 2021.05.08 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"

//-------------------------
// Define Registers
//-------------------------
#define UART_REG 0xb0000000 // word
#define UART_TXD 0xb0000000 // byte
#define UART_RXD 0xb0000000 // byte
#define UART_CSR 0xb0000001 // byte
#define UART_BG0 0xb0000002 // byte
#define UART_BG1 0xb0000003 // byte

//---------------
// Prototype
//---------------
uint32_t Get_UART_RxD_Buffer_DC(void);
uint8_t  Get_UART_RxD_BUffer_Data(void);

void INT_UART_Handler(void);
void UART_Init(void);
void UART_TxD(uint8_t data);
uint8_t UART_RxD(void);

void uart_puts(const char *s);
int putchar(int ch);

//===========================================================
// End of Program
//===========================================================
