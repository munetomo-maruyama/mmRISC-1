//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : slaves_ahb.v
// Description : Slaves with AHB Lite Bus Interface
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
module SLAVES_AHB
    #(parameter
        SLAVES  = 4
     )
(
    input  wire RES, // Reset
    input  wire CLK, // System Clock
    //
    input  wire        S_HSEL      [0:SLAVES-1], // AHB for Slave Function
    input  wire [ 1:0] S_HTRANS    [0:SLAVES-1], // AHB for Slave Function
    input  wire        S_HWRITE    [0:SLAVES-1], // AHB for Slave Function
    input  wire        S_HMASTLOCK [0:SLAVES-1], // AHB for Slave Function
    input  wire [ 2:0] S_HSIZE     [0:SLAVES-1], // AHB for Slave Function
    input  wire [ 2:0] S_HBURST    [0:SLAVES-1], // AHB for Slave Function
    input  wire [ 3:0] S_HPROT     [0:SLAVES-1], // AHB for Slave Function
    input  wire [31:0] S_HADDR     [0:SLAVES-1], // AHB for Slave Function
    input  wire [31:0] S_HWDATA    [0:SLAVES-1], // AHB for Slave Function
    input  wire        S_HREADY    [0:SLAVES-1], // AHB for Slave Function
    output wire        S_HREADYOUT [0:SLAVES-1], // AHB for Slave Function
    output wire [31:0] S_HRDATA    [0:SLAVES-1], // AHB for Slave Function
    output wire        S_HRESP     [0:SLAVES-1]  // AHB for Slave Function
);

//----------------------
// Genvar
//----------------------
genvar i;

