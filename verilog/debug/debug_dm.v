//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : debug_dm.v
// Description : Debug DM (Debug Module)
//-----------------------------------------------------------
// History :
// Rev.01 2017.08.02 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================
// RISC-V External Debug Support Version 0.13.2
// [Yes] 3     Debug Module (DM)
//     (1) Features to be implemented:
//         [Yes] 1. Give the debugger necessary information about the implementation. (Required)
//         [Yes] 2. Allow any individual hart to be halted and resumed. (Required)
//         [Yes] 3. Provide status on which harts are halted. (Required)
//         [Yes] 4. Provide abstract read and write access to a halted hart's GPRs. (Required)
//         [Yes] 5. Provide access to a reset signal that allows debugging from the very first instruction after reset. (Required)
//         [Yes] 6. Provide a mechanism to allow debugging harts immediately out of reset (regardless of the reset cause). (Optional)
//         [Yes] 7. Provide abstract access to non-GPR hart registers. (Optional)
//         [---] 8. Provide a Program Buffer to force the hart to execute arbitrary instructions. (Optional)
//         [Yes] 9. Allow multiple harts to be halted, resumed, and/or reset at the same time. (Optional)
//         [Yes] 10. Allow memory access from a hart's point of view. (Optional)
//         [Yes] 11. Allow direct System Bus Access. (Optional)
//     (2) In order to be compliant with this specifiation an implementation must:
//         [Yes] 1. Implement all the required features listed above.
//         [Yes] 2. Implement at least one of followings:
//             [---] Program Buffer
//             [Yes] System Bus Access
//             [Yes] Abstract Access Memory command mechanisms
//     (3) Do at least one of:
//         [---] (a) Implement the Program Buffer
//         [Yes] (b) Implement abstract access to all registers that are visible to software running on the hart
//                   including all the registers that are present on the hart and listed in Table 3.3.
//         [Yes] (c) Implement abstract access to at least all GPRs, dcsr, and dpc, 
//                   and advertise the implementation as conforming to the "Minimal RISC-V Debug Speciffiation 0.13.2",
//                   instead of the "RISC-V Debug Speciffiation 0.13.2".
//     (4) A single DM can debug up to 2^20 harts.--> This implementation supports maximum 1024 harts.
// [Yes] 3.1   Debug Module Interface (DMI)
// [Yes] 3.2   Reset Control
// [Yes] 3.3   Selecting Harts
// [Yes] 3.3.1 Selecting a Single Hart
// [Yes] 3.3.2 Selecting Multiple Harts
// [Yes] 3.4   Hart Status
// [Yes] 3.5   Run Control
// [Yes] 3.6   Abstract Commands
// [Yes] 3.6.1 Abstract Command Listings
// [Yes] 3.6.1.1 Access Register
//     [---] aarpostincrement (optional)
//     [---] postexec (optional)
// [---] 3.6.1.2 Quick Access (optional)
// [Yes] 3.6.1.3 Access Memory
// [---] 3.7   Program Buffer
// [Yes] 3.8   Overview of Status
// [Yes] 3.9   System Bus Access
// [Yes] 3.10  Minimally Intrusive Debugging
// [Yes] 3.11  Security
// [Yes] 3.12  Debug Module Registers
// [Yes] 3.12.1  Debug Module Status (dmstatus, at 0x11)
//                   impebreak = 0, confstrptrvalid = 0
// [Yes] 3.12.2  Debug Module Control (dmcontrol, at 0x10)
// [Yes] 3.12.3  Hart Info (hartinfo, at 0x12)
//                   nscratch = 0, dataaccess = 0
//                   datasize = 0, dataaddr = 0
// [Yes] 3.12.4  Hart Array Window Select (hawindowsel, at 0x14)
// [Yes] 3.12.5  Hart Array Window (hawindow, at 0x15)
// [Yes] 3.12.6  Abstract Control and Status (abstractcs, at 0x16)
//                   progbufsize = 0, datacount = 12
// [Yes] 3.12.7  Abstract Command (command, at 0x17)
// [---] 3.12.8  Abstract Command Autoexec (abstractauto, at 0x18)
// [---] 3.12.9  Configuration String Pointer 0 (confstrptr0, at 0x19)
//                   Default Read Value 0x00000000
// [---] 3.12.10 Next Debug Module (nextdm, at 0x1d)
//                   Default Read Value 0x00000000 as Last Debug Module
// [Yes] 3.12.11 Abstract Data (data0, at 0x04, ..., data11, at 0x0f)
// [---] 3.12.12 Program Buffer 0 (progbuf0, at 0x20, ...)
// [Yes] 3.12.13 Authentication Data (authdata, at 0x30)
// [Yes] 3.12.14 Halt Summary 0 (haltsum0, at 0x40)
// [Yes] 3.12.15 Halt Summary 1 (haltsum1, at 0x13)
// [Yes] 3.12.16 Halt Summary 2 (haltsum2, at 0x34)
// [Yes] 3.12.17 Halt Summary 3 (haltsum3, at 0x35)
// [Yes] 3.12.18 System Bus Access Control and Status (sbcs, at 0x38)
// [Yes] 3.12.19 System Bus Address 31:0 (sbaddress0, at 0x39)
// [---] 3.12.20 System Bus Address 63:32 (sbaddress1, at 0x3a)
// [---] 3.12.21 System Bus Address 95:64 (sbaddress2, at 0x3b)
// [---] 3.12.22 System Bus Address 127:96 (sbaddress3, at 0x37)
// [Yes] 3.12.23 System Bus Data 31:0 (sbdata0, at 0x3c)
// [---] 3.12.24 System Bus Data 63:32 (sbdata1, at 0x3d)
// [---] 3.12.25 System Bus Data 95:64 (sbdata2, at 0x3e)
// [---] 3.12.26 System Bus Data 127:96 (sbdata3, at 0x3f)

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module DEBUG_DM
    #(parameter
        HART_COUNT = 1
    ) 
