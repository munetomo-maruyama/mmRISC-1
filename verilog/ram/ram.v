//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : ram.v
// Description : RAM with AHB Lite Bus Interface
//-----------------------------------------------------------
// History :
// Rev.01 2021.02.13 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

`include "defines.v"

//----------------------
// Define Module
//----------------------
module RAM
    #(parameter
        RAM_SIZE = (64*1024),
        RAM_ADDR = $clog2(RAM_SIZE)
     )
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

//------------------
// RAM Model
//------------------
reg [ 3:0] ready_count;
reg        s_dphase;
//reg [ 1:0] s_dphase_htrans;
reg [31:0] s_dphase_haddr;
//reg [31:0] s_dphase_hwdata;
reg        s_dphase_hwrite;
reg [ 2:0] s_dphase_hsize;
//reg        s_dphase_hmastlock;
//
reg  [ 7:0] s_mem_0[0:(RAM_SIZE/4)-1];
reg  [ 7:0] s_mem_1[0:(RAM_SIZE/4)-1];
reg  [ 7:0] s_mem_2[0:(RAM_SIZE/4)-1];
reg  [ 7:0] s_mem_3[0:(RAM_SIZE/4)-1];
//
`ifdef SIMULATION
initial
begin
    reg [7:0] rom[0:RAM_SIZE-1];
    integer a;
    $readmemh("rom.memh", rom);
    for (a = 0; a < (RAM_SIZE/4); a = a + 1)
    begin
        s_mem_0[a] = rom[a * 4 + 0];
        s_mem_1[a] = rom[a * 4 + 1];
        s_mem_2[a] = rom[a * 4 + 2];
        s_mem_3[a] = rom[a * 4 + 3];
    end
