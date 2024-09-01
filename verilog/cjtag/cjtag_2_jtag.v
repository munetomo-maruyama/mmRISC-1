//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cjtag_2_jtag.v
// Description : cJTAG to JTAG Converter
//-----------------------------------------------------------
// History :
// Rev.01 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
// Rev.02 2023.10.05 M.Maruyama Both fCLK>fTCKC and fCLK>fTCKC
//                              are supported
// Rev.03 2024.07.27 M.Maruyama Adapted Generic Debugger I/F
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================

//-----------------------------
// cJTAG Online Sequence 
//-----------------------------
// Case1 : Detected (State : ANY --> STEP1)
// TCK  ____|^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|____
// TMS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// TDI  _________|^^^^|____|^^^^|____|^^^^|_________
// TDO  ---------------------------zzz--------------(HiZ)
//
// TCKC ____|^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|___
// TMSC _________|^^^^|____|^^^^|____|^^^^|________
//(TRSTn)^^^^^^^^^^^^^^^^^^^^^^^^^^^^|_________|^^^)
//
// Case2 : Ignored (State : Unchanged)
// TCK  ____|^^^^^^^^^^^^^^^^^^^^^^^^|____
// TMS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// TDI  _________|^^^^|____|^^^^|_________
// TDO  ----------------------------------(HiZ)
//
// TCKC ____|^^^^^^^^^^^^^^^^^^^^^^^^|____
// TMSC _________|^^^^|____|^^^^|_________
//(TRSTn)^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^)
//

//-------------------------------------------
// cJTAG Activation
//-------------------------------------------
// STEP1 : Wait for OAC (1100. LSB first)
//         State : if Matched STEP1 --> STEP2
//                 else       STEP1 --> OFFLINE
// TCK  _________|^^^^|____|^^^^|____|^^^^|____|^^^^|____
// TMS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// TDI  XXXXX____0_________0____|^^^^1^^^^^^^^^1^^^^|____
// TDO  -------------------------------------------------(HiZ)
//-------------------------------------------
// STEP2 : Wait for EC (1000, LSB first)
//         State : if Matched STEP2 --> STEP3
//                 else       STEP2 --> OFFLINE
// TCK  _________|^^^^|____|^^^^|____|^^^^|____|^^^^|____
// TMS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// TDI  XXXXX____0_________0_________0____|^^^^1^^^^|____
// TDO  -------------------------------------------------(HiZ)
//-------------------------------------------
// STEP3 : Wait for CP (0000, LSB first)
//         State : if Matched STEP3 --> ONLINE
//                 else       STEP3 --> OFFLINE
// TCK  _________|^^^^|____|^^^^|____|^^^^|____|^^^^|____
// TMS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// TDI  XXXXX____0_________0_________0_________0____xxxxx
// TDO  -------------------------------------------------(HiZ)

//--------------------------------------
// cJTAG OSCAN1 Protocol
//--------------------------------------
//
// TCKC __________|^^^^|____|^^^^|____|^^^^|____|^^^^|____|^^^^|____|^^^^|____
// TMSC_I    X   nTDI  X   TMS   X---------X   nTDI  X    TMS  X---------X
// TMSC_O------------------------X  TDO0   X-------------------X  TDO1   X----
//
// TCK  ______________________________|^^^^|________________________|^^^^|____
// TDI  ___________X_ TDI _______________________X_ TDI ______________________          
// TMS  _____________________X TMS ________________________X TMS _____________
// TDO________X TDO0________________________X TDO1____________________________
//
// state __001_________X___010___X___100___X___001___X___010___X___100___X___001__
//

`include "defines_chip.v"
`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CJTAG_2_JTAG
(
    input  wire RES,
    input  wire CLK,
    //
    input  wire TCKC,
    input  wire TMSC_I,
    output wire TMSC_O,
    output wire TMSC_E,
    output wire TMSC_PUP,
    output wire TMSC_PDN,
    //
    output wire TRSTn,
    output wire TCK,
    output reg  TMS,
    output reg  TDI,
    input  wire TDO,
    //
    output wire FORCE_HALT_ON_RESET_REQ,
    input  wire FORCE_HALT_ON_RESET_ACK,
    //
    output wire CJTAG_IN_OSCAN1
);

