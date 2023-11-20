//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : debug_top.v
// Description : Debug Top Module
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.19 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

// RISC-V External Debug Support Version 0.13.2
// [Yes] 4     RISC-V Debug
// [Yes] 4.1   Debug Mode
//              (1)Debug Mode is a special processor mode used only
//                 when a hart is halted for external debugging.
//              (2)Optional Program Buffer is not supported.
// [CPU] 4.2   Load Reserved / Store Conditional Instructions
//                 Ignore access to reserved memory location
//                 during Debug Mode (Halted) between LR and SC.
// [CPU] 4.3   Wait for Interrupt Instructions
//                 If halt is requested during WFI, the CPU enters
//                 Debug Mode after WFI wakes up by interrupt.
// [CPU] 4.4   Single Step
//              (1)A debugger can cause a halted hart to execute
//                 a single instruction and then re-enter Debug Mode
//                 by setting step before setting resumereq.
//              (2)If executing or fetching that instruction causes
//                 an exception, Debug Mode is re-entered immediately
//                 after the PC is changed to the exception handler and
//                 the appropriate tval and cause registers are updated.
//              (3)If executing or fetching the instruction causes
//                 a trigger to fire, Debug Mode is re-entered
//                 immediately after that trigger has fired. 
//                 In that case cause is set to 2 (trigger)
//                 instead of 4 (single step). Whether the instruction
//                 is executed or not depends on the specific
//                 configuration of the trigger.
//              (4)If the instruction that is executed causes the PC
//                 to change to an address where an instruction fetch
//                 causes an exception, that exception does not occurr
//                 until the next time the hart is resumed.
//              (5) Similarly, a trigger at the new address does not
//                 fire until the hart actually attempts to execute
//                 that instruction.
//              (6) If the instruction being stepped over is wfi and
//                  would normally stall the hart, then instead the
//                  instruction is treated as nop.
// [CPU] 4.5   Reset
//                 If the halt signal (driven by the hart's halt request
//                 bit in the Debug Module) or resethaltreq are asserted
//                 when a hart comes out of reset, the hart must enter
//                 Debug Mode before executing any instructions, but
//                 after performing any initialization that would
//                 usually happen before first instruction is executed.
// [---] 4.6   dret Instruction
//                 dret (0x7b200073) is used to return fromm Debug Mode.
//                 This instruction is not supported bacause no Program
//                 Buffer feature is not implemented.
//                 Executing dret outside of Debug Mode causes
//                 an illegal instruction exception.
// [Yes] 4.7   XLEN
//                 While in Debug Mode, XLEN is DXLEN. It is up to the
//                 debugger to determine the XLEN during normal program
//                 execution (by looking at misa) and to clearly
//                 communicate this to the user.
// [Yes] 4.8   Core Debug Registers
// [Yes] 4.8.1 Debug Control and Status (dcsr, at 0x7b0)
// [Yes] 4.8.2 Debug PC (dpc, at 0x7b1)
// [---] 4.8.3 Debug Scratch Register 0 (dscratch0, at 0x7b2)
// [---] 4.8.4 Debug Scratch Register 1 (dscratch1, at 0x7b3)
// [Yes] 4.9   Virtual Debug Registers
// [Yes] 4.9.1 Privilege Level (priv, at virtual)
//                 No hardware support
// [Yes] 5     Trigger Module
// 


// Implementation Memo (obsoleted)
// (1) impebreak=1 : Implicit ebreak at the end of Program Buffer (Ver0.13.2 p21)
// (2) Each hart should support Halt-on-Reset.
// (3) Quick Access in Abstract Command is still not implemented.

// Features Not Implemented as specification of mmRISC
// (1) Abstract Command Autoexec: abstractauto 0x18
// (2) Next Debug Module: nextdm 0x1d

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module DEBUG_TOP
    #(parameter
        HART_COUNT = 1
    )
