//===========================================================
// mmRISC-0 Project
//-----------------------------------------------------------
// File Name   : ram_fpga.v
// Description : RAM for FPGA (128KB)
//-----------------------------------------------------------
// History :
// Rev.01 2021.12.31 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2021-2022 M.Maruyama
//===========================================================

`include "defines.v"

//----------------------
// Define Module
//----------------------
module RAM_FPGA
(
    input  wire RES, // Reset
    input  wire CLK, // System Clock
    //
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
    output wire [31:0] S_HRDATA,
    output wire        S_HRESP
);

//--------------------
// RAM for FPGA
//--------------------
wire        s_mem_re;
wire        s_mem_we;
wire [ 3:0] s_mem_rbe;
wire [ 3:0] s_mem_wbe;
//
wire [14:0] s_mem_raddr;
wire [14:0] s_mem_waddr;
//
wire [31:0] s_mem_rdata; 
wire [31:0] s_mem_wdata; 
//
RAM128KB_DP U_RAM128KB_DP
(
    .address_a (s_mem_waddr),
	.address_b (s_mem_raddr),
	.byteena_a (s_mem_wbe),
	.byteena_b (s_mem_rbe),
	.clock     (CLK),
	.data_a    (s_mem_wdata),
	.data_b    (32'h00000000),
	.rden_a    (1'b0),
	.rden_b    (s_mem_re),
	.wren_a    (s_mem_we),
	.wren_b    (1'b0),
	.q_a       (),
	.q_b       (s_mem_rdata)
);

//-------------------------
// Control Logic
//-------------------------
reg [ 3:0] ready_count;
reg        s_dphase;
reg [31:0] s_dphase_haddr;
reg        s_dphase_hwrite;
reg [ 2:0] s_dphase_hsize;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        s_dphase <= 1'b0;
        s_dphase_haddr  <= 32'h00000000;
        s_dphase_hwrite <= 1'b0;
        s_dphase_hsize  <= 3'b000;
    end
    else if (S_HREADY & S_HREADYOUT)
    begin
        s_dphase <= S_HTRANS[1];
        s_dphase_haddr  <= S_HADDR;
        s_dphase_hwrite <= S_HWRITE;
        s_dphase_hsize  <= S_HSIZE;
    end
end
//
assign s_mem_re  = S_HREADY & S_HREADYOUT & S_HTRANS[1] & ~S_HWRITE;
assign s_mem_rbe = {s_mem_re, s_mem_re, s_mem_re, s_mem_re};
assign s_mem_raddr = S_HADDR[16:2];
//
assign s_mem_we     = S_HREADY & S_HREADYOUT & s_dphase & s_dphase_hwrite;
assign s_mem_wbe[0] = s_mem_we
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b00)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_wbe[1] = s_mem_we
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b01)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_wbe[2] = s_mem_we
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b10)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_wbe[3] = s_mem_we
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b11)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_waddr = s_dphase_haddr[16:2];
assign s_mem_wdata = S_HWDATA;

//---------------------------------------
// Simultanous Read-Write Contention
//---------------------------------------
reg  s_dphase_contention_0;
reg  s_dphase_contention_1;
reg  s_dphase_contention_2;
reg  s_dphase_contention_3;
reg  [7:0] s_mem_cdata_0; // forwarding from Write to Read
reg  [7:0] s_mem_cdata_1; // forwarding from Write to Read
reg  [7:0] s_mem_cdata_2; // forwarding from Write to Read
reg  [7:0] s_mem_cdata_3; // forwarding from Write to Read
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_0 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re & s_mem_we & s_mem_wbe[0])
        s_dphase_contention_0 <= (s_mem_raddr == s_mem_waddr);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_0 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_1 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re & s_mem_we & s_mem_wbe[1])
        s_dphase_contention_1 <= (s_mem_raddr == s_mem_waddr);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_1 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_2 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re & s_mem_we & s_mem_wbe[2])
        s_dphase_contention_2 <= (s_mem_raddr == s_mem_waddr);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_2 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_3 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re & s_mem_we & s_mem_wbe[3])
        s_dphase_contention_3 <= (s_mem_raddr == s_mem_waddr);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_3 <= 1'b0;
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_0 <= 8'h00;
    else if (s_mem_we & s_mem_wbe[0])
        s_mem_cdata_0 <= s_mem_wdata[ 7: 0];
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_1 <= 8'h00;
    else if (s_mem_we & s_mem_wbe[1])
        s_mem_cdata_1 <= s_mem_wdata[15: 8];
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_2 <= 8'h00;
    else if (s_mem_we & s_mem_wbe[2])
        s_mem_cdata_2 <= s_mem_wdata[23:16];
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_3 <= 8'h00;
    else if (s_mem_we & s_mem_wbe[3])
        s_mem_cdata_3 <= s_mem_wdata[31:24];
end

//-------------------------------
// Read Data
//-------------------------------
wire [7:0] rdata_0, rdata_1, rdata_2, rdata_3;
assign rdata_0 = (s_dphase_contention_0)? s_mem_cdata_0 : s_mem_rdata[ 7: 0];
assign rdata_1 = (s_dphase_contention_1)? s_mem_cdata_1 : s_mem_rdata[15: 8];
assign rdata_2 = (s_dphase_contention_2)? s_mem_cdata_2 : s_mem_rdata[23:16];
assign rdata_3 = (s_dphase_contention_3)? s_mem_cdata_3 : s_mem_rdata[31:24];
assign S_HRDATA = (s_dphase & S_HREADY & S_HREADYOUT)? 
                         {rdata_3, rdata_2, rdata_1, rdata_0} : 32'h00000000;        

//--------------------------------
// Wait Cycle
//--------------------------------
reg [3:0] wait_cycle;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        wait_cycle <= 4'h0;
`ifdef HAVE_RAM_WAIT
    else if (S_HREADY & S_HREADYOUT & S_HTRANS[1])
        wait_cycle <= {2'b00, S_HADDR[3:2]};
`endif
    else if (S_HREADY & S_HREADYOUT)
        wait_cycle <= 4'h0;
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        ready_count <= 0;
    else if (S_HREADY & S_HREADYOUT & S_HTRANS[1])
        ready_count <= 0;
    else if (s_dphase & (ready_count == wait_cycle))
        ready_count <= 0;
    else if (s_dphase)
        ready_count <= ready_count + 4'h1;
end
//
assign S_HREADYOUT = ~s_dphase | (s_dphase & (ready_count == wait_cycle));
assign S_HRESP = 1'b0;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