//----------------------------
// Control HALT_ON_RESET
//----------------------------
reg  halt_req;
wire halt_req_resclr;
wire halt_req_resset;
//
assign halt_req_resclr = RES &  TMSC_I;
assign halt_req_resset = RES & ~TMSC_I;
//
always @(posedge CLK, posedge halt_req_resclr, posedge halt_req_resset)
begin
    if (halt_req_resclr)
        halt_req <= 1'b0;
    else if (halt_req_resset)
        halt_req <= 1'b1;
    else if (FORCE_HALT_ON_RESET_ACK)
        halt_req <= 1'b0;
end
assign FORCE_HALT_ON_RESET_REQ = halt_req;

/*
//----------------------------
// Detect Escape Sequence
//----------------------------
reg  [2:0] escape_count;
wire [2:0] escape_count_din;
wire       escape_count_res;
wire       escape_count_inc;
//
assign escape_count_res = RES | ~TCKC;
assign escape_count_inc = TCKC & (escape_count != 3'b110);
assign escape_count_din = (escape_count_inc)? (escape_count + 3'b001 ): escape_count;
//
BEFF #(.WIDTH(3)) U_ESCAPE_COUNT
(
    .RES (escape_count_res),
    .CLK (TMSC_I),
    .DIN (escape_count_din),
    .OUT (escape_count)
);
//
reg  escape;
wire escape_res;
wire escape_set;
//
assign escape_res = RES | ~TCKC;
assign escape_set = ~escape & TCKC & (escape_count == 3'b100);
//
always @(negedge TMSC_I, posedge escape_res)
begin
    if (escape_res)
        escape <= 1'b0;
    else if (escape_set)
        escape <= 1'b1;
end

//-------------------------
// Online
//-------------------------
reg  online;
wire online_res;
reg  online_clr;
//
assign online_res = RES | online_clr;
//
always @(negedge TMSC_I, posedge online_res)
begin
    if (online_res)
        online <= 1'b0;
    else if (escape_set)
        online <= 1'b1;
end
*/

