//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : i2c.c
// Description : I2C Routine
//-----------------------------------------------------------
// History :
// Rev.01 2022.02.12 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "i2c.h"
#include "system.h"

//---------------------
// Global Data
//---------------------
uint8_t I2C_DEV_ADDR7[2];

//--------------------------
// I2C Initialization
//--------------------------
void I2C_Init(uint32_t ch, uint8_t dev_addr7)
{
    // SCL=100KHz
    mem_wr8(I2C_REG(ch, I2C_PRERL),  39);
    mem_wr8(I2C_REG(ch, I2C_PRERH),   0);
    // Enable I2C Module (disabled Interrupts)
    mem_wr8(I2C_REG(ch, I2C_CTL),  0x80);
    // Device Address
    I2C_DEV_ADDR7[ch] = dev_addr7;
}

//------------------------
// I2C Write a Byte
//------------------------
void I2C_WriteByte(uint32_t ch, uint8_t addr, uint8_t data)
{
    // START + I2C_DEV_ADDR7 + W
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x00);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send Access Address
    mem_wr8(I2C_REG(ch, I2C_TXR), addr);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send  Write Data + STOP
    mem_wr8(I2C_REG(ch, I2C_TXR), data);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STO);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
}

//-------------------------
// I2C Read a Byte
//-------------------------
uint8_t I2C_ReadByte(uint32_t ch, uint8_t addr)
{
    uint8_t data;

    // START + I2C_DEV_ADDR7 + W
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x00);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send Access Address
    mem_wr8(I2C_REG(ch, I2C_TXR), addr);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // START + I2C_DEV_ADDR7 + R
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x01);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Read + NACK (last) + STOP
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_RD | I2C_CR_ACK | I2C_CR_STO);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
    data = mem_rd8(I2C_REG(ch, I2C_RXR));

    return data;
}

//--------------------------
// I2C Write Multiple Bytes
//--------------------------
void I2C_WriteMultiBytes(uint32_t ch, uint8_t addr, uint8_t bytes, uint8_t *data)
{
    uint32_t i;

    // START + I2C_DEV_ADDR7 + W
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x00);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send Access Address
    mem_wr8(I2C_REG(ch, I2C_TXR), addr);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send Write Data * (bytes-1)
    i = 1;
    while(i < bytes)
    {
        mem_wr8(I2C_REG(ch, I2C_TXR), *data++);
        mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR);
        asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
        while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
        i++;
    }

    // Send  Write Data + STOP
    mem_wr8(I2C_REG(ch, I2C_TXR), *data++);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STO);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
}

//-------------------------
// I2C Read Multiple Bytes
//-------------------------
void I2C_ReadMultiBytes(uint32_t ch, uint8_t addr, uint8_t bytes, uint8_t *data)
{
    uint32_t i;

    // START + I2C_DEV_ADDR7 + W
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x00);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Send Access Address
    mem_wr8(I2C_REG(ch, I2C_TXR), addr);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // START + I2C_DEV_ADDR7 + R
    mem_wr8(I2C_REG(ch, I2C_TXR), (I2C_DEV_ADDR7[ch] << 1) + 0x01);
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_WR | I2C_CR_STA);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);

    // Read + ACK * (bytes-1)
    i = 1;
    while(i < bytes)
    {
        mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_RD);
        asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
        while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
        *data++ = mem_rd8(I2C_REG(ch, I2C_RXR));
        i++;
    }

    // Read + NACK (last) + STOP
    mem_wr8(I2C_REG(ch, I2C_CR), I2C_CR_RD | I2C_CR_ACK | I2C_CR_STO);
    asm volatile ("nop"); // TIP bit in SR is set 1cyc after CR write.
    while(mem_rd8(I2C_REG(ch, I2C_SR)) & I2C_SR_TIP);
    *data++ = mem_rd8(I2C_REG(ch, I2C_RXR));
}

//===========================================================
// End of Program
//===========================================================
