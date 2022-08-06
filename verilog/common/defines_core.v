//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : defines_core.v
// Description : Define Common Constants for Core
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2021.02.05 M.Maruyama Divided into for Core and for Chip
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

//-------------------------------------
// RISC-V Core ISA Configuration
//-------------------------------------
`define RISCV_ISA_RV32A // Atomic ISA
`define RISCV_ISA_RV32F // Single Floating Point ISA

//----------------------
// Define JTAG ID Code
//----------------------
// Version=0x1, PartNumber=0x6d6d(mm), ManuId=0
`define JTAG_IDCODE 32'h16d6d001

//------------------
// ID Code
//------------------
`define MVENDORID 32'h00000000 // Vendor
`define MARCHID   32'h6d6d3031 // Architecture mm01
`define MIMPID    32'h00000010 // Version
`define MISA_32   32'h40000000 // XLEN=32
`define MISA_A    32'h00000001 // Atomic
`define MISA_C    32'h00000004 // Compressed
`define MISA_E    32'h00000010 // Embedded
`define MISA_F    32'h00000020 // Single Precision Floating Point
`define MISA_I    32'h00000100 // RV32I Base ISA
`define MISA_M    32'h00001000 // Multiply and Divide
`define MISA_N    32'h00002000 // User Level Interrupt

//---------------------
// CSR
//---------------------
`define CSR_MVENDORID  12'hf11
`define CSR_MARCHID    12'hf12
`define CSR_MIMPID     12'hf13
`define CSR_MHARTID    12'hf14
`define CSR_MSTATUS    12'h300
`define CSR_MISA       12'h301
`define CSR_MIE        12'h304
`define CSR_MTVEC      12'h305
`define CSR_MSCRATCH   12'h340
`define CSR_MEPC       12'h341
`define CSR_MCAUSE     12'h342
`define CSR_MTVAL      12'h343
`define CSR_MIP        12'h344
`define CSR_MCYCLE        12'hb00
`define CSR_MCYCLEH       12'hb80
`define CSR_MINSTRET      12'hb02
`define CSR_MINSTRETH     12'hb82
`define CSR_MCOUNTINHIBIT 12'h320
`define CSR_CYCLE      12'hc00
`define CSR_CYCLEH     12'hc80
`define CSR_TIME       12'hc01
`define CSR_TIMEH      12'hc81
`define CSR_INSTRET    12'hc02
`define CSR_INSTRETH   12'hc82
//
`define CSR_DCSR      12'h7b0
`define CSR_DPC       12'h7b1
`define CSR_DSCRATCH0 12'h7b2 // optional
`define CSR_DSCRATCH1 12'h7b3 // optional
//
`define CSR_TSELECT   12'h7a0
`define CSR_TDATA1    12'h7a1
`define CSR_MCONTROL  12'h7a1
`define CSR_ICOUNT    12'h7a1
`define CSR_ITRIGER   12'h7a1
`define CSR_ETRIGER   12'h7a1
`define CSR_TDATA2    12'h7a2
`define CSR_TDATA3    12'h7a3 // optional
`define CSR_TEXTRA32  12'h7a3 // optional
`define CSR_TEXTRA64  12'h7a3 // optional
`define CSR_TINFO     12'h7a4
`define CSR_TCONTROL  12'h7a5
`define CSR_MCONTEXT  12'h7a8
`define CSR_SCONTEXT  12'h7aa // optional
//
`define CSR_MINTCURLVL 12'hbf0
`define CSR_MINTPRELVL 12'hbf1
`define CSR_MINTCFGENABLE0 12'hbf2
`define CSR_MINTCFGENABLE1 12'hbf3
`define CSR_MINTCFGSENSE0  12'hbf4
`define CSR_MINTCFGSENSE1  12'hbf5
`define CSR_MINTPENDING0   12'hbf6
`define CSR_MINTPENDING1   12'hbf7
`define CSR_MINTCFGPRIORITY0 12'hbf8
`define CSR_MINTCFGPRIORITY1 12'hbf9
`define CSR_MINTCFGPRIORITY2 12'hbfa
`define CSR_MINTCFGPRIORITY3 12'hbfb
`define CSR_MINTCFGPRIORITY4 12'hbfc
`define CSR_MINTCFGPRIORITY5 12'hbfd
`define CSR_MINTCFGPRIORITY6 12'hbfe
`define CSR_MINTCFGPRIORITY7 12'hbff
//
`define CSR_FFLAGS 12'h001
`define CSR_FRM    12'h002
`define CSR_FCSR   12'h003
`define CSR_FPU32CONV  12'hbe0

