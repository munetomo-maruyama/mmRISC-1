//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : int_gen.v
// Description : Interrupt Generator
//-----------------------------------------------------------
// S_History :
// Rev.01 2021.04.30 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

//======================================================
// INT_GEN Register (should be accessed with 32bit width)
//------------------------------------------------------
// Offset Name Description
//------------------------------------------------------
// 0x00   IRQ_EXT    External Interrupt Request
//     bit 31-01 Reserved (R)
//     bit    00 IRQ_EXT External Interrupt Pending (Request)  
//------------------------------------------------------
// 0x04   IRQ0       IRQ00-IRQ31 Request
//     bit 31-00 IRQ31-IRQ00  IRQ Pending (Request)
//------------------------------------------------------
// 0x08   IRQ1       IRQ32-IRQ63 Request
//     bit 31-00 IRQ63-IRQ32  IRQ Pending (Request)
//======================================================

//*************************************************
// Module Definition
//*************************************************
module INT_GEN
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
    // Interrupt Output
    output wire        IRQ_EXT,
    output wire [63:0] IRQ
);

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
// IRQ_EXT
//---------------------
reg  [31:0] irq_ext;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        irq_ext <= 32'h00000000;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h00))
        irq_ext <= {31'h0, S_HWDATA[0]};
end
//
assign IRQ_EXT = irq_ext[0];

//---------------------
// IRQ0, IRQ1
//---------------------
reg  [31:0] irq0, irq1;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        irq0 <= 32'h00000000;
        irq1 <= 32'h00000000;
    end
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h04))
        irq0 <= S_HWDATA;
    else if (dphase_active & dphase_write & (dphase_addr[7:0] == 8'h08))
        irq1 <= S_HWDATA;
end

//----------------------
// Register Read
//----------------------
always @*
begin
    if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h00))
        S_HRDATA = irq_ext;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h04))
        S_HRDATA = irq0;
    else if (dphase_active & ~dphase_write & (dphase_addr[7:0] == 8'h08))
        S_HRDATA = irq1;
    else
        S_HRDATA = 32'h00000000;
end

//----------------------
// IRQ Output
//----------------------
assign IRQ = {irq1, irq0};

//======================================================
  endmodule
//======================================================
