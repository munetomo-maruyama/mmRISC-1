//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_csr_dbg.v
// Description : CPU CSR for DEBUG (Control and Status Registers)
//-----------------------------------------------------------
// History :
// Rev.01 2020.08.02 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

// Trigger Module
//
// bit TRG_CND_BUS                   sizelo sel tim exe sto lod
//   0 Instruction 16bit Adrs Before 0 or 2  0   0   1   *   *
//   1 Instruction 16bit Adrs After  0 or 2  0   1   1   *   *
//   2 Instruction 16bit Insr Before 0 or 2  1   0   1   *   *
//   3 Instruction 16bit Insr After  0 or 2  1   1   1   *   *
//   4 Instruction 32bit Adrs Before 0 or 3  0   0   1   *   *
//   5 Instruction 32bit Adrs After  0 or 3  0   1   1   *   *
//   6 Instruction 32bit Insr Before 0 or 3  1   0   1   *   *
//   7 Instruction 32bit Insr After  0 or 3  1   1   1   *   *
//   8 Data Access  8bit Adrs Read   0 or 1  0   *   *   *   1
//   9 Data Access  8bit Adrs Write  0 or 1  0   *   *   1   *
//  10 Data Access  8bit Data Read   0 or 1  1   *   *   *   1
//  11 Data Access  8bit Data Write  0 or 1  1   *   *   1   *
//  12 Data Access 16bit Adrs Read   0 or 2  0   *   *   *   1
//  13 Data Access 16bit Adrs Write  0 or 2  0   *   *   1   *
//  14 Data Access 16bit Data Read   0 or 2  1   *   *   *   1
//  15 Data Access 16bit Data Write  0 or 2  1   *   *   1   *
//  16 Data Access 32bit Adrs Read   0 or 3  0   *   *   *   1
//  17 Data Access 32bit Adrs Write  0 or 3  0   *   *   1   *
//  18 Data Access 32bit Data Read   0 or 3  1   *   *   *   1
//  19 Data Access 32bit Data Write  0 or 3  1   *   *   1   *
//
// Trigger Bus Conditions below are ORed.
//     TRG_CND_BUS[0][19:0] {20'b0000....0001} ORed
//     TRG_CND_BUS[1][19:0] {20'b0000....1110} ORed
//     TRG_CND_BUS[2][19:0] {20'b0000....1100} ORed
//     TRG_CND_BUS[3][19:0] {20'b0000....0011} ORed
//
// Trigger Bus Condition chained (ANDed)
//     TRG_CND_BUS_CHAIN[0] {4'b0001} Single [0]
//     TRG_CND_BUS_CHAIN[1] {4'b0010} Single [1]
//     TRG_CND_BUS_CHAIN[2] {4'b0000} none
//     TRG_CND_BUS_CHAIN[3] {4'b1100} ANDed [2]&[3]
//
// Trigger Event Conditions
// bit TRG_CND_CNT
//   0 Instruction Count Trigger
//   1 Interrupt Trigger (Reserved)
//   2 Exception Trigger (Reserved)
//
//-----------------------------------------------
// Output Information
//     TRG_CND_BUS[0...3][19:0] Trigger Bus Conditions
//     TRG_CND_BUS_CHAIN[7:0] Designates chained (ANDed) conditions
//     TRG_CND_BUS_ACTION[0...7] Enter to BRK or DEBUG_MODE
//         [Note] All bits in the signal within same chain group
//                has a same value of the last chain.
//     TRG_CND_BUS_MATCH[0...7]
//     TRG_CND_BUS_MASK[0...7] made from maskmax and tdata2
//     TRG_CND_CNT[0...7][2:0] Trigger Event Conditions
//     TRG_CND_CNT_ACTION[0...7] Enter to BRK or DEBUG_MODE
//     TRG_CND_TDATA2[0...7]
//
// Input Information
//     DEBUG_MODE  Debug Mode or else
//     TRG_CND_BUS_HIT[0...7]
//     TRG_CND_CNT_HIT[0...7]
//
// Not Implemented
//     Interrupt Trigger, Exception Trigger
//     Trigger Data 3, Trigger Extra

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_CSR_DBG
(
    input  wire RES_SYS,  // System Reset
    output wire RES_CPU,  // CPU Reset
    input  wire CLK,      // System Clock
    input  wire STBY_ACK, // System Stand-by Acknowledge
    //
    input  wire HART_HALT_REQ,      // HART Halt Command
    output reg  HART_STATUS,        // HART Status (0:Run, 1:Halt) 
    input  wire HART_RESET,         // HART Reset Signal
    input  wire HART_HALT_ON_RESET, // HART Halt on Reset Request    
    input  wire HART_RESUME_REQ,    // HART Resume Request
    output reg  HART_RESUME_ACK,    // HART Resume Acknowledge
    output wire HART_AVAILABLE,     // HART_Available
    //
    input  wire        CSR_DBG_DBG_REQ,
    input  wire        CSR_DBG_DBG_WRITE,
    input  wire [11:0] CSR_DBG_DBG_ADDR,
    input  wire [31:0] CSR_DBG_DBG_WDATA,
    output wire [31:0] CSR_DBG_DBG_RDATA,
    input  wire        CSR_DBG_CPU_REQ,
    input  wire        CSR_DBG_CPU_WRITE,
    input  wire [11:0] CSR_DBG_CPU_ADDR,
    input  wire [31:0] CSR_DBG_CPU_WDATA,
    output wire [31:0] CSR_DBG_CPU_RDATA,
    //
    output wire        DBG_STOP_COUNT, // Stop Counter due to Debug Mode
    output wire        DBG_STOP_TIMER, // Stop Timer due to Debug Mode
    output wire        DBG_MIE_STEP,   // Master Interrupt Enable during Step
    //
    output reg         DBG_HALT_REQ,    // HALT Request
    input  wire        DBG_HALT_ACK,    // HALT Acknowledge
    output wire        DBG_HALT_RESET,  // HALT when Reset
    output wire        DBG_HALT_EBREAK, // HALT when EBREAK
    output reg         DBG_RESUME_REQ,  // Resume Request 
    input  wire        DBG_RESUME_ACK,  // Resume Acknowledge 
    input  wire [31:0] DBG_DPC_SAVE,    // Debug PC to be saved
    output wire [31:0] DBG_DPC_LOAD,    // Debug PC to be loaded
    input  wire [ 2:0] DBG_CAUSE,       // Debug Entry Cause
    //
    input  wire        INSTR_EXEC, // Instruction Retired
    //
    output reg  [19:0]            TRG_CND_BUS        [0:`TRG_CH_BUS-1],
    output reg  [`TRG_CH_BUS-1:0] TRG_CND_BUS_CHAIN  [0:`TRG_CH_BUS-1],
    output reg                    TRG_CND_BUS_ACTION [0:`TRG_CH_BUS-1],
    output reg  [ 3:0]            TRG_CND_BUS_MATCH  [0:`TRG_CH_BUS-1],
    output reg  [31:0]            TRG_CND_BUS_MASK   [0:`TRG_CH_BUS-1],
    input  wire                   TRG_CND_BUS_HIT    [0:`TRG_CH_BUS-1],
    output reg  [31:0]            TRG_CND_TDATA2     [0:`TRG_CH_BUS-1],
    output reg                    TRG_CND_ICOUNT_HIT,
    output reg                    TRG_CND_ICOUNT_ACT,
    input  wire                   TRG_CND_ICOUNT_DEC
);