(
    input  wire RES_ORG, // Reset Origin (e.g. Power On Reset)
    output wire RES_SYS, // Reset System
    input  wire CLK,     // System Clock
    //
    input  wire TRSTn,     // JTAG TAP Reset
    input  wire SRSTn_IN,  // System Reset Input except for Debug
    output wire SRSTn_OUT, // System Reset Output from Debug
    //
    input  wire FORCE_HALT_ON_RESET_REQ, // FORCE_HALT_ON_RESET Request
    output wire FORCE_HALT_ON_RESET_ACK, // FORCE_HALT_ON_RESET Acknowledge
    input  wire [31:0] JTAG_DR_USER_IN,  // JTAG DR User Register Input
    output wire [31:0] JTAG_DR_USER_OUT, // JTAG DR User Register Output
    //
    input  wire TCK, // JTAG Clock
    input  wire TMS, // JTAG Mode Select
    input  wire TDI, // JTAG Data Input
    output wire TDO_D, // JTAG Data Output
    output wire TDO_E, // JTAG Data Output Enable
    output wire RTCK,  // JTAG Return Clock
    //
    input  wire        DEBUG_MODE[0 : HART_COUNT - 1],  // Debug Mode
    //
    input  wire        DEBUG_SECURE,        // Debug should be secure, or not
    input  wire [31:0] DEBUG_SECURE_CODE_0, // Debug Security Pass Code 0
    input  wire [31:0] DEBUG_SECURE_CODE_1, // Debug Security Pass Code 1
    //
    output wire HART_HALT_REQ     [0 : HART_COUNT - 1], // HART Halt Command
    input  wire HART_STATUS       [0 : HART_COUNT - 1], // HART Status (0:Run, 1:Halt) 
    input  wire HART_AVAILABLE    [0 : HART_COUNT - 1], // HART Availability (eg. unavailabe if stby)
    output wire HART_RESET        [0 : HART_COUNT - 1], // HART Reset Signal
    output wire HART_HALT_ON_RESET[0 : HART_COUNT - 1], // HART Halt on Reset Request
    output wire HART_RESUME_REQ   [0 : HART_COUNT - 1], // HART Resume Request
    input  wire HART_RESUME_ACK   [0 : HART_COUNT - 1], // HART Resume Acknowledge
    //
    output wire        DBGABS_REQ   [0 : HART_COUNT - 1], // Debug Abstract Command Request
    input  wire        DBGABS_ACK   [0 : HART_COUNT - 1], // Debug Abstract Command Acknowledge
    output wire [ 1:0] DBGABS_TYPE  [0 : HART_COUNT - 1], // Debug Abstract Command Type
    output wire        DBGABS_WRITE [0 : HART_COUNT - 1], // Debug Abstract Command Write (if 0, read)
    output wire [ 1:0] DBGABS_SIZE  [0 : HART_COUNT - 1], // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
    output wire [31:0] DBGABS_ADDR  [0 : HART_COUNT - 1], // Debug Abstract Command Address / Reg No.
    output wire [31:0] DBGABS_WDATA [0 : HART_COUNT - 1], // Debug Abstract Command Write Data
    input  wire [31:0] DBGABS_RDATA [0 : HART_COUNT - 1], // Debug Abstract Command Read Data
    input  wire [ 3:0] DBGABS_DONE  [0 : HART_COUNT - 1], // Debug Abstract Command Done ({BUSERR, EXCEPT, WRITE, ACK})
    //
    output wire        BUSS_M_REQ,       // Debugger System Access
    input  wire        BUSS_M_ACK,       // Debugger System Access
    output wire        BUSS_M_SEQ,       // Debugger System Access
    output wire        BUSS_M_CONT,      // Debugger System Access
    output wire [ 2:0] BUSS_M_BURST,     // Debugger System Access
    output wire        BUSS_M_LOCK,      // Debugger System Access
    output wire [ 3:0] BUSS_M_PROT,      // Debugger System Access
    output wire        BUSS_M_WRITE,     // Debugger System Access
    output wire [ 1:0] BUSS_M_SIZE,      // Debugger System Access
    output wire [31:0] BUSS_M_ADDR,      // Debugger System Access
    output wire [31:0] BUSS_M_WDATA,     // Debugger System Access
    input  wire        BUSS_M_LAST,      // Debugger System Access
    input  wire [31:0] BUSS_M_RDATA,     // Debugger System Access
    input  wire [ 3:0] BUSS_M_DONE,      // Debugger System Access
    input  wire [31:0] BUSS_M_RDATA_RAW, // Debugger System Access
    input  wire [ 3:0] BUSS_M_DONE_RAW   // Debugger System Access
);

//--------------------
// Handle Resets
//--------------------
wire res_tap;
wire res_dbg;
wire res_sys_from_dm;
//
assign RES_SYS = RES_ORG | ~SRSTn_IN | res_sys_from_dm; 
assign SRSTn_OUT = ~res_sys_from_dm;

//----------------------
// Internal Signals
//----------------------
wire        dtmcs_we;    // DTMCS Write Enable (Update)
wire [31:0] dtmcs_wdata; // DTMCS Write Data from DTM to DM
wire [31:0] dtmcs_rdata; // DTMCS Read Data from DM to DTM
wire        dmi_we;    // DMI Write Enable (Update)
wire [40:0] dmi_wdata; // DMI Write Data from DTM to DM
wire        dmi_re;    // DMI Read Data Enable (Ready)
wire [40:0] dmi_rdata; // DMI Read Data from DM to DTM
//
wire        dmbus_req;   // DMBUS Access Request
wire        dmbus_rw;    // DMBUS Read(0)/Write(1)
wire [ 6:0] dmbus_addr;  // DMBUS Address
wire [31:0] dmbus_wdata; // DMBUS Write Data
wire [31:0] dmbus_rdata; // DMBUS Read Data
wire        dmbus_ack;   // DMBUS Access Acknowledge
wire        dmbus_err;   // DMBUS Response Error

