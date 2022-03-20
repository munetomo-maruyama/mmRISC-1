//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_csr_int.v
// Description : CPU CSR for Interrupt Controller
//-----------------------------------------------------------
// History :
// Rev.01 2021.04.22 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================
//
//===========================================================
// CSR for Interrupt Controller INTC
//---------------------------------------
// mintcurlvl : 0xbf0
//   bit[31:4] WIRI (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 3:0] R/W  intcurlevel : Interrupt Current Level
//---------------------------------------
// mintprelvl : 0xbf1
//   bit[31:4] WIRI (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 3:0] R/W  intprelevel : Interrupt Previous Level
//---------------------------------------
// mintcfgenable[x] (x=00...01) : 0xbf2...0xbf3
//   bit[b]     R/W  enable[x*32+b] : Enable for IRQ[x*32+b]
//---------------------------------------
// mintcfgsense[x] (x=00...01) : 0xbf4...0xbf5
//   bit[b]     R/W  sense[x*32+b] : Sense (0:Level, 1:Edge)
//---------------------------------------
// mintpending[x] (x=00...01) : 0xbf6...0xbf7
//   bit[b]     R or R/W1C pending[x*32+b] : Pending
//             (if Level sense, R; if Edge Sense, R/W1C)
//---------------------------------------
// mintcfgpriority[x] (x=00...07) : 0xbf8...0xbff
//   bit[31:28] R/W  priority[x*8+7] : Priority Level for IRQ[x*8+7]
//   bit[27:24] R/W  priority[x*8+6] : Priority Level for IRQ[x*8+6]
//   bit[23:20] R/W  priority[x*8+5] : Priority Level for IRQ[x*8+5]
//   bit[19:16] R/W  priority[x*8+4] : Priority Level for IRQ[x*8+4]
//   bit[15:12] R/W  priority[x*8+3] : Priority Level for IRQ[x*8+3]
//   bit[11: 8] R/W  priority[x*8+2] : Priority Level for IRQ[x*8+2]
//   bit[ 7: 4] R/W  priority[x*8+1] : Priority Level for IRQ[x*8+1]
//   bit[ 3: 0] R/W  priority[x*8+0] : Priority Level for IRQ[x*8+0]
//===========================================================

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_CSR_INT
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    input  wire        CSR_INT_DBG_REQ,
    input  wire        CSR_INT_DBG_WRITE,
    input  wire [11:0] CSR_INT_DBG_ADDR,
    input  wire [31:0] CSR_INT_DBG_WDATA,
    output wire [31:0] CSR_INT_DBG_RDATA,
    input  wire        CSR_INT_CPU_REQ,
    input  wire        CSR_INT_CPU_WRITE,
    input  wire [11:0] CSR_INT_CPU_ADDR,
    input  wire [31:0] CSR_INT_CPU_WDATA,
    output wire [31:0] CSR_INT_CPU_RDATA,
    //
    input  wire [63:0] IRQ,         // Interrupt Request Input
    output reg         INTCTRL_REQ, // Interrupt Controller Request
    output reg  [ 5:0] INTCTRL_NUM, // Interrupt Controller Request Number
    input  wire        INTCTRL_ACK  // Interrupt Controller Acknowledge
);

integer x, y;

//---------------------
// CSR Access Signal
//---------------------
wire   csr_int_dbg_we;
wire   csr_int_cpu_we;
assign csr_int_dbg_we = CSR_INT_DBG_REQ & CSR_INT_DBG_WRITE;
assign csr_int_cpu_we = CSR_INT_CPU_REQ & CSR_INT_CPU_WRITE;

//-------------------------------
// CSR for Interrupt Controller
//-------------------------------
reg [31:0] mintcurlvl;
reg [31:0] mintprelvl;
reg [31:0] mintcfgenable[0:1];
reg [31:0] mintcfgsense [0:1];
reg [31:0] mintpending  [0:1];
reg [31:0] mintcfgpriority[0:7];