//--------------
// CPU Reset
//--------------
assign RES_CPU = RES_SYS | HART_RESET;

//----------------------
// Interface to DM
//----------------------
reg hart_halt_req_delay;
reg hart_resume_req_delay;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        hart_halt_req_delay   <= 1'b0;
        hart_resume_req_delay <= 1'b0;
    end
    else
    begin
        hart_halt_req_delay   <= HART_HALT_REQ;
        hart_resume_req_delay <= HART_RESUME_REQ;
    end
end
//
`ifdef UNAVAILABLE_WHEN_STBY
assign HART_AVAILABLE = ~STBY_ACK;
`else
assign HART_AVAILABLE = 1'b1;
`endif
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        HART_STATUS <= 1'b0;
    else if (DBG_HALT_ACK)
        HART_STATUS <= 1'b1;
    else if (DBG_RESUME_ACK)
        HART_STATUS <= 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        HART_RESUME_ACK <= 1'b0;
    else if (DBG_RESUME_ACK)
        HART_RESUME_ACK <= 1'b1;
    else if (HART_RESUME_REQ & ~hart_resume_req_delay) // rising edge
        HART_RESUME_ACK <= 1'b0;
end

//--------------------
// Debug Control
//--------------------
reg         csr_dcsr_ebreakm;
reg         csr_dcsr_stepie;
reg         csr_dcsr_stopcount; // mcycle and minstret
reg         csr_dcsr_stoptime;  // other counters
reg         csr_dcsr_step;
//
reg         debug_mode;
reg  [ 2:0] dbg_cause_modify;
//
assign DBG_HALT_RESET  = HART_HALT_ON_RESET;
assign DBG_HALT_EBREAK = csr_dcsr_ebreakm;
assign DBG_STOP_COUNT  = csr_dcsr_stopcount & debug_mode;
assign DBG_STOP_TIMER  = csr_dcsr_stoptime & debug_mode;
assign DBG_MIE_STEP    = (csr_dcsr_step)? csr_dcsr_stepie : 1'b1;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        DBG_HALT_REQ <= 1'b0;
    else if (HART_HALT_REQ & ~hart_halt_req_delay) // rising edge
        DBG_HALT_REQ <= 1'b1;
    else if (~DBG_HALT_REQ & csr_dcsr_step & INSTR_EXEC) // step
        DBG_HALT_REQ <= 1'b1;
    else if (DBG_HALT_ACK)
        DBG_HALT_REQ <= 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        DBG_RESUME_REQ <= 1'b0;
    else if (HART_RESUME_REQ & ~hart_resume_req_delay) // rising edge
        DBG_RESUME_REQ <= 1'b1;
    else if (DBG_RESUME_ACK)
        DBG_RESUME_REQ <= 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        debug_mode <= 1'b0;
    else if (DBG_HALT_ACK)
        debug_mode <= 1'b1;
    else if (DBG_RESUME_ACK & ~csr_dcsr_step)
        debug_mode <= 1'b0;
end
//
always @*
begin
    casez (DBG_CAUSE)
        `DBG_CAUSE_BREAKPOINT: dbg_cause_modify = DBG_CAUSE;
        `DBG_CAUSE_EBRREK    : dbg_cause_modify = DBG_CAUSE;
        `DBG_CAUSE_RESETHALT : dbg_cause_modify = DBG_CAUSE;
        `DBG_CAUSE_HALTREQ   : dbg_cause_modify 
            = (csr_dcsr_step)? `DBG_CAUSE_STEPREQ : DBG_CAUSE;
        default : dbg_cause_modify = 3'b000;
    endcase