//----------------------------------------
// DTM (Debug Trasnport Module) by JTAG
//----------------------------------------
DEBUG_DTM_JTAG U_DEBUG_DTM_JTAG
(
    .TRSTn (TRSTn),
    //
    .TCK (TCK),
    .TMS (TMS),
    .TDI (TDI),
    .TDO_D (TDO_D),
    .TDO_E (TDO_E),
    .RTCK  (RTCK),
    //
    .JTAG_DR_USER_IN  (JTAG_DR_USER_IN ),
    .JTAG_DR_USER_OUT (JTAG_DR_USER_OUT),
    //
    .RES_ORG (RES_ORG),
    .CLK     (CLK),
    //
    .RES_DBG (res_dbg),
    //
    .DMBUS_REQ   (dmbus_req),
    .DMBUS_RW    (dmbus_rw),
    .DMBUS_ADDR  (dmbus_addr),
    .DMBUS_WDATA (dmbus_wdata),
    .DMBUS_RDATA (dmbus_rdata),
    .DMBUS_ACK   (dmbus_ack),
    .DMBUS_ERR   (dmbus_err)
);

//-----------------------------
// DM (Debug Module)
//-----------------------------
DEBUG_DM
    #(
         .HART_COUNT(HART_COUNT)
     )
U_DEBUG_DM
(
    .RES_ORG (RES_ORG),
    .RES_DBG (res_dbg),
    .CLK     (CLK),
    .RES_SYS (res_sys_from_dm),
    //
    .DMBUS_REQ   (dmbus_req),
    .DMBUS_RW    (dmbus_rw),
    .DMBUS_ADDR  (dmbus_addr),
    .DMBUS_WDATA (dmbus_wdata),
    .DMBUS_RDATA (dmbus_rdata),
    .DMBUS_ACK   (dmbus_ack),
    .DMBUS_ERR   (dmbus_err),
    //
    .DEBUG_SECURE        (DEBUG_SECURE),
    .DEBUG_SECURE_CODE_0 (DEBUG_SECURE_CODE_0),
    .DEBUG_SECURE_CODE_1 (DEBUG_SECURE_CODE_1),
    //
    .FORCE_HALT_ON_RESET_REQ (FORCE_HALT_ON_RESET_REQ),
    .FORCE_HALT_ON_RESET_ACK (FORCE_HALT_ON_RESET_ACK),
    //
    .HART_HALT_REQ      (HART_HALT_REQ),
    .HART_STATUS        (HART_STATUS),
    .HART_AVAILABLE     (HART_AVAILABLE),
    .HART_RESET         (HART_RESET),
    .HART_HALT_ON_RESET (HART_HALT_ON_RESET),
    .HART_RESUME_REQ    (HART_RESUME_REQ),
    .HART_RESUME_ACK    (HART_RESUME_ACK),
    //
    .DBGABS_REQ   (DBGABS_REQ),
    .DBGABS_ACK   (DBGABS_ACK),
    .DBGABS_TYPE  (DBGABS_TYPE),
    .DBGABS_WRITE (DBGABS_WRITE),
    .DBGABS_SIZE  (DBGABS_SIZE),
    .DBGABS_ADDR  (DBGABS_ADDR),
    .DBGABS_WDATA (DBGABS_WDATA),
    .DBGABS_RDATA (DBGABS_RDATA),
    .DBGABS_DONE  (DBGABS_DONE),
    //
    .BUSS_M_REQ   (BUSS_M_REQ),
    .BUSS_M_ACK   (BUSS_M_ACK),
    .BUSS_M_SEQ   (BUSS_M_SEQ),
    .BUSS_M_CONT  (BUSS_M_CONT),
    .BUSS_M_BURST (BUSS_M_BURST),
    .BUSS_M_LOCK  (BUSS_M_LOCK),
    .BUSS_M_PROT  (BUSS_M_PROT),
    .BUSS_M_WRITE (BUSS_M_WRITE),
    .BUSS_M_SIZE  (BUSS_M_SIZE),
    .BUSS_M_ADDR  (BUSS_M_ADDR),
    .BUSS_M_WDATA (BUSS_M_WDATA),
    .BUSS_M_LAST  (BUSS_M_LAST),
    .BUSS_M_RDATA (BUSS_M_RDATA),
    .BUSS_M_DONE  (BUSS_M_DONE),
    .BUSS_M_RDATA_raw (BUSS_M_RDATA_RAW),
    .BUSS_M_DONE_raw  (BUSS_M_DONE_RAW)
);

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
