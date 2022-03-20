//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : debug_dtm_jtag.v
// Description : Debug DTM (Debug Transport Module ) by JTAG
//-----------------------------------------------------------
// History :
// Rev.01 2017.08.02 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================
// RISC-V External Debug Support Version 0.13.2
// [Yes] 6     Debug Transport Module (DTM)
// [Yes] 6.1   JTAG Debug Transport Module
// [Yes] 6.1.1 JTAG Background
// [Yes] 6.1.2 JTAG DTM Registers
// [Yes] 6.1.3 IDCODE (at 0x01)
// [Yes] 6.1.4 DTM Control and Status (dtmcs, at 0x02)
// [Yes] 6.1.5 Debug Module Interface Access (dmi, at 0x11)
// [Yes] 6.1.6 BYPASS (at 0x11)
// [---] 6.1.7 Recommended JTAG Connector

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module DEBUG_DTM_JTAG
(
    // Domain : TCK
    input  wire TRSTn, // JTAG TAP Reset
    //
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output reg  TDO_D, // JTAG Data Output
    output reg  TDO_E, // JTAG Data Output Enable
    output wire RTCK,  // JTAG Return Clock
    //
    // Domain : CLK
    input  wire RES_ORG, // Reset Origin (e.g. Power On Reset)
    input  wire CLK,     // System Clock
    //
    output wire RES_DBG, // Reset Output for Debugger
    //
    output reg         DMBUS_REQ,   // DMBUS Access Request
    output reg         DMBUS_RW,    // DMBUS Read(0)/Write(1)
    output reg  [ 6:0] DMBUS_ADDR,  // DMBUS Address
    output reg  [31:0] DMBUS_WDATA, // DMBUS Write Data
    input  wire [31:0] DMBUS_RDATA, // DMBUS Read Data
    input  wire        DMBUS_ACK,   // DMBUS Access Acknowledge
    input  wire        DMBUS_ERR    // DMBUS Response Error
);

//---------------------
// Reset Signals
//---------------------
wire res_tap_async;          // Reset JTAG Tap Controller
wire res_dmihard_async;      // Reset DTM Hardware and Debuger
wire dtmcs_dmihardreset_tck; // Reset DTM Hardware
wire dtmcs_dmireset_tck;     // Reset Signal to Clear DTM Error State in DMI

