//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : debug_cdc.v
// Description : Debug Clock Domain Crossing
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.17 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

module DEBUG_CDC
    #(parameter
        WIDTH = 32
    )
(
    input  wire WR_CLK,
    input  wire WR_RES,
    input  wire WR_PUT,
    output wire WR_RDY,
    input  wire [WIDTH - 1 : 0] WR_DATA,
    //
    input  wire RD_CLK,
    input  wire RD_RES,
    input  wire RD_GET,
    output wire RD_RDY,
    output  wire [WIDTH - 1 : 0] RD_DATA
);

//-------------------
// Internal Signals
//-------------------
wire we;
wire re;
reg  wptr;
reg  rptr;
reg  [1:0] wptr_sync; // to RD_CLK
reg  [1:0] rptr_sync; // to WR_CLK

//--------------------
// Write Control
//--------------------
assign we = WR_PUT & WR_RDY;
//
always @(posedge WR_CLK, posedge WR_RES)
begin
    if (WR_RES)
        wptr <= 1'b0;
    else if (we)
        wptr <= ~wptr; // add one as 1bit gray code
end
//
always @(posedge WR_CLK, posedge WR_RES)
begin
    if (WR_RES)
    begin
        rptr_sync[0] <= 1'b0;
        rptr_sync[1] <= 1'b0;
    end
    else
    begin
        rptr_sync[0] <= rptr;
        rptr_sync[1] <= rptr_sync[0];
    end
    
end
//
assign WR_RDY = (wptr == rptr_sync[1]);

//--------------------
// Read Control
//--------------------
assign re = RD_GET & RD_RDY;
//
always @(posedge RD_CLK, posedge RD_RES)
begin
    if (RD_RES)
        rptr <= 1'b0;
    else if (re)
        rptr <= ~rptr; // add one as 1bit gray code
end
//
always @(posedge RD_CLK, posedge RD_RES)
begin
    if (RD_RES)
    begin
        wptr_sync[0] <= 1'b0;
        wptr_sync[1] <= 1'b0;
    end
    else
    begin
        wptr_sync[0] <= wptr;
        wptr_sync[1] <= wptr_sync[0];
    end
    
end
//
assign RD_RDY = ~(rptr == wptr_sync[1]);

//--------------------------------
// 2-Deep FIFO to make 1-Deep CDC 
//--------------------------------
reg [WIDTH - 1 : 0] fifo0;
reg [WIDTH - 1 : 0] fifo1;
//
always @(posedge WR_CLK, posedge WR_RES)
begin
    if (WR_RES)
    begin
        fifo0 <= 0;
        fifo1 <= 0;
    end
    else if (we & ~wptr) fifo0 <= WR_DATA;
    else if (we &  wptr) fifo1 <= WR_DATA;
end
//
assign RD_DATA = (~rptr)? fifo0 : fifo1;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================