//----------------------------
// Detect Escape Sequence
//----------------------------
reg  [1:0] escape_count;
wire       escape_count_res;
wire       escape_count_inc;
//
assign escape_count_res = RES | ~TCKC;
assign escape_count_inc = TCKC & (escape_count < 2'b11);
//
always @(posedge TMSC_I, posedge escape_count_res)
begin
    if (escape_count_res)
        escape_count <= 2'b00;
    else if (escape_count_inc)
        escape_count <= escape_count + 2'b01;
end
//
reg  escape;
wire escape_res;
wire escape_set;
//
assign escape_res = RES | ~TCKC;
assign escape_set = ~escape & TCKC & (escape_count == 2'b10);
//
always @(posedge TMSC_I, posedge escape_res)
begin
    if (escape_res)
        escape <= 1'b0;
    else if (escape_set)
        escape <= 1'b1;
end

//-------------------------
// Online
//-------------------------
reg  online;
wire online_res;
reg  online_clr;
//
assign online_res = RES | online_clr;
//
always @(posedge TMSC_I, posedge online_res)
begin
    if (online_res)
        online <= 1'b0;
    else if (escape_set)
        online <= 1'b1;
end

//----------------------------
// Detect Activation Sequence
//----------------------------
wire [15:0] actv_code;
assign actv_code = 16'b0000000010001100; // {0000, CP, EC, OAC}
reg  [ 3:0] actv_count; 
wire        actv_count_res;
wire        actv_count_inc;
wire        actv_count_equ;
//
assign actv_count_res = RES | escape | ~online;
assign actv_count_inc = online & (actv_count < 4'b1011);
assign actv_count_equ = (actv_code[actv_count] == TMSC_I);
//
always @(posedge TCKC, posedge actv_count_res)
begin
    if (actv_count_res)
        actv_count <= 4'b0000;
    else if (actv_count_inc)
        actv_count <= actv_count + 4'b0001;
end
//
reg  cjtag_in_oscan1;
wire cjtag_in_oscan1_res;
//
assign online_clr_res = RES | escape;
assign online_clr_set = online & ~actv_count_equ & ~cjtag_in_oscan1;
//
always @(posedge TCKC, posedge online_clr_res)
begin
    if (online_clr_res)
        online_clr <= 1'b0;
    else if (~online_clr_set)
        online_clr <= 1'b0;
    else if ( online_clr_set)
        online_clr <= 1'b1;
end
//
reg  activated;
wire activated_res;
wire activated_set;
//
assign activated_res = RES | escape | ~online;
assign activated_set = (actv_count == 4'b1011) & actv_count_equ;
//
always @(posedge TCKC, posedge activated_res)
begin
    if (activated_res)
        activated <= 1'b0;
    else if (activated_set)
        activated <= 1'b1;
end
//
assign cjtag_in_oscan1_res = RES | escape | ~online;
//
always @(negedge TCKC, posedge cjtag_in_oscan1_res)
begin
    if (cjtag_in_oscan1_res)
        cjtag_in_oscan1 <= 1'b0;
    else
        cjtag_in_oscan1 <= activated;
end

//--------------------------------
// OSCAN1 Sequence
//--------------------------------
reg  [2:0] oscan1_state;
wire       oscan1_state_res;
wire       oscan1_state_ini;
//
assign oscan1_state_res = ~activated;
assign oscan1_state_ini = (oscan1_state == 3'b000);
//
always @(negedge TCKC, posedge oscan1_state_res)
begin
    if (oscan1_state_res)
        oscan1_state <= 3'b000;
    else if (oscan1_state_ini)
        oscan1_state <= 3'b001;
    else 
        oscan1_state <= {oscan1_state[1:0], oscan1_state[2]};
end

//------------------------------
// Generate JTAG Signals
//------------------------------
assign TRSTn = cjtag_in_oscan1;
//
assign TCK   = cjtag_in_oscan1 & oscan1_state[2] & TCKC;
//
always @(posedge TCKC, negedge cjtag_in_oscan1)
begin
    if (~cjtag_in_oscan1)
        TDI <= 1'b0;
    else if (oscan1_state[0])
        TDI <= ~TMSC_I;
end
//
always @(posedge TCKC, negedge cjtag_in_oscan1)
begin
    if (~cjtag_in_oscan1)
        TMS <= 1'b0;
    else if (oscan1_state[1])
        TMS <= TMSC_I;
end
//
assign TMSC_O = TDO;
assign TMSC_E = (TCKC)? 1'b0       // When TCKC=1, HiZ
              : (cjtag_in_oscan1 & oscan1_state[2])? 1'b1
              : 1'b0;

//-----------------------------
// Status Output
//-----------------------------
assign CJTAG_IN_OSCAN1 = cjtag_in_oscan1;

//-----------------------------
// Control TMSC Bus Keeper
//-----------------------------
assign TMSC_PUP = (~cjtag_in_oscan1)? 1'b1   // Before OSCAN1, PULLUP ON
                :   TMSC_I;                  // During OSCAN1, KEEPER
assign TMSC_PDN = (~cjtag_in_oscan1)? 1'b0   // Before OSCAN1, PULLDN OFF
                :  ~TMSC_I;                  // During OSCAN1, KEEPER

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
/*
//----------------------------------------
// Define Module : Both Edge F/F
//----------------------------------------
module BEFF #(parameter WIDTH = 1)
(
  input  wire             CLK,
  input  wire             RES,
  input  wire [WIDTH-1:0] DIN,
  output wire [WIDTH-1:0] OUT
);
    reg  [WIDTH-1:0] trig1, trig2;
    //
    assign OUT = trig1 ^ trig2;
    //
    always @(posedge CLK, posedge RES)
    begin
        if (RES)
            trig1 <= 0;
        else
            trig1 <= DIN ^ trig2;
    end
    //
    always @(negedge CLK, posedge RES)
    begin
        if (RES)
            trig2 <= 0;
        else
            trig2 <= DIN ^ trig1;
    end
//------------------------
// End of Module
//------------------------
endmodule
*/

//===========================================================
// End of File
//===========================================================