end

//-------------------------
// CSR Write Access
//-------------------------
wire   csr_dbg_dbg_we;
wire   csr_dbg_cpu_we;
assign csr_dbg_dbg_we = CSR_DBG_DBG_REQ & CSR_DBG_DBG_WRITE;
assign csr_dbg_cpu_we = CSR_DBG_CPU_REQ & CSR_DBG_CPU_WRITE;
//
wire csr_dbg_dbg_we_dcsr;
wire csr_dbg_dbg_we_dpc;
wire csr_dbg_dbg_we_tselect;
wire csr_dbg_dbg_we_tdata1;
wire csr_dbg_dbg_we_tdata2;
wire csr_dbg_cpu_we_dcsr;
wire csr_dbg_cpu_we_dpc;
wire csr_dbg_cpu_we_tselect;
wire csr_dbg_cpu_we_tdata1;
wire csr_dbg_cpu_we_tdata2;
//
assign csr_dbg_dbg_we_dcsr    = csr_dbg_dbg_we & (CSR_DBG_DBG_ADDR == `CSR_DCSR);
assign csr_dbg_dbg_we_dpc     = csr_dbg_dbg_we & (CSR_DBG_DBG_ADDR == `CSR_DPC);
assign csr_dbg_dbg_we_tselect = csr_dbg_dbg_we & (CSR_DBG_DBG_ADDR == `CSR_TSELECT);
assign csr_dbg_dbg_we_tdata1  = csr_dbg_dbg_we & (CSR_DBG_DBG_ADDR == `CSR_TDATA1);
assign csr_dbg_dbg_we_tdata2  = csr_dbg_dbg_we & (CSR_DBG_DBG_ADDR == `CSR_TDATA2);
assign csr_dbg_cpu_we_dcsr    = csr_dbg_cpu_we & (CSR_DBG_CPU_ADDR == `CSR_DCSR);
assign csr_dbg_cpu_we_dpc     = csr_dbg_cpu_we & (CSR_DBG_CPU_ADDR == `CSR_DPC);
assign csr_dbg_cpu_we_tselect = csr_dbg_cpu_we & (CSR_DBG_CPU_ADDR == `CSR_TSELECT);
assign csr_dbg_cpu_we_tdata1  = csr_dbg_cpu_we & (CSR_DBG_CPU_ADDR == `CSR_TDATA1);
assign csr_dbg_cpu_we_tdata2  = csr_dbg_cpu_we & (CSR_DBG_CPU_ADDR == `CSR_TDATA2);

//------------------
// CSR DCSR
//------------------
wire [ 3:0] csr_dcsr_xdebugver; // tied to 4
wire        csr_dcsr_ebreaks; // tied to zero
wire        csr_dcsr_ebreaku; // tied to zero
reg  [ 2:0] csr_dcsr_cause;
wire        csr_dcsr_mprven; // tied to zero
wire        csr_dcsr_nmip;   // tied to zero
wire [ 1:0] csr_dcsr_prv;   // tied to 3 (M-Mode)
//
assign csr_dcsr_xdebugver = 4'b0100;
assign csr_dcsr_ebreaks   = 1'b0;
assign csr_dcsr_ebreaku   = 1'b0;
assign csr_dcsr_mprven    = 1'b0;
assign csr_dcsr_nmip      = 1'b0;
assign csr_dcsr_prv       = 2'b11;
//
// csr_dcsr_ebreakm
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dcsr_ebreakm <= 1'b0;
    end
    else if (csr_dbg_dbg_we_dcsr) // write from debug
    begin
        csr_dcsr_ebreakm <= CSR_DBG_DBG_WDATA[15]; 
    end
    else if (csr_dbg_cpu_we_dcsr) // write from cpu
    begin
        csr_dcsr_ebreakm <= CSR_DBG_CPU_WDATA[15]; 
    end
