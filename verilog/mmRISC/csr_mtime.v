//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : csr_mtime.v
// Description : Memory Mapped CSR MTIME
//-----------------------------------------------------------
// S_History :
// Rev.01 2021.04.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

//======================================================
// Timer Register (should be accessed with 32bit width)
//------------------------------------------------------
// Offset Name Description
// 0x00   MTIME_CTRL   Timer Control
//     bit 00    ENABLE  (RW) Timer Enable       
//     bit 01    CLKSRC  (RW) Timer Clock Source
//                 0 : Internal Clock (Clock Input of this IP)
//                 1 : External Clock (Slower than Internal Clock)
//     bit 02    INTE    (RW)   Interrupt Enable
//     bit 03    INTS    (RW1C) Interrupt Status, write 1 to clear
//     bit 31-04 Reserved (RZ)   
//------------------------------------------------------
// 0x04   MTIME_DIV    Timer Clock Divider       
//     bit 09-00 DIV (RW) Timer Divider
//                 A Tick occurs every DIV+1 clocks.
//     bit 31-10 Reserved (RZ)
//------------------------------------------------------
// 0x08   MTIME        Timer Ticks (lower 32bit)
//     bit 31-0  MTIME (RW) TImer Ticks (lower 32bit)
//------------------------------------------------------
// 0x0C   MTIMEH       Timer Ticks (higher 32bit)
//     bit 31-0  MTIME (RW) TImer Ticks (higher 32bit)
//------------------------------------------------------
// 0x10   MTIMECMP     Timer Ticks Comparation (lower 32bit)
//     bit 31-0  MTIMECMP  (RW) Timer Ticks Comparation (lower 32bit)
//------------------------------------------------------
// 0x14   MTIMECMPH    Timer Ticks Comparation (higher 32bit)
//     bit 31-0  MTIMECMPH (RW) Timer Ticks Comparation (higher 32bit)
//------------------------------------------------------
// [NOTE] Writing MTIME/MTIMECMP stores the value to each write buffer.
// Writing MTIMEH/MTIMECMPH stores the value to MTIMEH/MTIMECMPH,
// and stores each write buffer value to MTIME/MTIMECMP, simultaneously.
//------------------------------------------------------
// [NOTE] Reading MTIME/MTIMECMP captures {MTIMEH:MTIME}/{TIMECMPH:TIMECMP}
// into 64bit capture buffer and outputs lower 32bit of the buffer as read data.
// Reading MTIMEH/MTIMECMPH outputs higher 32bit of the buffer as read data.
//------------------------------------------------------
// 0x18   MSOFTIRQ    Software Interrupt Request
//     bit 31-01 Reserved (R)
//     bit    00 MSIP Machine Software Interrupt Pending (Request)  
//======================================================

//*************************************************
// Module Definition
//*************************************************
module CSR_MTIME
(
    // System
    input  wire CLK, // clock
    input  wire RES, // reset
    //
    // AHB Lite Slave port
    input  wire        S_HSEL,
    input  wire [ 1:0] S_HTRANS,
    input  wire        S_HWRITE,
    input  wire        S_HMASTLOCK,
    input  wire [ 2:0] S_HSIZE,
    input  wire [ 2:0] S_HBURST,
    input  wire [ 3:0] S_HPROT,
    input  wire [31:0] S_HADDR,
    input  wire [31:0] S_HWDATA,
    input  wire        S_HREADY,
    output wire        S_HREADYOUT,
    output reg  [31:0] S_HRDATA,
    output wire        S_HRESP,
    //
    // External Clock
    input  wire        CSR_MTIME_EXTCLK,
    //
    // Interrupt Output
    output wire        IRQ_MSOFT,
    output wire        IRQ_MTIME,
    //
    // Timer Counter
    output wire [31:0] MTIME,
    output wire [31:0] MTIMEH,
    input  wire        DBG_STOP_TIMER  // Stop Timer due to Debug Mode
);

//---------------------------------------------
// Synchronize CSR_MTIME_EXTCLK
//---------------------------------------------
reg  csr_mtime_extclk_sync1;
reg  csr_mtime_extclk_sync2;
reg  csr_mtime_extclk_sync3;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        csr_mtime_extclk_sync1 <= 1'b0;
        csr_mtime_extclk_sync2 <= 1'b0;
        csr_mtime_extclk_sync3 <= 1'b0;
    end
    else
    begin
        csr_mtime_extclk_sync1 <= CSR_MTIME_EXTCLK;
        csr_mtime_extclk_sync2 <= csr_mtime_extclk_sync1;
        csr_mtime_extclk_sync3 <= csr_mtime_extclk_sync2;
    end
end

//-------------------
// Register Access
//-------------------
reg         dphase_active;
reg  [31:0] dphase_addr;
reg         dphase_write;
//
assign S_HREADYOUT = 1'b1;
assign S_HRESP = 1'b0;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        dphase_active <= 1'b0;
        dphase_addr   <= 32'h00000000;
        dphase_write  <= 1'b0;
    end
    else if (S_HREADY & S_HSEL & S_HTRANS[1])
    begin
        dphase_active <= 1'b1;
        dphase_addr   <= S_HADDR;
        dphase_write  <= S_HWRITE;
    end
    else if (S_HREADY)
    begin
        dphase_active <= 1'b0;
        dphase_addr   <= 32'h00000000;
        dphase_write  <= 1'b0;
    end
end