end
`endif
//
wire        s_mem_re_0, s_mem_re_1, s_mem_re_2, s_mem_re_3;
wire        s_mem_we_0, s_mem_we_1, s_mem_we_2, s_mem_we_3;
//
wire [29:0] s_mem_raddr_0, s_mem_raddr_1, s_mem_raddr_2, s_mem_raddr_3;
wire [29:0] s_mem_waddr_0, s_mem_waddr_1, s_mem_waddr_2, s_mem_waddr_3;
//
reg  [ 7:0] s_mem_rdata_0, s_mem_rdata_1, s_mem_rdata_2, s_mem_rdata_3; 
wire [ 7:0] s_mem_wdata_0, s_mem_wdata_1, s_mem_wdata_2, s_mem_wdata_3; 
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        s_dphase <= 1'b0;
//      s_dphase_htrans <= 2'b00;
        s_dphase_haddr  <= 32'h00000000;
//      s_dphase_hwdata <= 32'h00000000;
        s_dphase_hwrite <= 1'b0;
        s_dphase_hsize  <= 3'b000;
//      s_dphase_hmastlock <= 1'b0;
    end
    else if (S_HREADY & S_HREADYOUT)
    begin
        s_dphase <= S_HTRANS[1];
//      s_dphase_htrans <= S_HTRANS;
        s_dphase_haddr  <= S_HADDR;
//      s_dphase_hwdata <= S_HWDATA;
        s_dphase_hwrite <= S_HWRITE;
        s_dphase_hsize  <= S_HSIZE;
//      s_dphase_hmastlock <= S_HMASTLOCK;
    end
end
//
assign s_mem_re_0 = S_HREADY & S_HREADYOUT & S_HTRANS[1] & ~S_HWRITE;
assign s_mem_re_1 = S_HREADY & S_HREADYOUT & S_HTRANS[1] & ~S_HWRITE;
assign s_mem_re_2 = S_HREADY & S_HREADYOUT & S_HTRANS[1] & ~S_HWRITE;
assign s_mem_re_3 = S_HREADY & S_HREADYOUT & S_HTRANS[1] & ~S_HWRITE;
assign s_mem_raddr_0 = S_HADDR[31:2];
assign s_mem_raddr_1 = S_HADDR[31:2];
assign s_mem_raddr_2 = S_HADDR[31:2];
assign s_mem_raddr_3 = S_HADDR[31:2];
//
assign s_mem_we_0 = S_HREADY & S_HREADYOUT & s_dphase & s_dphase_hwrite
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b00)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_we_1 = S_HREADY & S_HREADYOUT & s_dphase & s_dphase_hwrite
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b01)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_we_2 = S_HREADY & S_HREADYOUT & s_dphase & s_dphase_hwrite
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b10)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_we_3 = S_HREADY & S_HREADYOUT & s_dphase & s_dphase_hwrite
        & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b11)
        || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
        || (s_dphase_hsize == 3'b010));
assign s_mem_waddr_0 = s_dphase_haddr[31:2];
assign s_mem_waddr_1 = s_dphase_haddr[31:2];
assign s_mem_waddr_2 = s_dphase_haddr[31:2];
assign s_mem_waddr_3 = s_dphase_haddr[31:2];
assign s_mem_wdata_0 = S_HWDATA[ 7: 0];
assign s_mem_wdata_1 = S_HWDATA[15: 8];
assign s_mem_wdata_2 = S_HWDATA[23:16];
assign s_mem_wdata_3 = S_HWDATA[31:24];
//
// Simultanous Read-Write Contention
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
    else if (S_HREADY & S_HREADYOUT & s_mem_re_0 & s_mem_we_0)
        s_dphase_contention_0 <= (s_mem_raddr_0 == s_mem_waddr_0);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_0 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_1 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re_1 & s_mem_we_1)
        s_dphase_contention_1 <= (s_mem_raddr_1 == s_mem_waddr_1);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_1 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_2 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re_2 & s_mem_we_2)
        s_dphase_contention_2 <= (s_mem_raddr_2 == s_mem_waddr_2);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_2 <= 1'b0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_dphase_contention_3 <= 1'b0;
    else if (S_HREADY & S_HREADYOUT & s_mem_re_3 & s_mem_we_3)
        s_dphase_contention_3 <= (s_mem_raddr_3 == s_mem_waddr_3);
    else if (S_HREADY & S_HREADYOUT)
        s_dphase_contention_3 <= 1'b0;
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_0 <= 8'h00;
    else if (s_mem_we_0)
        s_mem_cdata_0 <= s_mem_wdata_0;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_1 <= 8'h00;
    else if (s_mem_we_1)
        s_mem_cdata_1 <= s_mem_wdata_1;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_2 <= 8'h00;
    else if (s_mem_we_2)
        s_mem_cdata_2 <= s_mem_wdata_2;
end
always @(posedge CLK, posedge RES)
begin
    if (RES)
        s_mem_cdata_3 <= 8'h00;
    else if (s_mem_we_3)
        s_mem_cdata_3 <= s_mem_wdata_3;
end
//
// Inferrence of Dual Port RAM (RW contention : Read new Write Data)
always @(posedge CLK)
begin
    if (s_mem_we_0) s_mem_0[s_mem_waddr_0[(RAM_ADDR-3):0]] <= s_mem_wdata_0; // non blocking
    if (s_mem_re_0) s_mem_rdata_0 <= s_mem_0[s_mem_raddr_0[(RAM_ADDR-3):0]]; // non blocking
end
always @(posedge CLK)
begin
    if (s_mem_we_1) s_mem_1[s_mem_waddr_1[(RAM_ADDR-3):0]] <= s_mem_wdata_1; // non blocking
    if (s_mem_re_1) s_mem_rdata_1 <= s_mem_1[s_mem_raddr_1[(RAM_ADDR-3):0]]; // non blocking
end
always @(posedge CLK)
begin
    if (s_mem_we_2) s_mem_2[s_mem_waddr_2[(RAM_ADDR-3):0]] <= s_mem_wdata_2; // non blocking
    if (s_mem_re_2) s_mem_rdata_2 <= s_mem_2[s_mem_raddr_2[(RAM_ADDR-3):0]]; // non blocking
end
always @(posedge CLK)
begin
    if (s_mem_we_3) s_mem_3[s_mem_waddr_3[(RAM_ADDR-3):0]] <= s_mem_wdata_3; // non blocking
    if (s_mem_re_3) s_mem_rdata_3 <= s_mem_3[s_mem_raddr_3[(RAM_ADDR-3):0]]; // non blocking
end
//
// Read Data
wire [7:0] rdata_0, rdata_1, rdata_2, rdata_3;
assign rdata_0 = (s_dphase_contention_0)? s_mem_cdata_0 : s_mem_rdata_0;
assign rdata_1 = (s_dphase_contention_1)? s_mem_cdata_1 : s_mem_rdata_1;
assign rdata_2 = (s_dphase_contention_2)? s_mem_cdata_2 : s_mem_rdata_2;
assign rdata_3 = (s_dphase_contention_3)? s_mem_cdata_3 : s_mem_rdata_3;
assign S_HRDATA = (s_dphase & S_HREADY & S_HREADYOUT)? 
                         {rdata_3, rdata_2, rdata_1, rdata_0} : 32'h00000000;        
//
// Wait Cycle
reg [3:0] wait_cycle;
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
