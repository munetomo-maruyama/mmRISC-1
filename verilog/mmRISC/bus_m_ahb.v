//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : bus_m_ahb.v
// Description : Bus Master Module (AHB)
//-----------------------------------------------------------
// History :
// Rev.01 2020.07.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//----------------------
// Define Module
//----------------------
module BUS_M_AHB
(
    input wire RES_SYS, // System Reset
    input wire CLK,     // System Clock
    //
    input  wire        BUS_M_REQ,   // BUS Master Command Request
    output wire        BUS_M_ACK,   // BUS Master Command Acknowledge
    input  wire        BUS_M_SEQ,   // Bus Master Command Sequence
    input  wire        BUS_M_CONT,  // Bus Master Command Continuing
    input  wire [ 2:0] BUS_M_BURST, // Bus Master Command Burst
    input  wire        BUS_M_LOCK,  // Bus Master Command Lock
    input  wire [ 3:0] BUS_M_PROT,  // Bus Master Command Protect
    input  wire        BUS_M_WRITE, // Bus Master Command Write (if 0, read)
    input  wire [ 1:0] BUS_M_SIZE,  // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
    input  wire [31:0] BUS_M_ADDR,  // Bus Master Command Address
    input  wire [31:0] BUS_M_WDATA, // Bus Master Command Write Data
    output wire        BUS_M_LAST,  // Bus Master Command Last Cycle
    output wire [31:0] BUS_M_RDATA, // Bus Master Command Read Data
    output reg  [ 3:0] BUS_M_DONE,  // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE})
    output wire [31:0] BUS_M_RDATA_RAW, // Bus Master Command Read Data Unclocked
    output wire [ 3:0] BUS_M_DONE_RAW,  // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked
    //
    output reg         M_HSEL     , // AHB Master Select
    output reg  [ 1:0] M_HTRANS   , // AHB Master Transfer
    output reg         M_HWRITE   , // AHB Master Write
    output reg         M_HMASTLOCK, // AHB Master Lock
    output reg  [ 2:0] M_HSIZE    , // AHB Master Size
    output reg  [ 2:0] M_HBURST   , // AHB Master Burst
    output reg  [ 3:0] M_HPROT    , // AHB Master Protect
    output reg  [31:0] M_HADDR    , // AHB Master Address
    output reg  [31:0] M_HWDATA   , // AHB Master Write Data
    output wire        M_HREADY   , // AHB Master Ready
    input  wire        M_HREADYOUT, // AHB Master Ready Out
    input  wire [31:0] M_HRDATA   , // AHB Master Read Data
    input  wire        M_HRESP      // AHB Master Response
);

//----------------------------
// Ready Signal
//----------------------------
assign M_HREADY = M_HREADYOUT;

