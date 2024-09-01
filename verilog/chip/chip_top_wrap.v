//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : chip_top_wrap.v
// Description : Chip Top Wrapper
//-----------------------------------------------------------
// History :
// Rev.01 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
// Rev.02 2024.07.27 M.Maruyama Changed selection method for JTAG/cJTAG
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================
//
// < FPGA Board Terasic DE10-Lite>
//
// TCKC_pri     W13  GPIO_13   Loopback to   TCKC_rep
// TCKC_rep     AB13 GPIO_15   Loopback from TCKC_pri
// TMSC_pri     AA14 GPIO_12   Loopback to   TMSC_rep
// TMSC_rep     W12  GPIO_14   Loopback from TMSC_pri
// TMSC_PUP_rep Y11  GPIO_17   Pull Up TMSC_rep (12mA Drive)
// TMSC_PDN_rep AB12 GPIO_16   Pull Dn TMSC_rep (12mA Drive)
//
// RES_N     B8  KEY0
// CLK50     P11
//
// RESOUT_N  F16 RESET Output (negative)
//
// TRSTn     Y5  GPIO_29
// TCK       Y6  GPIO_27
// TMS       AA2 GPIO_35
// TDI       Y4  GPIO_31
// TDO       Y3  GPIO_33
//
// TXD       W10 GPIO_1
// RXD       W9  GPIO_3
//
// I2C0_SCL  AB15  GSENSOR SCL
// I2C0_SDA  V11   GSENSOR SDA
// I2C0_ENA  AB16  GSENSOR CSn (Fixed to 1)
// I2C0_ADR  V12   GSENSOR ALTADDR (Fixed to 0)
// I2C0_INT1 Y14   GSENSOR INT1
// I2C0_INT2 Y13   GSENSOR INT2
//
// I2C1_SCL   AA20  Arduino IO15 CT_SCL (Capacitive Touch Controller)
// I2C1_SDA   AB21  Arduino IO14 CT_SDA (Capacitive Touch Controller)
// 
// SPI_CSN[3] AB9   Arduino IO04 CARD_CS (SD Card)
// SPI_CSN[2] AB17  Arduino IO08 RT_CS   (Resistive Touch Controller)
// SPI_CSN[1] AA17  Arduino IO09 TFT_DC  (LCD Controller)
// SPI_CSN[0] AB19  Arduino IO10 TFT_CS  (LCD Controller)
// SPI_MOSI   AA19  Arduino IO11
// SPI_MISO   Y19   Arduino IO12
// SPI_SCK    AB20  Arduino IO13
//
// SDRAM_CLK      L14
// SDRAM_CKE      N22
// SDRAM_CSn      U20
// SDRAM_DQM [ 0] V22
// SDRAM_DQM [ 1] J21
// SDRAM_RASn     U22
// SDRAM_CASn     U21
// SDRAM_WEn      V20
// SDRAM_BA  [ 0] T21
// SDRAM_BA  [ 1] T22
// SDRAM_ADDR[ 0] U17
// SDRAM_ADDR[ 1] W19 
// SDRAM_ADDR[ 2] V18
// SDRAM_ADDR[ 3] U18
// SDRAM_ADDR[ 4] U19
// SDRAM_ADDR[ 5] T18
// SDRAM_ADDR[ 6] T19
// SDRAM_ADDR[ 7] R18
// SDRAM_ADDR[ 8] P18
// SDRAM_ADDR[ 9] P19
// SDRAM_ADDR[10] T20
// SDRAM_ADDR[11] P20
// SDRAM_ADDR[12] R20
// SDRAM_DQ  [ 0] Y21
// SDRAM_DQ  [ 1] Y20
// SDRAM_DQ  [ 2] AA22
// SDRAM_DQ  [ 3] AA21
// SDRAM_DQ  [ 4] Y22
// SDRAM_DQ  [ 5] W22
// SDRAM_DQ  [ 6] W20
// SDRAM_DQ  [ 7] V21
// SDRAM_DQ  [ 8] P21
// SDRAM_DQ  [ 9] J22
// SDRAM_DQ  [10] H21
// SDRAM_DQ  [11] H22
// SDRAM_DQ  [12] G22
// SDRAM_DQ  [13] G20
// SDRAM_DQ  [14] G19
// SDRAM_DQ  [15] F22
//
// GPIO0[ 0] C14 HEX00 segA
// GPIO0[ 1] E15 HEX01 segB
// GPIO0[ 2] C15 HEX02 segC
// GPIO0[ 3] C16 HEX03 segD
// GPIO0[ 4] E16 HEX04 segE
// GPIO0[ 5] D17 HEX05 segF
// GPIO0[ 6] C17 HEX06 segG
// GPIO0[ 7] D15 HEX07 segDP
// GPIO0[ 8] C18 HEX10 segA
// GPIO0[ 9] D18 HEX11 segB
// GPIO0[10] E18 HEX12 segC
// GPIO0[11] B16 HEX13 segD
// GPIO0[12] A17 HEX14 segE
// GPIO0[13] A18 HEX15 segF
// GPIO0[14] B17 HEX16 segG
// GPIO0[15] A16 HEX17 segDP
// GPIO0[16] B20 HEX20 segA
// GPIO0[17] A20 HEX21 segB
// GPIO0[18] B19 HEX22 segC
// GPIO0[19] A21 HEX23 segD
// GPIO0[20] B21 HEX24 segE
// GPIO0[21] C22 HEX25 segF
// GPIO0[22] B22 HEX26 segG
// GPIO0[23] A19 HEX27 segDP
// GPIO0[24] F21 HEX30 segA
// GPIO0[25] E22 HEX31 segB
// GPIO0[26] E21 HEX32 segC
// GPIO0[27] C19 HEX33 segD
// GPIO0[28] C20 HEX34 segE
// GPIO0[29] D19 HEX35 segF
// GPIO0[30] E17 HEX36 segG
// GPIO0[31] D22 HEX37 segDP
//
// GPIO1[ 0] F18 HEX40 segA
// GPIO1[ 1] E20 HEX41 segB
// GPIO1[ 2] E19 HEX42 segC
// GPIO1[ 3] J18 HEX43 segD
// GPIO1[ 4] H19 HEX44 segE
// GPIO1[ 5] F19 HEX45 segF
// GPIO1[ 6] F20 HEX46 segG
// GPIO1[ 7] F17 HEX47 segDP
// GPIO1[ 8] J20 HEX50 segA
// GPIO1[ 9] K20 HEX51 segB
// GPIO1[10] L18 HEX52 segC
// GPIO1[11] N18 HEX53 segD
// GPIO1[12] M20 HEX54 segE
// GPIO1[13] N19 HEX55 segF
// GPIO1[14] N20 HEX56 segG
// GPIO1[15] Y2  VGA_R2
// GPIO1[16] A8  LEDR0
// GPIO1[17] A9  LEDR1
// GPIO1[18] A10 LEDR2
// GPIO1[19] B10 LEDR3
// GPIO1[20] D13 LEDR4
// GPIO1[21] C13 LEDR5
// GPIO1[22] E14 LEDR6
// GPIO1[23] D14 LEDR7
// GPIO1[24] A11 LEDR8
// GPIO1[25] B11 LEDR9
// GPIO1[26] V10 GPIO_0
// GPIO1[27] V9  GPIO_2
// GPIO1[28] V8  GPIO_4
// GPIO1[29] W8  GPIO_5
// GPIO1[30] V7  GPIO_6
// GPIO1[31] W7  GPIO_7
//
// GPIO2[ 0] C10  SW0
// GPIO2[ 1] C11  SW1
// GPIO2[ 2] D12  SW2
// GPIO2[ 3] C12  SW3
// GPIO2[ 4] A12  SW4
// GPIO2[ 5] B12  SW5
// GPIO2[ 6] A13  SW6  (ENABLE_CJTAG)
// GPIO2[ 7] A14  SW7  (Slow Clock)
// GPIO2[ 8] B14  SW8  (STBY_REQ)
// GPIO2[ 9] F15  SW9  (DEBUG_SECURE)
// GPIO2[10] A7   KEY1 (RESET_HALT_N)
// GPIO2[11] W6   GPIO_8
// GPIO2[12] V5   GPIO_9
// GPIO2[13] W5   GPIO_10
// GPIO2[14] AA15 GPIO_11
// GPIO2[15] AB11 GPIO_18
// GPIO2[16] W11  GPIO_19
// GPIO2[17] AB10 GPIO_20
// GPIO2[18] AA10 GPIO_21
// GPIO2[19] AA9  GPIO_22
// GPIO2[20] Y8   GPIO_23
// GPIO2[21] AA8  GPIO_24
// GPIO2[22] Y7   GPIO_25
// GPIO2[23] AA7  GPIO_26
// GPIO2[24] AA6  GPIO_28
// GPIO2[25] AA5  GPIO_30
// GPIO2[26] AB3  GPIO32
// GPIO2[27] AB2  GPIO34
// GPIO2[28] N1   VGA_VS
// GPIO2[29] N3   VGA_HS
// GPIO2[30] AA1  VGA_R0
// GPIO2[31] V1   VGA_R1
//
// STBY_ACK_N L19 HEX57 segDP