//---------------------
// MTIME_CTRL
//---------------------
reg  [31:0] mtime_ctrl;
wire        mtime_ctrl_enable;
wire        mtime_ctrl_clksrc;
wire        mtime_ctrl_inte;
reg         mtime_ctrl_ints;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        mtime_ctrl <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h00))
        mtime_ctrl <= {29'h0, S_HWDATA[2:0]};
end
//
assign mtime_ctrl_enable = mtime_ctrl[0] & ~DBG_STOP_TIMER;
assign mtime_ctrl_clksrc = mtime_ctrl[1];
assign mtime_ctrl_inte   = mtime_ctrl[2];
//
// INTS : bit3
wire   mtime_tick_match;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        mtime_ctrl_ints <= 1'b0;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h00) & S_HWDATA[3])
        mtime_ctrl_ints <= 1'b0;
    else if (mtime_tick_match)
        mtime_ctrl_ints <= 1'b1;
end

//-------------------------------------------
// Select Internal Clock or External Clock
//-------------------------------------------
wire mtime_clkenb;
assign mtime_clkenb = (mtime_ctrl_clksrc == 1'b0)? 1'b1
                    : csr_mtime_extclk_sync2 & ~csr_mtime_extclk_sync3;

//--------------------
// MTIME_DIV
//--------------------
reg  [31:0] mtime_div;
wire [ 9:0] mtime_div_div;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        mtime_div <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h04))   
        mtime_div <= {22'h0, S_HWDATA[9:0]};
end
//
assign mtime_div_div = mtime_div[9:0];
//
reg  [9:0] prescaler;
wire       prescaler_match;
wire       mtime_tick;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        prescaler <= 10'h0;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h04))   
        prescaler <= S_HWDATA[9:0];
    else if (mtime_ctrl_enable == 1'b0)
        prescaler <= 10'h0;
    else if (mtime_tick)
        prescaler <= 10'h0;
    else if (mtime_clkenb)
        prescaler <= prescaler + 10'h1;
end
//
assign prescaler_match = mtime_ctrl_enable & (prescaler == mtime_div_div);
assign mtime_tick      = mtime_ctrl_enable & prescaler_match & mtime_clkenb;

//-------------------------
// MTIME / MTIMEH
//-------------------------
reg  [31:0] mtime;
reg  [31:0] mtime_wbuf;
reg  [31:0] mtime_rbuf;
reg  [31:0] mtimeh;
reg  [31:0] mtimeh_rbuf;
wire        mtime_match;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        mtime_wbuf <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h08))   
        mtime_wbuf <= S_HWDATA;
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        mtime  <= 32'h00000000;
        mtimeh <= 32'h00000000;
    end
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h0c))   
    begin
        mtime  <= mtime_wbuf;
        mtimeh <= S_HWDATA;
    end
    else if (mtime_tick & mtime_match)
    begin
        mtime  <= 32'h00000000;
        mtimeh <= 32'h00000000;
    end
    else if (mtime_tick)
    begin
        mtime  <= mtime + 32'h00000001;
        mtimeh <= (mtime == 32'hffffffff)? mtimeh + 32'h00000001 : mtimeh;
    end
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        mtime_rbuf  <= 32'h00000000;
        mtimeh_rbuf <= 32'h00000000;
    end
    else if (S_HREADY & S_HSEL & S_HTRANS[1] & ~S_HWRITE & (S_HADDR[7:0] == 8'h08))
    begin
        mtime_rbuf  <= mtime;
        mtimeh_rbuf <= mtimeh;
    end
end

//-------------------------
// MTIMECMP / MTIMECMPH
//-------------------------
reg  [31:0] mtimecmp;
reg  [31:0] mtimecmp_wbuf;
reg  [31:0] mtimecmph;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        mtimecmp_wbuf <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h10))   
        mtimecmp_wbuf <= S_HWDATA;
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        mtimecmp  <= 32'h00000000;
        mtimecmph <= 32'h00000000;
    end
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h14))   
    begin
        mtimecmp  <= mtimecmp_wbuf;
        mtimecmph <= S_HWDATA;
    end
end
//
assign mtime_match = (mtime == mtimecmp) & (mtimeh == mtimecmph);

//-------------------------
// MSOFTIRQ
//-------------------------
reg  [31:0] msoftirq;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        msoftirq <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h18))   
        msoftirq <= {31'h0, S_HWDATA[0]};
end

//-------------------------
// Register Read
//-------------------------
always @*
begin
    if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h00))
        S_HRDATA = {28'h0, mtime_ctrl_ints, mtime_ctrl[2:0]};
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h04))
        S_HRDATA = {22'h0, mtime_div[9:0]};
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h08))
        S_HRDATA = mtime_rbuf;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h0c))
        S_HRDATA = mtimeh_rbuf;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h10))
        S_HRDATA = mtimecmp;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h14))
        S_HRDATA = mtimecmph;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h18))
        S_HRDATA = msoftirq;
    else
        S_HRDATA = 32'h00000000;
end

//----------------------
// Interrupt Output
//----------------------
assign mtime_tick_match = (mtime == mtimecmp)
                        & (mtimeh == mtimecmph)
                        & mtime_tick;
assign IRQ_MSOFT = msoftirq[0];
assign IRQ_MTIME = mtime_ctrl_inte & mtime_ctrl_ints;

//--------------------
// Counter Output
//--------------------
assign MTIME  = mtime;
assign MTIMEH = mtimeh;

//======================================================
  endmodule
//======================================================