//--------------------------------
// TAP Controller State Machine
//--------------------------------
reg [3:0] state_tap_tck;
reg [3:0] state_tap_next_tck;
//
always @(posedge TCK, negedge TRSTn)
begin
    if (~TRSTn)
        state_tap_tck <= `JTAG_TAP_TEST_LOGIC_RESET;
    else
        state_tap_tck <= state_tap_next_tck;
end
//
always @*
begin
    case(state_tap_tck)
        `JTAG_TAP_TEST_LOGIC_RESET : state_tap_next_tck = (TMS)? state_tap_tck : `JTAG_TAP_RUN_TEST_IDLE;
        `JTAG_TAP_RUN_TEST_IDLE    : state_tap_next_tck = (TMS)? `JTAG_TAP_SELECT_DR_SCAN : state_tap_tck;
        //
        `JTAG_TAP_SELECT_DR_SCAN   : state_tap_next_tck = (TMS)? `JTAG_TAP_SELECT_IR_SCAN : `JTAG_TAP_CAPTURE_DR;
        `JTAG_TAP_CAPTURE_DR       : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT1_DR : `JTAG_TAP_SHIFT_DR;
        `JTAG_TAP_SHIFT_DR         : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT1_DR : state_tap_tck;
        `JTAG_TAP_EXIT1_DR         : state_tap_next_tck = (TMS)? `JTAG_TAP_UPDATE_DR : `JTAG_TAP_PAUSE_DR;
        `JTAG_TAP_PAUSE_DR         : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT2_DR : state_tap_tck;
        `JTAG_TAP_EXIT2_DR         : state_tap_next_tck = (TMS)? `JTAG_TAP_UPDATE_DR : `JTAG_TAP_SHIFT_DR;
        `JTAG_TAP_UPDATE_DR        : state_tap_next_tck = (TMS)? `JTAG_TAP_SELECT_DR_SCAN : `JTAG_TAP_RUN_TEST_IDLE;
        //
        `JTAG_TAP_SELECT_IR_SCAN   : state_tap_next_tck = (TMS)? `JTAG_TAP_TEST_LOGIC_RESET : `JTAG_TAP_CAPTURE_IR;
        `JTAG_TAP_CAPTURE_IR       : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT1_IR : `JTAG_TAP_SHIFT_IR;
        `JTAG_TAP_SHIFT_IR         : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT1_IR : state_tap_tck;
        `JTAG_TAP_EXIT1_IR         : state_tap_next_tck = (TMS)? `JTAG_TAP_UPDATE_IR : `JTAG_TAP_PAUSE_IR;
        `JTAG_TAP_PAUSE_IR         : state_tap_next_tck = (TMS)? `JTAG_TAP_EXIT2_IR : state_tap_tck;
        `JTAG_TAP_EXIT2_IR         : state_tap_next_tck = (TMS)? `JTAG_TAP_UPDATE_IR : `JTAG_TAP_SHIFT_IR;
        `JTAG_TAP_UPDATE_IR        : state_tap_next_tck = (TMS)? `JTAG_TAP_SELECT_DR_SCAN : `JTAG_TAP_RUN_TEST_IDLE;
        //
        default : state_tap_next_tck = `JTAG_TAP_TEST_LOGIC_RESET;
    endcase
end

//--------------------
// Register IR
//--------------------
reg [4:0] ir_sft_tck;
reg [4:0] ir_tap_tck;
//
always @(posedge TCK, posedge res_tap_async)
begin
    if (res_tap_async)
        ir_sft_tck <= 5'b0;
    else if (state_tap_tck == `JTAG_TAP_CAPTURE_IR)
        ir_sft_tck <= ir_tap_tck;
    else if (state_tap_tck == `JTAG_TAP_SHIFT_IR)
        ir_sft_tck <= {TDI, ir_sft_tck[4:1]};
end
//
always @(posedge TCK, posedge res_tap_async)
begin
    if (res_tap_async)
        ir_tap_tck <= `JTAG_IR_IDCODE;
    else if (state_tap_tck == `JTAG_TAP_UPDATE_IR)
        ir_tap_tck <= ir_sft_tck;
end

//------------------
// Register BYPASS
//------------------
reg bypass_sft_tck;
//
always @(posedge TCK, posedge res_tap_async)
begin
    if (res_tap_async)
        bypass_sft_tck <= 1'b0;
    else if ((ir_tap_tck != `JTAG_IR_IDCODE) && (ir_tap_tck != `JTAG_IR_DTMCS) && (ir_tap_tck != `JTAG_IR_DMI))
    begin
        case (state_tap_tck)
            `JTAG_TAP_SHIFT_DR  : bypass_sft_tck <= TDI;
            default             : bypass_sft_tck <= bypass_sft_tck;
        endcase
    end
end

//------------------
// Register IDCODE
//------------------
reg  [31:0] idcode_sft_tck;
//
always @(posedge TCK, posedge res_tap_async)
begin
    if (res_tap_async)
        idcode_sft_tck <= 32'h0;
    else if (ir_tap_tck == `JTAG_IR_IDCODE)
    begin
        case (state_tap_tck)
            `JTAG_TAP_CAPTURE_DR : idcode_sft_tck <= `JTAG_IDCODE;
            `JTAG_TAP_SHIFT_DR   : idcode_sft_tck <= {TDI, idcode_sft_tck[31:1]};
            default              : idcode_sft_tck <= idcode_sft_tck;
        endcase
    end
end

//-------------------
// Register DTMCS
//-------------------
reg  [1:0] dmi_status_tck;
//
reg  [31:0] dtmcs_sft_tck;
wire [31:0] dtmcs_rdata_tck;
//
always @(posedge TCK, posedge res_tap_async)
begin
    if (res_tap_async)
        dtmcs_sft_tck <= 32'h0;
    else if (ir_tap_tck == `JTAG_IR_DTMCS)
    begin
        case (state_tap_tck)
            `JTAG_TAP_CAPTURE_DR : dtmcs_sft_tck <= dtmcs_rdata_tck;
            `JTAG_TAP_SHIFT_DR   : dtmcs_sft_tck <= {TDI, dtmcs_sft_tck[31:1]};
            default              : dtmcs_sft_tck <= dtmcs_sft_tck;
        endcase
    end