`include "defines_chip.v"
`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CHIP_TOP_WRAP
(
    input  wire RES_N, // Reset Input (Negative)
    input  wire CLK50, // Clock Input (50MHz)
    //
  //input  wire STBY_REQ,   // Stand-by Request --> GPIO2[8]
    output wire STBY_ACK_N, // Stand=by Acknowledge (negative)
    //
    output wire RESOUT_N, // Reset Output (negative) 
    //
`ifdef SIMULATION
    inout  wire SRSTn, // System Reset In/Out
    output wire RTCK,  // JTAG Return Clock
`endif
    //
    input  wire TRSTn, // JTAG TAP Reset
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output wire TDO,   // JTAG Data Output (3-state)
    //
    output wire TCKC_pri, // cJTAG TCKC Loop Primary
    input  wire TCKC_rep, // cJTAG TCKC Loop Replica
    inout  wire TMSC_pri, // cJTAG TMSC Loop Primary
    inout  wire TMSC_rep, // cJTAG TMSC Loop Replica
    //
    output wire TMSC_PUP_rep, // cJTAG TMSC should be PullUp when 1
    output wire TMSC_PDN_rep, // cJTAG TMSC should be PullDn when 0
    //
    inout  wire [31:0] GPIO0, // GPIO0 Port (should be pulled-up)
    inout  wire [31:0] GPIO1, // GPIO1 Port (should be pulled-up)
    inout  wire [31:0] GPIO2, // GPIO2 Port (should be pulled-up)
    //
    input  wire RXD, // UART receive data
    output wire TXD, // UART transmit data
    //
    inout  wire I2C0_SCL,  // I2C0 SCL
    inout  wire I2C0_SDA,  // I2C0 SDA
    output wire I2C0_ENA,  // I2C0 Enable (Fixed to 1)
    output wire I2C0_ADR,  // I2C0 ALTADDR (Fixed to 0)
    input  wire I2C0_INT1, // I2C0 Device Interrupt Request 1
    input  wire I2C0_INT2, // I2C0 Device Interrupt Request 2
    //
    inout  wire I2C1_SCL,  // I2C1 SCL
    inout  wire I2C1_SDA,  // I2C1 SDA
    //
    output wire [ 3:0] SPI_CSN,  // SPI Chip Select
    output wire        SPI_SCK,  // SPI Clock
    output wire        SPI_MOSI, // SPI MOSI
    input  wire        SPI_MISO, // SPI MISO
    //
    output wire        SDRAM_CLK,  // SDRAM Clock
    output wire        SDRAM_CKE,  // SDRAM Clock Enable
    output wire        SDRAM_CSn,  // SDRAM Chip Select
    output wire [ 1:0] SDRAM_DQM,  // SDRAM Byte Data Mask
    output wire        SDRAM_RASn, // SDRAM Row Address Strobe
    output wire        SDRAM_CASn, // SDRAM Column Address Strobe
    output wire        SDRAM_WEn,  // SDRAM Write Enable
    output wire [ 1:0] SDRAM_BA,   // SDRAM Bank Address
    output wire [12:0] SDRAM_ADDR, // SDRAM Addess
    inout  wire [15:0] SDRAM_DQ    // SDRAM Data
);

