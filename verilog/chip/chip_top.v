//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : fpga_top.v
// Description : Top Layer of FPGA
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================
//
// < FPGA Board Terasic DE10-Lite>
// RES_N     B8  KEY0
// CLK50     P11
// SDRAM_CLK L14 Disable SDRAM
// SDRAM_CKE N22 Disable SDRAM
// SDRAM_CSn U20 Disable SDRAM
// TRSTn     Y5  GPIO_29
// TCK       Y6  GPIO_27
// TMS       AA2 GPIO_35
// TDI       Y4  GPIO_31
// TDO       Y3  GPIO_33
//
// TXD       W10 GPIO_1
// RXD       W9  GPIO_3
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
// GPIO1[15] L19 HEX57 segDP
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
// GPIO2[ 7] A14  SW7
// GPIO2[ 8] B14  SW8
// GPIO2[ 9] F15  SW9
// GPIO2[10] A7   KEY1
// GPIO2[11] W6   GPIO_8
// GPIO2[12] V5   GPIO_9
// GPIO2[13] W5   GPIO_10
// GPIO2[14] AA15 GPIO_11
// GPIO2[15] AA14 GPIO_12 
// GPIO2[16] W13  GPIO_13
// GPIO2[17] W12  GPIO_14
// GPIO2[18] AB13 GPIO_15
// GPIO2[19] AB12 GPIO_16
// GPIO2[20] Y11  GPIO_17
// GPIO2[21] AB11 GPIO_18
// GPIO2[22] W11  GPIO_19
// GPIO2[23] AB10 GPIO_20
// GPIO2[24] AA10 GPIO_21
// GPIO2[25] AA9  GPIO_22
// GPIO2[26] Y8   GPIO_23
// GPIO2[27] AA8  GPIO_24
// GPIO2[28] Y7   GPIO_25
// GPIO2[29] AA7  GPIO_26
// GPIO2[30] AA6  GPIO_28
// GPIO2[31] AA5  GPIO_30

`include "defines.v"

//---------------------
// RAM Size
//---------------------
`ifdef SIMULATION
    `define RAM0_SIZE (16*1024*1024)
    `define RAM1_SIZE (16*1024*1024)
`elsif
    `define RAM0_SIZE ( 48*1024) // RAM
    `define RAM1_SIZE (128*1024) // ROM
`endif

//----------------------
// Bus Configuration
//----------------------
`define MASTERS (`HART_COUNT * 2 + 1)
`define MASTERS_BIT $clog2(`MASTERS)
//
`define M_PRIORITY_0 1 // CPUD
`define M_PRIORITY_1 1 // CPUD
`define M_PRIORITY_2 1 // CPUD
`define M_PRIORITY_3 1 // CPUD
`define M_PRIORITY_4 2 // CPUI
`define M_PRIORITY_5 2 // CPUI
`define M_PRIORITY_6 2 // CPUI
`define M_PRIORITY_7 2 // CPUI
`define M_PRIORITY_8 0 // DBGD
//
`define SLAVES 6
`define SLAVE_CSR_MTIME 0
`define SLAVE_RAM0      1
`define SLAVE_RAM1      2
`define SLAVE_GPIO      3
`define SLAVE_UART      4
`define SLAVE_INT_GETN  5

//----------------------
// Define Module
//----------------------
module CHIP_TOP
(
    input wire RES_N, // Reset Input (Negative)
    input wire CLK50, // Clock Input (50MHz)
    //
    input  wire TRSTn, // JTAG TAP Reset
`ifdef SIMULATION
    inout  wire SRSTn, // System Reset In/Out
`endif
    //
    input  wire TCK,  // JTAG Clock
    input  wire TMS,  // JTAG Mode Select
    input  wire TDI,  // JTAG Data Input
    output wire TDO,  // JTAG Data Output (3-state)
`ifdef SIMULATION
    output wire RTCK, // JTAG Return Clock
`endif
    //
    inout  wire [31:0] GPIO0, // GPIO0 Port (should be pulled-up)
    inout  wire [31:0] GPIO1, // GPIO1 Port (should be pulled-up)
    inout  wire [31:0] GPIO2, // GPIO2 Port (should be pulled-up)
    //
    input  wire RXD, // UART receive data
    output wire TXD, // UART transmit data
    //
    output wire SDRAM_CLK, // Disable SDRAM
    output wire SDRAM_CKE, // Disable SDRAM
    output wire SDRAM_CSn  // Disable SDRAM
);