//---------------------
// Trigger Module
//---------------------
`define TRG_CH_BUS 4 // Channel Counts of Type2 (MCONTROL)
`define TRG_CH_ALL (`TRG_CH_BUS + 1) // Channel Counts of Type2 and Type3 (ICOUNT)
`define TRG_CH_ALL_BIT ($clog2(`TRG_CH_ALL))
`define TRG_CND_I_16_AD_B 32'h00000001
`define TRG_CND_I_16_AD_A 32'h00000002
`define TRG_CND_I_16_DT_B 32'h00000004
`define TRG_CND_I_16_DT_A 32'h00000008
`define TRG_CND_I_32_AD_B 32'h00000010
`define TRG_CND_I_32_AD_A 32'h00000020
`define TRG_CND_I_32_DT_B 32'h00000040
`define TRG_CND_I_32_DT_A 32'h00000080
`define TRG_CND_D_08_AD_R 32'h00000100
`define TRG_CND_D_08_AD_W 32'h00000200
`define TRG_CND_D_08_DT_R 32'h00000400
`define TRG_CND_D_08_DT_W 32'h00000800
`define TRG_CND_D_16_AD_R 32'h00001000
`define TRG_CND_D_16_AD_W 32'h00002000
`define TRG_CND_D_16_DT_R 32'h00004000
`define TRG_CND_D_16_DT_W 32'h00008000
`define TRG_CND_D_32_AD_R 32'h00010000
`define TRG_CND_D_32_AD_W 32'h00020000
`define TRG_CND_D_32_DT_R 32'h00040000
`define TRG_CND_D_32_DT_W 32'h00080000
`define TRG_CND_INSTCOUNT 32'h00100000
`define TRG_CND_INTERRUPT 32'h00200000
`define TRG_CND_EXCEPTION 32'h00400000

//---------------------------------
// Define JTAG DTM TAP Registers
//---------------------------------
`define JTAG_IR_BYPASS    5'h00
`define JTAG_IR_IDCODE    5'h01
`define JTAG_IR_DTMCS     5'h10
`define JTAG_IR_DMI       5'h11
`define JTAG_IR_BYPASS_1F 5'h1f

//-------------------------
// Define JTAG TAP State
//-------------------------
`define JTAG_TAP_TEST_LOGIC_RESET 4'b0000
`define JTAG_TAP_RUN_TEST_IDLE    4'b1000
`define JTAG_TAP_SELECT_DR_SCAN   4'b0001
`define JTAG_TAP_CAPTURE_DR       4'b0010
`define JTAG_TAP_SHIFT_DR         4'b0011
`define JTAG_TAP_EXIT1_DR         4'b0100
`define JTAG_TAP_PAUSE_DR         4'b0101
`define JTAG_TAP_EXIT2_DR         4'b0110
`define JTAG_TAP_UPDATE_DR        4'b0111
`define JTAG_TAP_SELECT_IR_SCAN   4'b1001
`define JTAG_TAP_CAPTURE_IR       4'b1010
`define JTAG_TAP_SHIFT_IR         4'b1011
`define JTAG_TAP_EXIT1_IR         4'b1100
`define JTAG_TAP_PAUSE_IR         4'b1101
`define JTAG_TAP_EXIT2_IR         4'b1110
`define JTAG_TAP_UPDATE_IR        4'b1111

//------------------------
// Define Verbose Switch
//------------------------
`define VERBOSE_OFF 0
`define VERBOSE_ON  1

//-----------------------------
// Define DMI Command & Status
//-----------------------------
`define DMI_COMMAND_NOP 2'b00
`define DMI_COMMAND_RD  2'b01
`define DMI_COMMAND_WR  2'b10
//
`define DMI_RESPONSE_OK    2'b00
`define DMI_RESPONSE_RSVD  2'b01
`define DMI_RESPONSE_ERROR 2'b10
`define DMI_RESPONSE_BUSY  2'b11
//
`define DMI_STATE_IDLE    2'b00
`define DMI_STATE_BUSY_RD 2'b10
`define DMI_STATE_BUSY_WR 2'b11

//-------------------------------
// Define DM Debug Bus Registers
//-------------------------------
`define DM_DATA_0 7'h04
`define DM_DATA_1 7'h05
`define DM_DATA_2 7'h06 // none
`define DM_DATA_3 7'h07 // none
`define DM_DATA_4 7'h08 // none
`define DM_DATA_5 7'h09 // none
`define DM_DATA_6 7'h0a // none
`define DM_DATA_7 7'h0b // none
`define DM_DATA_8 7'h0c // none
`define DM_DATA_9 7'h0d // none
`define DM_DATA_A 7'h0e // none
`define DM_DATA_B 7'h0f // none
`define DM_CONTROL 7'h10
`define DM_STATUS  7'h11
`define DM_HARTINFO 7'h12
`define DM_HALTSUM1 7'h13
`define DM_HAWINDOWSEL 7'h14
`define DM_HAWINDOW    7'h15
`define DM_ABSTRACTCS  7'h16
`define DM_COMMAND      7'h17
`define DM_ABSTRACTAUTO 7'h18
`define DM_CONFSTRPTR0 7'h19
`define DM_CONFSTRPTR1 7'h1a
`define DM_CONFSTRPTR2 7'h1b
`define DM_CONFSTRPTR3 7'h1c
`define DM_NEXTDM    7'h1d
`define DM_PROGBUF_0 7'h20
`define DM_PROGBUF_1 7'h21
`define DM_PROGBUF_2 7'h22
`define DM_PROGBUF_3 7'h23
`define DM_PROGBUF_4 7'h24
`define DM_PROGBUF_5 7'h25
`define DM_PROGBUF_6 7'h26
`define DM_PROGBUF_7 7'h27
`define DM_PROGBUF_8 7'h28
`define DM_PROGBUF_9 7'h29
`define DM_PROGBUF_A 7'h2a
`define DM_PROGBUF_B 7'h2b
`define DM_PROGBUF_C 7'h2c
`define DM_PROGBUF_D 7'h2d
`define DM_PROGBUF_E 7'h2e
`define DM_PROGBUF_F 7'h2f
`define DM_AUTHDATA 7'h30
`define DM_HALTSUM2 7'h34
`define DM_HALTSUM3 7'h35
`define DM_SBADDRESS_3 7'h37
`define DM_SBCS        7'h38
`define DM_SBADDRESS_0 7'h39
`define DM_SBADDRESS_1 7'h3a
`define DM_SBADDRESS_2 7'h3b
`define DM_SBDATA_0    7'h3c
`define DM_SBDATA_1    7'h3d
`define DM_SBDATA_2    7'h3e
`define DM_SBDATA_3    7'h3f
`define DM_HALTSUM0 7'h40

//-----------------------
// Code Buffer Status
//-----------------------
`define CODE_NON 2'b00
`define CODE_16W 2'b01
`define CODE_32L 2'b10
`define CODE_32H 2'b11

//---------------------------
// Pipeline Control States
//---------------------------
`define STATE_ID_RESET          4'b0000
`define STATE_ID_DECODE         4'b001?
`define STATE_ID_DECODE_NORMAL  4'b0010
`define STATE_ID_DECODE_TARGET  4'b0011
`define STATE_ID_DEBUG_MODE     4'b0100 

//----------------------------
// ALU Input/Output Resource
//----------------------------
`define ALU_CSR 14'h2000 // CSR0000 - CSR4095
`define ALU_GPR 14'h3000 // X00 - X31
`define ALU_FPR 14'h3020 // F00 - F31
`define ALU_IMM 14'h3800 // any immediate data
`define ALU_PC  14'h3801 // current PC
`define ALU_MSK 14'h3820 // Mask Pattern

//----------------------
// ALU Function
//----------------------
// ADDI  ???????_000_00100
// SLTI  ???????_010_00100
// SLTIU ???????_011_00100
// XORI  ???????_100_00100
// ORI   ???????_110_00100
// ANDI  ???????_111_00100
// SLLI  0000000_001_00100
// SRLI  0000000_101_00100
// SRAI  0100000_101_00100
// ADD   0000000_000_01100
// SUB   0100000_000_01100
// SLL   0000000_001_01100
// SLT   0000000_010_01100
// SLTU  0000000_011_01100
// XOR   0000000_100_01100
// SRL   0000000_101_01100
// SRA   0100000_101_01100
// OR    0000000_110_01100
// AND   0000000_111_01100
//        ^      ^^^
`define ALUFUNC_ADD  5'b00000
`define ALUFUNC_SUB  5'b01000
`define ALUFUNC_SLL  5'b00001 // shift left logical
`define ALUFUNC_SLLI 5'b10001 // shift left logical by shamnt
`define ALUFUNC_SLT  5'b00010 // set less than signed
`define ALUFUNC_SLTU 5'b00011 // set less than unsigned
`define ALUFUNC_XOR  5'b00100
`define ALUFUNC_SRL  5'b00101 // shift right logical
`define ALUFUNC_SRLI 5'b10101 // shift right logical by shamnt
`define ALUFUNC_SRA  5'b01101 // shift right arithmetic
`define ALUFUNC_SRAI 5'b11101 // shift right arithmetic by shamnt
`define ALUFUNC_OR   5'b00110
`define ALUFUNC_AND  5'b00111
`define ALUFUNC_SWAP 5'b11001 // Swap for CSRRW/CSRRWI
`define ALUFUNC_SWPS 5'b11010 // Swap and Bit Set for CSRRS/CSRRSI
`define ALUFUNC_SWPC 5'b11011 // Swap and Bit Clr for CSRRC/CSRRCI
`define ALUFUNC_MINS 5'b01001 // Minimum Signed
`define ALUFUNC_MAXS 5'b01010 // Maximum Signed
`define ALUFUNC_MINU 5'b01011 // Minimum Unsigned
`define ALUFUNC_MAXU 5'b01100 // Maximum Unsigned 
`define ALUFUNC_BUSX 5'b01110 // aluout = busX
`define ALUFUNC_BUSY 5'b01111 // aluout = busY
//                   5'b10000
//                   5'b10010
//                   5'b10011
//                   5'b10100
//                   5'b10110
//                   5'b10111
//                   5'b11000
//                   5'b11100
//                   5'b11110
//                   5'b11111

//--------------------------
// Comparator Function
//--------------------------
// BEQ  000_1100011
// BNE  001_1100011
// BLT  100_1100011
// BGE  101_1100011
// BLTU 110_1100011
// BGEU 111_1100011
`define CMPFUNC_EQ  3'b000
`define CMPFUNC_NE  3'b001
`define CMPFUNC_LT  3'b100
`define CMPFUNC_GE  3'b101
`define CMPFUNC_LTU 3'b110
`define CMPFUNC_GEU 3'b111

//--------------------------
// Multiplier Function
//--------------------------
`define MULFUNC_NOP    3'b000
`define MULFUNC_MUL    3'b100
`define MULFUNC_MULH   3'b101
`define MULFUNC_MULHSU 3'b110
`define MULFUNC_MULHU  3'b111

//--------------------------
// Divider Function
//--------------------------
`define DIVFUNC_NOP  3'b000
`define DIVFUNC_DIVS 3'b100
`define DIVFUNC_DIVU 3'b101
`define DIVFUNC_REMS 3'b110
`define DIVFUNC_REMU 3'b111

//--------------------------
// Memory Stage Command
//--------------------------
`define MACMD_NOP 5'b00000
`define MACMD_LB  5'b10000
`define MACMD_LH  5'b10001
`define MACMD_LW  5'b10010
`define MACMD_LBU 5'b10100
`define MACMD_LHU 5'b10101
`define MACMD_SB  5'b11000
`define MACMD_SH  5'b11001
`define MACMD_SW  5'b11010

//-----------------------
// Exception Cause Code
//-----------------------
`define MCAUSE_INTERRUPT_MEI        32'h8000000b        
`define MCAUSE_INTERRUPT_MSI        32'h80000003        
`define MCAUSE_INTERRUPT_MTI        32'h80000007        
`define MCAUSE_INTERRUPT_IRQ_BASE   32'h80000010
`define MCAUSE_INSTR_ADDR_MISALIGN  32'h00000000
`define MCAUSE_INSTR_ACCESS_FAULT   32'h00000001
`define MCAUSE_ILLEGAL_INSTRUCTION  32'h00000002
`define MCAUSE_BREAK_POINT          32'h00000003
`define MCAUSE_LD_ADDR_MISALIGN     32'h00000004
`define MCAUSE_LD_ACCESS_FAULT      32'h00000005
`define MCAUSE_ST_AMO_ADDR_MISALIGN 32'h00000006
`define MCAUSE_ST_AMO_ACCESS_FAULT  32'h00000007
`define MCAUSE_ENVIRONMENT_CALL     32'h0000000b

//------------------------
// Debug Mode Cause
//------------------------
`define DBG_CAUSE_BREAKPOINT 3'b010 // Priority 4
`define DBG_CAUSE_EBRREK     3'b001 // Priority 3
`define DBG_CAUSE_RESETHALT  3'b101 // Priority 2
`define DBG_CAUSE_HALTREQ    3'b011 // Priority 1
`define DBG_CAUSE_STEPREQ    3'b100 // Priority 0

//----------------------------------
// FPU32 Rounding Modes
//----------------------------------
`define FPU32_RMODE_RNE 3'b000 // Round to Nearest, ties to Even
`define FPU32_RMODE_RTZ 3'b001 // Round towards Zero
`define FPU32_RMODE_RDN 3'b010 // Round Down (towards -infinite)
`define FPU32_RMODE_RUP 3'b011 // Round Up   (towards +infinite)
`define FPU32_RMODE_RMM 3'b100 // Round to Nearest, ties to Max Magitude    
`define FPU32_RMODE_DYN 3'b111 // Dynamic Rounding Mode    

//----------------------------------
// FPU32 Accured Exception Flags
//----------------------------------
`define FPU32_FLAG_OK 5'b00000 //FLAG_OK
`define FPU32_FLAG_NX 5'b00001 //Inexact (rounding happened)
`define FPU32_FLAG_UF 5'b00010 //Underflow
`define FPU32_FLAG_OF 5'b00100 //Overflow
`define FPU32_FLAG_DZ 5'b01000 //Divide by Zero
`define FPU32_FLAG_NV 5'b10000 //Invalid Operation

//----------------------------------
// FPU32 Floating Number Type
//----------------------------------
`define FPU32_FT_POSZRO 4'b0100 // Positive Zero
`define FPU32_FT_POSNOR 4'b0110 // Positive Normal
`define FPU32_FT_POSSUB 4'b0101 // Positive Subnormal
`define FPU32_FT_POSQNA 4'b1001 // Positive Quiet NaN (Canonical NaN)
`define FPU32_FT_POSSNA 4'b1000 // Positive Signal Nan
`define FPU32_FT_POSINF 4'b0111 // Positive Infinite
//
`define FPU32_FT_NEGZRO 4'b0011 // Negative Zero
`define FPU32_FT_NEGNOR 4'b0001 // Negative Normal
`define FPU32_FT_NEGSUB 4'b0010 // Negative Subnormal
`define FPU32_FT_NEGQNA 4'b1011 // Negative Quiet NaN
`define FPU32_FT_NEGSNA 4'b1010 // Negative Signal Nan
`define FPU32_FT_NEGINF 4'b0000 // Negative Infinite
//
`define FPU32_FT_ERROR  4'b1111 // Unknown

//-------------------------------
// FPU32 Stage Control Command
//-------------------------------
`define FPU32_CMD_NOP     8'b00000000
`define FPU32_CMD_FMADD   8'b11111000
`define FPU32_CMD_FMSUB   8'b11111001
`define FPU32_CMD_FNMSUB  8'b11111010
`define FPU32_CMD_FNMADD  8'b11111011
`define FPU32_CMD_FADD    8'b00000100
`define FPU32_CMD_FSUB    8'b00001100
`define FPU32_CMD_FMUL    8'b00010100
`define FPU32_CMD_FDIV    8'b00011100
`define FPU32_CMD_FSQRT   8'b01011100
`define FPU32_CMD_FMVXW   8'b11100000
`define FPU32_CMD_FMVWX   8'b11110000
`define FPU32_CMD_FLW     8'b01000001
`define FPU32_CMD_FSW     8'b01001001
`define FPU32_CMD_FMIN    8'b00101000
`define FPU32_CMD_FMAX    8'b00101001
`define FPU32_CMD_FCVTWS  8'b11000000
`define FPU32_CMD_FCVTWUS 8'b11000001
`define FPU32_CMD_FCVTSW  8'b11010000
`define FPU32_CMD_FCVTSWU 8'b11010001
`define FPU32_CMD_FSGNJS  8'b00100000
`define FPU32_CMD_FSGNJNS 8'b00100001
`define FPU32_CMD_FSGNJXS 8'b00100010
`define FPU32_CMD_FEQ     8'b10100010
`define FPU32_CMD_FLT     8'b10100001
`define FPU32_CMD_FLE     8'b10100000
`define FPU32_CMD_FCLASS  8'b11100001

//-------------------------------------
// FPU32 FDIV/FSQRT Convergence Loop
//-------------------------------------
`define FPU32_DIV_LOOP_INIT 4'b0100
`define FPU32_SQR_LOOP_INIT 4'b0100

//===========================================================
// End of File
//===========================================================
