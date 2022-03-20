//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : mmRISC.v
// Description : Top Layer of mmRISC Subsystem
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module mmRISC
    #(parameter
        HART_COUNT = 1
     )
(
    input  wire RES_ORG, // Reset Origin (e.g. Power On Reset)
    output wire RES_SYS, // Reset System (including reset from debug)
    input  wire CLK,  // System Clock
    input  wire STBY, // System Stand-by
    //
    input  wire TRSTn,     // JTAG TAP Reset
    input  wire SRSTn_IN,  // System Reset Input except for Debug
    output wire SRSTn_OUT, // System Reset Output from Debug
    //
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output wire TDO_D, // JTAG Data Output
    output wire TDO_E, // JTAG Data Output Enable
    output wire RTCK,  // JTAG Return Clock
    //
    input  wire [31:0] RESET_VECTOR     [0:HART_COUNT-1], // Reset Vector
    input  wire        DEBUG_SECURE,      // Debug should be secure, or not
    input  wire [31:0] DEBUG_SECURE_CODE, // Debug Security Pass Code
    //
    output wire        CPUI_M_HSEL      [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [ 1:0] CPUI_M_HTRANS    [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire        CPUI_M_HWRITE    [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire        CPUI_M_HMASTLOCK [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [ 2:0] CPUI_M_HSIZE     [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [ 2:0] CPUI_M_HBURST    [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [ 3:0] CPUI_M_HPROT     [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [31:0] CPUI_M_HADDR     [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire [31:0] CPUI_M_HWDATA    [0:HART_COUNT-1], // AHB for CPU Instruction
    output wire        CPUI_M_HREADY    [0:HART_COUNT-1], // AHB for CPU Instruction
    input  wire        CPUI_M_HREADYOUT [0:HART_COUNT-1], // AHB for CPU Instruction
    input  wire [31:0] CPUI_M_HRDATA    [0:HART_COUNT-1], // AHB for CPU Instruction
    input  wire        CPUI_M_HRESP     [0:HART_COUNT-1], // AHB for CPU Instruction
    //
    output wire        CPUD_M_HSEL      [0:HART_COUNT-1], // AHB for CPU Data
    output wire [ 1:0] CPUD_M_HTRANS    [0:HART_COUNT-1], // AHB for CPU Data
    output wire        CPUD_M_HWRITE    [0:HART_COUNT-1], // AHB for CPU Data
    output wire        CPUD_M_HMASTLOCK [0:HART_COUNT-1], // AHB for CPU Data
    output wire [ 2:0] CPUD_M_HSIZE     [0:HART_COUNT-1], // AHB for CPU Data
    output wire [ 2:0] CPUD_M_HBURST    [0:HART_COUNT-1], // AHB for CPU Data
    output wire [ 3:0] CPUD_M_HPROT     [0:HART_COUNT-1], // AHB for CPU Data
    output wire [31:0] CPUD_M_HADDR     [0:HART_COUNT-1], // AHB for CPU Data
    output wire [31:0] CPUD_M_HWDATA    [0:HART_COUNT-1], // AHB for CPU Data
    output wire        CPUD_M_HREADY    [0:HART_COUNT-1], // AHB for CPU Data
    input  wire        CPUD_M_HREADYOUT [0:HART_COUNT-1], // AHB for CPU Data
    input  wire [31:0] CPUD_M_HRDATA    [0:HART_COUNT-1], // AHB for CPU Data
    input  wire        CPUD_M_HRESP     [0:HART_COUNT-1], // AHB for CPU Data
    //
    `ifdef RISCV_ISA_RV32A
    input  wire        CPUM_S_HSEL      [0:HART_COUNT-1], // AHB Monitor for LR/SC
    input  wire [ 1:0] CPUM_S_HTRANS    [0:HART_COUNT-1], // AHB Monitor for LR/SC
    input  wire        CPUM_S_HWRITE    [0:HART_COUNT-1], // AHB Monitor for LR/SC
    input  wire [31:0] CPUM_S_HADDR     [0:HART_COUNT-1], // AHB Monitor for LR/SC
    input  wire        CPUM_S_HREADY    [0:HART_COUNT-1], // AHB Monitor for LR/SC
    input  wire        CPUM_S_HREADYOUT [0:HART_COUNT-1], // AHB Monitor for LR/SC
    `endif
    //
    output wire        DBGD_M_HSEL     , // AHB for Debugger System Access
    output wire [ 1:0] DBGD_M_HTRANS   , // AHB for Debugger System Access
    output wire        DBGD_M_HWRITE   , // AHB for Debugger System Access
    output wire        DBGD_M_HMASTLOCK, // AHB for Debugger System Access
    output wire [ 2:0] DBGD_M_HSIZE    , // AHB for Debugger System Access
    output wire [ 2:0] DBGD_M_HBURST   , // AHB for Debugger System Access
    output wire [ 3:0] DBGD_M_HPROT    , // AHB for Debugger System Access
    output wire [31:0] DBGD_M_HADDR    , // AHB for Debugger System Access
    output wire [31:0] DBGD_M_HWDATA   , // AHB for Debugger System Access
    output wire        DBGD_M_HREADY   , // AHB for Debugger System Access
    input  wire        DBGD_M_HREADYOUT, // AHB for Debugger System Access
    input  wire [31:0] DBGD_M_HRDATA   , // AHB for Debugger System Access
    input  wire        DBGD_M_HRESP    , // AHB for Debugger System Access
    //
    input  wire        IRQ_EXT,    // External Interrupt
    input  wire        IRQ_MSOFT,  // Machine SOftware Interrupt
    input  wire        IRQ_MTIME,  // Machine Timer Interrupt
    input  wire [63:0] IRQ,        // Interrupt Request    
    //
    input  wire [31:0] MTIME,  // Timer Counter LSB
    input  wire [31:0] MTIMEH, // Timer Counter MSB 
    output reg         DBG_STOP_TIMER  // Stop Timer due to Debug Mode
);

//----------------
// genvar
//----------------
genvar i;
integer x;

//------------------------
// Instruction Fetch Bus
//------------------------
wire        busi_m_req      [0 : HART_COUNT - 1]; // Bus Master Command Request
wire        busi_m_ack      [0 : HART_COUNT - 1]; // Bus Master Command Acknowledge
wire        busi_m_seq      [0 : HART_COUNT - 1]; // Bus Master Command Sequence
wire        busi_m_cont     [0 : HART_COUNT - 1]; // Bus Master Command Continuing
wire [ 2:0] busi_m_burst    [0 : HART_COUNT - 1]; // Bus Master Command Burst
wire        busi_m_lock     [0 : HART_COUNT - 1]; // Bus Master Command Lock
wire [ 3:0] busi_m_prot     [0 : HART_COUNT - 1]; // Bus Master Command Protect
wire        busi_m_write    [0 : HART_COUNT - 1]; // Bus Master Command Write (if 0, read)
wire [ 1:0] busi_m_size     [0 : HART_COUNT - 1]; // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
wire [31:0] busi_m_addr     [0 : HART_COUNT - 1]; // Bus Master Command Address
wire [31:0] busi_m_wdata    [0 : HART_COUNT - 1]; // Bus Master Command Write Data
wire        busi_m_last     [0 : HART_COUNT - 1]; // Bus Master Command Last Cycle
wire [31:0] busi_m_rdata    [0 : HART_COUNT - 1]; // Bus Master Command Read Data
reg  [ 3:0] busi_m_done     [0 : HART_COUNT - 1]; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE})
wire [31:0] busi_m_rdata_raw[0 : HART_COUNT - 1]; // Bus Master Command Read Data Unclocked
wire [ 3:0] busi_m_done_raw [0 : HART_COUNT - 1]; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked

//------------------------
// Data Access Bus
//------------------------
wire        busd_m_req      [0 : HART_COUNT - 1]; // Bus Master Command Request
wire        busd_m_ack      [0 : HART_COUNT - 1]; // Bus Master Command Acknowledge
wire        busd_m_seq      [0 : HART_COUNT - 1]; // Bus Master Command Sequence
wire        busd_m_cont     [0 : HART_COUNT - 1]; // Bus Master Command Continuing
wire [ 2:0] busd_m_burst    [0 : HART_COUNT - 1]; // Bus Master Command Burst
wire        busd_m_lock     [0 : HART_COUNT - 1]; // Bus Master Command Lock
wire [ 3:0] busd_m_prot     [0 : HART_COUNT - 1]; // Bus Master Command Protect
wire        busd_m_write    [0 : HART_COUNT - 1]; // Bus Master Command Write (if 0, read)
wire [ 1:0] busd_m_size     [0 : HART_COUNT - 1]; // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
wire [31:0] busd_m_addr     [0 : HART_COUNT - 1]; // Bus Master Command Address
wire [31:0] busd_m_wdata    [0 : HART_COUNT - 1]; // Bus Master Command Write Data
wire        busd_m_last     [0 : HART_COUNT - 1]; // Bus Master Command Last Cycle
wire [31:0] busd_m_rdata    [0 : HART_COUNT - 1]; // Bus Master Command Read Data
reg  [ 3:0] busd_m_done     [0 : HART_COUNT - 1]; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE})
wire [31:0] busd_m_rdata_raw[0 : HART_COUNT - 1]; // Bus Master Command Read Data Unclocked
wire [ 3:0] busd_m_done_raw [0 : HART_COUNT - 1]; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked

//--------------------------------
// Bus Monitor for LR/SC
//--------------------------------
wire        busm_s_req      [0 : HART_COUNT - 1]; // AHB Monitor for LR/SC
wire        busm_s_write    [0 : HART_COUNT - 1]; // AHB Monitor for LR/SC
wire [31:0] busm_s_addr     [0 : HART_COUNT - 1]; // AHB Monitor for LR/SC

//-----------------------------
// Debugger System Access Bus
//-----------------------------
wire        buss_m_req      ; // Bus Master Command Request
wire        buss_m_ack      ; // Bus Master Command Acknowledge
wire        buss_m_seq      ; // Bus Master Command Sequence
wire        buss_m_cont     ; // Bus Master Command Continuing
wire [ 2:0] buss_m_burst    ; // Bus Master Command Burst
wire        buss_m_lock     ; // Bus Master Command Lock
wire [ 3:0] buss_m_prot     ; // Bus Master Command Protect
wire        buss_m_write    ; // Bus Master Command Write (if 0, read)
wire [ 1:0] buss_m_size     ; // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
wire [31:0] buss_m_addr     ; // Bus Master Command Address
wire [31:0] buss_m_wdata    ; // Bus Master Command Write Data
wire        buss_m_last     ; // Bus Master Command Last Cycle
wire [31:0] buss_m_rdata    ; // Bus Master Command Read Data
reg  [ 3:0] buss_m_done     ; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE})
wire [31:0] buss_m_rdata_raw; // Bus Master Command Read Data Unclocked
wire [ 3:0] buss_m_done_raw ; // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked

//---------------
// Debug Module
//---------------
wire debug_mode[0 : HART_COUNT - 1]; // Debug Mode
//
wire hart_halt_req     [0 : HART_COUNT - 1]; // HART Halt Command
wire hart_status       [0 : HART_COUNT - 1]; // HART Status (0:Run, 1:Halt) 
wire hart_available    [0 : HART_COUNT - 1]; // HART Availability (eg. unavailabe if stby)
wire hart_reset        [0 : HART_COUNT - 1]; // HART Reset Signal    
wire hart_halt_on_reset[0 : HART_COUNT - 1]; // HART Halt on Reset
wire hart_resume_req   [0 : HART_COUNT - 1]; // HART Resume Request
wire hart_resume_ack   [0 : HART_COUNT - 1]; // HART Resume Acknowledge
//
wire        dbgabs_req  [0 : HART_COUNT - 1]; // Debug Abstract Command Request
wire        dbgabs_ack  [0 : HART_COUNT - 1]; // Debug Abstract Command Acknowledge
wire [ 1:0] dbgabs_type [0 : HART_COUNT - 1]; // Debug Abstract Command Type
wire        dbgabs_write[0 : HART_COUNT - 1]; // Debug Abstract Command Write (if 0, read)
wire [ 1:0] dbgabs_size [0 : HART_COUNT - 1]; // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
wire [31:0] dbgabs_addr [0 : HART_COUNT - 1]; // Debug Abstract Command Address
wire [31:0] dbgabs_wdata[0 : HART_COUNT - 1]; // Debug Abstract Command Write Data
wire [31:0] dbgabs_rdata[0 : HART_COUNT - 1]; // Debug Abstract Command Read Data
wire [ 3:0] dbgabs_done [0 : HART_COUNT - 1]; // Debug Abstract Command Done ({BUSERR, EXCEPT, WRITE, ACK})
//
wire dbg_stop_timer[0 : HART_COUNT - 1]; // Stop Timer due to Debug Mode
//
DEBUG_TOP
    #(
         .HART_COUNT(HART_COUNT)
    )
U_DEBUG_TOP
(
    .RES_ORG (RES_ORG),
    .RES_SYS (RES_SYS),
    .CLK (CLK),
    //
    .TRSTn     (TRSTn),
    .SRSTn_IN  (SRSTn_IN),
    .SRSTn_OUT (SRSTn_OUT),
    //
    .TCK (TCK),
    .TMS (TMS),
    .TDI (TDI),
    .TDO_D (TDO_D),
    .TDO_E (TDO_E),
    .RTCK  (RTCK),
    //
    .DEBUG_MODE (debug_mode),
    //
    .DEBUG_SECURE      (DEBUG_SECURE),
    .DEBUG_SECURE_CODE (DEBUG_SECURE_CODE),
    //
    .HART_HALT_REQ      (hart_halt_req),
    .HART_STATUS        (hart_status),
    .HART_AVAILABLE     (hart_available),
    .HART_RESET         (hart_reset),
    .HART_HALT_ON_RESET (hart_halt_on_reset),
    .HART_RESUME_REQ    (hart_resume_req),
    .HART_RESUME_ACK    (hart_resume_ack),
    //
    .DBGABS_REQ   (dbgabs_req),
    .DBGABS_ACK   (dbgabs_ack),
    .DBGABS_TYPE  (dbgabs_type),
    .DBGABS_WRITE (dbgabs_write),
    .DBGABS_SIZE  (dbgabs_size),
    .DBGABS_ADDR  (dbgabs_addr),
    .DBGABS_WDATA (dbgabs_wdata),
    .DBGABS_RDATA (dbgabs_rdata),
    .DBGABS_DONE  (dbgabs_done),
    //
    .BUSS_M_REQ   (buss_m_req),
    .BUSS_M_ACK   (buss_m_ack),
    .BUSS_M_SEQ   (buss_m_seq),
    .BUSS_M_CONT  (buss_m_cont),
    .BUSS_M_BURST (buss_m_burst),
    .BUSS_M_LOCK  (buss_m_lock),
    .BUSS_M_PROT  (buss_m_prot),
    .BUSS_M_WRITE (buss_m_write),
    .BUSS_M_SIZE  (buss_m_size),
    .BUSS_M_ADDR  (buss_m_addr),
    .BUSS_M_WDATA (buss_m_wdata),
    .BUSS_M_LAST  (buss_m_last),
    .BUSS_M_RDATA (buss_m_rdata),
    .BUSS_M_DONE  (buss_m_done),
    .BUSS_M_RDATA_RAW (buss_m_rdata_raw),
    .BUSS_M_DONE_RAW  (buss_m_done_raw)
);

//--------------
// CPU Cores
//--------------
generate
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin : U_CPU_TOP
        CPU_TOP U_CPU_TOP
        (
            .RES_SYS (RES_SYS),
            .CLK     (CLK),
            .STBY    (STBY),
            //
            .HART_ID      (i),
            .RESET_VECTOR (RESET_VECTOR[i]),
            //
            .DEBUG_MODE (debug_mode[i]),
            //
            .HART_HALT_REQ      (hart_halt_req[i]),
            .HART_STATUS        (hart_status[i]),
            .HART_AVAILABLE     (hart_available[i]),
            .HART_RESET         (hart_reset[i]),
            .HART_HALT_ON_RESET (hart_halt_on_reset[i]),
            .HART_RESUME_REQ    (hart_resume_req[i]),
            .HART_RESUME_ACK    (hart_resume_ack[i]),
            //
            .DBGABS_REQ   (dbgabs_req[i]),
            .DBGABS_ACK   (dbgabs_ack[i]),
            .DBGABS_TYPE  (dbgabs_type[i]),
            .DBGABS_WRITE (dbgabs_write[i]),
            .DBGABS_SIZE  (dbgabs_size[i]),
            .DBGABS_ADDR  (dbgabs_addr[i]),
            .DBGABS_WDATA (dbgabs_wdata[i]),
            .DBGABS_RDATA (dbgabs_rdata[i]),
            .DBGABS_DONE  (dbgabs_done[i]),
            //
            .BUSI_M_REQ   (busi_m_req[i]),
            .BUSI_M_ACK   (busi_m_ack[i]),
            .BUSI_M_SEQ   (busi_m_seq[i]),
            .BUSI_M_CONT  (busi_m_cont[i]),
            .BUSI_M_BURST (busi_m_burst[i]),
            .BUSI_M_LOCK  (busi_m_lock[i]),
            .BUSI_M_PROT  (busi_m_prot[i]),
            .BUSI_M_WRITE (busi_m_write[i]),
            .BUSI_M_SIZE  (busi_m_size[i]),
            .BUSI_M_ADDR  (busi_m_addr[i]),
            .BUSI_M_WDATA (busi_m_wdata[i]),
            .BUSI_M_LAST  (busi_m_last[i]),
            .BUSI_M_RDATA (busi_m_rdata[i]),
            .BUSI_M_DONE  (busi_m_done[i]),
            .BUSI_M_RDATA_RAW (busi_m_rdata_raw[i]),
            .BUSI_M_DONE_RAW  (busi_m_done_raw[i]),
            //
            .BUSD_M_REQ   (busd_m_req[i]),
            .BUSD_M_ACK   (busd_m_ack[i]),
            .BUSD_M_SEQ   (busd_m_seq[i]),
            .BUSD_M_CONT  (busd_m_cont[i]),
            .BUSD_M_BURST (busd_m_burst[i]),
            .BUSD_M_LOCK  (busd_m_lock[i]),
            .BUSD_M_PROT  (busd_m_prot[i]),
            .BUSD_M_WRITE (busd_m_write[i]),
            .BUSD_M_SIZE  (busd_m_size[i]),
            .BUSD_M_ADDR  (busd_m_addr[i]),
            .BUSD_M_WDATA (busd_m_wdata[i]),
            .BUSD_M_LAST  (busd_m_last[i]),
            .BUSD_M_RDATA (busd_m_rdata[i]),
            .BUSD_M_DONE  (busd_m_done[i]),
            .BUSD_M_RDATA_RAW (busd_m_rdata_raw[i]),
            .BUSD_M_DONE_RAW  (busd_m_done_raw[i]),
            //
            `ifdef RISCV_ISA_RV32A
            .BUSM_S_REQ   (busm_s_req[i]),
            .BUSM_S_WRITE (busm_s_write[i]),
            .BUSM_S_ADDR  (busm_s_addr[i]),
            `endif
            //
            .IRQ_EXT   (IRQ_EXT),
            .IRQ_MSOFT (IRQ_MSOFT),
            .IRQ_MTIME (IRQ_MTIME),
            .IRQ       (IRQ),
            //
            .MTIME          (MTIME),
            .MTIMEH         (MTIMEH),
            .DBG_STOP_TIMER (dbg_stop_timer[i])
        );
    end
endgenerate
//
// Treatment of DBG_STOP_TIMER
//
always @*
begin
    DBG_STOP_TIMER = 1'b0;
    for (x = 0; x < HART_COUNT; x = x + 1)
        DBG_STOP_TIMER = DBG_STOP_TIMER | dbg_stop_timer[x];
end

//--------------------------------------------------
// Bus Interface : AHB for CPU Instruction
//--------------------------------------------------
generate
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin : U_BUS_M_AHB_CPUI
        BUS_M_AHB U_BUS_M_AHB_CPUI
        (
            .RES_SYS (RES_SYS),
            .CLK     (CLK),
            //
            .BUS_M_REQ   (busi_m_req[i]),
            .BUS_M_ACK   (busi_m_ack[i]),
            .BUS_M_SEQ   (busi_m_seq[i]),
            .BUS_M_CONT  (busi_m_cont[i]),
            .BUS_M_BURST (busi_m_burst[i]),
            .BUS_M_LOCK  (busi_m_lock[i]),
            .BUS_M_PROT  (busi_m_prot[i]),
            .BUS_M_WRITE (busi_m_write[i]),
            .BUS_M_SIZE  (busi_m_size[i]),
            .BUS_M_ADDR  (busi_m_addr[i]),
            .BUS_M_WDATA (busi_m_wdata[i]),
            .BUS_M_LAST  (busi_m_last[i]),
            .BUS_M_RDATA (busi_m_rdata[i]),
            .BUS_M_DONE  (busi_m_done[i]),
            .BUS_M_RDATA_RAW (busi_m_rdata_raw[i]),
            .BUS_M_DONE_RAW  (busi_m_done_raw[i]),
            //
            .M_HSEL      (CPUI_M_HSEL[i]),
            .M_HTRANS    (CPUI_M_HTRANS[i]),
            .M_HWRITE    (CPUI_M_HWRITE[i]),
            .M_HMASTLOCK (CPUI_M_HMASTLOCK[i]),
            .M_HSIZE     (CPUI_M_HSIZE[i]),
            .M_HBURST    (CPUI_M_HBURST[i]),
            .M_HPROT     (CPUI_M_HPROT[i]),
            .M_HADDR     (CPUI_M_HADDR[i]),
            .M_HWDATA    (CPUI_M_HWDATA[i]),
            .M_HREADY    (CPUI_M_HREADY[i]),
            .M_HREADYOUT (CPUI_M_HREADYOUT[i]),
            .M_HRDATA    (CPUI_M_HRDATA[i]),
            .M_HRESP     (CPUI_M_HRESP[i])
        );
    end
endgenerate

//--------------------------------------------------
// Bus Interface : AHB for CPU Data
//--------------------------------------------------
generate
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin : U_BUS_M_AHB_CPUD
        BUS_M_AHB U_BUS_M_AHB_CPUD
        (
            .RES_SYS (RES_SYS),
            .CLK     (CLK),
            //
            .BUS_M_REQ   (busd_m_req[i]),
            .BUS_M_ACK   (busd_m_ack[i]),
            .BUS_M_SEQ   (busd_m_seq[i]),
            .BUS_M_CONT  (busd_m_cont[i]),
            .BUS_M_BURST (busd_m_burst[i]),
            .BUS_M_LOCK  (busd_m_lock[i]),
            .BUS_M_PROT  (busd_m_prot[i]),
            .BUS_M_WRITE (busd_m_write[i]),
            .BUS_M_SIZE  (busd_m_size[i]),
            .BUS_M_ADDR  (busd_m_addr[i]),
            .BUS_M_WDATA (busd_m_wdata[i]),
            .BUS_M_LAST  (busd_m_last[i]),
            .BUS_M_RDATA (busd_m_rdata[i]),
            .BUS_M_DONE  (busd_m_done[i]),
            .BUS_M_RDATA_RAW (busd_m_rdata_raw[i]),
            .BUS_M_DONE_RAW  (busd_m_done_raw[i]),
            //
            .M_HSEL      (CPUD_M_HSEL[i]),
            .M_HTRANS    (CPUD_M_HTRANS[i]),
            .M_HWRITE    (CPUD_M_HWRITE[i]),
            .M_HMASTLOCK (CPUD_M_HMASTLOCK[i]),
            .M_HSIZE     (CPUD_M_HSIZE[i]),
            .M_HBURST    (CPUD_M_HBURST[i]),
            .M_HPROT     (CPUD_M_HPROT[i]),
            .M_HADDR     (CPUD_M_HADDR[i]),
            .M_HWDATA    (CPUD_M_HWDATA[i]),
            .M_HREADY    (CPUD_M_HREADY[i]),
            .M_HREADYOUT (CPUD_M_HREADYOUT[i]),
            .M_HRDATA    (CPUD_M_HRDATA[i]),
            .M_HRESP     (CPUD_M_HRESP[i])
        );
    end
endgenerate

//--------------------------------------------------
// Bus Interface : AHB for Debugger System Access
//--------------------------------------------------
BUS_M_AHB U_BUS_M_AHB_DBGD
(
    .RES_SYS (RES_SYS),
    .CLK     (CLK),
    //
    .BUS_M_REQ   (buss_m_req),
    .BUS_M_ACK   (buss_m_ack),
    .BUS_M_SEQ   (buss_m_seq),
    .BUS_M_CONT  (buss_m_cont),
    .BUS_M_BURST (buss_m_burst),
    .BUS_M_LOCK  (buss_m_lock),
    .BUS_M_PROT  (buss_m_prot),
    .BUS_M_WRITE (buss_m_write),
    .BUS_M_SIZE  (buss_m_size),
    .BUS_M_ADDR  (buss_m_addr),
    .BUS_M_WDATA (buss_m_wdata),
    .BUS_M_LAST  (buss_m_last),
    .BUS_M_RDATA (buss_m_rdata),
    .BUS_M_DONE  (buss_m_done),
    .BUS_M_RDATA_RAW (buss_m_rdata_raw),
    .BUS_M_DONE_RAW  (buss_m_done_raw),
    //
    .M_HSEL      (DBGD_M_HSEL),
    .M_HTRANS    (DBGD_M_HTRANS),
    .M_HWRITE    (DBGD_M_HWRITE),
    .M_HMASTLOCK (DBGD_M_HMASTLOCK),
    .M_HSIZE     (DBGD_M_HSIZE),
    .M_HBURST    (DBGD_M_HBURST),
    .M_HPROT     (DBGD_M_HPROT),
    .M_HADDR     (DBGD_M_HADDR),
    .M_HWDATA    (DBGD_M_HWDATA),
    .M_HREADY    (DBGD_M_HREADY),
    .M_HREADYOUT (DBGD_M_HREADYOUT),
    .M_HRDATA    (DBGD_M_HRDATA),
    .M_HRESP     (DBGD_M_HRESP)
);

`ifdef RISCV_ISA_RV32A
//-----------------------------------
// Bus Interface : Monitor for LR/SC
//-----------------------------------
generate
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin : U_BUS_MONITOR
        assign busm_s_req[i] = CPUM_S_HSEL[i]   & CPUM_S_HTRANS[i][1]
                             & CPUM_S_HREADY[i] & CPUM_S_HREADYOUT[i];
        assign busm_s_write[i] = CPUM_S_HWRITE[i];
        assign busm_s_addr[i]  = CPUM_S_HADDR[i];
    end
endgenerate
`endif

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