(
    input  wire  RES_ORG, // Reset Origin (e.g. Power On Reset)
    input  wire  RES_DBG, // Reset Debugger
    input  wire  CLK,     // Clock
    output wire  RES_SYS, // Reset Rest of System
    //
    input  wire        DMBUS_REQ,   // DMBUS Access Request
    input  wire        DMBUS_RW,    // DMBUS Read(0)/Write(1)
    input  wire [ 6:0] DMBUS_ADDR,  // DMBUS Address
    input  wire [31:0] DMBUS_WDATA, // DMBUS Write Data
    output wire [31:0] DMBUS_RDATA, // DMBUS Read Data
    output wire        DMBUS_ACK,   // DMBUS Access Acknowledge
    output wire        DMBUS_ERR,   // DMBUS Response Error
    //
    input  wire        DEBUG_SECURE,        // Debug should be secure, or not
    input  wire [31:0] DEBUG_SECURE_CODE_0, // Debug Security Pass Code 0
    input  wire [31:0] DEBUG_SECURE_CODE_1, // Debug Security Pass Code 1
    //
    input  wire FORCE_HALT_ON_RESET_REQ, // FORCE_HALT_ON_RESET Request
    output reg  FORCE_HALT_ON_RESET_ACK, // FORCE_HALT_ON_RESET Acknowledge
    //
    output reg  HART_HALT_REQ     [0 : HART_COUNT - 1], // HART Halt Command
    input  wire HART_STATUS       [0 : HART_COUNT - 1], // HART Status (0:Run, 1:Halt) 
    input  wire HART_AVAILABLE    [0 : HART_COUNT - 1], // HART Availability (eg. unavailabe if stby)
    output reg  HART_RESET        [0 : HART_COUNT - 1], // HART Reset Signal
    output reg  HART_HALT_ON_RESET[0 : HART_COUNT - 1], // HART Halt on Reset Request
    output reg  HART_RESUME_REQ   [0 : HART_COUNT - 1], // HART Resume Request
    input  wire HART_RESUME_ACK   [0 : HART_COUNT - 1], // HART Resume Acknowledge
    //
    output reg         DBGABS_REQ   [0 : HART_COUNT - 1], // Debug Abstract Command Request
    input  wire        DBGABS_ACK   [0 : HART_COUNT - 1], // Debug Abstract Command Acknowledge
    output reg  [ 1:0] DBGABS_TYPE  [0 : HART_COUNT - 1], // Debug Abstract Command Type
    output reg         DBGABS_WRITE [0 : HART_COUNT - 1], // Debug Abstract Command Write (if 0, read)
    output reg  [ 1:0] DBGABS_SIZE  [0 : HART_COUNT - 1], // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
    output reg  [31:0] DBGABS_ADDR  [0 : HART_COUNT - 1], // Debug Abstract Command Address / Reg No.
    output reg  [31:0] DBGABS_WDATA [0 : HART_COUNT - 1], // Debug Abstract Command Write Data
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
    input  wire [31:0] BUSS_M_RDATA_raw, // Debugger System Access
    input  wire [ 3:0] BUSS_M_DONE_raw   // Debugger System Access
);

//----------------------
// Internal Signals
//----------------------
wire authok; // Authentification OK
reg [HART_COUNT - 1 : 0] ha_sel; // Hart Select

//-----------------
// Reset Signals
//-----------------
wire res_dm; // Reset Debug Module
reg  [HART_COUNT - 1 : 0] havereset; // Sticky Reset Flag

//----------------------------
// DM Debug Bus Registers
//----------------------------
reg [31:0] dm_data[0:1];
reg [31:0] dm_control;
reg [31:0] dm_authdata;
reg [14:0] dm_hawindowsel;
reg [HART_COUNT - 1 : 0] dm_hamask; // Hart Select Array Mask