//------------------
// Genvar
//------------------
genvar i;

//----------------
// Disable SDRAM
//----------------
assign SDRAM_CLK = 1'b0;
assign SDRAM_CKE = 1'b0;
assign SDRAM_CSn = 1'b1;

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

//-----------------
// Clock and PLL
//-----------------
wire clk0;
wire clk1;
wire clk;
wire stby;
//
`ifdef SIMULATION
assign clk = CLK50;
assign locked = 1'b1;
`else
wire locked_pll;
reg  locked_reg;
//
PLL U_PLL
(
    .areset  (res_pll),
    .inclk0  (CLK50),
    .c0      (clk0),  // 20.00MHz
    .c1      (clk1),  // 16.66MHz
    .locked  (locked_pll)
);
//
`ifdef RISCV_ISA_RV32F
assign clk = clk1; // 16MHz with FPU
`else
assign clk = clk0; // 20MHz without FPU
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
assign stby = 1'b0;

//-----------------
// JTAG TDO Buffer
//-----------------
wire tdo_e, tdo_d;
assign TDO = (tdo_e)? tdo_d : 1'bz;

//---------------
// mmRISC
//---------------
wire [31:0] reset_vector     [0:`HART_COUNT-1]; // Reset Vector
wire        debug_secure;      // Debug Authentication is available or not
wire [31:0] debug_secure_code; // Debug Authentication Code
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
        assign cpum_s_hsel[i]      = s_hsel[2];      // Monitor RAM1
        assign cpum_s_htrans[i]    = s_htrans[2];    // Monitor RAM1
        assign cpum_s_hwrite[i]    = s_hwrite[2];    // Monitor RAM1
        assign cpum_s_haddr[i]     = s_haddr[2];     // Monitor RAM1
        assign cpum_s_hready[i]    = s_hready[2];    // Monitor RAM1
        assign cpum_s_hreadyout[i] = s_hreadyout[2]; // Monitor RAM1
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
endgenerate
//
// Interrupts
wire        irq_ext;
wire        irq_msoft;
wire        irq_mtime;
wire [63:0] irq_gen;
wire [63:0] irq;
//
// Timer Counter
wire [31:0] mtime;
wire [31:0] mtimeh;
wire        dbg_stop_timer; // Stop Timer due to Debug Mode
//
// UART
wire cts, rts;
wire irq_uart;
//
assign cts = 1'b0;

//-----------------------------------------
// mmRISC
//-----------------------------------------
// Reset Vector
generate
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : RESET_VECTOR
        if (i == 0) assign reset_vector[0] = 32'h90000000;
        if (i == 1) assign reset_vector[1] = 32'h91000000;
        if (i == 2) assign reset_vector[2] = 32'h92000000;
        if (i == 3) assign reset_vector[3] = 32'h93000000;
    end
endgenerate
//
// Security
assign debug_secure = 1'b0;              // no Debug Authentification
assign debug_secure_code = 32'h12345678; // Debug Authentification Code
//
// mmRISC Body
mmRISC U_MMRISC
(
    .RES_ORG (res_org),
    .RES_SYS (res_sys),
    .CLK     (clk),
    .STBY    (stby),
    //
    .TRSTn     (TRSTn),
    .SRSTn_IN  (srst_n_in),
    .SRSTn_OUT (srst_n_out),
    //
    .TCK   (TCK),
    .TMS   (TMS),
    .TDI   (TDI),
    .TDO_D (tdo_d),
    .TDO_E (tdo_e),
    .RTCK  (RTCK),
    //
    .RESET_VECTOR      (reset_vector),
    .DEBUG_SECURE      (debug_secure),
    .DEBUG_SECURE_CODE (debug_secure_code),
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
    for (i = 0; i < `MASTERS; i = i + 1)
    begin : MASTER_PRIORITY
        if (i == 0)      assign m_priority[i] = `M_PRIORITY_0;
        else if (i == 1) assign m_priority[i] = `M_PRIORITY_1;
        else if (i == 2) assign m_priority[i] = `M_PRIORITY_2;
        else if (i == 3) assign m_priority[i] = `M_PRIORITY_3;
        else if (i == 4) assign m_priority[i] = `M_PRIORITY_4;
        else if (i == 5) assign m_priority[i] = `M_PRIORITY_5;
        else if (i == 6) assign m_priority[i] = `M_PRIORITY_6;
        else if (i == 7) assign m_priority[i] = `M_PRIORITY_7;
        else if (i == 8) assign m_priority[i] = `M_PRIORITY_8;
        else             assign m_priority[i] = ((`MASTERS_BIT)'(i));
    end
