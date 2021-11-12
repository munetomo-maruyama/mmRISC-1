//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : common.h
// Description : Common Header
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#ifndef COMMON_H_
#define COMMON_H_

#include <stdint.h>
#include <stdio.h>
#include "xprintf.h"

//----------------------
// Configuration
//----------------------
#define FPGA
//#define MODELSIM

//----------------------
// printf()
//----------------------
#define printf xprintf

//---------------------------
// Low Level Access Routine
//---------------------------
static inline void mem_wr32(uint32_t addr, uint32_t data)
{
    *(volatile uint32_t *)(addr) = data;
}
static inline void mem_wr16(uint32_t addr, uint16_t data)
{
    *(volatile uint16_t *)(addr) = data;
}
static inline void mem_wr8(uint32_t addr, uint8_t data)
{
    *(volatile uint8_t *)(addr) = data;
}
//
static inline uint32_t mem_rd32(uint32_t addr)
{
    return *(volatile uint32_t *)(addr);
}
static inline uint16_t mem_rd16(uint32_t addr)
{
    return *(volatile uint16_t *)(addr);
}
static inline uint8_t mem_rd8(uint32_t addr)
{
    return *(volatile uint8_t *)(addr);
}

#endif /* COMMON_H_ */
//===========================================================
// End of Program
//===========================================================

