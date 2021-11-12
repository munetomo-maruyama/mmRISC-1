//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : port.v
// Description : In/Out Port (GPIO)
//-----------------------------------------------------------
// S_History :
// Rev.01 2021.02.22 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

//======================================================
// GPIO Register
//------------------------------------------------------
// Offset Name Description
// 0x00   PDR0 Port Data Register 0
// 0x04   PDR1 Port Data Register 1
// 0x08   PDR2 Port Data Register 2
//                 Each bit corresponds to each pin
//                 Input  Port : Read  Pin Level
//                               Write PDR F/F
//                 Output Port : Read  PDR F/F
//                               Write PDR F/F
// 0x10   PDD0 Port Data Direction 0
// 0x14   PDD1 Port Data Direction 1
// 0x18   PDD2 Port Data Direction 2
//                 0 : Input 
//                 1 : Output
//======================================================

//*************************************************
// Module Definition
//*************************************************
module PORT
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
    // GPIO
    inout  wire [31:0] GPIO0, // should be pulled-up
    inout  wire [31:0] GPIO1, // should be pulled-up
    inout  wire [31:0] GPIO2   // should be pulled-up
);

//---------------------
// Internal Signals
//---------------------
reg  [31:0] pdr0; // Port Data Register 0
reg  [31:0] pdr1; // Port Data Register 1
reg  [31:0] pdr2; // Port Data Register 2
reg  [31:0] pdd0; // Port Data Direction 0
reg  [31:0] pdd1; // Port Data Direction 1
reg  [31:0] pdd2; // Port Data Direction 2
//
reg         dphase_active;
reg  [31:0] dphase_addr;
reg         dphase_write;
//
reg  [31:0] gpio0_rd;
reg  [31:0] gpio1_rd;
reg  [31:0] gpio2_rd;

//-------------------
// Register Access
//-------------------
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
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        pdr0 <= 32'h00000000;
        pdr1 <= 32'h00000000;
        pdr2 <= 32'h00000000;
    end
    else if (dphase_active & dphase_write)   
    begin
        if (dphase_addr[4:2] == 3'b000) pdr0 <= S_HWDATA;
        if (dphase_addr[4:2] == 3'b001) pdr1 <= S_HWDATA;
        if (dphase_addr[4:2] == 3'b010) pdr2 <= S_HWDATA;
    end
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        pdd0 <= 32'h00000000;
        pdd1 <= 32'h00000000;
        pdd2 <= 32'h00000000;
    end
    else if (dphase_active & dphase_write)
    begin
        if (dphase_addr[4:2] == 3'b100) pdd0 <= S_HWDATA;
        if (dphase_addr[4:2] == 3'b101) pdd1 <= S_HWDATA;
        if (dphase_addr[4:2] == 3'b110) pdd2 <= S_HWDATA;
    end
end
//
always @*
begin
    if (dphase_active & ~dphase_write)
    begin
             if (dphase_addr[4:2] == 3'b000) S_HRDATA = gpio0_rd;
        else if (dphase_addr[4:2] == 3'b001) S_HRDATA = gpio1_rd;
        else if (dphase_addr[4:2] == 3'b010) S_HRDATA = gpio2_rd;
        else if (dphase_addr[4:2] == 3'b100) S_HRDATA = pdd0;
        else if (dphase_addr[4:2] == 3'b101) S_HRDATA = pdd1;
        else if (dphase_addr[4:2] == 3'b110) S_HRDATA = pdd2;
        else S_HRDATA = 32'h00000000;
    end
    else
    begin
        S_HRDATA = 32'h00000000;
    end
end

//----------------------
// Port Input/Output
//----------------------
integer i;
genvar  j;
//
always @*
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        gpio0_rd[i] = (pdd0[i])? pdr0[i] : GPIO0[i];
        gpio1_rd[i] = (pdd1[i])? pdr1[i] : GPIO1[i];
        gpio2_rd[i] = (pdd2[i])? pdr2[i] : GPIO2[i];
    end
end
//
generate
    for (j = 0; j < 32; j = j + 1)
    begin : GPIO_PIN
        assign GPIO0[j] = (pdd0[j])? pdr0[j] : 1'bz;
        assign GPIO1[j] = (pdd1[j])? pdr1[j] : 1'bz;
        assign GPIO2[j] = (pdd2[j])? pdr2[j] : 1'bz;
    end
endgenerate

//======================================================
  endmodule
//======================================================