//------------------------------------
// IRQ Delay to extract Rising Edge
//------------------------------------
reg [63:0] irq_delay;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        irq_delay <= 64'b0;
    else
        irq_delay <= IRQ;
end

//-----------------------
// Interrupt Sense
//-----------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        for (y = 0; y < 2; y = y + 1)
        begin
            mintcfgsense[y] <= 32'h00000000;
        end
    end
    else
    begin
        for (y = 0; y < 2; y = y + 1)
        begin
            if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == (`CSR_MINTCFGSENSE0 + y))) // write from debug
            begin
                mintcfgsense[y] <= CSR_INT_DBG_WDATA;
            end
            else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == (`CSR_MINTCFGSENSE0 + y))) // write from cpu
            begin
                mintcfgsense[y] <= CSR_INT_CPU_WDATA;
            end
        end
    end
end

//------------------------
// Interrupt Pending
//------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        for (y = 0; y < 2; y = y + 1)
            for (x = 0; x < 32; x = x + 1)
            begin
                mintpending[y][x] <= 1'b0;
            end
    end
    else
    begin
        for (y = 0; y < 2; y = y + 1)
            for (x = 0; x < 32; x = x + 1)
            begin
                if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == (`CSR_MINTPENDING0 + y)) & CSR_INT_DBG_WDATA[x]) // clear to set from debug
                    mintpending[y][x] <= 1'b0;
                else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == (`CSR_MINTPENDING0 + y)) & CSR_INT_CPU_WDATA[x]) // clear to set from cpu
                    mintpending[y][x] <= 1'b0;
                else if (mintcfgsense[y][x] & IRQ[y*32+x] & ~irq_delay[y*32+x]) // rising edge sense
                    mintpending[y][x] <= 1'b1;
                else if (~mintcfgsense[y][x]) // level sense
                    mintpending[y][x] <= IRQ[y*32+x];
            end
    end
end

//----------------------
// Interrupt Enable
//----------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        for (y = 0; y < 2; y = y + 1)
        begin
            mintcfgenable[y] <= 32'h00000000;
        end
    end
    else
    begin
        for (y = 0; y < 2; y = y + 1)
        begin
            if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == (`CSR_MINTCFGENABLE0 + y))) // write from debug
            begin
                mintcfgenable[y] <= CSR_INT_DBG_WDATA;
            end
            else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == (`CSR_MINTCFGENABLE0 + y))) // write from cpu
            begin
                mintcfgenable[y] <= CSR_INT_CPU_WDATA;
            end
        end
    end
end
//
reg  [63:0] irq_pend;
//
always @*
begin
    for (y = 0; y < 2; y = y + 1)
        for (x = 0; x < 32; x = x + 1)
            irq_pend[y*32+x] = mintpending[y][x] & mintcfgenable[y][x];
end

//--------------------------
// Interrupt Priority
//--------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        for (y = 0; y < 8; y = y + 1)
        begin
            mintcfgpriority[y] <= 32'h00000000;
        end
    end
    else
    begin
        for (y = 0; y < 8; y = y + 1)
        begin
            if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == (`CSR_MINTCFGPRIORITY0 + y))) // write from debug
            begin
                mintcfgpriority[y] <= CSR_INT_DBG_WDATA;
            end
            else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == (`CSR_MINTCFGPRIORITY0 + y))) // write from cpu
            begin
                mintcfgpriority[y] <= CSR_INT_CPU_WDATA;
            end
        end    
    end
end

//--------------------------
// Priority Tournament
//--------------------------
reg [3:0] bit_max;
//
always @*
begin
    bit_max = 4'b0000;
    for (y = 0; y < 8; y = y + 1)
        for (x = 0; x < 8; x = x + 1)
        begin
            bit_max[3] = bit_max[3]
                       | mintcfgpriority[y][x*4+3] & irq_pend[y*8+x];
            bit_max[2] = bit_max[2]
                       | mintcfgpriority[y][x*4+2] & irq_pend[y*8+x];
            bit_max[1] = bit_max[1]
                       | mintcfgpriority[y][x*4+1] & irq_pend[y*8+x];
            bit_max[0] = bit_max[0]
                       | mintcfgpriority[y][x*4+0] & irq_pend[y*8+x];
        end