//-------------------
// STBY Request
//-------------------
wire stby_req;
assign stby_req = GPIO2[8];

//--------------------------------
// Enable or Disable RESET_HALT 
//--------------------------------
wire reset_halt_n;
//
`ifdef USE_FORCE_HALT_ON_RESET
    assign reset_halt_n = GPIO2[10]; // KEY1
`else
    assign reset_halt_n = 1'b1;
`endif

//----------------------------------------
// Selection whether using JTAG or cJTAG
//----------------------------------------
wire enable_cjtag;
assign enable_cjtag = GPIO2[6]; 

//---------------------------------------------
// Adapter to convert JTAG to cJTAG
//---------------------------------------------
wire tdo_d_jtag , tdo_e_jtag;
wire tdo_d_cjtag, tdo_e_cjtag;
wire tckc_o, tmsc_i, tmsc_o, tmsc_e;
wire tmsc_pup, tmsc_pdn;
//
CJTAG_ADAPTER U_CJTAG_ADAPTER
(
    .RESET_HALT_N (reset_halt_n),
    //
    .TCK    (TCK),
    .TMS    (TMS),
    .TDI    (TDI),
    .TDO_D  (tdo_d_cjtag),
    .TDO_E  (tdo_e_cjtag),
    //
    .TCKC   (tckc_o),
    .TMSC_I (tmsc_i),
    .TMSC_O (tmsc_o),
    .TMSC_E (tmsc_e)
);
//
assign TDO = (enable_cjtag)? ((tdo_e_cjtag)? tdo_d_cjtag : 1'bz)
                           : ((tdo_e_jtag )? tdo_d_jtag  : 1'bz);
//
assign TCKC_pri = tckc_o;
assign TMSC_pri = (tmsc_e)? tmsc_o : 1'bz;
assign tmsc_i   = TMSC_pri;
//
// Keeper Control
assign TMSC_PUP_rep = (tmsc_pup)? 1'b1 : 1'bz;
assign TMSC_PDN_rep = (tmsc_pdn)? 1'b0 : 1'bz;

//------------------------
// Chip Top
//------------------------
CHIP_TOP U_CHIP_TOP
(
    .RES_N    (RES_N), // Reset Input (Negative)
    .CLK50    (CLK50), // Clock Input (50MHz)
    //
    .STBY_REQ   (stby_req),   // Stand-by Request
    .STBY_ACK_N (STBY_ACK_N), // Stand=by Acknowledge (negative)
    //
    .RESOUT_N (RESOUT_N), // Reset Output (negative) 
    //
    .RESET_HALT_N (reset_halt_n), // Request of RESET_HALT
    .ENABLE_CJTAG (enable_cjtag), // Selection whether using JTAG or cJTAG
    //
    .TCKC     (TCKC_rep), // cJTAG Clock
    .TMSC     (TMSC_rep), // cJTAG TMS/TDI/TDO
    .TMSC_PUP (tmsc_pup), // cJTAG TMSC should be Pull Up when 1
    .TMSC_PDN (tmsc_pdn), // cJTAG TMSC should be Pull Dn when 1
    //
    .TRSTn (TRSTn), // JTAG TAP Reset
    .TCK   (TCK),   // JTAG Clock
    .TMS   (TMS),   // JTAG Mode Select
    .TDI   (TDI),   // JTAG Data Input
    .TDO   (),      // JTAG Data Output (3-state)
    .TDO_D (tdo_d_jtag), // JTAG Data Output Level
    .TDO_E (tdo_e_jtag), // JTAG Data Output Enable
    //
`ifdef SIMULATION
    .SRSTn (SRSTn), // System Reset In/Out
    .RTCK  (RTCK),  // JTAG Return Clock
