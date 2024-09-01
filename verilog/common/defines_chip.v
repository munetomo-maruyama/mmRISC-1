//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : defines_chipv
// Description : Define Common Constants for Chip
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2021.02.05 M.Maruyama Divided into for Core and for Chip
// Rev.04 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
// Rev.05 2024.07.27 M.Maruyama Changed selection method for JTAG/cJTAG
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================

//------------------------------
// JTAG or CJTAG
//------------------------------
// Selection from JTAG or cJTAG is now determined by an external signal level. 
// So a macro "ENABLE_CJTAG" is not used any more.
`define USE_FORCE_HALT_ON_RESET // If you use input signal FORCE_HALT_ON_RESET

//-------------------------------------
// Configuration only for Simulation
//-------------------------------------
//`define MULTI_HART
//`define RAM_WAIT

//--------------------------
// Simulation COnfiguration
//--------------------------
`ifdef RISCV_ARCH_TEST
    `ifdef BUS_INTERVENTION_01
        `define HART_COUNT 1 // maximum 2^20
    `endif
    `ifdef BUS_INTERVENTION_02
        `define HART_COUNT 4 // maximum 2^20
    `endif
    `ifdef BUS_INTERVENTION_03
        `define HART_COUNT 1 // maximum 2^20
        `define HAVE_RAM_WAIT // Insert RAM Wait
    `endif
    `ifdef BUS_INTERVENTION_04
        `define HART_COUNT 4 // maximum 2^20
        `define HAVE_RAM_WAIT // Insert RAM Wait
    `endif
`elsif RISCV_TESTS
    `ifdef BUS_INTERVENTION_01
        `define HART_COUNT 1 // maximum 2^20
    `endif
    `ifdef BUS_INTERVENTION_02
        `define HART_COUNT 2 // maximum 2^20
    `endif
    `ifdef BUS_INTERVENTION_03
        `define HART_COUNT 1 // maximum 2^20
        `define HAVE_RAM_WAIT // Insert RAM Wait
    `endif
    `ifdef BUS_INTERVENTION_04
        `define HART_COUNT 2 // maximum 2^20
        `define HAVE_RAM_WAIT // Insert RAM Wait
    `endif
`elsif SIMULATION
    `ifdef MULTI_HART
        `define HART_COUNT 4 // maximum 2^20
    `else
        `define HART_COUNT 1 // maximum 2^20
    `endif
    `ifdef RAM_WAIT
        `define HAVE_RAM_WAIT // Insert RAM Wait
    `endif
`else // Logic Synthesis
    `define HART_COUNT 1 // maximum 2^20
`endif

//---------------------
// cJTAG
//---------------------
//`define ENABLE_CJTAG // Comment out if cJTAG is not used

//---------------------
// RAM Size
//---------------------
`ifdef SIMULATION
    `define RAMD_SIZE (16*1024*1024)
    `define RAMI_SIZE (16*1024*1024)
`else
    `define RAMD_SIZE ( 48*1024) // RAM
    `define RAMI_SIZE (128*1024) // ROM
`endif

//----------------------
// Bus Configuration
//----------------------
`define MASTERS (`HART_COUNT * 2 + 1)
`define MASTERS_BIT $clog2(`MASTERS)
//
//`define M_PRIORITY_0 1 // CPUD
//`define M_PRIORITY_1 1 // CPUD
//`define M_PRIORITY_2 1 // CPUD
//`define M_PRIORITY_3 1 // CPUD
//`define M_PRIORITY_4 2 // CPUI
//`define M_PRIORITY_5 2 // CPUI
//`define M_PRIORITY_6 2 // CPUI
//`define M_PRIORITY_7 2 // CPUI
//`define M_PRIORITY_8 0 // DBGD
//
`define SLAVES 10
`define SLAVE_MTIME   0
`define SLAVE_SDRAM   1
`define SLAVE_RAMD    2
`define SLAVE_RAMI    3
`define SLAVE_GPIO    4
`define SLAVE_UART    5
`define SLAVE_INTGEN  6
`define SLAVE_I2C0    7
`define SLAVE_I2C1    8
`define SLAVE_SPI     9

//-----------------------
// Slave Address
//-----------------------
// MTIME  : 0x49000000-0x4900001f
// SDRAM  : 0x80000000-0x87ffffff
// RAMD   : 0x88000000-0x8fffffff
// RAMI   : 0x90000000-0x9fffffff
// GPIO   : 0xA0000000-0xafffffff
// UART   : 0xB0000000-0xbfffffff
// INTGEN : 0xC0000000-0xcfffffff
// I2C0   : 0xd0000000-0xd00000ff
// I2C1   : 0xd0000100-0xd00001ff
// SPI    : 0xe0000000-0xe00000ff
//
`define SLAVE_BASE_MTIME  32'h49000000
`define SLAVE_BASE_SDRAM  32'h80000000
`define SLAVE_BASE_RAMD   32'h88000000
`define SLAVE_BASE_RAMI   32'h90000000
`define SLAVE_BASE_GPIO   32'ha0000000
`define SLAVE_BASE_UART   32'hb0000000
`define SLAVE_BASE_INTGEN 32'hc0000000
`define SLAVE_BASE_I2C0   32'hd0000000
`define SLAVE_BASE_I2C1   32'hd0000100
`define SLAVE_BASE_SPI    32'he0000000
//
`define SLAVE_MASK_MTIME  32'hffffffe0
`define SLAVE_MASK_SDRAM  32'hf8000000
`define SLAVE_MASK_RAMD   32'hf8000000
`define SLAVE_MASK_RAMI   32'hf0000000
`define SLAVE_MASK_GPIO   32'hf0000000
`define SLAVE_MASK_UART   32'hf0000000
`define SLAVE_MASK_INTGEN 32'hf0000000
`define SLAVE_MASK_I2C0   32'hffffff00
`define SLAVE_MASK_I2C1   32'hffffff00
`define SLAVE_MASK_SPI    32'hffffff00

//-----------------------------
// mmRISC Reset Vectors
//-----------------------------
`define RESET_VECTOR_BASE 32'h90000000
`define RESET_VECTOR_DISP 32'h01000000

//-----------------------------
// Debug Security
//-----------------------------
//`define DEBUG_SECURE_ENBL  1'b0         // Set 1 if Enable Debug Authentification
`define DEBUG_SECURE_CODE_0 32'h12345678 // Debug Authentification Code 0
`define DEBUG_SECURE_CODE_1 32'hbeefcafe // Debug Authentification Code 1

//===========================================================
// End of File
//===========================================================
