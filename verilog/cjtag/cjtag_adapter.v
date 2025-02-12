//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cjtag_adapter.v
// Description : Adapter to convert JTAG to cJTAG
//-----------------------------------------------------------
// History :
// Rev.01 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================

`include "defines_chip.v"
`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CJTAG_ADAPTER
(
    input  wire RESET_HALT_N,
    //
    input  wire TCK,
    input  wire TMS,
    input  wire TDI,
    output wire TDO_D,
    output wire TDO_E,
    //
    output wire TCKC,
    input  wire TMSC_I,
    output wire TMSC_O,
    output wire TMSC_E
);

//
assign TCKC   = (~RESET_HALT_N)? 1'b1  // Force Target not to drive TMSC
              : TCK;                   // Through TCK
assign TMSC_O = (~RESET_HALT_N)? 1'b0  // Force Low Level to make CPU in halt state
              : TDI;                   // TDI determines TMSC output level
assign TMSC_E = (~RESET_HALT_N)? 1'b1  // Force Low Level to make CPU in halt state
              : (TMS          )? 1'b1  // TMS=1 then Drive TMSC
              :                  1'b0; // TMS=0 then Open TMSC (HiZ)
//
assign TDO_D  = TMSC_I;
assign TDO_E  = 1'b1;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