//----------------
// Decode Signals
//----------------
reg  sel_dm_data;
reg  sel_dm_control;
reg  sel_dm_status;
reg  sel_dm_hartinfo;
reg  sel_dm_hawindowsel;
reg  sel_dm_hawindow;
reg  sel_dm_abstractcs;
reg  sel_dm_command;
reg  sel_dm_authdata;
reg  sel_dm_haltsum0;
reg  sel_dm_haltsum1;
reg  sel_dm_haltsum2;
reg  sel_dm_haltsum3;
wire sel_dm_haltsum;
reg  sel_dm_default;
reg  sel_dm_sbcs;
reg  sel_dm_sbaddr;
reg  sel_dm_sbdata;
//
always @*
begin
    sel_dm_data = 1'b0;
    sel_dm_control = 1'b0;
    sel_dm_status = 1'b0;
    sel_dm_hartinfo = 1'b0;
    sel_dm_hawindowsel = 1'b0;
    sel_dm_hawindow = 1'b0;
    sel_dm_abstractcs = 1'b0;
    sel_dm_command  = 1'b0;
    sel_dm_authdata = 1'b0;
    sel_dm_haltsum0 = 1'b0;
    sel_dm_haltsum1 = 1'b0;
    sel_dm_haltsum2 = 1'b0;
    sel_dm_haltsum3 = 1'b0;
    sel_dm_default = 1'b0;
    sel_dm_sbcs = 1'b0;
    sel_dm_sbaddr = 1'b0;
    sel_dm_sbdata = 1'b0;
    //
    casez(DMBUS_ADDR)
      //7'b000_01?? : sel_dm_data = DMBUS_REQ;
      //7'b000_1??? : sel_dm_data = DMBUS_REQ;
        7'b000_010? : sel_dm_data = DMBUS_REQ;
        `DM_CONTROL : sel_dm_control = DMBUS_REQ;
        `DM_STATUS      : sel_dm_status = DMBUS_REQ;
        `DM_HARTINFO    : sel_dm_hartinfo = DMBUS_REQ;
        `DM_HAWINDOWSEL : sel_dm_hawindowsel = DMBUS_REQ;
        `DM_HAWINDOW    : sel_dm_hawindow = DMBUS_REQ;
        `DM_AUTHDATA    : sel_dm_authdata = DMBUS_REQ;
        `DM_ABSTRACTCS  : sel_dm_abstractcs = DMBUS_REQ;
        `DM_COMMAND     : sel_dm_command  = DMBUS_REQ;
        `DM_HALTSUM0    : sel_dm_haltsum0 = DMBUS_REQ;
        `DM_HALTSUM1    : sel_dm_haltsum1 = DMBUS_REQ;
        `DM_HALTSUM2    : sel_dm_haltsum2 = DMBUS_REQ;
        `DM_HALTSUM3    : sel_dm_haltsum3 = DMBUS_REQ;
        `DM_SBCS        : sel_dm_sbcs = DMBUS_REQ;
        `DM_SBADDRESS_0 : sel_dm_sbaddr = DMBUS_REQ;
        `DM_SBDATA_0    : sel_dm_sbdata = DMBUS_REQ;
        default         : sel_dm_default = DMBUS_REQ;
    endcase
end
assign sel_dm_haltsum = sel_dm_haltsum0 | sel_dm_haltsum1 | sel_dm_haltsum2 | sel_dm_haltsum3;

//-----------
// Read Data
//-----------
wire [31:0] rdata_dm_data;
wire [31:0] rdata_dm_control;
wire [31:0] rdata_dm_status;
wire [31:0] rdata_dm_hartinfo;
wire [31:0] rdata_dm_hawindowsel;
reg  [31:0] rdata_dm_hawindow;
wire [31:0] rdata_dm_abstractcs;
wire [31:0] rdata_dm_command;
wire [31:0] rdata_dm_authdata;
reg  [31:0] rdata_dm_haltsum0;
reg  [31:0] rdata_dm_haltsum1;
reg  [31:0] rdata_dm_haltsum2;
reg  [31:0] rdata_dm_haltsum3;
wire [31:0] rdata_dm_default;
wire [31:0] rdata_dm_sbcs;
wire [31:0] rdata_dm_sbaddr;
wire [31:0] rdata_dm_sbdata;
//
assign DMBUS_RDATA = rdata_dm_data
                   | rdata_dm_control
                   | rdata_dm_status
                   | rdata_dm_hartinfo
                   | rdata_dm_hawindowsel
                   | rdata_dm_hawindow
                   | rdata_dm_abstractcs
                   | rdata_dm_command
                   | rdata_dm_authdata
                   | rdata_dm_haltsum0
                   | rdata_dm_haltsum1
                   | rdata_dm_haltsum2
                   | rdata_dm_haltsum3
                   | rdata_dm_default
                   | rdata_dm_sbcs
                   | rdata_dm_sbaddr
                   | rdata_dm_sbdata;
                   
//----------------------------
// Acknowledge & Error Signal
//----------------------------
reg  ack_dm_data;
reg  ack_dm_control;
reg  ack_dm_status;
reg  ack_dm_hartinfo;
reg  ack_dm_hawindowsel;
reg  ack_dm_hawindow;
reg  ack_dm_abstractcs;
reg  ack_dm_command;
reg  ack_dm_authdata;
reg  ack_dm_haltsum;
reg  ack_dm_default;
reg  ack_dm_sbcs;
reg  ack_dm_sbaddr;
reg  ack_dm_sbdata;
//
wire err_dm_data;
wire err_dm_control;
wire err_dm_status;
wire err_dm_hartinfo;
wire err_dm_hawindowsel;
wire err_dm_hawindow;
wire err_dm_abstractcs;
wire err_dm_command;
wire err_dm_authdata;
wire err_dm_haltsum;
wire err_dm_default;
wire err_dm_sbcs;
wire err_dm_sbaddr;
wire err_dm_sbdata;
//
assign DMBUS_ACK = ack_dm_data | ack_dm_control
                 | ack_dm_status | ack_dm_hartinfo
                 | ack_dm_hawindowsel | ack_dm_hawindow
                 | ack_dm_abstractcs  | ack_dm_command
                 | ack_dm_authdata
                 | ack_dm_haltsum | ack_dm_default
                 | ack_dm_sbcs | ack_dm_sbaddr | ack_dm_sbdata;
assign DMBUS_ERR = err_dm_data | err_dm_control
                 | err_dm_status | err_dm_hartinfo
                 | err_dm_hawindowsel | err_dm_hawindow
                 | err_dm_abstractcs  | err_dm_command
                 | err_dm_authdata
                 | err_dm_haltsum | err_dm_default
                 | err_dm_sbcs | err_dm_sbaddr | err_dm_sbdata;

//---------------------
// DM Default
//---------------------
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_default <= 1'b0;
    else if (ack_dm_default)
        ack_dm_default <= 1'b0;
    else if (sel_dm_default)
        ack_dm_default <= 1'b1;
end
assign err_dm_default = 1'b0;
assign rdata_dm_default = (ack_dm_default)? 
    {16'hdead, 9'b0, DMBUS_ADDR} : 32'h00000000;

//--------------------------------------
// DM Authentification Data authdata
//--------------------------------------
wire authbusy;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
    begin
        dm_authdata <= 32'h00000000;
    end
    else if (sel_dm_authdata & DMBUS_RW)
    begin
        dm_authdata <= DMBUS_WDATA;
    end
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_authdata <= 1'b0;
    else if (ack_dm_authdata)
        ack_dm_authdata <= 1'b0;
    else if (sel_dm_authdata)
        ack_dm_authdata <= 1'b1;
end
assign err_dm_authdata = 1'b0;
//
assign rdata_dm_authdata
    = (ack_dm_authdata & authok)? dm_authdata : 32'h00000000;
//
assign authok = ~DEBUG_SECURE | (dm_authdata == DEBUG_SECURE_CODE_0)
                              | (dm_authdata == DEBUG_SECURE_CODE_1);
assign authbusy = 1'b0;

//---------------------------
// DM Abstract Data 0-1
//---------------------------
wire        dbgabs_arg0_read;
reg  [31:0] dbgabs_arg0_data;
wire [ 2:0] dbgabs_arg1_incr; // +1, +2, +4
//
reg  abstract_busy; // abstract command busy
//
always @(posedge CLK, posedge res_dm)
begin
    if (res_dm)
    begin
      dm_data[ 0] <= 32'h00000000;
    end
    else if (~abstract_busy & sel_dm_data & DMBUS_RW & authok & (DMBUS_ADDR == 7'h04))
    begin
        dm_data[ 0] <= DMBUS_WDATA;
    end
    else if (dbgabs_arg0_read)
    begin
        dm_data[ 0] <= dbgabs_arg0_data;
    end
end
//
always @(posedge CLK, posedge res_dm)
begin
    if (res_dm)
    begin
      dm_data[ 1] <= 32'h00000000;
    end
    else if (~abstract_busy & sel_dm_data & DMBUS_RW & authok & (DMBUS_ADDR == 7'h05))
    begin
        dm_data[ 1] <= DMBUS_WDATA;
    end
    else if (dbgabs_arg1_incr)
        dm_data[ 1] <= dm_data[ 1] + {29'h0, dbgabs_arg1_incr};
end
//
//always @(posedge CLK, posedge res_dm)
//begin
//    if (res_dm)
//    begin
//      dm_data[ 2] <= 32'h00000000; dm_data[ 3] <= 32'h00000000;
//      dm_data[ 4] <= 32'h00000000; dm_data[ 5] <= 32'h00000000;
//      dm_data[ 6] <= 32'h00000000; dm_data[ 7] <= 32'h00000000;
//      dm_data[ 8] <= 32'h00000000; dm_data[ 9] <= 32'h00000000;
//      dm_data[10] <= 32'h00000000; dm_data[11] <= 32'h00000000;
//    end
//    else if (~abstract_busy & sel_dm_data & DMBUS_RW & authok & (addr_dm_data >= 4'h2))
//    begin
//             if (addr_dm_data == 4'd02) dm_data[ 2] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd03) dm_data[ 3] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd04) dm_data[ 4] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd05) dm_data[ 5] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd06) dm_data[ 6] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd07) dm_data[ 7] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd08) dm_data[ 8] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd09) dm_data[ 9] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd10) dm_data[10] <= DMBUS_WDATA;
//        else if (addr_dm_data == 4'd11) dm_data[11] <= DMBUS_WDATA;
//    end
//end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_data <= 1'b0;
    else if (ack_dm_data)
        ack_dm_data <= 1'b0;
    else if (sel_dm_data)
        ack_dm_data <= 1'b1;
end
assign err_dm_data = 1'b0;
// DMBUS_ADDR is kept between REQ and ACK
assign rdata_dm_data
    = (ack_dm_data & authok)? dm_data[DMBUS_ADDR[0]] : 32'h00000000;

//-----------------------------------
// Debug Module Control : dmcontrol
//-----------------------------------
wire        sethaltreq;   // Set Halt Request
wire        clrhaltreq;   // Clear Halt Request
wire        haltreq;      // Halt Request
wire        resumereq;    // Resume Request
wire        sethartreset; // Set Hart Reset
wire        clrhartreset; // Clear Hart Reset
wire        hartreset;    // Hart Reset
wire        ackhavereset; // Have Reset Acknowledge
wire        hasel;        // Hart Select Method
wire [19:0] hartsel;      // Hart Selected
wire        setresethaltreq; // Set Halt on Reset Request
wire        clrresethaltreq; // Set Halt on Reset Request
wire        ndmreset;     // Reset Rest of System
wire        dmactive;     // if 0 then reset DM
assign sethaltreq   = sel_dm_control & DMBUS_RW & authok &  DMBUS_WDATA[31];
assign clrhaltreq   = sel_dm_control & DMBUS_RW & authok & ~DMBUS_WDATA[31];
assign haltreq      = dm_control[31];
assign resumereq    = sel_dm_control & DMBUS_RW & authok &  DMBUS_WDATA[30] & ~haltreq;
assign sethartreset = sel_dm_control & DMBUS_RW & authok &  DMBUS_WDATA[29];
assign clrhartreset = sel_dm_control & DMBUS_RW & authok & ~DMBUS_WDATA[29];
assign hartreset    = dm_control[29];
assign ackhavereset = sel_dm_control & DMBUS_RW & authok & DMBUS_WDATA[28];
assign hasel        = dm_control[26];
assign hartsel      = {dm_control[15:6], dm_control[25:16]};
assign setresethaltreq = sel_dm_control & DMBUS_RW & authok & DMBUS_WDATA[3];
assign clrresethaltreq = sel_dm_control & DMBUS_RW & authok & DMBUS_WDATA[2];
assign ndmreset  = dm_control[1];
assign dmactive  = dm_control[0];
//
// dmactive can be accessed even if not authencated
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        dm_control[0] <= 1'b0;
    else if (sel_dm_control & DMBUS_RW) // do not include authok
        dm_control[0] <= DMBUS_WDATA[0];
end
//
always @(posedge CLK, posedge res_dm)
begin
    if (res_dm)
        dm_control[31:1] <= 31'h00000000;
    else if (sel_dm_control & DMBUS_RW & authok)
    begin
        dm_control[31:1] <= DMBUS_WDATA[31:1];
    end
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_control <= 1'b0;
    else if (ack_dm_control)
        ack_dm_control <= 1'b0;
    else if (sel_dm_control)
        ack_dm_control <= 1'b1;
end
assign err_dm_control = 1'b0;
//
assign rdata_dm_control
    = (ack_dm_control & ~authok)? {31'h0, dm_control[0]} :
      (ack_dm_control &  authok)?
      {
          dm_control[31], 1'b0, dm_control[29], 2'b00, dm_control[26], 
          dm_control[25:16], dm_control[15:6], 4'b0000,
          dm_control[1], dm_control[0]          
      } : 32'h00000000;

//---------------------------------
// Debug Module Status dmstatus
//---------------------------------
wire impebreak;
reg  allhavereset;
reg  anyhavereset;
reg  allresumeack;
reg  anyresumeack;
reg  allnoexistent;
reg  anynoexistent;
reg  allunavail;
reg  anyunavail;
reg  allrunning;
reg  anyrunning;
reg  allhalted;
reg  anyhalted;
wire authenticated;
//wire authbusy;
wire hasresethaltreq;
wire confstrptrvalid;
wire [3:0] version;
//
assign impebreak = 1'b0;
assign authenticated = authok;
assign hasresethaltreq = 1'b1;
assign confstrptrvalid = 1'b0;
assign version = 4'b0010; // Ver.0.13
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_status <= 1'b0;
    else if (ack_dm_status)
        ack_dm_status <= 1'b0;
    else if (sel_dm_status)
        ack_dm_status <= 1'b1;
end
assign err_dm_status = 1'b0;
//
always @*
begin
    integer i;
    allhavereset = 1'b1;
    anyhavereset = 1'b0;
    allresumeack = 1'b1;
    anyresumeack = 1'b0;
    allnoexistent = 1'b1;
    anynoexistent = 1'b1;
    allunavail = 1'b1;
    anyunavail = 1'b0;
    allrunning = 1'b1;
    anyrunning = 1'b0;
    allhalted = 1'b1;
    anyhalted = 1'b0;
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin
        allhavereset = allhavereset & ((ha_sel[i])? havereset[i] : 1'b1);
        anyhavereset = anyhavereset | ((ha_sel[i])? havereset[i] : 1'b0);
        allresumeack = allresumeack & ((ha_sel[i])? HART_RESUME_ACK[i] : 1'b1);
        anyresumeack = anyresumeack | ((ha_sel[i])? HART_RESUME_ACK[i] : 1'b0);
        allnoexistent = allnoexistent & ~ha_sel[i]; // if selected, exists
        anynoexistent = anynoexistent & ~ha_sel[i]; // if selected, exists
        allunavail = allunavail & ((ha_sel[i])? ~HART_AVAILABLE[i] : 1'b1);
        anyunavail = anyunavail | ((ha_sel[i])? ~HART_AVAILABLE[i] : 1'b0);
        allrunning = allrunning & ((ha_sel[i])? ~HART_STATUS[i] : 1'b1);
        anyrunning = anyrunning | ((ha_sel[i])? ~HART_STATUS[i] : 1'b0);
        allhalted = allhalted & ((ha_sel[i])? HART_STATUS[i] : 1'b1);
        anyhalted = anyhalted | ((ha_sel[i])? HART_STATUS[i] : 1'b0);
    end
end
//
assign rdata_dm_status
    = (sel_dm_status)?
          {9'h0,
           impebreak & authok,
           2'h0,
           allhavereset & authok,
           anyhavereset & authok,
           allresumeack & authok,
           anyresumeack & authok,
           allnoexistent & authok,
           anynoexistent & authok,
           allunavail & authok,
           anyunavail & authok,
           allrunning & authok,
           anyrunning & authok,
           allhalted & authok,
           anyhalted & authok,
           authenticated,
           authbusy,
           hasresethaltreq & authok,
           confstrptrvalid & authok,
           version  // Ver0.13
          } : 32'h00000000;

//----------------------------
// Hart Information : hartinfo
//----------------------------
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_hartinfo <= 1'b0;
    else if (ack_dm_hartinfo)
        ack_dm_hartinfo <= 1'b0;
    else if (sel_dm_hartinfo)
        ack_dm_hartinfo <= 1'b1;
end
assign err_dm_hartinfo = 1'b0;
assign rdata_dm_hartinfo = (ack_dm_hartinfo)? 
    {
        8'b0,
        4'b0000,  // nscratch = 0
        3'b0,
        1'b0,     // dataaccess = 0
        4'b0000,  // datasize = 0
        12'h000   // dataaddr = 0
    } : 32'h00000000;

//-----------------------------------------
// Hart Array Window Select : hawindowsel
//-----------------------------------------
always @(posedge CLK, posedge res_dm)
begin
    if (res_dm)
    begin
        dm_hawindowsel <= 15'h0000;
    end
    else if (sel_dm_hawindowsel & DMBUS_RW & authok)
    begin
        dm_hawindowsel <= {DMBUS_WDATA[14:0]};
    end
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_hawindowsel <= 1'b0;
    else if (ack_dm_hawindowsel)
        ack_dm_hawindowsel <= 1'b0;
    else if (sel_dm_hawindowsel)
        ack_dm_hawindowsel <= 1'b1;
end
assign err_dm_hawindowsel = 1'b0;
//
assign rdata_dm_hawindowsel
    = (ack_dm_hawindowsel & authok)? {17'h0, dm_hawindowsel} : 32'h00000000;

//---------------------------------
// Hart Array Window : hawindow
// (Hart Array Mask Register)
//---------------------------------
always @(posedge CLK, posedge res_dm)
begin
    integer i;
    if (res_dm)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1) dm_hamask[i] <= 1'b0;
    end
    else if (sel_dm_hawindow & DMBUS_RW & authok)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            dm_hamask[i] <= ((i >> 5) == dm_hawindowsel)? 
                                DMBUS_WDATA[i - (i >> 5)] : dm_hamask[i];
        end
    end
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_hawindow <= 1'b0;
    else if (ack_dm_hawindow)
        ack_dm_hawindow <= 1'b0;
    else if (sel_dm_hawindow)
        ack_dm_hawindow <= 1'b1;
end
assign err_dm_hawindow = 1'b0;
//
always @*
begin
    rdata_dm_hawindow = 32'h00000000;
    if (ack_dm_hawindow & authok)
    begin
        rdata_dm_hawindow = dm_hamask >> (dm_hawindowsel << 5);
    end
end

//----------------------------------------
// Hart Select Signal (Single and Array)
//----------------------------------------
always @*
begin
    integer i;
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin
        ha_sel[i] = (hartsel == i) | (hasel & dm_hamask[i]);
    end
end

//-------------------
// Hart Control
//-------------------
//always @(posedge CLK, posedge res_dm)
//begin
//    integer i;
//    for (i = 0; i < HART_COUNT; i = i + 1)
//    begin
//        if (res_dm)
//            HART_HALT_REQ[i] <= 1'b0;
//        else if (sethaltreq & ha_sel[i])
//            HART_HALT_REQ[i] <= 1'b1;
//        else if (clrhaltreq & ha_sel[i])
//            HART_HALT_REQ[i] <= 1'b0;    
//    end
//end
always @(posedge CLK, posedge res_dm)
begin
    integer i;    
    if (res_dm)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            HART_HALT_REQ[i] <= 1'b0;
        end
    end
    else
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            if (sethaltreq & ha_sel[i])
            begin
                HART_HALT_REQ[i] <= 1'b1;
            end
            else if (clrhaltreq & ha_sel[i])
            begin
                HART_HALT_REQ[i] <= 1'b0;
            end
        end
    end
end
//
//always @(posedge CLK, posedge res_dm)
//begin
//    integer i;
//    for (i = 0; i < HART_COUNT; i = i + 1)
//    begin
//        if (res_dm)
//            HART_RESET[i] <= 1'b0;
//        else if (sethartreset & ha_sel[i])
//            HART_RESET[i] <= 1'b1;
//        else if (clrhartreset & ha_sel[i])
//            HART_RESET[i] <= 1'b0;    
//    end
//end
always @(posedge CLK, posedge res_dm)
begin
    integer i;    
    if (res_dm)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            HART_RESET[i] <= 1'b0;
        end
    end
    else
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            if (sethartreset & ha_sel[i])
            begin
                HART_RESET[i] <= 1'b1;
            end
            else if (clrhartreset & ha_sel[i])
            begin
                HART_RESET[i] <= 1'b0;    
            end
        end
    end
end
//
reg  hart_halt_on_reset[0 : HART_COUNT - 1];
//always @(posedge CLK, posedge res_dm)
//begin
//    integer i;
//    for (i = 0; i < HART_COUNT; i = i + 1)
//    begin
//        if (res_dm)
//            hart_halt_on_reset[i] <= 1'b0;
//        else if (setresethaltreq & ha_sel[i])
//            hart_halt_on_reset[i] <= 1'b1;
//        else if (clrresethaltreq & ha_sel[i])
//            hart_halt_on_reset[i] <= 1'b0;    
//    end
//end
always @(posedge CLK, posedge res_dm)
begin
    integer i;
    if (res_dm)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            hart_halt_on_reset[i] <= 1'b0;
        end
    end
    else
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            if (setresethaltreq & ha_sel[i])
            begin
                hart_halt_on_reset[i] <= 1'b1;
            end
            else if (clrresethaltreq & ha_sel[i])
            begin
                hart_halt_on_reset[i] <= 1'b0;    
            end
        end
    end
end
//
always @*
begin
    integer i;
    FORCE_HALT_ON_RESET_ACK = 1'b0;
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin
        HART_HALT_ON_RESET[i]
        = FORCE_HALT_ON_RESET_REQ | hart_halt_on_reset[i];
        //
        FORCE_HALT_ON_RESET_ACK
        = FORCE_HALT_ON_RESET_ACK | HART_RESUME_ACK[i];
    end
end
//
//always @(posedge CLK, posedge res_dm)
//begin
//    integer i;
//    for (i = 0; i < HART_COUNT; i = i + 1)
//    begin
//        if (res_dm)
//            HART_RESUME_REQ[i] <= 1'b0;
//        else if (resumereq & ha_sel[i])
//            HART_RESUME_REQ[i] <= 1'b1;
//        else if (HART_RESUME_ACK[i])
//            HART_RESUME_REQ[i] <= 1'b0;    
//    end
//end
always @(posedge CLK, posedge res_dm)
begin
    integer i;    
    if (res_dm)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            HART_RESUME_REQ[i] <= 1'b0;
        end
    end
    else
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin        
            if (resumereq & ha_sel[i])
            begin
                HART_RESUME_REQ[i] <= 1'b1;
            end
            else if (HART_RESUME_ACK[i])
            begin
                HART_RESUME_REQ[i] <= 1'b0;    
            end
        end
    end
end

//---------------------------
// Halt Summary haltsum0,1,2
//---------------------------
reg hart_group_status1;
reg hart_group_status2;
reg hart_group_status3;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_haltsum <= 1'b0;
    else if (ack_dm_haltsum)
        ack_dm_haltsum <= 1'b0;
    else if (sel_dm_haltsum)
        ack_dm_haltsum <= 1'b1;
end
assign err_dm_haltsum = 1'b0;
//
always @*
begin
    integer i;
    rdata_dm_haltsum0 = 32'h00000000;
    if (sel_dm_haltsum0 & authok)
    begin
        for (i = 0; i < 32; i = i + 1)
        begin
            if ((hartsel & 20'hfffe0) + i < HART_COUNT)
                rdata_dm_haltsum0[i] = HART_STATUS[(hartsel & 20'hfffe0) + i];
        end
    end
end
//
always @*
begin
    rdata_dm_haltsum1 = 32'h00000000;
    //
    if (HART_COUNT >= 32)
    begin
        integer i, j;
        if (sel_dm_haltsum1 & authok)
        begin
            for (i = 0; i < 32; i = i + 1)
            begin
                for (j = 0; j < 32; j = j + 1)
                begin
                    if ((hartsel & 20'hffc00) + (i << 5) + j < HART_COUNT)
                        rdata_dm_haltsum1[i] = rdata_dm_haltsum1[i] 
                            | HART_STATUS[(hartsel & 20'hffc00) + (i << 5) + j];
                end
            end
        end
    end
end
//
always @*
begin
    rdata_dm_haltsum2 = 32'h00000000;
    //
    if (HART_COUNT >= 1024)
    begin
        integer i, j;
        if (sel_dm_haltsum2 & authok)
        begin
            for (i = 0; i < 32; i = i + 1)
            begin
                for (j = 0; j < 1024; j = j + 1)
                begin
                    if ((hartsel & 20'hf8000) + (i << 10) + j < HART_COUNT)
                        rdata_dm_haltsum2[i] = rdata_dm_haltsum2[i] 
                            | HART_STATUS[(hartsel & 20'hf8000) + (i << 10) + j];
                end
            end
        end        
    end
end
//
always @*
begin
    rdata_dm_haltsum3 = 32'h00000000;
    //
    if (HART_COUNT >= 32768)
    begin
        integer i, j, k;
        if (sel_dm_haltsum3 & authok)
        begin
            for (i = 0; i < 32; i = i + 1)
            begin
                for (j = 0; j < 8; j = j + 1)
                begin
                    for (k = 0; k < 4096; k = k + 1)
                    begin
                        if ((i << 15) + (j * 4096) + k < HART_COUNT)
                            rdata_dm_haltsum3[i] = rdata_dm_haltsum3[i] 
                                | HART_STATUS[(i << 15) + j];
                    end
                end
            end
        end
    end
end

//-----------------------------------
// Abstract Command Internal Signal
//-----------------------------------
reg         DBGABS_REQ_internal;   // Debug Abstract Command Request
reg         DBGABS_ACK_internal;   // Debug Abstract Command Acknowledge
reg  [ 1:0] DBGABS_TYPE_internal;  // Debug Abstract Command Type
reg         DBGABS_WRITE_internal; // Debug Abstract Command Write (if 0, read)
reg  [ 1:0] DBGABS_SIZE_internal;  // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
reg  [31:0] DBGABS_ADDR_internal;  // Debug Abstract Command Address / Reg No.
reg  [31:0] DBGABS_WDATA_internal; // Debug Abstract Command Write Data
reg  [31:0] DBGABS_RDATA_internal; // Debug Abstract Command Read Data
reg  [ 3:0] DBGABS_DONE_internal;  // Debug Abstract Command Done ({BUSERR, EXCEPT, WRITE, ACK})

//-----------------------------
// Abstract Control and Status
//-----------------------------
wire [4:0] progbufsize;
//reg        abstract_busy; // abstract command busy
reg  [2:0] cmderr;
wire [3:0] datacount;
//
assign progbufsize = 0; // 00000
assign datacount   = 2; //  0010
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_abstractcs <= 1'b0;
    else if (ack_dm_abstractcs)
        ack_dm_abstractcs <= 1'b0;
    else if (sel_dm_abstractcs)
        ack_dm_abstractcs <= 1'b1;
end
assign err_dm_abstractcs = 1'b0;
assign rdata_dm_abstractcs = (ack_dm_abstractcs & authok)? 
    {3'b0, progbufsize, 11'b0, abstract_busy, 1'b0, cmderr, 4'b0, datacount}
    : 32'h00000000;
//
// abstract_busy
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        abstract_busy <= 1'b0;
    else if (DBGABS_REQ_internal & (DBGABS_TYPE_internal == 2'b00)) // Register Access
        abstract_busy <= 1'b1;
    else if (DBGABS_REQ_internal & (DBGABS_TYPE_internal == 2'b10)) // Memory Access
        abstract_busy <= 1'b1;
    else if (DBGABS_DONE_internal[0])  // Done
        abstract_busy <= 1'b0;
    else if (~HART_AVAILABLE[hartsel]) // Hart is Unavailable
        abstract_busy <= 1'b0;
end
//
// cmderr
// 000 - No Error
// 001 - Busy (set it if cmderr is zero) 
// 010 - Command not supported
// 011 - Exception occured (in executing program buffer)
// 100 - Hart is not in expected state (Halt, Resume, Unavailable)
// 101 - Bus Error
// 111 - Another Error Reason
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        cmderr <= 3'b0;
    else if (sel_dm_command & DMBUS_RW & authok & (DMBUS_WDATA[31:24] == 8'h01)) // Quick Access
        cmderr <= 3'b010; // Command not supported
    else if (sel_dm_command & DMBUS_RW & authok & (DMBUS_WDATA[31:24] >= 8'h03))
        cmderr <= 3'b010; // Command not supported
    else if (sel_dm_command & DMBUS_RW & authok & (DMBUS_WDATA[31:24] == 8'h00) & (DMBUS_WDATA[22:20] != 3'b010)) // Register, aarsize!=32bits
        cmderr <= 3'b111; // Another Error Reason
    else if (sel_dm_command & DMBUS_RW & authok & (DMBUS_WDATA[31:24] == 8'h02) & (DMBUS_WDATA[23] == 1'b1)) // Memory, aamvirtual=1
        cmderr <= 3'b111; // Another Error Reason
    else if (sel_dm_command & DMBUS_RW & authok & abstract_busy && (cmderr == 3'b000))
        cmderr <= 3'b001; // Busy
    else if (sel_dm_command & DMBUS_RW & authok & ~HART_AVAILABLE[hartsel])
        cmderr <= 3'b100; // Hart is Unavailable
    else if (DBGABS_DONE_internal[2]) // Exception
        cmderr <= 3'b011;
    else if (DBGABS_DONE_internal[3]) // BUSERR
        cmderr <= 3'b101;
    else if (sel_dm_abstractcs & DMBUS_RW & authok)
        cmderr <= cmderr & ~(DMBUS_WDATA[10:8]); // Clear bits
end

//----------------------
// Abstract Command
//----------------------
always @*
begin
    integer i;
    DBGABS_ACK_internal   = 1'b0;
    DBGABS_RDATA_internal = 32'h00000000;
    DBGABS_DONE_internal  = 4'b0000;
    //
    for (i = 0; i < HART_COUNT; i = i + 1)
    begin
         DBGABS_REQ[i]   = 1'b0;
         DBGABS_TYPE[i]  = 2'b00;
         DBGABS_WRITE[i] = 1'b0;
         DBGABS_SIZE[i]  = 2'b00;
         DBGABS_ADDR[i]  = 32'h00000000;
         DBGABS_WDATA[i] = 32'h00000000;
         //
       //if (ha_sel[i])
         if (hartsel == i) // one hot
         begin
             DBGABS_REQ[i]   = DBGABS_REQ_internal;
             DBGABS_TYPE[i]  = DBGABS_TYPE_internal;
             DBGABS_WRITE[i] = DBGABS_WRITE_internal;
             DBGABS_SIZE[i]  = DBGABS_SIZE_internal;
             DBGABS_ADDR[i]  = DBGABS_ADDR_internal;
             DBGABS_WDATA[i] = DBGABS_WDATA_internal;
             DBGABS_ACK_internal   = DBGABS_ACK[i];
             DBGABS_RDATA_internal = DBGABS_RDATA[i];
             DBGABS_DONE_internal  = DBGABS_DONE[i];
         end
    end
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_command <= 1'b0;
    else if (ack_dm_command)
        ack_dm_command <= 1'b0;
    else if (sel_dm_command)
        ack_dm_command <= 1'b1;
end
assign err_dm_command = 1'b0;
assign rdata_dm_command = (ack_dm_command)? 
    {32'h00000000} : 32'h00000000;

// Abstract Command Transaction
reg [2:0] dbgabs_transaction; // bit2:reg(0)/mem(1), bit1:wr, bit0:running
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        dbgabs_transaction <= 3'b000;
    else if (sel_dm_command & DMBUS_RW & authok)
    begin
        if (DMBUS_WDATA[25:24] == 2'b00) // register
            dbgabs_transaction <= {1'b0, DMBUS_WDATA[16], 1'b1};
        else if (DMBUS_WDATA[25:24] == 2'b10) // memory
            dbgabs_transaction <= {1'b1, DMBUS_WDATA[16], 1'b1};
        else
            dbgabs_transaction <= 3'b000;
    end
    else if (DBGABS_DONE_internal[0])
        dbgabs_transaction <= 3'b000;
end               

// DBGABS_REQ_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_REQ_internal <= 1'b0;
    else if (sel_dm_command & DMBUS_RW & authok & ~DBGABS_ACK_internal)
        DBGABS_REQ_internal <= ((DMBUS_WDATA[31:24] == 8'h00) & DMBUS_WDATA[17]) // register
                             | ((DMBUS_WDATA[31:24] == 8'h02)); // memory 
    else if (DBGABS_ACK_internal)
        DBGABS_REQ_internal <= 1'b0;
end

// DBGABS_TYPE_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_TYPE_internal <= 2'b00;
    else if (sel_dm_command & DMBUS_RW & authok)
        DBGABS_TYPE_internal <= DMBUS_WDATA[25:24];
    else if (DBGABS_ACK_internal)
        DBGABS_TYPE_internal <= 2'b00;
end

// DBGABS_WRITE_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_WRITE_internal <= 1'b0;
    else if (sel_dm_command & DMBUS_RW & authok)
        DBGABS_WRITE_internal <= DMBUS_WDATA[16];
    else if (DBGABS_ACK_internal)
        DBGABS_WRITE_internal <= 1'b0;
end

// DBGABS_SIZE_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_SIZE_internal <= 2'b00;
    else if (sel_dm_command & DMBUS_RW & authok)
        DBGABS_SIZE_internal <= 
            (DMBUS_WDATA[25:24] == 2'b00)?
                2'b10               // Register 32bit
              : DMBUS_WDATA[21:20]; // Memory 32/16/8 bit
    else if (DBGABS_ACK_internal)
        DBGABS_SIZE_internal <= 2'b00;
end

// DBGABS_ADDR_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_ADDR_internal <= 32'h00000000;
    else if (sel_dm_command & DMBUS_RW & authok)
    begin
        DBGABS_ADDR_internal <= (DMBUS_WDATA[25:24] == 2'b00)?
            {16'h0000, DMBUS_WDATA[15:0]}  // Register
          : dm_data[1]; // Memory (arg1)
    end
    else if (DBGABS_ACK_internal)
        DBGABS_ADDR_internal <= 32'h00000000;
end

// DBGABS_WDATA_internal
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DBGABS_WDATA_internal <= 32'h00000000;
    else if (sel_dm_command & DMBUS_RW & authok)
    begin
        DBGABS_WDATA_internal <= dm_data[0]; // arg0
    end
    else if (DBGABS_ACK_internal)
        DBGABS_WDATA_internal <= 32'h00000000;
end

// DBGABS_RDATA
assign dbgabs_arg0_data = DBGABS_RDATA_internal;
assign dbgabs_arg0_read = (dbgabs_transaction[1:0] == 2'b01)
                        &  DBGABS_DONE_internal[0];

// Auto Increment (Memory)
reg dbgabs_autoincr;
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        dbgabs_autoincr <= 1'b0;
    else if (sel_dm_command & DMBUS_RW & authok)
        dbgabs_autoincr <= (DMBUS_WDATA[25:24] == 2'b10) & DMBUS_WDATA[19];
    else if (DBGABS_DONE_internal[0])
        dbgabs_autoincr <= 1'b0;
end
assign dbgabs_arg1_incr
     //= (DBGABS_DONE_internal[0] & dbgabs_autoincr)? 
       = (DBGABS_ACK_internal & dbgabs_autoincr)? 
           ((3'b001) << DBGABS_SIZE_internal) : 3'b000;

//-------------------
// Reset Structure
//-------------------
assign res_dm  = ~dmactive;
assign RES_SYS = ndmreset;
//
//always @(posedge CLK, posedge RES_ORG)
//begin
//    integer i;
//    for (i = 0; i < HART_COUNT; i = i + 1)
//    begin
//        if (RES_ORG)
//            havereset[i] <= 1'b1;
//        else if (hartreset & ha_sel[i])
//            havereset[i] <= 1'b1;
//        else if (ackhavereset & ha_sel[i])
//            havereset[i] <= 1'b0;        
//    end
//end
always @(posedge CLK, posedge RES_ORG)
begin
    integer i;    
    if (RES_ORG)
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin
            havereset[i] <= 1'b1;
        end
    end
    else
    begin
        for (i = 0; i < HART_COUNT; i = i + 1)
        begin        
            if (hartreset & ha_sel[i])
            begin
                havereset[i] <= 1'b1;
            end
            else if (ackhavereset & ha_sel[i])
            begin
                havereset[i] <= 1'b0;        
            end
        end
    end
end

//-------------------------------
// System Bus Access
//-------------------------------
//
// SBCS
reg  [31:0] sbcs;
wire [ 2:0] sbversion;
reg         sbbusyerror;
reg         sbbusy;
reg         sbreadonaddr;
reg  [ 2:0] sbaccess;
reg         sbautoincrement;
reg         sbreadondata;
reg  [ 2:0] sberror;
wire [ 6:0] sbasize;
wire [ 4:0] sbaccessNNN;
//
assign sbversion = 3'b001;
assign sbasize = 7'd32; // 7'h20
assign sbaccessNNN = 5'b00111; // 32/16/8
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sbcs <= 32'h00000000;
    else if (sel_dm_sbcs & DMBUS_RW & authok)
        sbcs <= DMBUS_WDATA;
end
assign sbreadonaddr    = sbcs[20];
assign sbaccess        = sbcs[19:17];
assign sbautoincrement = sbcs[16];
assign sbreadondata    = sbcs[15];
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_sbcs <= 1'b0;
    else if (ack_dm_sbcs)
        ack_dm_sbcs <= 1'b0;
    else if (sel_dm_sbcs)
        ack_dm_sbcs <= 1'b1;
end
assign err_dm_sbcs = 1'b0;
assign rdata_dm_sbcs = (ack_dm_sbcs & authok)? 
    {sbversion, 6'h00, sbbusyerror, sbbusy, sbreadonaddr,
     sbaccess, sbautoincrement, sbreadondata, sberror, 
     sbasize, sbaccessNNN} : 32'h00000000;
//
reg  sb_req_readonaddr;
reg  sb_req_readondata;
reg  sb_req_write;
wire sb_req;
wire sb_ack;
wire [3:0] sb_done;
//
assign sb_req = (sb_req_readonaddr | sb_req_readondata | sb_req_write)
              & (sbaccess < 3);
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
    begin
        sb_req_readonaddr <= 1'b0;
        sb_req_readondata <= 1'b0;
        sb_req_write      <= 1'b0;
    end
    else if (~sbbusy & sel_dm_sbaddr &  DMBUS_RW & authok & sbreadonaddr & ~sb_ack)
        sb_req_readonaddr <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (~sbbusy & sel_dm_sbdata & ~DMBUS_RW & authok & sbreadondata & ~sb_ack)
        sb_req_readondata <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (~sbbusy & sel_dm_sbdata &  DMBUS_RW & authok & ~sb_ack)
        sb_req_write <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sb_ack)
    begin
        sb_req_readonaddr <= 1'b0;
        sb_req_readondata <= 1'b0;
        sb_req_write      <= 1'b0;
    end
end    
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sbbusyerror <= 1'b0;
    else if (sbbusy & sel_dm_sbaddr &  DMBUS_RW & authok & sbreadonaddr & ~sb_ack)
        sbbusyerror <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sbbusy & sel_dm_sbdata & ~DMBUS_RW & authok & sbreadondata & ~sb_ack)
        sbbusyerror <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sbbusy & sel_dm_sbdata &  DMBUS_RW & authok & ~sb_ack)
        sbbusyerror <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sel_dm_sbcs & DMBUS_RW & authok & DMBUS_WDATA[22])
        sbbusyerror <= 1'b0;
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sbbusy <= 1'b0;
    else if (sel_dm_sbaddr &  DMBUS_RW & authok & sbreadonaddr & ~sb_ack)
        sbbusy <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sel_dm_sbdata & ~DMBUS_RW & authok & sbreadondata & ~sb_ack)
        sbbusy <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sel_dm_sbdata &  DMBUS_RW & authok & ~sb_ack)
        sbbusy <= (sbaccess < 3)? 1'b1 : 1'b0;
    else if (sb_done[0])
        sbbusy <= 1'b0;
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sberror <= 3'b000;
    else if (~sbbusy & sel_dm_sbaddr &  DMBUS_RW & authok & sbreadonaddr & ~sb_ack)
        sberror <= (sbaccess < 3)? 3'b000 : 3'b100;
    else if (~sbbusy & sel_dm_sbdata & ~DMBUS_RW & authok & sbreadondata & ~sb_ack)
        sberror <= (sbaccess < 3)? 3'b000 : 3'b100;
    else if (~sbbusy & sel_dm_sbdata &  DMBUS_RW & authok & ~sb_ack)
        sberror <= (sbaccess < 3)? 3'b000 : 3'b100;
    else if (sb_done[0])
        sberror <= (sb_done[3] | sb_done[2])? 3'b111 : 3'b000;
    else if (sel_dm_sbcs & DMBUS_RW & authok)
    begin
        sberror[2] <= (DMBUS_WDATA[14])? 1'b0 : sberror[2];
        sberror[1] <= (DMBUS_WDATA[13])? 1'b0 : sberror[1];
        sberror[0] <= (DMBUS_WDATA[12])? 1'b0 : sberror[0];
    end
end
//
// SBADDR
reg [31:0] sbaddr;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_sbaddr <= 1'b0;
    else if (ack_dm_sbaddr)
        ack_dm_sbaddr <= 1'b0;
    else if (sel_dm_sbaddr)
        ack_dm_sbaddr <= 1'b1;
end
assign err_dm_sbaddr = 1'b0;
assign rdata_dm_sbaddr = (ack_dm_sbaddr & authok)? sbaddr : 32'h00000000;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sbaddr <= 32'h00000000;
    else if (sel_dm_sbaddr & DMBUS_RW & authok)
        sbaddr <= DMBUS_WDATA;
    else if (sbautoincrement & ((sb_done == 4'b0001) | (sb_done == 4'b0011)))
        sbaddr <= sbaddr + ((32'h1) << sbaccess);
end
//
// SBDATA
reg  [31:0] sbdata;
wire [31:0] sbdata_read;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        ack_dm_sbdata <= 1'b0;
    else if (ack_dm_sbdata)
        ack_dm_sbdata <= 1'b0;
    else if (sel_dm_sbdata)
        ack_dm_sbdata <= 1'b1;
end
assign err_dm_sbdata = 1'b0;
assign rdata_dm_sbdata = (ack_dm_sbdata & authok)? sbdata : 32'h00000000;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        sbdata <= 32'h00000000;
    else if (sel_dm_sbdata & DMBUS_RW & authok)
        sbdata <= DMBUS_WDATA;
    else if (sb_done == 4'b0001) // read done
        sbdata <= sbdata_read; 
end
//
// Bus Interface
//
assign BUSS_M_REQ   = sb_req;
assign sb_ack       = BUSS_M_ACK;
assign BUSS_M_SEQ   = 1'b0;
assign BUSS_M_CONT  = 1'b0;
assign BUSS_M_BURST = 3'b000;
assign BUSS_M_LOCK  = 1'b0;
assign BUSS_M_PROT  = 4'b0011; // Privileded, Data
assign BUSS_M_WRITE = sb_req_write;
assign BUSS_M_SIZE  = sbaccess[1:0];
assign BUSS_M_ADDR  = sbaddr;
assign BUSS_M_WDATA = sbdata;
assign sbdata_read  = BUSS_M_RDATA;
assign sb_done      = BUSS_M_DONE;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