//------------------------------------
// Write Data Alignment 
//------------------------------------
wire [31:0] bus_m_wdata_align;
assign bus_m_wdata_align =
            (BUS_M_SIZE == 2'b10)? {BUS_M_WDATA[31:0]}                                // WORD
          : (BUS_M_SIZE == 2'b01)? {BUS_M_WDATA[15:0], BUS_M_WDATA[15:0]}             // HWORD
          : {BUS_M_WDATA[7:0], BUS_M_WDATA[7:0], BUS_M_WDATA[7:0], BUS_M_WDATA[7:0]}; // BYTE

//--------------------------------------------
// AHB Bus Master
//--------------------------------------------
reg [31:0] m_hwdata_aphase;
reg        m_dphase;
reg        m_hwrite_dphase;
reg [ 2:0] m_hsize_dphase;
reg [ 1:0] m_haddr_dphase;
//
// Command Acknowledge
assign BUS_M_ACK = BUS_M_REQ & M_HREADY & M_HREADYOUT;
//
// Address Phase
always @*
begin
    if (BUS_M_ACK) // last cyc of dphase
    begin
        M_HSEL      = 1'b1;
        M_HTRANS    = {1'b1, BUS_M_SEQ};
        M_HWRITE    = BUS_M_WRITE;
        M_HMASTLOCK = BUS_M_LOCK;
        M_HSIZE     = {1'b0, BUS_M_SIZE};
        M_HBURST    = BUS_M_BURST;
        M_HPROT     = BUS_M_PROT;
        M_HADDR     = BUS_M_ADDR;
        m_hwdata_aphase = bus_m_wdata_align;
    end
    else
    begin
        M_HSEL      = 1'b0;
        M_HTRANS    = (BUS_M_CONT == 1'b0)? 2'b00 : 2'b01; // idle or busy
        M_HWRITE    = 1'b0;
        M_HMASTLOCK = 1'b0;
        M_HSIZE     = 3'b000;
        M_HBURST    = 3'b000;
        M_HPROT     = 4'b0000;
        M_HADDR     = 32'h00000000;
        m_hwdata_aphase = 32'h00000000;    
    end
end

/*
always @(posedge CLK, posedge RES_SYS)
begin
    if (RES_SYS)
    begin
        M_HSEL      <= 1'b0;
        M_HTRANS    <= 2'b00;
        M_HWRITE    <= 1'b0;
        M_HMASTLOCK <= 1'b0;
        M_HSIZE     <= 3'b000;
        M_HBURST    <= 3'b000;
        M_HPROT     <= 4'b0000;
        M_HADDR     <= 32'h00000000;
        m_hwdata_aphase <= 32'h00000000;
    end
    else if (BUS_M_ACK) // last cyc of dphase
    begin
        M_HSEL      <= 1'b1;
        M_HTRANS    <= {1'b1, BUS_M_SEQ};
        M_HWRITE    <= BUS_M_WRITE;
        M_HMASTLOCK <= BUS_M_LOCK;
        M_HSIZE     <= {1'b0, BUS_M_SIZE};
        M_HBURST    <= BUS_M_BURST;
        M_HPROT     <= BUS_M_PROT;
        M_HADDR     <= BUS_M_ADDR;
        m_hwdata_aphase <= bus_m_wdata_align;
    end
    else if (M_HREADY & M_HREADYOUT)
    begin
        M_HSEL      <= 1'b0;
        M_HTRANS    <= 2'b00;
        M_HWRITE    <= 1'b0;
        M_HMASTLOCK <= 1'b0;
        M_HSIZE     <= 3'b000;
        M_HBURST    <= 3'b000;
        M_HPROT     <= 4'b0000;
        M_HADDR     <= 32'h00000000;
        m_hwdata_aphase <= 32'h00000000;
      //m_hwrite_dphase <= M_HWRITE;
      //m_hsize_dphase  <= M_HSIZE;
      //m_haddr_dphase  <= M_HADDR[1:0];
    end
end
*/
//
// Data Phase
always @(posedge CLK, posedge RES_SYS)
begin
    if (RES_SYS)
    begin
        M_HWDATA <= 32'h00000000;
        m_dphase <= 1'b0;
        m_hwrite_dphase <= 1'b0;
        m_hsize_dphase  <= 3'b000;
        m_haddr_dphase  <= 2'b00;
    end
    else if (M_HSEL & M_HREADY & M_HREADYOUT)
    begin
        M_HWDATA <= m_hwdata_aphase;
        m_dphase <= 1'b1;
        m_hwrite_dphase <= M_HWRITE;
        m_hsize_dphase  <= M_HSIZE;
        m_haddr_dphase  <= M_HADDR[1:0];    
    end
    else if (M_HREADY & M_HREADYOUT)
    begin
        M_HWDATA <= 32'h00000000;
        m_dphase <= 1'b0;
        m_hwrite_dphase <= 1'b0;
        m_hsize_dphase  <= 3'b000;
        m_haddr_dphase  <= 2'b00;
    end
end

//-------------------------------
// Read Data Alignment
//-------------------------------
reg [31:0] m_hrdata_latched;
reg [ 2:0] m_hsize_latched;
reg [ 1:0] m_haddr_latched;


always @(posedge CLK, posedge RES_SYS)
begin
    if (RES_SYS)
    begin
        m_hrdata_latched <= 32'h00000000;
        m_hsize_latched  <= 3'b000;
        m_haddr_latched  <= 2'b00;
    end
    else if (m_dphase & ~m_hwrite_dphase & M_HREADY & M_HREADYOUT)
    begin
        m_hrdata_latched <= M_HRDATA;
        m_hsize_latched  <= m_hsize_dphase;
        m_haddr_latched  <= m_haddr_dphase[1:0];
    end
end
//
reg [31:0] bus_m_rdata_align;
always @*
begin
    bus_m_rdata_align = m_hrdata_latched; // Default
    if (m_hsize_latched == 3'b010) // WORD
    begin
        bus_m_rdata_align = m_hrdata_latched;
    end
    if (m_hsize_latched == 3'b001) // HWORD
    begin
        if (m_haddr_latched[1] == 1'b0) // Addr = 0
            bus_m_rdata_align = {16'h0000, m_hrdata_latched[15: 0]};
        else                           // Addr = 2
            bus_m_rdata_align = {16'h0000, m_hrdata_latched[31:16]};
    end
    if (m_hsize_latched == 3'b000) // BYTE
    begin
        if (m_haddr_latched[1:0] == 2'b00)      // Addr = 0
            bus_m_rdata_align = {24'h000000, m_hrdata_latched[ 7: 0]};
        else if (m_haddr_latched[1:0] == 2'b01) // Addr = 1
            bus_m_rdata_align = {24'h000000, m_hrdata_latched[15: 8]};
        else if (m_haddr_latched[1:0] == 2'b10) // Addr = 2
            bus_m_rdata_align = {24'h000000, m_hrdata_latched[23:16]};
        else                                   // Addr = 3
            bus_m_rdata_align = {24'h000000, m_hrdata_latched[31:24]};
    end
end
//
assign BUS_M_RDATA = 
    (BUS_M_DONE[1:0] == 2'b01)? bus_m_rdata_align : 32'h00000000;

//---------------------
// Last Cycle
//---------------------
assign BUS_M_LAST = m_dphase & M_HREADY & M_HREADYOUT;

//---------------------
// Done Signal
//---------------------
always @(posedge CLK, posedge RES_SYS)
begin
    if (RES_SYS)
        BUS_M_DONE <= 4'b0000;
    else if (m_dphase & M_HREADY & M_HREADYOUT)
        BUS_M_DONE <= {M_HRESP, 1'b0, m_hwrite_dphase, 1'b1};
    else if (BUS_M_DONE[0])
        BUS_M_DONE <= 4'b0000;
end

//---------------------
// Unclocked Output
//---------------------
assign BUS_M_RDATA_RAW = (BUS_M_DONE_RAW[1:0] == 2'b01)? M_HRDATA : 32'h00000000;
assign BUS_M_DONE_RAW  =
    {M_HRESP, 1'b0, m_hwrite_dphase, m_dphase & M_HREADY & M_HREADYOUT};

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