end
//
reg [1:0] irq3_tour[0:63]; // 00:kill, 10:draw, 11:won
reg [1:0] irq2_tour[0:63]; // 00:kill, 10:draw, 11:won
reg [1:0] irq1_tour[0:63]; // 00:kill, 10:draw, 11:won
reg [1:0] irq0_tour[0:63]; // 00:kill, 10:draw, 11:won
//
always @*
begin
    for (y = 0; y < 8; y = y + 1)
        for (x = 0; x < 8; x = x + 1)
        begin
            irq3_tour[y*8+x] = (irq_pend[y*8+x] == 1'b0)? 2'b00
                : (mintcfgpriority[y][x*4+3] >  bit_max[3])? 2'b11
                : (mintcfgpriority[y][x*4+3] == bit_max[3])? 2'b10
                : 2'b00;
        end
end
//
always @*
begin
    for (y = 0; y < 8; y = y + 1)
        for (x = 0; x < 8; x = x + 1)
        begin
            irq2_tour[y*8+x] = (irq3_tour[y*8+x] == 2'b00)? 2'b00
                : (irq3_tour[y*8+x] == 2'b11)? 2'b11
                : (mintcfgpriority[y][x*4+2] >  bit_max[2])? 2'b11
                : (mintcfgpriority[y][x*4+2] == bit_max[2])? 2'b10
                : 2'b00;
        end
end
//
always @*
begin
    for (y = 0; y < 8; y = y + 1)
        for (x = 0; x < 8; x = x + 1)
        begin
            irq1_tour[y*8+x] = (irq2_tour[y*8+x] == 2'b00)? 2'b00
                : (irq2_tour[y*8+x] == 2'b11)? 2'b11
                : (mintcfgpriority[y][x*4+1] >  bit_max[1])? 2'b11
                : (mintcfgpriority[y][x*4+1] == bit_max[1])? 2'b10
                : 2'b00;
        end
end
//
always @*
begin
    for (y = 0; y < 8; y = y + 1)
        for (x = 0; x < 8; x = x + 1)
        begin
            irq0_tour[y*8+x] = (irq1_tour[y*8+x] == 2'b00)? 2'b00
                : (irq1_tour[y*8+x] == 2'b11)? 2'b11
                : (mintcfgpriority[y][x*4+0] >  bit_max[0])? 2'b11
                : (mintcfgpriority[y][x*4+0] == bit_max[0])? 2'b10
                : 2'b00;
        end
end

//--------------------------------
// Output Interrupt Request
//--------------------------------
reg       intctrl_req;
reg [5:0] intctrl_num;
reg [3:0] intctrl_lvl;
//
always @*
begin
    intctrl_req = 1'b0;
    intctrl_num = 6'h0;
    intctrl_lvl = 4'b0000;
    //
    begin : loop_irq_tournament
        for (y = 0; y < 8; y = y + 1)
            for (x = 0; x < 8; x = x + 1)
            begin
                if (irq0_tour[y*8+x][1] == 1'b1)
                begin
                    intctrl_req = 1'b1;
                    intctrl_num = y*8+x;
                    intctrl_lvl = {mintcfgpriority[y][x*4+3],
                                   mintcfgpriority[y][x*4+2],
                                   mintcfgpriority[y][x*4+1],
                                   mintcfgpriority[y][x*4+0]};
                    disable loop_irq_tournament;
                end
            end
    end
end
//
reg [3:0] intctrl_lvl_delay;
reg [3:0] mintcurlvl_delay;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        INTCTRL_REQ <= 1'b0;
        INTCTRL_NUM <= 6'h0;
        intctrl_lvl_delay <= 4'b0000;
        mintcurlvl_delay  <= 4'b0000;
    end
    else
    begin
        INTCTRL_REQ <= (intctrl_lvl > mintcurlvl[3:0])? intctrl_req : 1'b0;
        INTCTRL_NUM <= intctrl_num;
        intctrl_lvl_delay <= intctrl_lvl;
        mintcurlvl_delay  <= mintcurlvl[3:0];
    end
end

//-----------------------------------
// Interrupt Current Priority Level
//-----------------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        mintcurlvl <= 32'h0000000f;
    end
    else if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == `CSR_MINTCURLVL)) // write from debug
    begin
        mintcurlvl <= {28'h0, CSR_INT_DBG_WDATA[3:0]};
    end
    else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == `CSR_MINTCURLVL)) // write from cpu
    begin
        mintcurlvl <= {28'h0, CSR_INT_CPU_WDATA[3:0]};
    end
    else if (INTCTRL_REQ & INTCTRL_ACK)
    begin
        mintcurlvl <= {28'h0, intctrl_lvl_delay};
    end
end

//----------------------------------
// Interrut Previous Priority Level
//----------------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        mintprelvl <= 32'h0000000f;
    end
    else if (csr_int_dbg_we & (CSR_INT_DBG_ADDR == `CSR_MINTPRELVL)) // write from debug
    begin
        mintprelvl <= {28'h0, CSR_INT_DBG_WDATA[3:0]};
    end
    else if (csr_int_cpu_we & (CSR_INT_CPU_ADDR == `CSR_MINTPRELVL)) // write from cpu
    begin
        mintprelvl <= {28'h0, CSR_INT_CPU_WDATA[3:0]};
    end
    else if (INTCTRL_REQ & INTCTRL_ACK)
    begin
        mintprelvl <= mintcurlvl_delay;
    end
end

//------------------------------
// CSR Read Data
//------------------------------
assign CSR_INT_DBG_RDATA = (~CSR_INT_DBG_REQ)? 32'h00000000 // do not include CSR_INT_WRITE
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCURLVL)? mintcurlvl
                         : (CSR_INT_DBG_ADDR == `CSR_MINTPRELVL)? mintprelvl
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGENABLE0)? mintcfgenable[0]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGENABLE1)? mintcfgenable[1]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGSENSE0)? mintcfgsense[0]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGSENSE1)? mintcfgsense[1]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTPENDING0)? mintpending[0]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTPENDING1)? mintpending[1]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY0)? mintcfgpriority[0]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY1)? mintcfgpriority[1]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY2)? mintcfgpriority[2]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY3)? mintcfgpriority[3]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY4)? mintcfgpriority[4]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY5)? mintcfgpriority[5]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY6)? mintcfgpriority[6]
                         : (CSR_INT_DBG_ADDR == `CSR_MINTCFGPRIORITY7)? mintcfgpriority[7]
                         : 32'h00000000;
assign CSR_INT_CPU_RDATA = (~CSR_INT_CPU_REQ)? 32'h00000000 // do not include CSR_INT_WRITE
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCURLVL)? mintcurlvl
                         : (CSR_INT_CPU_ADDR == `CSR_MINTPRELVL)? mintprelvl
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGENABLE0)? mintcfgenable[0]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGENABLE1)? mintcfgenable[1]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGSENSE0)? mintcfgsense[0]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGSENSE1)? mintcfgsense[1]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTPENDING0)? mintpending[0]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTPENDING1)? mintpending[1]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY0)? mintcfgpriority[0]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY1)? mintcfgpriority[1]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY2)? mintcfgpriority[2]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY3)? mintcfgpriority[3]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY4)? mintcfgpriority[4]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY5)? mintcfgpriority[5]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY6)? mintcfgpriority[6]
                         : (CSR_INT_CPU_ADDR == `CSR_MINTCFGPRIORITY7)? mintcfgpriority[7]
                         : 32'h00000000;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