end
//
wire dtmcs_we_tck;
wire dtmcs_re_tck;
//
assign dtmcs_we_tck = (ir_tap_tck == `JTAG_IR_DTMCS) && (state_tap_tck == `JTAG_TAP_UPDATE_DR);
//assign dtmcs_re_tck = (ir_tap_tck == `JTAG_IR_DTMCS) && (state_tap_tck == `JTAG_TAP_CAPTURE_DR);
//
wire [2:0] dtmcs_idle_tck;         // How many TCK to avoid dmistat==3
wire [1:0] dtmcs_dmistat_tck;      // 0:No Error, 1:Reserved, 2:Failed, 3:Busy (Still in progress)
wire [5:0] dtmcs_abits_tck;        // DMI Address Width
wire [3:0] dtmcs_version_tck;      // Debugger Version (1:Ver.0.13)
//
assign dtmcs_idle_tck    = 3'h5;
assign dtmcs_dmistat_tck = (dmi_status_tck == 2'h1)? 2'h2 : dmi_status_tck;
assign dtmcs_abits_tck   = 6'h7;
assign dtmcs_version_tck = 4'h1;
//
assign dtmcs_rdata_tck = {14'h0, 1'b0, 1'b0, 1'b0, 
                          dtmcs_idle_tck,
                          dtmcs_dmistat_tck,
                          dtmcs_abits_tck,
                          dtmcs_version_tck};

//-------------------
// Register DMI
//-------------------
reg  [40:0] dmi_sft_tck;
reg  [40:0] dmi_rdata_tck;
reg         dmi_cmd_in_progress_tck;
//
always @(posedge TCK, posedge res_dmihard_async)
begin
    if (res_dmihard_async)
        dmi_sft_tck <= 41'h0;
    else if (ir_tap_tck == `JTAG_IR_DMI)
    begin
        case (state_tap_tck)
            `JTAG_TAP_CAPTURE_DR : dmi_sft_tck <= dmi_rdata_tck;
            `JTAG_TAP_SHIFT_DR   : dmi_sft_tck <= {TDI, dmi_sft_tck[40:1]};
            default              : dmi_sft_tck <= dmi_sft_tck;
        endcase
    end
end
//
// Write from Debugger
wire        dmiwr_wr_put_try_tck;
wire        dmiwr_wr_put_any_tck_;
wire        dmiwr_wr_put_tck;
wire        dmiwr_wr_rdy_tck;
wire [40:0] dmiwr_wr_data_tck;
wire        dmiwr_rd_get;
wire        dmiwr_rd_rdy;
wire [40:0] dmiwr_rd_data;
//
assign dmiwr_wr_put_try_tck = (dmi_status_tck == 2'b00)
                            & (ir_tap_tck == `JTAG_IR_DMI)
                            & (state_tap_tck == `JTAG_TAP_UPDATE_DR)
                            & (dmi_sft_tck[1:0] != 2'b00); // Write or Read
assign dmiwr_wr_put_any_tck_= (ir_tap_tck == `JTAG_IR_DMI)
                            & (state_tap_tck == `JTAG_TAP_UPDATE_DR); // whenever UPDATE
assign dmiwr_wr_put_tck = dmiwr_wr_put_try_tck & dmiwr_wr_rdy_tck;
assign dmiwr_wr_data_tck = dmi_sft_tck; // addr(7) + data(32) + OP(2)
//
DEBUG_CDC #(.WIDTH(41)) U_DEBUG_CDC_DMI_WR
(
    .WR_CLK  (TCK),
    .WR_RES  (res_dmihard_async),
    .WR_PUT  (dmiwr_wr_put_tck),
    .WR_RDY  (dmiwr_wr_rdy_tck),
    .WR_DATA (dmiwr_wr_data_tck),
    //
    .RD_CLK  (CLK),
    .RD_RES  (res_dmihard_async),
    .RD_GET  (dmiwr_rd_get),
    .RD_RDY  (dmiwr_rd_rdy),
    .RD_DATA (dmiwr_rd_data)
);
//
// Read from Debugger
wire        dmird_wr_put;
wire        dmird_wr_rdy;
reg  [40:0] dmird_wr_data;
wire        dmird_rd_get_try_tck;
wire        dmird_rd_get_tck;
wire        dmird_rd_rdy_tck;
wire [40:0] dmird_rd_data_tck;
//
assign dmird_rd_get_try_tck =  dmi_cmd_in_progress_tck
                            & (dmi_status_tck == 2'b00)
                            & (ir_tap_tck == `JTAG_IR_DMI)
                            & (state_tap_tck == `JTAG_TAP_CAPTURE_DR);
assign dmird_rd_get_tck = dmird_rd_get_try_tck & dmird_rd_rdy_tck;
//
DEBUG_CDC #(.WIDTH(41)) U_DEBUG_CDC_DMI_RD
(
    .WR_CLK  (CLK),
    .WR_RES  (res_dmihard_async),
    .WR_PUT  (dmird_wr_put),
    .WR_RDY  (dmird_wr_rdy),
    .WR_DATA (dmird_wr_data),
    //
    .RD_CLK  (TCK),
    .RD_RES  (res_dmihard_async),
    .RD_GET  (dmird_rd_get_tck),
    .RD_RDY  (dmird_rd_rdy_tck),
    .RD_DATA (dmird_rd_data_tck)
);
//
// DMI Command in Progress from UPDATE_DR to DMBUS_ACK
always @(posedge TCK, posedge res_dmihard_async)
begin
    if (res_dmihard_async)
        dmi_cmd_in_progress_tck <= 1'b0;
  //else if (dtmcs_dmireset_tck)
  //    dmi_cmd_in_progress_tck <= 1'b0; // clear sticky error
    else if (dmiwr_wr_put_tck)
        dmi_cmd_in_progress_tck <= 1'b1;
  //else if (dmird_rd_rdy_tck)
    else if (dmird_rd_get_tck)
        dmi_cmd_in_progress_tck <= 1'b0;
end
//
// DMI Status to Remember
always @(posedge TCK, posedge res_dmihard_async)
begin
    if (res_dmihard_async)
        dmi_status_tck <= 2'b00;
    else if (dtmcs_dmireset_tck)
        dmi_status_tck <= 2'b00;  // clear sticky error
    else if (dmi_status_tck != 2'b00) // keep value until dmirest
        dmi_status_tck <= dmi_status_tck;
    else if (~dmiwr_wr_rdy_tck & dmiwr_wr_put_try_tck) // busy when UPDATE?
        dmi_status_tck <= 2'b11;
    else if (dmiwr_wr_put_any_tck_& dmi_cmd_in_progress_tck) // UPDATE during command progress
        dmi_status_tck <= 2'b11;    
    else if (~dmird_rd_rdy_tck & dmird_rd_get_try_tck & dmi_cmd_in_progress_tck) // busy when CAPTURE?
        dmi_status_tck <= 2'b11;
    else if (dmird_rd_get_tck & (dmird_rd_data_tck[1:0] == 2'b10)) // error?
        dmi_status_tck <= 2'b10;
end
//
// DMI Read Data (to Capture)
always @*
begin
    if (dmi_status_tck != 2'b00) // already something error
        dmi_rdata_tck = {39'h0, dmi_status_tck};    
    else if (~dmird_rd_rdy_tck & dmird_rd_get_try_tck & dmi_cmd_in_progress_tck) // busy when CAPTURE?
        dmi_rdata_tck = 41'h03; // busy
    else if (dmird_rd_get_tck & (dmird_rd_data_tck[1:0] == 2'b10)) // error?
        dmi_rdata_tck = 41'h02; // error
    else if (dmi_cmd_in_progress_tck)
        dmi_rdata_tck = dmird_rd_data_tck; // dmird_rd_data_tck is changed at CAPTURE_DR
    else
        dmi_rdata_tck = 41'h00; // nop    
end

//---------------------------------------
// DMBUS : DMI (Debug Module Interface)
//---------------------------------------
wire        dmi_op_cmd_rd; // DMI OP Command as Read
wire        dmi_op_cmd_wr; // DMI OP Command as Write
wire        dmi_op_cmd;    // DMI OP Command as Read or Write
wire        dmi_busy;      // DMI in Busy
//
reg  [1:0] dmi_state;
reg  [1:0] dmi_state_next;
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        dmi_state <= `DMI_STATE_IDLE;
    else
        dmi_state <= dmi_state_next;
end
//
always @*
begin
    case(dmi_state)
        `DMI_STATE_IDLE    : dmi_state_next = (dmi_op_cmd_rd)? `DMI_STATE_BUSY_RD :
                                              (dmi_op_cmd_wr)? `DMI_STATE_BUSY_WR :
                                                                dmi_state;
        `DMI_STATE_BUSY_RD : dmi_state_next = (DMBUS_ACK)? `DMI_STATE_IDLE : dmi_state;
        `DMI_STATE_BUSY_WR : dmi_state_next = (DMBUS_ACK)? `DMI_STATE_IDLE : dmi_state;        
        default            : dmi_state_next = `DMI_STATE_IDLE;
    endcase
end
//
assign dmi_busy = (dmi_state != `DMI_STATE_IDLE);
//
assign dmiwr_rd_get = ~dmi_busy & dmiwr_rd_rdy;
assign dmi_op_cmd_rd = dmiwr_rd_get & (dmiwr_rd_data[1:0] == 2'b01);
assign dmi_op_cmd_wr = dmiwr_rd_get & (dmiwr_rd_data[1:0] == 2'b10);
assign dmi_op_cmd = dmi_op_cmd_rd | dmi_op_cmd_wr;
//
assign dmird_wr_put = dmird_wr_rdy & DMBUS_ACK;
//
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DMBUS_REQ <= 1'b0;
    else if (dmi_op_cmd & ~DMBUS_REQ)
        DMBUS_REQ <= 1'b1;
    else if (DMBUS_ACK)
        DMBUS_REQ <= 1'b0;
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DMBUS_RW <= 1'b0;
    else if (dmi_op_cmd_rd)
        DMBUS_RW <= 1'b0;
    else if (dmi_op_cmd_wr)
        DMBUS_RW <= 1'b1;
    else if (DMBUS_ACK)
        DMBUS_RW <= 1'b0;
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DMBUS_ADDR <= 7'h00;
    else if (dmi_op_cmd)
        DMBUS_ADDR <= dmiwr_rd_data[40:34];
end
//
always @(posedge CLK, posedge RES_DBG)
begin
    if (RES_DBG)
        DMBUS_WDATA <= 32'h00000000;
    else if (dmi_op_cmd_wr)
        DMBUS_WDATA <= dmiwr_rd_data[33:2];
end
//
always @*
begin
    if (dmi_state == `DMI_STATE_BUSY_RD)
        dmird_wr_data = {DMBUS_ADDR, DMBUS_RDATA, DMBUS_ERR, 1'b0};
    else if (dmi_state == `DMI_STATE_BUSY_WR)
        dmird_wr_data = {DMBUS_ADDR, DMBUS_WDATA, DMBUS_ERR, 1'b0};
    else
        dmird_wr_data = 41'h0;
end

//-------------------
// Make TDO
//-------------------
always @(negedge TCK, posedge res_tap_async) // negative TCK edge
begin
    if (res_tap_async)
    begin
        TDO_D <= 1'b1;
        TDO_E <= 1'b0;
    end
    else if (state_tap_tck == `JTAG_TAP_SHIFT_IR)
    begin
        TDO_D <= ir_sft_tck[0];
        TDO_E <= 1'b1;
    end
    else if (state_tap_tck == `JTAG_TAP_SHIFT_DR)
    begin
        case (ir_tap_tck)
            `JTAG_IR_BYPASS : TDO_D <= bypass_sft_tck; 
            `JTAG_IR_IDCODE : TDO_D <= idcode_sft_tck[0];
            `JTAG_IR_DTMCS  : TDO_D <= dtmcs_sft_tck[0];
            `JTAG_IR_DMI    : TDO_D <= dmi_sft_tck[0];
            default         : TDO_D <= 1'b1;
        endcase
        TDO_E <= 1'b1;
    end
    else
    begin
        TDO_D <= 1'b1;
        TDO_E <= 1'b0;
    end    
end

//------------------------
// Make Return Clock
//------------------------
assign RTCK = TCK;

//---------------------------
// Reset Structure
//---------------------------
// Reset JTAG TAP
assign res_tap_async = RES_ORG | (state_tap_tck == `JTAG_TAP_TEST_LOGIC_RESET) | ~TRSTn;
// Reset Signal to Clear Error State in DMI
assign dtmcs_dmireset_tck     = dtmcs_we_tck & dtmcs_sft_tck[16];
// Reset Signal from DTMCS
assign dtmcs_dmihardreset_tck = dtmcs_we_tck & dtmcs_sft_tck[17];
assign res_dmihard_async = RES_ORG | dtmcs_dmihardreset_tck;
// Reset Debugger
assign RES_DBG = res_dmihard_async;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