endgenerate

// Slave Address
//   MTIME  : 0x49000000-0x4900001f
//   RAM0   : 0x80000000-0x8fffffff
//   RAM1   : 0x90000000-0x9fffffff
//   PORT   : 0xA0000000-0xafffffff
//   UART   : 0xB0000000-0xbfffffff
//   INT_GEN: 0xC0000000-0xcfffffff
assign s_haddr_base[0] = 32'h49000000;
assign s_haddr_base[1] = 32'h80000000;
assign s_haddr_base[2] = 32'h90000000;
assign s_haddr_base[3] = 32'ha0000000;
assign s_haddr_base[4] = 32'hb0000000;
assign s_haddr_base[5] = 32'hc0000000;
//
assign s_haddr_mask[0] = 32'hffffffe0;
assign s_haddr_mask[1] = 32'hf0000000;
assign s_haddr_mask[2] = 32'hf0000000;
assign s_haddr_mask[3] = 32'hf0000000;
assign s_haddr_mask[4] = 32'hf0000000;
assign s_haddr_mask[5] = 32'hf0000000;
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
    .S_HSEL      (s_hsel[0]),
    .S_HTRANS    (s_htrans[0]),
    .S_HWRITE    (s_hwrite[0]),
    .S_HMASTLOCK (s_hmastlock[0]),
    .S_HSIZE     (s_hsize[0]),
    .S_HBURST    (s_hburst[0]),
    .S_HPROT     (s_hprot[0]),
    .S_HADDR     (s_haddr[0]),
    .S_HWDATA    (s_hwdata[0]),
    .S_HREADY    (s_hready[0]),
    .S_HREADYOUT (s_hreadyout[0]),
    .S_HRDATA    (s_hrdata[0]),
    .S_HRESP     (s_hresp[0]),
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

