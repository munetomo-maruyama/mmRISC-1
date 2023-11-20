//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : chip_top.v
// Description : Top Layer of Chip
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
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
// GPIO1[15] Y1  VGA_R3
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
// GPIO2[ 6] A13  SW6
// GPIO2[ 7] A14  SW7  (Slow Clock)
// GPIO2[ 8] Y2   VGA_R2
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
// STBY_REQ   B14  SW8
// STBY_ACK_N L19 HEX57 segDP

`include "defines_chip.v"
`include "defines_core.v"

`define VERIFY_SLOW_CLOCK

//----------------------
// Define Module
//----------------------
module CHIP_TOP
(
    input  wire RES_N, // Reset Input (Negative)
    input  wire CLK50, // Clock Input (50MHz)
    //
    input  wire STBY_REQ,   // Stand-by Request
    output wire STBY_ACK_N, // Stand=by Acknowledge (negative)
    //
    output wire RESOUT_N, // Reset Output (negative) 
    //
`ifdef SIMULATION
    inout  wire SRSTn, // System Reset In/Out
`endif
    //
`ifdef ENABLE_CJTAG
    input  wire TCKC,     // cJTAG Clock
    inout  wire TMSC,     // cJTAG TMS/TDI/TDO
    output wire TMSC_PUP, // cJTAG TMSC should be Pull Up when 1
    output wire TMSC_PDN, // cJTAG TMSC should be Pull Dn when 1
`else
    input  wire TRSTn, // JTAG TAP Reset
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output wire TDO,   // JTAG Data Output (3-state)
`endif
    //
`ifdef SIMULATION
    output wire RTCK,  // JTAG Return Clock
`endif
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

