//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : i2c.h
// Description : I2C Header
//-----------------------------------------------------------
// History :
// Rev.01 2022.02.12 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"

//-------------------------
// Define Registers
//-------------------------
#define I2C0 0
#define I2C1 1
#define I2C_REG(ch, addr) ((ch == I2C0)? addr : addr + 0x0100)
//
#define I2C_PRERL 0xd0000000 // byte
#define I2C_PRERH 0xd0000004 // byte
#define I2C_CTL   0xd0000008 // byte
#define I2C_TXR   0xd000000c // byte
#define I2C_RXR   0xd000000c // byte
#define I2C_CR    0xd0000010 // byte
#define I2C_SR    0xd0000010 // byte
//
#define I2C_CR_STA  0x80
#define I2C_CR_STO  0x40
#define I2C_CR_RD   0x20
#define I2C_CR_WR   0x10
#define I2C_CR_ACK  0x08
#define I2C_CR_IACK 0x01
//
#define I2C_SR_RXACK 0x80
#define I2C_SR_BUSY  0x40
#define I2C_SR_AL    0x20
#define I2C_SR_TIP   0x02
#define I2C_SR_IF    0x01

//---------------
// Prototype
//---------------
void I2C_Init(uint32_t ch, uint8_t dev_addr7);
void I2C_WriteByte(uint32_t ch, uint8_t addr, uint8_t data);
uint8_t I2C_ReadByte(uint32_t ch, uint8_t addr);
void I2C_WriteMultiBytes(uint32_t ch, uint8_t addr, uint8_t bytes, uint8_t *data);
void I2C_ReadMultiBytes(uint32_t ch, uint8_t addr, uint8_t bytes, uint8_t *data);

//===========================================================
// End of Program
//===========================================================