end
//
// csr_dcsr_stepie
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dcsr_stepie <= 1'b0;
    end
    else if (csr_dbg_dbg_we_dcsr)
    begin
        csr_dcsr_stepie <= CSR_DBG_DBG_WDATA[11]; 
    end
    else if (csr_dbg_cpu_we_dcsr)
    begin
        csr_dcsr_stepie <= CSR_DBG_CPU_WDATA[11]; 
    end
end
//
// csr_dcsr_stopcount, csr_dcsr_stoptime
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dcsr_stopcount <= 1'b0;
        csr_dcsr_stoptime  <= 1'b0;
    end
    else if (csr_dbg_dbg_we_dcsr)
    begin
        csr_dcsr_stopcount <= CSR_DBG_DBG_WDATA[10]; 
        csr_dcsr_stoptime  <= CSR_DBG_DBG_WDATA[ 9]; 
    end
    else if (csr_dbg_cpu_we_dcsr)
    begin
        csr_dcsr_stopcount <= CSR_DBG_CPU_WDATA[10]; 
        csr_dcsr_stoptime  <= CSR_DBG_CPU_WDATA[ 9]; 
    end
end
//
// csr_dcsr_cause
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dcsr_cause <= 3'b000;
    end
    else if (DBG_HALT_ACK)
    begin
        csr_dcsr_cause <= dbg_cause_modify; 
    end
end
//
// csr_dcsr_step
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dcsr_step <= 1'b0;
    end
    else if (csr_dbg_dbg_we_dcsr)
    begin
        csr_dcsr_step <= CSR_DBG_DBG_WDATA[2]; 
    end
    else if (csr_dbg_cpu_we_dcsr)
    begin
        csr_dcsr_step <= CSR_DBG_CPU_WDATA[2]; 
    end
end
//
// Read Data of CSR_DCSR
wire [31:0] csr_rdata_dcsr;
assign csr_rdata_dcsr = 
          {csr_dcsr_xdebugver, 12'h000,
           csr_dcsr_ebreakm, 1'b0, csr_dcsr_ebreaks, csr_dcsr_ebreaku,
           csr_dcsr_stepie, csr_dcsr_stopcount, csr_dcsr_stoptime,
           csr_dcsr_cause, 1'b0, csr_dcsr_mprven, csr_dcsr_nmip,
           csr_dcsr_step, csr_dcsr_prv};

//-----------------
// CSR DPC
//-----------------
reg  [31:0] csr_dpc;
assign DBG_DPC_LOAD = csr_dpc;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_dpc <= 32'h00000000;
    end
    else if (csr_dbg_dbg_we_dpc)
    begin
        csr_dpc <= CSR_DBG_DBG_WDATA; 
    end
    else if (csr_dbg_cpu_we_dpc)
    begin
        csr_dpc <= CSR_DBG_CPU_WDATA; 
    end
    else if (DBG_HALT_ACK)
    begin
        csr_dpc <= DBG_DPC_SAVE; 
    end
end
//
// Read Data of CSR_DPC
wire [31:0] csr_rdata_dpc;
assign csr_rdata_dpc = csr_dpc;