//------------------------------
// Treatment of SRSTn and RTCK
//------------------------------
`ifdef SIMULATION
wire srst_n_in;
wire srst_n_out;
assign SRSTn = (srst_n_out)? 1'bz : 1'b0;
assign srst_n_in = (SRSTn === 1'bz)? 1'b1 : SRSTn; // if HIZ, then 1
`else
wire srst_n_in;
wire srst_n_out;
wire RTCK;
assign srst_n_in = RES_N;
`endif

//--------------------------
// Internal Power on Reset
//--------------------------
`ifdef SIMULATION
    `define POR_MAX 16'h000f // period of power on reset 
`else  // Real FPGA
    `define POR_MAX 16'hffff // period of power on reset 
`endif
wire res_pll;          // Reset PLL
wire res_org;          // Reset Origin
wire res_sys;          // Reset System
reg  por_n;            // should be power-up level = Low
reg  [15:0] por_count; // should be power-up level = Low
wire locked;
//
always @(posedge CLK50)
begin
    if (por_count != `POR_MAX)
    begin
        por_n <= 1'b0;
        por_count <= por_count + 16'h0001;
    end
    else
    begin
        por_n <= 1'b1;
        por_count <= por_count;
    end
end
//
assign res_pll = (~por_n) | (~RES_N);
assign res_org = res_pll | (~locked);
//
assign RESOUT_N = ~res_sys;

//-----------------
// Clock and PLL
//-----------------
wire clk0;
wire clk1;
wire clk01;
wire clk;
//
`ifdef SIMULATION
reg  clk2;
assign clk01 = CLK50;
initial clk2 = 1'b0;
always #(10us) clk2 = ~clk2;
assign locked = 1'b1;
`else
wire clk2;
wire locked_pll;
reg  locked_reg;
//
PLL U_PLL
(
    .areset  (res_pll),
    .inclk0  (CLK50),
    .c0      (clk0),  // 20.00MHz
    .c1      (clk1),  // 16.66MHz
    .c2      (clk2),  // 100KHz
    .locked  (locked_pll)
);
//
`ifdef RISCV_ISA_RV32F
assign clk01 = clk1; // 16MHz with FPU
`else
assign clk01 = clk0; // 20MHz without FPU
`endif
//
always @(posedge locked_pll, posedge res_pll)
begin
    if (res_pll)
        locked_reg <= 1'b0;
    else
        locked_reg <= 1'b1;
end
//
assign locked = locked_pll & locked_reg;
`endif
//
assign SDRAM_CLK = ~clk;
//
//-------------------------------------------
// To vefify whether there is no relationship
// between fCLK and fTCK(fTCLK) (temporary)..
//-------------------------------------------
wire clkA, clkB, clkOUT;
wire selA, selB;
//
reg  clkA_ena0, clkA_ena1, clkA_ena2;
reg  clkB_ena0, clkB_ena1, clkB_ena2;
wire clkA_qual, clkB_qual;
//
wire clkA_gated, clkB_gated;
//
`ifdef VERIFY_SLOW_CLOCK
//
// Glitchless Clock Selector
//
assign clkA = clk01;
assign clkB = clk2;
//
assign selA = ~GPIO2[7]; // SW7
assign selB =  GPIO2[7]; // SW7
//
assign clkA_qual = selA & ~clkB_ena2;
assign clkB_qual = selB & ~clkA_ena2;
//
`ifdef SIMULATION
initial clkA_ena0 = 1'b0;
initial clkA_ena1 = 1'b0;
initial clkA_ena2 = 1'b0;
initial clkB_ena0 = 1'b0;
initial clkB_ena1 = 1'b0;
initial clkB_ena2 = 1'b0;
`endif
//
always @(posedge clkA)
begin
    clkA_ena0 <= clkA_qual;
    clkA_ena1 <= clkA_ena0;
end
always @(negedge clkA)
begin
    clkA_ena2 <= clkA_ena1;
end
//
always @(posedge clkB)
begin
    clkB_ena0 <= clkB_qual;
    clkB_ena1 <= clkB_ena0;
end
always @(negedge clkB)
begin
    clkB_ena2 <= clkB_ena1;
end
//
assign clkA_gated = clkA & clkA_ena2;
assign clkB_gated = clkB & clkB_ena2;
assign clkOUT = clkA_gated | clkB_gated;
assign clk = clkOUT;
`else
assign clk = clk01;
`endif

//--------------------------------------------
// STBY Control (dummy; it does not stop clk)
//--------------------------------------------
reg  [ 1:0] stby_sync;
reg  [31:0] stby_count;
wire        stby_count_end;
reg         stby_req;
wire        stby_ack;
//
// Synchronization
always @(posedge clk, posedge res_org)
begin
    if (res_org)
        stby_sync <= 2'b00;
    else
    begin
        stby_sync <= {stby_sync[0], STBY_REQ};
    end
end
//
// De-Bounce
always @(posedge clk, posedge res_org)
begin
    if (res_org)
        stby_count <= 32'h00000000;
    else if (stby_count_end)
        stby_count <= 32'h00000000;
    else
        stby_count <= stby_count + 32'h00000001;
end
`ifdef SIMULATION
assign stby_count_end = (stby_count == 32'd10);
`else
assign stby_count_end = (stby_count == 32'd1600000);
`endif
//
always @(posedge clk, posedge res_org)
begin
    if (res_org)
        stby_req <= 1'b0;
    else if (stby_count_end)
        stby_req <= stby_sync[1];
end
//
assign STBY_ACK_N = ~stby_ack;
// [Note] 
// When entering to STBY,  Assert stby_req, and Stop clk after stby_ack is asserted.
// When exiting from STBY, Start clk and Negate stby_req.

//-----------------
// JTAG Signals
//-----------------
wire trstn;
wire tms;
wire tck;
wire tdi;
wire tdo_d;
wire tdo_e;

//-------------------
// JTAG and CJTAG
//-------------------
wire        force_halt_on_reset_req;
wire        force_halt_on_reset_ack;
wire [31:0] jtag_dr_user_in;   // You can put data to JTAG
wire [31:0] jtag_dr_user_out;  // You can get data from JTAG such as Mode Settings
assign jtag_dr_user_in = ~jtag_dr_user_out; // So far, Loop back inverted value

//-------------------
// CJTAG
//-------------------
`ifdef ENABLE_CJTAG
//
wire   tmsc_i, tmsc_o, tmsc_e;
//
assign tmsc_i = TMSC;
assign TMSC   = (tmsc_e)? tmsc_o : 1'bz;
//
CJTAG_2_JTAG U_CJTAG_2_JTAG
(
    .RES    (res_org),
    .CLK    (clk),
    //
    .TCKC   (TCKC),
    .TMSC_I (tmsc_i),
    .TMSC_O (tmsc_o),
    .TMSC_E (tmsc_e),
    .TMSC_PUP (TMSC_PUP), // cJTAG TMSC should be Pull Up when 1
    .TMSC_PDN (TMSC_PDN), // cJTAG TMSC should be Pull Dn when 1
    //
    .TRSTn  (trstn),
    .TCK    (tck),
    .TMS    (tms),
    .TDI    (tdi),
    .TDO    (tdo_d),
    //
    .FORCE_HALT_ON_RESET_REQ (force_halt_on_reset_req),
    .FORCE_HALT_ON_RESET_ACK (force_halt_on_reset_ack),
    //
    .CJTAG_IN_OSCAN1 ()
);

//-----------------
// JTAG
//-----------------
`else
assign trstn = TRSTn;
assign tck   = TCK;
assign tms   = TMS;
assign tdi   = TDI;
assign TDO   = (tdo_e)? tdo_d : 1'bz;
//
`ifdef USE_FORCE_HALT_ON_RESET
reg halt_req;
always @(posedge clk, posedge res_org)
begin
    if (res_org)
        halt_req <= ~GPIO2[10]; // KEY1
    else if (force_halt_on_reset_ack)
        halt_req <= 1'b0;
end
assign force_halt_on_reset_req = halt_req;
`else
assign force_halt_on_reset_req = 1'b0;
`endif
`endif

//---------------
// mmRISC
//---------------
wire [31:0] reset_vector     [0:`HART_COUNT-1]; // Reset Vector
wire        debug_secure;        // Debug Authentication is available or not
wire [31:0] debug_secure_code_0; // Debug Authentication Code 0
wire [31:0] debug_secure_code_1; // Debug Authentication Code 1
//
wire        cpui_m_hsel      [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 1:0] cpui_m_htrans    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hwrite    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hmastlock [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 2:0] cpui_m_hsize     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 2:0] cpui_m_hburst    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 3:0] cpui_m_hprot     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_haddr     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_hwdata    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hready    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hreadyout [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_hrdata    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hresp     [0:`HART_COUNT-1]; // AHB for CPU Instruction
//
wire        cpud_m_hsel      [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 1:0] cpud_m_htrans    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hwrite    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hmastlock [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 2:0] cpud_m_hsize     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 2:0] cpud_m_hburst    [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 3:0] cpud_m_hprot     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_haddr     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_hwdata    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hready    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hreadyout [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_hrdata    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hresp     [0:`HART_COUNT-1]; // AHB for CPU Data
//
`ifdef RISCV_ISA_RV32A
wire        cpum_s_hsel      [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire [ 1:0] cpum_s_htrans    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hwrite    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire [31:0] cpum_s_haddr     [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hready    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hreadyout [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
`endif
//
wire        dbgd_m_hsel     ; // AHB for Debugger System Access
wire [ 1:0] dbgd_m_htrans   ; // AHB for Debugger System Access
wire        dbgd_m_hwrite   ; // AHB for Debugger System Access
wire        dbgd_m_hmastlock; // AHB for Debugger System Access
wire [ 2:0] dbgd_m_hsize    ; // AHB for Debugger System Access
wire [ 2:0] dbgd_m_hburst   ; // AHB for Debugger System Access
wire [ 3:0] dbgd_m_hprot    ; // AHB for Debugger System Access
wire [31:0] dbgd_m_haddr    ; // AHB for Debugger System Access
wire [31:0] dbgd_m_hwdata   ; // AHB for Debugger System Access
wire        dbgd_m_hready   ; // AHB for Debugger System Access
wire        dbgd_m_hreadyout; // AHB for Debugger System Access
wire [31:0] dbgd_m_hrdata   ; // AHB for Debugger System Access
wire        dbgd_m_hresp    ; // AHB for Debugger System Access
//
wire        m_hsel     [0:`MASTERS-1];
wire [ 1:0] m_htrans   [0:`MASTERS-1];
wire        m_hwrite   [0:`MASTERS-1];
wire        m_hmastlock[0:`MASTERS-1];
wire [ 2:0] m_hsize    [0:`MASTERS-1];
wire [ 2:0] m_hburst   [0:`MASTERS-1];
wire [ 3:0] m_hprot    [0:`MASTERS-1];
wire [31:0] m_haddr    [0:`MASTERS-1];
wire [31:0] m_hwdata   [0:`MASTERS-1];
wire        m_hready   [0:`MASTERS-1];
wire        m_hreadyout[0:`MASTERS-1];
wire [31:0] m_hrdata   [0:`MASTERS-1];
wire        m_hresp    [0:`MASTERS-1];
//
wire        s_hsel     [0:`SLAVES-1];
wire [ 1:0] s_htrans   [0:`SLAVES-1];
wire        s_hwrite   [0:`SLAVES-1];
wire        s_hmastlock[0:`SLAVES-1];
wire [ 2:0] s_hsize    [0:`SLAVES-1];
wire [ 2:0] s_hburst   [0:`SLAVES-1];
wire [ 3:0] s_hprot    [0:`SLAVES-1];
wire [31:0] s_haddr    [0:`SLAVES-1];
wire [31:0] s_hwdata   [0:`SLAVES-1];
wire        s_hready   [0:`SLAVES-1];
wire        s_hreadyout[0:`SLAVES-1];
wire [31:0] s_hrdata   [0:`SLAVES-1];
wire        s_hresp    [0:`SLAVES-1];
//
// Bus Signals
generate
begin
    genvar i;
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : AHB_SIGNALS
        assign m_hsel     [i            ] = cpud_m_hsel[i];
        assign m_htrans   [i            ] = cpud_m_htrans[i];
        assign m_hwrite   [i            ] = cpud_m_hwrite[i];
        assign m_hmastlock[i            ] = cpud_m_hmastlock[i];
        assign m_hsize    [i            ] = cpud_m_hsize[i];
        assign m_hburst   [i            ] = cpud_m_hburst[i];
        assign m_hprot    [i            ] = cpud_m_hprot[i];
        assign m_haddr    [i            ] = cpud_m_haddr[i];
        assign m_hwdata   [i            ] = cpud_m_hwdata[i];
        assign m_hready   [i            ] = cpud_m_hready[i];
        assign m_hsel     [i+`HART_COUNT] = cpui_m_hsel[i];
        assign m_htrans   [i+`HART_COUNT] = cpui_m_htrans[i];
        assign m_hwrite   [i+`HART_COUNT] = cpui_m_hwrite[i];
        assign m_hmastlock[i+`HART_COUNT] = cpui_m_hmastlock[i];
        assign m_hsize    [i+`HART_COUNT] = cpui_m_hsize[i];
        assign m_hburst   [i+`HART_COUNT] = cpui_m_hburst[i];
        assign m_hprot    [i+`HART_COUNT] = cpui_m_hprot[i];
        assign m_haddr    [i+`HART_COUNT] = cpui_m_haddr[i];
        assign m_hwdata   [i+`HART_COUNT] = cpui_m_hwdata[i];
        assign m_hready   [i+`HART_COUNT] = cpui_m_hready[i];
        assign cpud_m_hreadyout[i] = m_hreadyout[i            ];
        assign cpud_m_hrdata[i]    = m_hrdata   [i            ];
        assign cpud_m_hresp[i]     = m_hresp    [i            ];
        assign cpui_m_hreadyout[i] = m_hreadyout[i+`HART_COUNT];
        assign cpui_m_hrdata[i]    = m_hrdata   [i+`HART_COUNT];
        assign cpui_m_hresp[i]     = m_hresp    [i+`HART_COUNT];
        //
        `ifdef RISCV_ISA_RV32A
        assign cpum_s_hsel[i]      = s_hsel     [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_htrans[i]    = s_htrans   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hwrite[i]    = s_hwrite   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_haddr[i]     = s_haddr    [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hready[i]    = s_hready   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hreadyout[i] = s_hreadyout[`SLAVE_SDRAM]; // Monitor SDRAM
        `endif
    end
    //
    assign m_hsel     [`HART_COUNT * 2] = dbgd_m_hsel;
    assign m_htrans   [`HART_COUNT * 2] = dbgd_m_htrans;
    assign m_hwrite   [`HART_COUNT * 2] = dbgd_m_hwrite;
    assign m_hmastlock[`HART_COUNT * 2] = dbgd_m_hmastlock;
    assign m_hsize    [`HART_COUNT * 2] = dbgd_m_hsize;
    assign m_hburst   [`HART_COUNT * 2] = dbgd_m_hburst;
    assign m_hprot    [`HART_COUNT * 2] = dbgd_m_hprot;
    assign m_haddr    [`HART_COUNT * 2] = dbgd_m_haddr;
    assign m_hwdata   [`HART_COUNT * 2] = dbgd_m_hwdata;
    assign m_hready   [`HART_COUNT * 2] = dbgd_m_hready;
    assign dbgd_m_hreadyout = m_hreadyout[`HART_COUNT * 2];
    assign dbgd_m_hrdata    = m_hrdata   [`HART_COUNT * 2];
    assign dbgd_m_hresp     = m_hresp    [`HART_COUNT * 2];
end
endgenerate
//
// Interrupts
wire        irq_ext;
wire        irq_msoft;
wire        irq_mtime;
wire [63:0] irq_gen;
wire [63:0] irq;
wire        irq_uart;
wire        irq_i2c0;
wire        irq_i2c1;
wire        irq_spi;
//
// Timer Counter
wire [31:0] mtime;
wire [31:0] mtimeh;
wire        dbg_stop_timer; // Stop Timer due to Debug Mode
//
// UART
wire cts, rts;
assign cts = 1'b0;
//
// I2C0
wire i2c0_scl_i;   // SCL Input
wire i2c0_scl_o;   // SCL Output
wire i2c0_scl_oen; // SCL Output Enable (neg)
wire i2c0_sda_i;   // SDA Input
wire i2c0_sda_o;   // SDA Output
wire i2c0_sda_oen; // SDA Output Enable (neg)
//
assign i2c0_scl_i = I2C0_SCL;
assign I2C0_SCL   = (i2c0_scl_oen)? 1'bz : i2c0_scl_o;
assign i2c0_sda_i = I2C0_SDA;
assign I2C0_SDA   = (i2c0_sda_oen)? 1'bz : i2c0_sda_o;
assign I2C0_ENA   = 1'b1;
assign I2C0_ADR   = 1'b0;
//
// I2C1
wire i2c1_scl_i;   // SCL Input
wire i2c1_scl_o;   // SCL Output
wire i2c1_scl_oen; // SCL Output Enable (neg)
wire i2c1_sda_i;   // SDA Input
wire i2c1_sda_o;   // SDA Output
wire i2c1_sda_oen; // SDA Output Enable (neg)
//
assign i2c1_scl_i = I2C1_SCL;
assign I2C1_SCL   = (i2c1_scl_oen)? 1'bz : i2c1_scl_o;
assign i2c1_sda_i = I2C1_SDA;
assign I2C1_SDA   = (i2c1_sda_oen)? 1'bz : i2c1_sda_o;

//-----------------------------------------
// mmRISC
//-----------------------------------------
// Reset Vector
generate
begin
    genvar i;
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : RESET_VECTOR
        assign reset_vector[i] = (`RESET_VECTOR_BASE) + (`RESET_VECTOR_DISP * i);
    end
end
endgenerate
//
// Security
assign debug_secure        = GPIO2[9]; //`DEBUG_SECURE_ENBL;
assign debug_secure_code_0 = `DEBUG_SECURE_CODE_0;
assign debug_secure_code_1 = `DEBUG_SECURE_CODE_1;
//
// mmRISC Body
mmRISC
   #(
        .HART_COUNT   (`HART_COUNT)
    )
U_MMRISC
(
    .RES_ORG (res_org),
    .RES_SYS (res_sys),
    .CLK     (clk),
    //
    .STBY_REQ (stby_req),
    .STBY_ACK (stby_ack),
    //
    .SRSTn_IN  (srst_n_in),
    .SRSTn_OUT (srst_n_out),
    //
    .FORCE_HALT_ON_RESET_REQ (force_halt_on_reset_req),
    .FORCE_HALT_ON_RESET_ACK (force_halt_on_reset_ack),
    .JTAG_DR_USER_IN  (jtag_dr_user_in ),
    .JTAG_DR_USER_OUT (jtag_dr_user_out),
    //
    .TRSTn (trstn),
    .TCK   (tck),
    .TMS   (tms),
    .TDI   (tdi),
    .TDO_D (tdo_d),
    .TDO_E (tdo_e),
    .RTCK  (RTCK),
    //
    .RESET_VECTOR        (reset_vector),
    .DEBUG_SECURE        (debug_secure),
    .DEBUG_SECURE_CODE_0 (debug_secure_code_0),
    .DEBUG_SECURE_CODE_1 (debug_secure_code_1),
    //
    .CPUI_M_HSEL      (cpui_m_hsel),
    .CPUI_M_HTRANS    (cpui_m_htrans),
    .CPUI_M_HWRITE    (cpui_m_hwrite),
    .CPUI_M_HMASTLOCK (cpui_m_hmastlock),
    .CPUI_M_HSIZE     (cpui_m_hsize),
    .CPUI_M_HBURST    (cpui_m_hburst),
    .CPUI_M_HPROT     (cpui_m_hprot),
    .CPUI_M_HADDR     (cpui_m_haddr),
    .CPUI_M_HWDATA    (cpui_m_hwdata),
    .CPUI_M_HREADY    (cpui_m_hready),
    .CPUI_M_HREADYOUT (cpui_m_hreadyout),
    .CPUI_M_HRDATA    (cpui_m_hrdata),
    .CPUI_M_HRESP     (cpui_m_hresp),
    //
    .CPUD_M_HSEL      (cpud_m_hsel),
    .CPUD_M_HTRANS    (cpud_m_htrans),
    .CPUD_M_HWRITE    (cpud_m_hwrite),
    .CPUD_M_HMASTLOCK (cpud_m_hmastlock),
    .CPUD_M_HSIZE     (cpud_m_hsize),
    .CPUD_M_HBURST    (cpud_m_hburst),
    .CPUD_M_HPROT     (cpud_m_hprot),
    .CPUD_M_HADDR     (cpud_m_haddr),
    .CPUD_M_HWDATA    (cpud_m_hwdata),
    .CPUD_M_HREADY    (cpud_m_hready),
    .CPUD_M_HREADYOUT (cpud_m_hreadyout),
    .CPUD_M_HRDATA    (cpud_m_hrdata),
    .CPUD_M_HRESP     (cpud_m_hresp),
    //
    `ifdef RISCV_ISA_RV32A
    .CPUM_S_HSEL      (cpum_s_hsel),
    .CPUM_S_HTRANS    (cpum_s_htrans),
    .CPUM_S_HWRITE    (cpum_s_hwrite),
    .CPUM_S_HADDR     (cpum_s_haddr),
    .CPUM_S_HREADY    (cpum_s_hready),
    .CPUM_S_HREADYOUT (cpum_s_hreadyout),
    `endif
    //
    .DBGD_M_HSEL      (dbgd_m_hsel),
    .DBGD_M_HTRANS    (dbgd_m_htrans),
    .DBGD_M_HWRITE    (dbgd_m_hwrite),
    .DBGD_M_HMASTLOCK (dbgd_m_hmastlock),
    .DBGD_M_HSIZE     (dbgd_m_hsize),
    .DBGD_M_HBURST    (dbgd_m_hburst),
    .DBGD_M_HPROT     (dbgd_m_hprot),
    .DBGD_M_HADDR     (dbgd_m_haddr),
    .DBGD_M_HWDATA    (dbgd_m_hwdata),
    .DBGD_M_HREADY    (dbgd_m_hready),
    .DBGD_M_HREADYOUT (dbgd_m_hreadyout),
    .DBGD_M_HRDATA    (dbgd_m_hrdata),
    .DBGD_M_HRESP     (dbgd_m_hresp),
    //
    .IRQ_EXT   (irq_ext),
    .IRQ_MSOFT (irq_msoft),
    .IRQ_MTIME (irq_mtime),
    .IRQ       (irq),
    //
    .MTIME  (mtime),
    .MTIMEH (mtimeh),
    .DBG_STOP_TIMER (dbg_stop_timer)  // Stop Timer due to Debug Mode
);

//---------------------
// AHB Bus Matrix
//---------------------
wire  [`MASTERS_BIT-1:0] m_priority[0:`MASTERS-1];
wire [31:0] s_haddr_base[0:`SLAVES-1];
wire [31:0] s_haddr_mask[0:`SLAVES-1];
//
generate
begin
    genvar i;
    //
    // Priorty of Data Port and Instruction Port for Each Hart
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : MASTER_HART_PRIORITY
        assign m_priority[i              ] = ((`MASTERS_BIT)'(1)); // Data
        assign m_priority[i + `HART_COUNT] = ((`MASTERS_BIT)'(2)); // Inst
    end
    //
    // Priorty of Other Ports
    assign m_priority[(`HART_COUNT * 2    )] = ((`MASTERS_BIT)'(0)); // DBGD
end
endgenerate
//
//generate
//    for (i = 0; i < `MASTERS; i = i + 1)
//    begin : MASTER_PRIORITY
//        if (i == 0)      assign m_priority[i] = `M_PRIORITY_0;
//        else if (i == 1) assign m_priority[i] = `M_PRIORITY_1;
//        else if (i == 2) assign m_priority[i] = `M_PRIORITY_2;
//        else if (i == 3) assign m_priority[i] = `M_PRIORITY_3;
//        else if (i == 4) assign m_priority[i] = `M_PRIORITY_4;
//        else if (i == 5) assign m_priority[i] = `M_PRIORITY_5;
//        else if (i == 6) assign m_priority[i] = `M_PRIORITY_6;
//        else if (i == 7) assign m_priority[i] = `M_PRIORITY_7;
//        else if (i == 8) assign m_priority[i] = `M_PRIORITY_8;
//        else             assign m_priority[i] = ((`MASTERS_BIT)'(i));
//    end
//endgenerate

//-----------------------
// Slave Address
//-----------------------
assign s_haddr_base[`SLAVE_MTIME ] = `SLAVE_BASE_MTIME;
assign s_haddr_base[`SLAVE_SDRAM ] = `SLAVE_BASE_SDRAM;
assign s_haddr_base[`SLAVE_RAMD  ] = `SLAVE_BASE_RAMD;
assign s_haddr_base[`SLAVE_RAMI  ] = `SLAVE_BASE_RAMI;
assign s_haddr_base[`SLAVE_GPIO  ] = `SLAVE_BASE_GPIO;
assign s_haddr_base[`SLAVE_UART  ] = `SLAVE_BASE_UART;
assign s_haddr_base[`SLAVE_INTGEN] = `SLAVE_BASE_INTGEN;
assign s_haddr_base[`SLAVE_I2C0  ] = `SLAVE_BASE_I2C0;
assign s_haddr_base[`SLAVE_I2C1  ] = `SLAVE_BASE_I2C1;
assign s_haddr_base[`SLAVE_SPI   ] = `SLAVE_BASE_SPI;
//
assign s_haddr_mask[`SLAVE_MTIME ] = `SLAVE_MASK_MTIME;
assign s_haddr_mask[`SLAVE_SDRAM ] = `SLAVE_MASK_SDRAM;
assign s_haddr_mask[`SLAVE_RAMD  ] = `SLAVE_MASK_RAMD;
assign s_haddr_mask[`SLAVE_RAMI  ] = `SLAVE_MASK_RAMI;
assign s_haddr_mask[`SLAVE_GPIO  ] = `SLAVE_MASK_GPIO;
assign s_haddr_mask[`SLAVE_UART  ] = `SLAVE_MASK_UART;
assign s_haddr_mask[`SLAVE_INTGEN] = `SLAVE_MASK_INTGEN;
assign s_haddr_mask[`SLAVE_I2C0  ] = `SLAVE_MASK_I2C0;
assign s_haddr_mask[`SLAVE_I2C1  ] = `SLAVE_MASK_I2C1;
assign s_haddr_mask[`SLAVE_SPI   ] = `SLAVE_MASK_SPI;
//
AHB_MATRIX
   #(
        .MASTERS  (`MASTERS),
        .SLAVES   (`SLAVES)
    )
U_AHB_MATRIX 
(
    // Global Signals
    .HCLK    (clk),
    .HRESETn (~res_sys),
    // Master Ports
    .M_HSEL      (m_hsel),
    .M_HTRANS    (m_htrans),
    .M_HWRITE    (m_hwrite),
    .M_HMASTLOCK (m_hmastlock),
    .M_HSIZE     (m_hsize),
    .M_HBURST    (m_hburst),
    .M_HPROT     (m_hprot),
    .M_HADDR     (m_haddr),
    .M_HWDATA    (m_hwdata),
    .M_HREADY    (m_hready),
    .M_HREADYOUT (m_hreadyout),
    .M_HRDATA    (m_hrdata),
    .M_HRESP     (m_hresp),
    .M_PRIORITY  (m_priority),
    // Slave Ports
    .S_HSEL      (s_hsel),
    .S_HTRANS    (s_htrans),
    .S_HWRITE    (s_hwrite),
    .S_HMASTLOCK (s_hmastlock),
    .S_HSIZE     (s_hsize),
    .S_HBURST    (s_hburst),
    .S_HPROT     (s_hprot),
    .S_HADDR     (s_haddr),
    .S_HWDATA    (s_hwdata),
    .S_HREADY    (s_hready),
    .S_HREADYOUT (s_hreadyout),
    .S_HRDATA    (s_hrdata),
    .S_HRESP     (s_hresp),
    .S_HADDR_BASE(s_haddr_base),
    .S_HADDR_MASK(s_haddr_mask)
);

//--------------------
// CSR_MTIME
//--------------------
CSR_MTIME U_CSR_MTIME 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_MTIME]),
    .S_HTRANS    (s_htrans   [`SLAVE_MTIME]),
    .S_HWRITE    (s_hwrite   [`SLAVE_MTIME]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_MTIME]),
    .S_HSIZE     (s_hsize    [`SLAVE_MTIME]),
    .S_HBURST    (s_hburst   [`SLAVE_MTIME]),
    .S_HPROT     (s_hprot    [`SLAVE_MTIME]),
    .S_HADDR     (s_haddr    [`SLAVE_MTIME]),
    .S_HWDATA    (s_hwdata   [`SLAVE_MTIME]),
    .S_HREADY    (s_hready   [`SLAVE_MTIME]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_MTIME]),
    .S_HRDATA    (s_hrdata   [`SLAVE_MTIME]),
    .S_HRESP     (s_hresp    [`SLAVE_MTIME]),
    // External Clock
    .CSR_MTIME_EXTCLK (TCK),
    // Interrupt Output
    .IRQ_MSOFT (irq_msoft),
    .IRQ_MTIME (irq_mtime),
    // Timer Counter
    .MTIME  (mtime),
    .MTIMEH (mtimeh),
    .DBG_STOP_TIMER (dbg_stop_timer)  // Stop Timer due to Debug Mode
);

//----------------------
// SDRAM Interface
//----------------------
ahb_lite_sdram U_AHB_SDRAM
(
    // Global Signals
    .HCLK     (clk),
    .HRESETn  (~res_sys),
    // Slave Ports
    // Slave Ports
    .HSEL      (s_hsel     [`SLAVE_SDRAM]),
    .HTRANS    (s_htrans   [`SLAVE_SDRAM]),
    .HWRITE    (s_hwrite   [`SLAVE_SDRAM]),
    .HMASTLOCK (s_hmastlock[`SLAVE_SDRAM]),
    .HSIZE     (s_hsize    [`SLAVE_SDRAM]),
    .HBURST    (s_hburst   [`SLAVE_SDRAM]),
    .HPROT     (s_hprot    [`SLAVE_SDRAM]),
    .HADDR     (s_haddr    [`SLAVE_SDRAM]),
    .HWDATA    (s_hwdata   [`SLAVE_SDRAM]),
    .HREADY    (s_hready   [`SLAVE_SDRAM]),
    .HREADYOUT (s_hreadyout[`SLAVE_SDRAM]),
    .HRDATA    (s_hrdata   [`SLAVE_SDRAM]),
    .HRESP     (s_hresp    [`SLAVE_SDRAM]),
    .SI_Endian (1'b0),
    //SDRAM side
    .CKE   (SDRAM_CKE),
    .CSn   (SDRAM_CSn),
    .RASn  (SDRAM_RASn),
    .CASn  (SDRAM_CASn),
    .WEn   (SDRAM_WEn),
    .ADDR  (SDRAM_ADDR),
    .BA    (SDRAM_BA),
    .DQ    (SDRAM_DQ),
    .DQM   (SDRAM_DQM)
);

//--------------------
// RAM Data
//--------------------
RAM
   #(
        .RAM_SIZE(`RAMD_SIZE)
    )
U_RAMD
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMD]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMD]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMD]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMD]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMD]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMD]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMD]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMD]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMD]),
    .S_HREADY    (s_hready   [`SLAVE_RAMD]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMD]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMD]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMD])
);

//--------------------
// RAM Instruction
//--------------------
`ifdef FPGA
RAM_FPGA U_RAMI
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMI]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMI]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMI]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMI]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMI]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMI]),
    .S_HREADY    (s_hready   [`SLAVE_RAMI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMI]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMI])
);
`else
RAM
   #(
        .RAM_SIZE(`RAMI_SIZE)
    )
U_RAMI
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMI]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMI]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMI]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMI]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMI]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMI]),
    .S_HREADY    (s_hready   [`SLAVE_RAMI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMI]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMI])
);
`endif

//--------------------
// GPIO Port
//--------------------
PORT U_PORT 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_GPIO]),
    .S_HTRANS    (s_htrans   [`SLAVE_GPIO]),
    .S_HWRITE    (s_hwrite   [`SLAVE_GPIO]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_GPIO]),
    .S_HSIZE     (s_hsize    [`SLAVE_GPIO]),
    .S_HBURST    (s_hburst   [`SLAVE_GPIO]),
    .S_HPROT     (s_hprot    [`SLAVE_GPIO]),
    .S_HADDR     (s_haddr    [`SLAVE_GPIO]),
    .S_HWDATA    (s_hwdata   [`SLAVE_GPIO]),
    .S_HREADY    (s_hready   [`SLAVE_GPIO]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_GPIO]),
    .S_HRDATA    (s_hrdata   [`SLAVE_GPIO]),
    .S_HRESP     (s_hresp    [`SLAVE_GPIO]),
    // GPIO Port
    .GPIO0 (GPIO0),
    .GPIO1 (GPIO1),
    .GPIO2 (GPIO2)
);

//-------------------
// UART
//-------------------
UART U_UART 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_UART]),
    .S_HTRANS    (s_htrans   [`SLAVE_UART]),
    .S_HWRITE    (s_hwrite   [`SLAVE_UART]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_UART]),
    .S_HSIZE     (s_hsize    [`SLAVE_UART]),
    .S_HBURST    (s_hburst   [`SLAVE_UART]),
    .S_HPROT     (s_hprot    [`SLAVE_UART]),
    .S_HADDR     (s_haddr    [`SLAVE_UART]),
    .S_HWDATA    (s_hwdata   [`SLAVE_UART]),
    .S_HREADY    (s_hready   [`SLAVE_UART]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_UART]),
    .S_HRDATA    (s_hrdata   [`SLAVE_UART]),
    .S_HRESP     (s_hresp    [`SLAVE_UART]),
    // UART Port
    .RXD (RXD),
    .TXD (TXD),
    .CTS (cts),
    .RTS (rts),
    // Interrupt
    .IRQ_UART (irq_uart)
);

//--------------------
// INT_GEN
//--------------------
INT_GEN U_INT_GEN 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_INTGEN]),
    .S_HTRANS    (s_htrans   [`SLAVE_INTGEN]),
    .S_HWRITE    (s_hwrite   [`SLAVE_INTGEN]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_INTGEN]),
    .S_HSIZE     (s_hsize    [`SLAVE_INTGEN]),
    .S_HBURST    (s_hburst   [`SLAVE_INTGEN]),
    .S_HPROT     (s_hprot    [`SLAVE_INTGEN]),
    .S_HADDR     (s_haddr    [`SLAVE_INTGEN]),
    .S_HWDATA    (s_hwdata   [`SLAVE_INTGEN]),
    .S_HREADY    (s_hready   [`SLAVE_INTGEN]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_INTGEN]),
    .S_HRDATA    (s_hrdata   [`SLAVE_INTGEN]),
    .S_HRESP     (s_hresp    [`SLAVE_INTGEN]),
    // Interrupt Output
    .IRQ_EXT (irq_ext),
    .IRQ     (irq_gen)
);

//-------------------
// I2C0
//-------------------
I2C U_I2C0
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_I2C0]),
    .S_HTRANS    (s_htrans   [`SLAVE_I2C0]),
    .S_HWRITE    (s_hwrite   [`SLAVE_I2C0]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_I2C0]),
    .S_HSIZE     (s_hsize    [`SLAVE_I2C0]),
    .S_HBURST    (s_hburst   [`SLAVE_I2C0]),
    .S_HPROT     (s_hprot    [`SLAVE_I2C0]),
    .S_HADDR     (s_haddr    [`SLAVE_I2C0]),
    .S_HWDATA    (s_hwdata   [`SLAVE_I2C0]),
    .S_HREADY    (s_hready   [`SLAVE_I2C0]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_I2C0]),
    .S_HRDATA    (s_hrdata   [`SLAVE_I2C0]),
    .S_HRESP     (s_hresp    [`SLAVE_I2C0]),
    // I2C Port
    .I2C_SCL_I   (i2c0_scl_i),   // SCL Input
    .I2C_SCL_O   (i2c0_scl_o),   // SCL Output
    .I2C_SCL_OEN (i2c0_scl_oen), // SCL Output Enable (neg)
    .I2C_SDA_I   (i2c0_sda_i),   // SDA Input
    .I2C_SDA_O   (i2c0_sda_o),   // SDA Output
    .I2C_SDA_OEN (i2c0_sda_oen), // SDA Output Enable (neg)
    // Interrupt
    .IRQ_I2C (irq_i2c0)
);

//-------------------
// I2C1
//-------------------
I2C U_I2C1
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_I2C1]),
    .S_HTRANS    (s_htrans   [`SLAVE_I2C1]),
    .S_HWRITE    (s_hwrite   [`SLAVE_I2C1]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_I2C1]),
    .S_HSIZE     (s_hsize    [`SLAVE_I2C1]),
    .S_HBURST    (s_hburst   [`SLAVE_I2C1]),
    .S_HPROT     (s_hprot    [`SLAVE_I2C1]),
    .S_HADDR     (s_haddr    [`SLAVE_I2C1]),
    .S_HWDATA    (s_hwdata   [`SLAVE_I2C1]),
    .S_HREADY    (s_hready   [`SLAVE_I2C1]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_I2C1]),
    .S_HRDATA    (s_hrdata   [`SLAVE_I2C1]),
    .S_HRESP     (s_hresp    [`SLAVE_I2C1]),
    // I2C Port
    .I2C_SCL_I   (i2c1_scl_i),   // SCL Input
    .I2C_SCL_O   (i2c1_scl_o),   // SCL Output
    .I2C_SCL_OEN (i2c1_scl_oen), // SCL Output Enable (neg)
    .I2C_SDA_I   (i2c1_sda_i),   // SDA Input
    .I2C_SDA_O   (i2c1_sda_o),   // SDA Output
    .I2C_SDA_OEN (i2c1_sda_oen), // SDA Output Enable (neg)
    // Interrupt
    .IRQ_I2C (irq_i2c1)
);

//-------------------
// SPI
//-------------------
SPI U_SPI 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_SPI]),
    .S_HTRANS    (s_htrans   [`SLAVE_SPI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_SPI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_SPI]),
    .S_HSIZE     (s_hsize    [`SLAVE_SPI]),
    .S_HBURST    (s_hburst   [`SLAVE_SPI]),
    .S_HPROT     (s_hprot    [`SLAVE_SPI]),
    .S_HADDR     (s_haddr    [`SLAVE_SPI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_SPI]),
    .S_HREADY    (s_hready   [`SLAVE_SPI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_SPI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_SPI]),
    .S_HRESP     (s_hresp    [`SLAVE_SPI]),
    // SPI Port
    .SPI_CSN   (SPI_CSN),  // SPI Chip Select
    .SPI_SCK   (SPI_SCK),  // SPI Clock
    .SPI_MOSI  (SPI_MOSI), // SPI MOSI
    .SPI_MISO  (SPI_MISO), // SPI MISO
    // Interrupt
    .IRQ_SPI (irq_spi)
);

//-----------------------------------------
// Interrupts
//-----------------------------------------
assign irq = irq_gen | 
    {
        58'h0,
        I2C0_INT2,
        I2C0_INT1,
        irq_spi,
        irq_i2c1,
        irq_i2c0,
        irq_uart
    };

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