`endif
    //
    .GPIO0 (GPIO0), // GPIO0 Port (should be pulled-up)
    .GPIO1 (GPIO1), // GPIO1 Port (should be pulled-up)
    .GPIO2 (GPIO2), // GPIO2 Port (should be pulled-up)
    //
    .RXD (RXD), // UART receive data
    .TXD (TXD), // UART transmit data
    //
    .I2C0_SCL  (I2C0_SCL),  // I2C0 SCL
    .I2C0_SDA  (I2C0_SDA),  // I2C0 SDA
    .I2C0_ENA  (I2C0_ENA),  // I2C0 Enable (Fixed to 1)
    .I2C0_ADR  (I2C0_ADR),  // I2C0 ALTADDR (Fixed to 0)
    .I2C0_INT1 (I2C0_INT1), // I2C0 Device Interrupt Request 1
    .I2C0_INT2 (I2C0_INT2), // I2C0 Device Interrupt Request 2
    //
    .I2C1_SCL  (I2C1_SCL),  // I2C1 SCL
    .I2C1_SDA  (I2C1_SDA),  // I2C1 SDA
    //
    .SPI_CSN   (SPI_CSN),  // SPI Chip Select
    .SPI_SCK   (SPI_SCK),  // SPI Clock
    .SPI_MOSI  (SPI_MOSI), // SPI MOSI
    .SPI_MISO  (SPI_MISO), // SPI MISO
    //
    .SDRAM_CLK  (SDRAM_CLK),  // SDRAM Clock
    .SDRAM_CKE  (SDRAM_CKE),  // SDRAM Clock Enable
    .SDRAM_CSn  (SDRAM_CSn),  // SDRAM Chip Select
    .SDRAM_DQM  (SDRAM_DQM),  // SDRAM Byte Data Mask
    .SDRAM_RASn (SDRAM_RASn), // SDRAM Row Address Strobe
    .SDRAM_CASn (SDRAM_CASn), // SDRAM Column Address Strobe
    .SDRAM_WEn  (SDRAM_WEn),  // SDRAM Write Enable
    .SDRAM_BA   (SDRAM_BA),   // SDRAM Bank Address
    .SDRAM_ADDR (SDRAM_ADDR), // SDRAM Addess
    .SDRAM_DQ   (SDRAM_DQ)    // SDRAM Data
);

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