//------------------
// Slave Model
//------------------
generate
    for (i = 0; i < SLAVES; i = i + 1)
    begin : SLAVE_MODEL
        reg [ 3:0] ready_count;
        reg        s_dphase;
        reg [ 1:0] s_dphase_htrans;
        reg [31:0] s_dphase_haddr;
        reg [31:0] s_dphase_hwdata;
        reg        s_dphase_hwrite;
        reg [ 2:0] s_dphase_hsize;
        reg        s_dphase_hmastlock;
        //
        reg  [ 7:0] s_mem_0[0:8191];
        reg  [ 7:0] s_mem_1[0:8191];
        reg  [ 7:0] s_mem_2[0:8191];
        reg  [ 7:0] s_mem_3[0:8191];
        //
        `ifdef SIMULATION
        initial
        begin
            reg [7:0] rom[0:65535];
            integer a;
            $readmemh("rom.memh", rom);
            for (a = 0; a < 8192; a = a + 1)
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
        wire [12:0] s_mem_raddr_0, s_mem_raddr_1, s_mem_raddr_2, s_mem_raddr_3;
        wire [12:0] s_mem_waddr_0, s_mem_waddr_1, s_mem_waddr_2, s_mem_waddr_3;
        //
        reg  [ 7:0] s_mem_rdata_0, s_mem_rdata_1, s_mem_rdata_2, s_mem_rdata_3; 
        wire [ 7:0] s_mem_wdata_0, s_mem_wdata_1, s_mem_wdata_2, s_mem_wdata_3; 
        //
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
            begin
                s_dphase <= 1'b0;
                s_dphase_htrans <= 2'b00;
                s_dphase_haddr  <= 32'h00000000;
                s_dphase_hwdata <= 32'h00000000;
                s_dphase_hwrite <= 1'b0;
                s_dphase_hsize  <= 3'b000;
                s_dphase_hmastlock <= 1'b0;
            end
            else if (S_HREADY[i] & S_HREADYOUT[i])
            begin
                s_dphase <= S_HTRANS[i][1];
                s_dphase_htrans <= S_HTRANS[i];
                s_dphase_haddr  <= S_HADDR[i];
                s_dphase_hwdata <= S_HWDATA[i];
                s_dphase_hwrite <= S_HWRITE[i];
                s_dphase_hsize  <= S_HSIZE[i];
                s_dphase_hmastlock <= S_HMASTLOCK[i];
            end
        end
        //
        assign s_mem_re_0 = S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1] & ~S_HWRITE[i];
        assign s_mem_re_1 = S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1] & ~S_HWRITE[i];
        assign s_mem_re_2 = S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1] & ~S_HWRITE[i];
        assign s_mem_re_3 = S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1] & ~S_HWRITE[i];
        assign s_mem_raddr_0 = S_HADDR[i][14:2];
        assign s_mem_raddr_1 = S_HADDR[i][14:2];
        assign s_mem_raddr_2 = S_HADDR[i][14:2];
        assign s_mem_raddr_3 = S_HADDR[i][14:2];
        //
        assign s_mem_we_0 = S_HREADY[i] & S_HREADYOUT[i] & s_dphase & s_dphase_hwrite
                & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b00)
                || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
                || (s_dphase_hsize == 3'b010));
        assign s_mem_we_1 = S_HREADY[i] & S_HREADYOUT[i] & s_dphase & s_dphase_hwrite
                & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b01)
                || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b0 )
                || (s_dphase_hsize == 3'b010));
        assign s_mem_we_2 = S_HREADY[i] & S_HREADYOUT[i] & s_dphase & s_dphase_hwrite
                & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b10)
                || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
                || (s_dphase_hsize == 3'b010));
        assign s_mem_we_3 = S_HREADY[i] & S_HREADYOUT[i] & s_dphase & s_dphase_hwrite
                & ((s_dphase_hsize == 3'b000) && (s_dphase_haddr[1:0] == 2'b11)
                || (s_dphase_hsize == 3'b001) && (s_dphase_haddr[1]   == 1'b1 )
                || (s_dphase_hsize == 3'b010));
        assign s_mem_waddr_0 = s_dphase_haddr[14:2];
        assign s_mem_waddr_1 = s_dphase_haddr[14:2];
        assign s_mem_waddr_2 = s_dphase_haddr[14:2];
        assign s_mem_waddr_3 = s_dphase_haddr[14:2];
        assign s_mem_wdata_0 = S_HWDATA[i][ 7: 0];
        assign s_mem_wdata_1 = S_HWDATA[i][15: 8];
        assign s_mem_wdata_2 = S_HWDATA[i][23:16];
        assign s_mem_wdata_3 = S_HWDATA[i][31:24];
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
            else if (S_HREADY[i] & S_HREADYOUT[i] & s_mem_re_0 & s_mem_we_0)
                s_dphase_contention_0 <= (s_mem_raddr_0 == s_mem_waddr_0);
            else if (S_HREADY[i] & S_HREADYOUT[i])
                s_dphase_contention_0 <= 1'b0;
        end
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
                s_dphase_contention_1 <= 1'b0;
            else if (S_HREADY[i] & S_HREADYOUT[i] & s_mem_re_1 & s_mem_we_1)
                s_dphase_contention_1 <= (s_mem_raddr_1 == s_mem_waddr_1);
            else if (S_HREADY[i] & S_HREADYOUT[i])
                s_dphase_contention_1 <= 1'b0;
        end
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
                s_dphase_contention_2 <= 1'b0;
            else if (S_HREADY[i] & S_HREADYOUT[i] & s_mem_re_2 & s_mem_we_2)
                s_dphase_contention_2 <= (s_mem_raddr_2 == s_mem_waddr_2);
            else if (S_HREADY[i] & S_HREADYOUT[i])
                s_dphase_contention_2 <= 1'b0;
        end
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
                s_dphase_contention_3 <= 1'b0;
            else if (S_HREADY[i] & S_HREADYOUT[i] & s_mem_re_3 & s_mem_we_3)
                s_dphase_contention_3 <= (s_mem_raddr_3 == s_mem_waddr_3);
            else if (S_HREADY[i] & S_HREADYOUT[i])
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
            if (s_mem_we_0) s_mem_0[s_mem_waddr_0] <= s_mem_wdata_0; // blocking
            if (s_mem_re_0) s_mem_rdata_0 <= s_mem_0[s_mem_raddr_0]; // blocking
        end
        always @(posedge CLK)
        begin
            if (s_mem_we_1) s_mem_1[s_mem_waddr_1] <= s_mem_wdata_1; // blocking
            if (s_mem_re_1) s_mem_rdata_1 <= s_mem_1[s_mem_raddr_1]; // blocking
        end
        always @(posedge CLK)
        begin
            if (s_mem_we_2) s_mem_2[s_mem_waddr_2] <= s_mem_wdata_2; // blocking
            if (s_mem_re_2) s_mem_rdata_2 <= s_mem_2[s_mem_raddr_2]; // blocking
        end
        always @(posedge CLK)
        begin
            if (s_mem_we_3) s_mem_3[s_mem_waddr_3] <= s_mem_wdata_3; // blocking
            if (s_mem_re_3) s_mem_rdata_3 <= s_mem_3[s_mem_raddr_3]; // blocking
        end
        //
        // Read Data
        wire [7:0] rdata_0, rdata_1, rdata_2, rdata_3;
        assign rdata_0 = (s_dphase_contention_0)? s_mem_cdata_0 : s_mem_rdata_0;
        assign rdata_1 = (s_dphase_contention_1)? s_mem_cdata_1 : s_mem_rdata_1;
        assign rdata_2 = (s_dphase_contention_2)? s_mem_cdata_2 : s_mem_rdata_2;
        assign rdata_3 = (s_dphase_contention_3)? s_mem_cdata_3 : s_mem_rdata_3;
        assign S_HRDATA[i] = (s_dphase & S_HREADY[i] & S_HREADYOUT[i])? 
                                 {rdata_3, rdata_2, rdata_1, rdata_0} : 32'h00000000;        
        //
        // Wait Cycle
        reg [3:0] wait_cycle;
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
                wait_cycle <= 4'h0;
            else if (S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1])
                wait_cycle <= (S_HADDR[i][3:2] + i) & 4'b0011;
            else if (S_HREADY[i] & S_HREADYOUT[i])
                wait_cycle <= 4'h0;
        end
        //
        always @(posedge CLK, posedge RES)
        begin
            if (RES)
                ready_count <= 0;
            else if (S_HREADY[i] & S_HREADYOUT[i] & S_HTRANS[i][1])
                ready_count <= 0;
            else if (s_dphase & (ready_count == wait_cycle))
                ready_count <= 0;
            else if (s_dphase)
                ready_count <= ready_count + 4'h1;
        end
        //
        assign S_HREADYOUT[i] = ~s_dphase | (s_dphase & (ready_count == wait_cycle));
        assign S_HRESP[i] = 1'b0;
    end
endgenerate

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