//--------------------
// RAM 0
//--------------------
RAM
   #(
        .RAM_SIZE(`RAM0_SIZE)
    )
U_RAM0 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel[1]),
    .S_HTRANS    (s_htrans[1]),
    .S_HWRITE    (s_hwrite[1]),
    .S_HMASTLOCK (s_hmastlock[1]),
    .S_HSIZE     (s_hsize[1]),
    .S_HBURST    (s_hburst[1]),
    .S_HPROT     (s_hprot[1]),
    .S_HADDR     (s_haddr[1]),
    .S_HWDATA    (s_hwdata[1]),
    .S_HREADY    (s_hready[1]),
    .S_HREADYOUT (s_hreadyout[1]),
    .S_HRDATA    (s_hrdata[1]),
    .S_HRESP     (s_hresp[1])
);

//--------------------
// RAM 1
//--------------------
`ifdef FPGA
RAM_FPGA U_RAM1
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel[2]),
    .S_HTRANS    (s_htrans[2]),
    .S_HWRITE    (s_hwrite[2]),
    .S_HMASTLOCK (s_hmastlock[2]),
    .S_HSIZE     (s_hsize[2]),
    .S_HBURST    (s_hburst[2]),
    .S_HPROT     (s_hprot[2]),
    .S_HADDR     (s_haddr[2]),
    .S_HWDATA    (s_hwdata[2]),
    .S_HREADY    (s_hready[2]),
    .S_HREADYOUT (s_hreadyout[2]),
    .S_HRDATA    (s_hrdata[2]),
    .S_HRESP     (s_hresp[2])
);
`else
RAM
   #(
        .RAM_SIZE(`RAM1_SIZE)
    )
U_RAM1 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel[2]),
    .S_HTRANS    (s_htrans[2]),
    .S_HWRITE    (s_hwrite[2]),
    .S_HMASTLOCK (s_hmastlock[2]),
    .S_HSIZE     (s_hsize[2]),
    .S_HBURST    (s_hburst[2]),
    .S_HPROT     (s_hprot[2]),
    .S_HADDR     (s_haddr[2]),
    .S_HWDATA    (s_hwdata[2]),
    .S_HREADY    (s_hready[2]),
    .S_HREADYOUT (s_hreadyout[2]),
    .S_HRDATA    (s_hrdata[2]),
    .S_HRESP     (s_hresp[2])
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
    .S_HSEL      (s_hsel[3]),
    .S_HTRANS    (s_htrans[3]),
    .S_HWRITE    (s_hwrite[3]),
    .S_HMASTLOCK (s_hmastlock[3]),
    .S_HSIZE     (s_hsize[3]),
    .S_HBURST    (s_hburst[3]),
    .S_HPROT     (s_hprot[3]),
    .S_HADDR     (s_haddr[3]),
    .S_HWDATA    (s_hwdata[3]),
    .S_HREADY    (s_hready[3]),
    .S_HREADYOUT (s_hreadyout[3]),
    .S_HRDATA    (s_hrdata[3]),
    .S_HRESP     (s_hresp[3]),
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
    .S_HSEL      (s_hsel[4]),
    .S_HTRANS    (s_htrans[4]),
    .S_HWRITE    (s_hwrite[4]),
    .S_HMASTLOCK (s_hmastlock[4]),
    .S_HSIZE     (s_hsize[4]),
    .S_HBURST    (s_hburst[4]),
    .S_HPROT     (s_hprot[4]),
    .S_HADDR     (s_haddr[4]),
    .S_HWDATA    (s_hwdata[4]),
    .S_HREADY    (s_hready[4]),
    .S_HREADYOUT (s_hreadyout[4]),
    .S_HRDATA    (s_hrdata[4]),
    .S_HRESP     (s_hresp[4]),
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
    .S_HSEL      (s_hsel[5]),
    .S_HTRANS    (s_htrans[5]),
    .S_HWRITE    (s_hwrite[5]),
    .S_HMASTLOCK (s_hmastlock[5]),
    .S_HSIZE     (s_hsize[5]),
    .S_HBURST    (s_hburst[5]),
    .S_HPROT     (s_hprot[5]),
    .S_HADDR     (s_haddr[5]),
    .S_HWDATA    (s_hwdata[5]),
    .S_HREADY    (s_hready[5]),
    .S_HREADYOUT (s_hreadyout[5]),
    .S_HRDATA    (s_hrdata[5]),
    .S_HRESP     (s_hresp[5]),
    // Interrupt Output
    .IRQ_EXT (irq_ext),
    .IRQ     (irq_gen)
);
//
assign irq = irq_gen | {63'h0, irq_uart};

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