//------------------
// CSR TSELECT
//------------------
reg [`TRG_CH_ALL_BIT-1:0] csr_tselect;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_tselect <= {(`TRG_CH_ALL_BIT){1'b0}};
    end
    else if (csr_dbg_dbg_we_tselect)
    begin
        if (CSR_DBG_DBG_WDATA < `TRG_CH_ALL) csr_tselect <= CSR_DBG_DBG_WDATA[`TRG_CH_ALL_BIT-1:0];
    end
    else if (csr_dbg_cpu_we_tselect)
    begin
        if (CSR_DBG_CPU_WDATA < `TRG_CH_ALL) csr_tselect <= CSR_DBG_CPU_WDATA[`TRG_CH_ALL_BIT-1:0];
    end
end
//
// Read Data of CSR_TSELECT
wire [31:0] csr_rdata_tselect;
assign csr_rdata_tselect = {{(32-`TRG_CH_ALL_BIT){1'b0}}, csr_tselect};

//-----------------
// CSR TINFO
//-----------------
// Read Data of CSR_TINFO
wire [31:0] csr_rdata_tinfo;
assign csr_rdata_tinfo
    = (csr_tselect <  `TRG_CH_BUS)? 32'h00000004  // type 2 (mcontrol)
    : (csr_tselect == `TRG_CH_BUS)? 32'h00000008  // type 3 (icount)
    : 32'h00000001; // type 0 (no trigger)

//------------------
// CSR TDATA1
//------------------
reg         csr_tdata1_dmode [0:`TRG_CH_ALL-1];
reg  [26:0] csr_mcontrol     [0:`TRG_CH_BUS-1];
reg  [26:0] csr_icount;
reg  [13:0] csr_icount_count;
reg  [13:0] csr_icount_reload;
//
// dmode
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0; i < `TRG_CH_ALL; i = i + 1)
        begin
            csr_tdata1_dmode[i] <= 1'b0;
        end
    end
    else if (csr_dbg_dbg_we_tdata1)
    begin
        csr_tdata1_dmode[csr_tselect] <= CSR_DBG_DBG_WDATA[27];
    end
    else if (csr_dbg_cpu_we_tdata1)
    begin
        csr_tdata1_dmode[csr_tselect] <= CSR_DBG_CPU_WDATA[27];
    end
//  else if (csr_dbg_dbg_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[csr_tselect]))
//  begin
//      if (debug_mode) csr_tdata1_dmode[csr_tselect] <= CSR_DBG_DBG_WDATA[27];
//  end
//  else if (csr_dbg_cpu_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[csr_tselect]))
//  begin
//      if (debug_mode) csr_tdata1_dmode[csr_tselect] <= CSR_DBG_CPU_WDATA[27];
//  end
end
//
// MCONTROL
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            csr_mcontrol[i] <= 27'h0;
        end
    end
    else
    begin
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            if (i == csr_tselect)
            begin
                if (csr_dbg_dbg_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[i]))
                begin
                    csr_mcontrol[i] <= CSR_DBG_DBG_WDATA[26: 0];        
                end
                else if (csr_dbg_cpu_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[i]))
                begin
                    csr_mcontrol[i] <= CSR_DBG_CPU_WDATA[26: 0];        
                end
                else if (TRG_CND_BUS_HIT[i] & csr_mcontrol[i][6]) // m
                begin
                    csr_mcontrol[i][20] <= 1'b1; // hit
                end
            end
            else
            begin
                if (TRG_CND_BUS_HIT[i] & csr_mcontrol[i][6]) // m
                begin
                    csr_mcontrol[i][20] <= 1'b1; // hit
                end
            end
        end
    end
end
//
// ICOUNT
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_icount        <= 27'h0;
        csr_icount_count  <= 14'h0;
        csr_icount_reload <= 14'h0;
    end
    else if ((csr_tselect == (`TRG_CH_ALL - 1)) & csr_dbg_dbg_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[`TRG_CH_ALL - 1]))
    begin
        csr_icount        <= CSR_DBG_DBG_WDATA[26: 0];
        csr_icount_count  <= CSR_DBG_DBG_WDATA[23:10];
        csr_icount_reload <= CSR_DBG_DBG_WDATA[23:10];
    end
    else if ((csr_tselect == (`TRG_CH_ALL - 1)) & csr_dbg_cpu_we_tdata1 & (debug_mode | ~csr_tdata1_dmode[`TRG_CH_ALL - 1]))
    begin
        csr_icount        <= CSR_DBG_CPU_WDATA[26: 0];
        csr_icount_count  <= CSR_DBG_CPU_WDATA[23:10];
        csr_icount_reload <= CSR_DBG_CPU_WDATA[23:10];
    end
    else if (TRG_CND_ICOUNT_HIT) // m
    begin
        csr_icount[24]   <= 1'b1; // hit
        csr_icount_count <= csr_icount_reload;
    end
    else if (~csr_icount[24] & TRG_CND_ICOUNT_DEC & csr_icount[9]) // m
    begin
        csr_icount_count <= csr_icount_count - 14'h1;
    end
end
//
// ICOUNT Hit
always @*
begin
    TRG_CND_ICOUNT_HIT = ~csr_icount[24] & csr_icount[9] & (csr_icount_count == 14'h0); // m
    TRG_CND_ICOUNT_ACT = csr_icount[0] & csr_tdata1_dmode[`TRG_CH_ALL - 1];
  //TRG_CND_ICOUNT_ACT = csr_icount[0];
end
//
// Read Data of CSR_TDATA1
wire [31:0] csr_rdata_tdata1;
assign csr_rdata_tdata1
    = (csr_tselect <  (`TRG_CH_ALL - 1))? {4'h2, csr_tdata1_dmode[csr_tselect], 
                                           6'h20, // maskmax = 32
                                           csr_mcontrol[csr_tselect][20:6],
                                           1'b0,
                                           csr_mcontrol[csr_tselect][ 4:0]}
    : (csr_tselect == (`TRG_CH_ALL - 1))? {4'h3, csr_tdata1_dmode[csr_tselect], 
                                           2'b00,
                                           csr_icount[24],
                                           csr_icount_count,
                                           csr_icount[9],
                                           1'b0,
                                           csr_icount[7:0]}
    : 32'h00000000;

//------------------
// CSR TDATA2
//------------------
reg [31:0] csr_tdata2[0:`TRG_CH_BUS-1];
//
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            csr_tdata2[i]  <= 32'h0;
        end
    end
    else if (csr_dbg_dbg_we_tdata2)
    begin
        csr_tdata2[csr_tselect] <= CSR_DBG_DBG_WDATA;
    end
    else if (csr_dbg_cpu_we_tdata2)
    begin
        csr_tdata2[csr_tselect] <= CSR_DBG_CPU_WDATA;
    end
end
//
// Read Data of CSR_TDATA2
wire [31:0] csr_rdata_tdata2;
assign csr_rdata_tdata2
    = (csr_tselect < `TRG_CH_BUS)? csr_tdata2[csr_tselect] : 32'h00000000;
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        TRG_CND_TDATA2[i] = csr_tdata2[i];
    end    
end

//----------------------------
// TRG_CND_BUS
//----------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            TRG_CND_BUS[i] <= 0;
        end    
    end
    else
    begin
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            // bit TRG_CND_BUS                   sizelo sel tim exe sto lod
            //   0 Instruction 16bit Adrs Before 0 or 2  0   0   1   *   *
            //   1 Instruction 16bit Adrs After  0 or 2  0   1   1   *   *
            //   2 Instruction 16bit Insr Before 0 or 2  1   0   1   *   *
            //   3 Instruction 16bit Insr After  0 or 2  1   1   1   *   *
            TRG_CND_BUS[i][ 0] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][18] == 1'b0)  // timing=0
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 1] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][18] == 1'b1)  // timing=1
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 2] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][18] == 1'b0)  // timing=0
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 3] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][18] == 1'b1)  // timing=1
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            // bit TRG_CND_BUS                   sizelo sel tim exe sto lod
            //   4 Instruction 32bit Adrs Before 0 or 3  0   0   1   *   *
            //   5 Instruction 32bit Adrs After  0 or 3  0   1   1   *   *
            //   6 Instruction 32bit Insr Before 0 or 3  1   0   1   *   *
            //   7 Instruction 32bit Insr After  0 or 3  1   1   1   *   *
            TRG_CND_BUS[i][ 4] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][18] == 1'b0)  // timing=0
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 5] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][18] == 1'b1)  // timing=1
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 6] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][18] == 1'b0)  // timing=0
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            TRG_CND_BUS[i][ 7] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][18] == 1'b1)  // timing=1
                                & (csr_mcontrol[i][ 2] == 1'b1); // execute=1
            // bit TRG_CND_BUS                   sizelo sel tim exe sto lod
            //   8 Data Access  8bit Adrs Read   0 or 1  0   *   *   *   1
            //   9 Data Access  8bit Adrs Write  0 or 1  0   *   *   1   *
            //  10 Data Access  8bit Data Read   0 or 1  1   *   *   *   1
            //  11 Data Access  8bit Data Write  0 or 1  1   *   *   1   *
            TRG_CND_BUS[i][ 8] <= (csr_mcontrol[i][17] == 1'b0)  // sizelo=0or1
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][ 9] <= (csr_mcontrol[i][17] == 1'b0)  // sizelo=0or1
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
            TRG_CND_BUS[i][10] <= (csr_mcontrol[i][17] == 1'b0)  // sizelo=0or1
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][11] <= (csr_mcontrol[i][17] == 1'b0)  // sizelo=0or1
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
            // bit TRG_CND_BUS                   sizelo sel tim exe sto lod
            //  12 Data Access 16bit Adrs Read   0 or 2  0   *   *   *   1
            //  13 Data Access 16bit Adrs Write  0 or 2  0   *   *   1   *
            //  14 Data Access 16bit Data Read   0 or 2  1   *   *   *   1
            //  15 Data Access 16bit Data Write  0 or 2  1   *   *   1   *
            TRG_CND_BUS[i][12] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][13] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
            TRG_CND_BUS[i][14] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][15] <= (csr_mcontrol[i][16] == 1'b0)  // sizelo=0or2
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
            // bit TRG_CND_BUS                   sizelo sel tim exe sto lod
            //  16 Data Access 32bit Adrs Read   0 or 3  0   *   *   *   1
            //  17 Data Access 32bit Adrs Write  0 or 3  0   *   *   1   *
            //  18 Data Access 32bit Data Read   0 or 3  1   *   *   *   1
            //  19 Data Access 32bit Data Write  0 or 3  1   *   *   1   *
            TRG_CND_BUS[i][16] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][17] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b0)  // select=0
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
            TRG_CND_BUS[i][18] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 0] == 1'b1); // load=1
            TRG_CND_BUS[i][19] <= (^csr_mcontrol[i][17:16] == 1'b0)  // sizelo=0or3
                                & (csr_mcontrol[i][19] == 1'b1)  // select=1
                                & (csr_mcontrol[i][ 1] == 1'b1); // store=1
        end
    end
end

//----------------------------
// TRG_CND_BUS_CHAIN
//----------------------------
// In the case `TRG_CH_BUS = 8.
// chain    00111010   00111010  00111010  00111010  00111010  00111010  00111010  00111010  00111010
// CHAIN[0] 10000000   1          .          .          .          .          .          .          .
// CHAIN[1] 01000000   0          1          .          .          .          .          .          .
// CHAIN[2] 00000000   0          0          0          .          .          .          .          .
// CHAIN[3] 00000000   0          0          0          0          .          .          .          .
// CHAIN[4] 00000000   0          0          0          0          0          .          .          .
// CHAIN[5] 00111100   0          0          1          1          1          1          .          .
// CHAIN[6] 00000000   0          0          0          0          0          0          0          .
// CHAIN[7] 00000011   0          0          0          0          0          0          1          1
//
reg  [`TRG_CH_BUS-1:0] trg_cnd_bus_chain_temp[0:`TRG_CH_BUS-1];
//
//always @*
//begin
//    integer c, b;
//    for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
//    begin
//        trg_cnd_bus_chain_temp[c] = 0; // 00000000
//    end
//    //
//    for (b = 0;  b < `TRG_CH_BUS; b = b + 1)
//    begin: LOOP_TRG_CND_BUS_CHAIN
//        for (c = b;  c < `TRG_CH_BUS; c = c + 1)
//         begin 
//             if (csr_mcontrol[c][11] == 1'b0) // chain=0
//             begin
//                 trg_cnd_bus_chain_temp[c][b] = 1'b1;
//                 disable LOOP_TRG_CND_BUS_CHAIN; // break for c loop
//             end
//         end    
//    end
//end
always @*
begin
    integer c, b;
    for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
    begin
        trg_cnd_bus_chain_temp[c] = 0; // 00000000
    end
    //
    for (b = 0;  b < `TRG_CH_BUS; b = b + 1)
    begin: LOOP_TRG_CND_BUS_CHAIN
        reg disable_LOOP_TRG_CND_BUS_CHAIN;
        disable_LOOP_TRG_CND_BUS_CHAIN = 1'b0;
        for (c = b;  c < `TRG_CH_BUS; c = c + 1)
        begin
            if (!disable_LOOP_TRG_CND_BUS_CHAIN)
            begin
                if (csr_mcontrol[c][11] == 1'b0) // chain=0
                begin
                    trg_cnd_bus_chain_temp[c][b] = 1'b1;
                    disable_LOOP_TRG_CND_BUS_CHAIN = 1'b1; // break for c loop
                end
            end
        end    
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    integer c, b;
    if (RES_CPU)
    begin
        for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
        begin
            TRG_CND_BUS_CHAIN[c] <= 0; // 00000000
        end
    end
    else
    begin
        for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
        begin
            TRG_CND_BUS_CHAIN[c] <= trg_cnd_bus_chain_temp[c];
        end    
    end
end

//------------------------
// TRG_CND_BUS_ACTION
//------------------------
// [Note] All bits in TRG_CND_BUS_ACTION[...] within same chain group
//        has a same value of the last chain.
// In the case `TRG_CH_BUS = 8.
// chain    00111010
// action   abcdefgh
// CHAIN[0] 10000000 : temp[0] aaaaaaaa
// CHAIN[1] 01000000 : temp[1] bbbbbbbb
// CHAIN[2] 00000000 : temp[2] cccccccc
// CHAIN[3] 00000000 : temp[3] dddddddd
// CHAIN[4] 00111000 : temp[4] eeeeeeee
// CHAIN[5] 00000100 : temp[5] ffffffff
// CHAIN[6] 00000000 : temp[6] gggggggg
// CHAIN[7] 00000011 : temp[7] hhhhhhhh
// ACTION[] abfffghh
reg [`TRG_CH_BUS-1:0] trg_cnd_bus_action_temp[0:`TRG_CH_BUS-1];
//
always @*
begin
    integer b, c;
    for (c = 0; c < `TRG_CH_BUS; c = c + 1)
    begin
        trg_cnd_bus_action_temp[c] = 0;
        for (b = 0; b < `TRG_CH_BUS; b = b + 1)
        begin
            trg_cnd_bus_action_temp[c]
            = trg_cnd_bus_action_temp[c]
            | ((csr_mcontrol[c][15:12] == 4'h1) << b); // action = 1
        end
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    integer c;
    if (RES_CPU)
    begin
        for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
        begin
            TRG_CND_BUS_ACTION[c] <= 1'b0;
        end
    end
    else
    begin
        for (c = 0;  c < `TRG_CH_BUS; c = c + 1)
        begin
          //TRG_CND_BUS_ACTION[c] <= trg_cnd_bus_chain_temp[c][c] & trg_cnd_bus_action_temp[c][c];
            if (csr_tdata1_dmode[c])
                TRG_CND_BUS_ACTION[c] <= trg_cnd_bus_chain_temp[c][c] & trg_cnd_bus_action_temp[c][c];
            else
                TRG_CND_BUS_ACTION[c] <= 1'b0;
        end    
    end
end

//-------------------------
// TRG_CND_BUS_MATCH
//-------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0;  i < `TRG_CH_BUS; i = i + 1)
        begin
            TRG_CND_BUS_MATCH[i] <= 0; //0000
        end
    end
    else
    begin
        for (i = 0;  i < `TRG_CH_BUS; i = i + 1)
        begin
            TRG_CND_BUS_MATCH[i] <= csr_mcontrol[i][10:7];
        end
    end
end

//-------------------------
// TRG_CND_BUS_MASK
//-------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    if (RES_CPU)
    begin
        for (i = 0;  i < `TRG_CH_BUS; i = i + 1)
        begin
            TRG_CND_BUS_MASK[i] <= 0; //32'h0    
        end
    end
    else
    begin
        for (i = 0;  i < `TRG_CH_BUS; i = i + 1)
        begin
            casez(csr_tdata2[i])
                32'b????_????_????_????_????_????_????_???0 : TRG_CND_BUS_MASK[i] <= 32'hfffffffe;
                32'b????_????_????_????_????_????_????_??01 : TRG_CND_BUS_MASK[i] <= 32'hfffffffc;
                32'b????_????_????_????_????_????_????_?011 : TRG_CND_BUS_MASK[i] <= 32'hfffffff8;
                32'b????_????_????_????_????_????_????_0111 : TRG_CND_BUS_MASK[i] <= 32'hfffffff0;
                32'b????_????_????_????_????_????_???0_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffffe0;
                32'b????_????_????_????_????_????_??01_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffffc0;
                32'b????_????_????_????_????_????_?011_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffff80;
                32'b????_????_????_????_????_????_0111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffff00;
                32'b????_????_????_????_????_???0_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffffe00;
                32'b????_????_????_????_????_??01_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffffc00;
                32'b????_????_????_????_????_?011_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffff800;
                32'b????_????_????_????_????_0111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffff000;
                32'b????_????_????_????_???0_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffe000;
                32'b????_????_????_????_??01_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffffc000;
                32'b????_????_????_????_?011_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffff8000;
                32'b????_????_????_????_0111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffff0000;
                32'b????_????_????_???0_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffe0000;
                32'b????_????_????_??01_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfffc0000;
                32'b????_????_????_?011_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfff80000;
                32'b????_????_????_0111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfff00000;
                32'b????_????_???0_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffe00000;
                32'b????_????_??01_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hffc00000;
                32'b????_????_?011_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hff800000;
                32'b????_????_0111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hff000000;
                32'b????_???0_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfe000000;
                32'b????_??01_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hfc000000;
                32'b????_?011_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hf8000000;
                32'b????_0111_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hf0000000;
                32'b???0_1111_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'he0000000;
                32'b??01_1111_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'hc0000000;
                32'b?011_1111_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'h80000000;
                32'b0111_1111_1111_1111_1111_1111_1111_1111 : TRG_CND_BUS_MASK[i] <= 32'h00000000;
                default : TRG_CND_BUS_MASK[i] <= 32'hffffffff;
            endcase
        end
    end
end

//------------------------------
// CSR Read from CSR
//------------------------------
assign CSR_DBG_DBG_RDATA = (~CSR_DBG_DBG_REQ)? 32'h00000000 // do not include CSR_DBG_DBG_WRITE
                         : (CSR_DBG_DBG_ADDR == `CSR_DCSR   )? csr_rdata_dcsr
                         : (CSR_DBG_DBG_ADDR == `CSR_DPC    )? csr_rdata_dpc
                         : (CSR_DBG_DBG_ADDR == `CSR_TSELECT)? csr_rdata_tselect
                         : (CSR_DBG_DBG_ADDR == `CSR_TINFO  )? csr_rdata_tinfo
                         : (CSR_DBG_DBG_ADDR == `CSR_TDATA1 )? csr_rdata_tdata1
                         : (CSR_DBG_DBG_ADDR == `CSR_TDATA2 )? csr_rdata_tdata2
                         : 32'h00000000;
assign CSR_DBG_CPU_RDATA = (~CSR_DBG_CPU_REQ)? 32'h00000000 // do not include CSR_DBG_DBG_WRITE
                         : (CSR_DBG_CPU_ADDR == `CSR_DCSR   )? csr_rdata_dcsr
                         : (CSR_DBG_CPU_ADDR == `CSR_DPC    )? csr_rdata_dpc
                         : (CSR_DBG_CPU_ADDR == `CSR_TSELECT)? csr_rdata_tselect
                         : (CSR_DBG_CPU_ADDR == `CSR_TINFO  )? csr_rdata_tinfo
                         : (CSR_DBG_CPU_ADDR == `CSR_TDATA1 )? csr_rdata_tdata1
                         : (CSR_DBG_CPU_ADDR == `CSR_TDATA2 )? csr_rdata_tdata2
                         : 32'h00000000;

//------------------------
// End of Module
//------------------------
endmodule

//-----------------------------------------------------------------
// CSR Counter and Timer should be controlled by 
//     csr_dcsr_stopcount
//     csr_dcsr_stoptime
// ---> done!

//===========================================================
// End of File
//===========================================================
