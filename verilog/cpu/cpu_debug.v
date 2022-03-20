//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_debug.v
// Description : Debug Function in CPU
//-----------------------------------------------------------
// History :
// Rev.01 2020.02.02 M.Maruyama
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_DEBUG
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    input  wire        DBGABS_REQ,   // Debug Abstract Command Request
    output wire        DBGABS_ACK,   // Debug Abstract Command Aknowledge
    input  wire [ 1:0] DBGABS_TYPE,  // Debug Abstract Command Type
    input  wire        DBGABS_WRITE, // Debug Abstract Command Write (if 0, read)
    input  wire [ 1:0] DBGABS_SIZE,  // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
    input  wire [31:0] DBGABS_ADDR,  // Debug Abstract Command Address / Reg No.
    input  wire [31:0] DBGABS_WDATA, // Debug Abstract Command Write Data
    output wire [31:0] DBGABS_RDATA, // Debug Abstract Command Read Data
    output wire [ 3:0] DBGABS_DONE,  // Debug Abstract Command Done ({BUSERR, EXCEPT, WRITE, ACK})
    //
    output wire        DBGABS_CSR_REQ,   // Debug Abstract Command Request for CSR
    output wire        DBGABS_CSR_WRITE, // Debug Abstract Command Write   for CSR
    output wire [11:0] DBGABS_CSR_ADDR,  // Debug Abstract Command Address for CSR
    output wire [31:0] DBGABS_CSR_WDATA, // Debug Abstract Command Write Data for CSR
    input  wire [31:0] DBGABS_CSR_RDATA, // Debug Abstract Command Read  Data for CSR
    //
    output wire        DBGABS_GPR_REQ,   // Debug Abstract Command Request for GPR
    output wire        DBGABS_GPR_WRITE, // Debug Abstract Command Write   for GPR
    output wire [11:0] DBGABS_GPR_ADDR,  // Debug Abstract Command Address for GPR
    output wire [31:0] DBGABS_GPR_WDATA, // Debug Abstract Command Write Data for GPR
    input  wire [31:0] DBGABS_GPR_RDATA, // Debug Abstract Command Read  Data for GPR
    //
    output wire        DBGABS_FPR_REQ,   // Debug Abstract Command Request for FPR
    output wire        DBGABS_FPR_WRITE, // Debug Abstract Command Write   for FPR
    output wire [11:0] DBGABS_FPR_ADDR,  // Debug Abstract Command Address for FPR
    output wire [31:0] DBGABS_FPR_WDATA, // Debug Abstract Command Write Data for FPR
    input  wire [31:0] DBGABS_FPR_RDATA, // Debug Abstract Command Read  Data for FPR
    //
    output wire        BUSA_M_REQ,       // Abstract Command Memory Access
    input  wire        BUSA_M_ACK,       // Abstract Command Memory Access
    output wire        BUSA_M_SEQ,       // Abstract Command Memory Access
    output wire        BUSA_M_CONT,      // Abstract Command Memory Access
    output wire [ 2:0] BUSA_M_BURST,     // Abstract Command Memory Access
    output wire        BUSA_M_LOCK,      // Abstract Command Memory Access
    output wire [ 3:0] BUSA_M_PROT,      // Abstract Command Memory Access
    output wire        BUSA_M_WRITE,     // Abstract Command Memory Access
    output wire [ 1:0] BUSA_M_SIZE,      // Abstract Command Memory Access
    output wire [31:0] BUSA_M_ADDR,      // Abstract Command Memory Access
    output wire [31:0] BUSA_M_WDATA,     // Abstract Command Memory Access
    input  wire        BUSA_M_LAST,      // Abstract Command Memory Access
    input  wire [31:0] BUSA_M_RDATA,     // Abstract Command Memory Access
    input  wire [ 3:0] BUSA_M_DONE,      // Abstract Command Memory Access
    input  wire [31:0] BUSA_M_RDATA_RAW, // Abstract Command Memory Access
    input  wire [ 3:0] BUSA_M_DONE_RAW,  // Abstract Command Memory Access
    //
    input  wire [19:0]            TRG_CND_BUS        [0:`TRG_CH_BUS-1],
    input  wire [`TRG_CH_BUS-1:0] TRG_CND_BUS_CHAIN  [0:`TRG_CH_BUS-1],
    input  wire                   TRG_CND_BUS_ACTION [0:`TRG_CH_BUS-1],
    input  wire [ 3:0]            TRG_CND_BUS_MATCH  [0:`TRG_CH_BUS-1],
    input  wire [31:0]            TRG_CND_BUS_MASK   [0:`TRG_CH_BUS-1],
    output reg                    TRG_CND_BUS_HIT    [0:`TRG_CH_BUS-1],
    input  wire [31:0]            TRG_CND_TDATA2     [0:`TRG_CH_BUS-1],
    input  wire                   TRG_CND_ICOUNT_HIT,
    input  wire                   TRG_CND_ICOUNT_ACT,
    //
    input  wire        DEBUG_MODE,   // Debug Mode
    output wire [ 1:0] TRG_REQ_INST, // Trigger Request by Instruction (bit1:action, bit0:hit)
    output wire [ 1:0] TRG_REQ_DATA, // Trigger Request by Data Access (bit1:action, bit0:hit)
    input  wire        TRG_ACK_INST, // Trigger Acknowledge for TRG_REQ_INST
    input  wire        TRG_ACK_DATA, // Trigger Acknowledge for TRG_REQ_DATA
    //
    input  wire        INSTR_EXEC, // Instruction Retired
    input  wire [31:0] INSTR_ADDR, // Instruction Retired Address
    input  wire [31:0] INSTR_CODE, // Instruction Retired Code
    //
    input  wire        BUSM_M_REQ,       // M Stage Memory Access
    input  wire        BUSM_M_ACK,       // M Stage Memory Access
    input  wire        BUSM_M_WRITE,     // M Stage Memory Access
    input  wire [ 1:0] BUSM_M_SIZE,      // M Stage Memory Access
    input  wire [31:0] BUSM_M_ADDR,      // M Stage Memory Access
    input  wire [31:0] BUSM_M_WDATA,     // M Stage Memory Access
    input  wire [31:0] BUSM_M_RDATA,     // M Stage Memory Access
    input  wire        BUSM_M_LAST,      // M Stage Memory Access
    input  wire [ 3:0] BUSM_M_DONE       // M Stage Memory Access
);

//--------------------------------------
// Debug Abstract Command
//--------------------------------------
wire [31:0] dbgabs_rdata_reg;
wire [31:0] dbgabs_rdata_mem;
wire        dbgabs_req_reg;
wire        dbgabs_req_mem;
wire        dbgabs_ack_reg;
wire        dbgabs_ack_mem;
reg  [ 3:0] dbgabs_done_reg;
wire [ 3:0] dbgabs_done_mem;
//
assign dbgabs_req_reg = DBGABS_REQ & (DBGABS_TYPE == 2'b00);
assign dbgabs_req_mem = DBGABS_REQ & (DBGABS_TYPE == 2'b10);
assign dbgabs_ack_reg = dbgabs_req_reg;
//
assign DBGABS_RDATA = dbgabs_rdata_reg | dbgabs_rdata_mem;
assign DBGABS_ACK   = dbgabs_ack_reg   | dbgabs_ack_mem;
assign DBGABS_DONE  = dbgabs_done_reg  | dbgabs_done_mem;

//--------------------------------------
// Debug Abstract Command : Register
//--------------------------------------
// CSR : 0x0000-0x0fff
// GPR : 0x1000-0x101f
// FPR : 0x1020-0x103f
assign DBGABS_CSR_REQ = dbgabs_req_reg & (DBGABS_ADDR[15:12] == 4'b0000);
assign DBGABS_GPR_REQ = dbgabs_req_reg & (DBGABS_ADDR[15: 5] == 11'b00010000000);
assign DBGABS_FPR_REQ = dbgabs_req_reg & (DBGABS_ADDR[15: 5] == 11'b00010000001);
//
assign DBGABS_CSR_WRITE = DBGABS_WRITE;
assign DBGABS_GPR_WRITE = DBGABS_WRITE;
assign DBGABS_FPR_WRITE = DBGABS_WRITE;
assign DBGABS_CSR_ADDR  = DBGABS_ADDR[11:0];
assign DBGABS_GPR_ADDR  = DBGABS_ADDR[11:0];
assign DBGABS_FPR_ADDR  = DBGABS_ADDR[11:0];
assign DBGABS_CSR_WDATA = DBGABS_WDATA;
assign DBGABS_GPR_WDATA = DBGABS_WDATA;
assign DBGABS_FPR_WDATA = DBGABS_WDATA;
//
assign dbgabs_rdata_reg = DBGABS_CSR_RDATA | DBGABS_GPR_RDATA | DBGABS_FPR_RDATA;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        dbgabs_done_reg <= 4'b0000;
    else if (DBGABS_REQ & (DBGABS_TYPE == 2'b00))
    begin
        if (DBGABS_CSR_REQ | DBGABS_GPR_REQ | DBGABS_FPR_REQ)
            dbgabs_done_reg <= {2'b00, DBGABS_WRITE, 1'b1};
        else
            dbgabs_done_reg <= {2'b01, DBGABS_WRITE, 1'b1}; // Exception
    end
    else
        dbgabs_done_reg <= 4'b0000;
end

//--------------------------------------------------
// Bus Interface : Debug Abstract Command for Memory
//--------------------------------------------------
assign BUSA_M_REQ       = dbgabs_req_mem;
assign dbgabs_ack_mem   = BUSA_M_ACK;
assign BUSA_M_SEQ       = 1'b0;
assign BUSA_M_CONT      = 1'b0;
assign BUSA_M_BURST     = 3'b000;
assign BUSA_M_LOCK      = 1'b0;
assign BUSA_M_PROT      = 4'b0000;
assign BUSA_M_WRITE     = DBGABS_WRITE;
assign BUSA_M_SIZE      = DBGABS_SIZE;
assign BUSA_M_ADDR      = DBGABS_ADDR;
assign BUSA_M_WDATA     = DBGABS_WDATA;
assign dbgabs_rdata_mem = BUSA_M_RDATA;
assign dbgabs_done_mem  = BUSA_M_DONE;

//-----------------------------------------
// Trigger by Instruction Execution
//-----------------------------------------
reg trg_inst_hit_addr[0:`TRG_CH_BUS-1];
reg trg_inst_hit_code[0:`TRG_CH_BUS-1];
//
reg trg_inst_hit_16b_addr_before[0:`TRG_CH_BUS-1];
reg trg_inst_hit_16b_code_before[0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_addr_before[0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_code_before[0:`TRG_CH_BUS-1];
reg trg_inst_hit_16b_addr_keep  [0:`TRG_CH_BUS-1];
reg trg_inst_hit_16b_code_keep  [0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_addr_keep  [0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_code_keep  [0:`TRG_CH_BUS-1];
reg trg_inst_hit_16b_addr_after [0:`TRG_CH_BUS-1];
reg trg_inst_hit_16b_code_after [0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_addr_after [0:`TRG_CH_BUS-1];
reg trg_inst_hit_32b_code_after [0:`TRG_CH_BUS-1];
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    casez(TRG_CND_BUS_MATCH[i])
        4'h0: trg_inst_hit_addr[i] = ( INSTR_ADDR == TRG_CND_TDATA2[i]);
        4'h1: trg_inst_hit_addr[i] = ((INSTR_ADDR & TRG_CND_BUS_MASK[i]) == (TRG_CND_TDATA2[i] & TRG_CND_BUS_MASK[i]));
        4'h2: trg_inst_hit_addr[i] = ( INSTR_ADDR >= TRG_CND_TDATA2[i]);
        4'h3: trg_inst_hit_addr[i] = ( INSTR_ADDR <  TRG_CND_TDATA2[i]);
        4'h4: trg_inst_hit_addr[i] = ((INSTR_ADDR[15: 0] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        4'h5: trg_inst_hit_addr[i] = ((INSTR_ADDR[31:16] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        default: trg_inst_hit_addr[i] = 1'b0;
    endcase
end
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    casez(TRG_CND_BUS_MATCH[i])
        4'h0: trg_inst_hit_code[i] = ( INSTR_CODE == TRG_CND_TDATA2[i]);
        4'h1: trg_inst_hit_code[i] = ((INSTR_CODE & TRG_CND_BUS_MASK[i]) == (TRG_CND_TDATA2[i] & TRG_CND_BUS_MASK[i]));
        4'h2: trg_inst_hit_code[i] = ( INSTR_CODE >= TRG_CND_TDATA2[i]);
        4'h3: trg_inst_hit_code[i] = ( INSTR_CODE <  TRG_CND_TDATA2[i]);
        4'h4: trg_inst_hit_code[i] = ((INSTR_CODE[15: 0] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        4'h5: trg_inst_hit_code[i] = ((INSTR_CODE[31:16] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        default: trg_inst_hit_code[i] = 1'b0;
    endcase
end
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        trg_inst_hit_16b_addr_before[i] = trg_inst_hit_addr[i] & (INSTR_CODE[1:0] != 2'b11);
        trg_inst_hit_16b_code_before[i] = trg_inst_hit_code[i] & (INSTR_CODE[1:0] != 2'b11);
        trg_inst_hit_32b_addr_before[i] = trg_inst_hit_addr[i] & (INSTR_CODE[1:0] == 2'b11);
        trg_inst_hit_32b_code_before[i] = trg_inst_hit_code[i] & (INSTR_CODE[1:0] == 2'b11);
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        if (RES_CPU)
        begin
            trg_inst_hit_16b_addr_keep[i] <= 1'b0;
            trg_inst_hit_16b_code_keep[i] <= 1'b0;
            trg_inst_hit_32b_addr_keep[i] <= 1'b0;
            trg_inst_hit_32b_code_keep[i] <= 1'b0;
        end
        else if (INSTR_EXEC)
        begin
            trg_inst_hit_16b_addr_keep[i] <= trg_inst_hit_16b_addr_before[i];
            trg_inst_hit_16b_code_keep[i] <= trg_inst_hit_16b_code_before[i];
            trg_inst_hit_32b_addr_keep[i] <= trg_inst_hit_32b_addr_before[i];
            trg_inst_hit_32b_code_keep[i] <= trg_inst_hit_32b_code_before[i];
        end
    end
end
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        trg_inst_hit_16b_addr_after[i] = trg_inst_hit_16b_addr_keep[i];
        trg_inst_hit_16b_code_after[i] = trg_inst_hit_16b_code_keep[i];
        trg_inst_hit_32b_addr_after[i] = trg_inst_hit_32b_addr_keep[i];
        trg_inst_hit_32b_code_after[i] = trg_inst_hit_32b_code_keep[i];
    end
end
//
reg trg_inst_hit[0:`TRG_CH_BUS-1];
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        trg_inst_hit[i] = TRG_CND_BUS[i][0] & trg_inst_hit_16b_addr_before[i]
                        | TRG_CND_BUS[i][1] & trg_inst_hit_16b_addr_after [i]
                        | TRG_CND_BUS[i][2] & trg_inst_hit_16b_code_before[i]
                        | TRG_CND_BUS[i][3] & trg_inst_hit_16b_code_after [i]
                        | TRG_CND_BUS[i][4] & trg_inst_hit_32b_addr_before[i]
                        | TRG_CND_BUS[i][5] & trg_inst_hit_32b_addr_after [i]
                        | TRG_CND_BUS[i][6] & trg_inst_hit_32b_code_before[i]
                        | TRG_CND_BUS[i][7] & trg_inst_hit_32b_code_after [i];
    end
end

//-----------------------------------------
// Trigger by Data Access
//-----------------------------------------
reg        busm_active_ma;
reg        busm_active_wb;
reg        busm_write_ma;
reg        busm_write_wb;
reg [ 1:0] busm_size_ma;
reg [ 1:0] busm_size_wb;
reg [31:0] busm_addr_ma;
reg [31:0] busm_addr_wb;
reg [31:0] busm_wdata_ma;
reg [31:0] busm_wdata_wb;
reg [31:0] busm_rdata_wb;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        busm_active_ma <= 1'b0;
        busm_write_ma  <= 1'b0;
        busm_size_ma   <= 2'b00;
        busm_addr_ma   <= 32'h00000000;
        busm_wdata_ma  <= 32'h00000000;
    end
    else if (BUSM_M_REQ & BUSM_M_ACK)
    begin
        busm_active_ma <= BUSM_M_REQ & BUSM_M_ACK;
        busm_write_ma  <= BUSM_M_WRITE;
        busm_size_ma   <= BUSM_M_SIZE;
        busm_addr_ma   <= BUSM_M_ADDR;
        busm_wdata_ma  <= (BUSM_M_SIZE == 2'b00)? {24'h0, BUSM_M_WDATA[ 7:0]}
                        : (BUSM_M_SIZE == 2'b01)? {16'h0, BUSM_M_WDATA[15:0]}
                        : (BUSM_M_SIZE == 2'b10)? {       BUSM_M_WDATA[31:0]}
                        : BUSM_M_WDATA;
    end
    else if (BUSM_M_LAST)
    begin
        busm_active_ma <= 1'b0;
        busm_write_ma  <= 1'b0;
        busm_size_ma   <= 2'b00;
        busm_addr_ma   <= 32'h00000000;
        busm_wdata_ma  <= 32'h00000000;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        busm_active_wb <= 1'b0;
        busm_write_wb  <= 1'b0;
        busm_size_wb   <= 2'b00;
        busm_addr_wb   <= 32'h00000000;
        busm_wdata_wb  <= 32'h00000000;
    end
    else if (BUSM_M_LAST)
    begin
        busm_active_wb <= busm_active_ma;
        busm_write_wb  <= busm_write_ma;
        busm_size_wb   <= busm_size_ma;
        busm_addr_wb   <= busm_addr_ma;
        busm_wdata_wb  <= busm_wdata_ma;
    end
    else
    begin
        busm_active_wb <= 1'b0;
        busm_write_wb  <= 1'b0;
        busm_size_wb   <= 2'b00;
        busm_addr_wb   <= 32'h00000000;
        busm_wdata_wb  <= 32'h00000000;
    end
end
//
assign busm_rdata_wb = BUSM_M_RDATA; // aligned
//
reg trg_data_hit_addr [0:`TRG_CH_BUS-1];
reg trg_data_hit_rdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_wdata[0:`TRG_CH_BUS-1];
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    casez(TRG_CND_BUS_MATCH[i])
        4'h0: trg_data_hit_addr[i] = ( busm_addr_wb == TRG_CND_TDATA2[i]);
        4'h1: trg_data_hit_addr[i] = ((busm_addr_wb & TRG_CND_BUS_MASK[i]) == (TRG_CND_TDATA2[i] & TRG_CND_BUS_MASK[i]));
        4'h2: trg_data_hit_addr[i] = ( busm_addr_wb >= TRG_CND_TDATA2[i]);
        4'h3: trg_data_hit_addr[i] = ( busm_addr_wb <  TRG_CND_TDATA2[i]);
        4'h4: trg_data_hit_addr[i] = ((busm_addr_wb[15: 0] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        4'h5: trg_data_hit_addr[i] = ((busm_addr_wb[31:16] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        default: trg_data_hit_addr[i] = 1'b0;
    endcase
end
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    casez(TRG_CND_BUS_MATCH[i])
        4'h0: trg_data_hit_rdata[i] = ( busm_rdata_wb == TRG_CND_TDATA2[i]);
        4'h1: trg_data_hit_rdata[i] = ((busm_rdata_wb & TRG_CND_BUS_MASK[i]) == (TRG_CND_TDATA2[i] & TRG_CND_BUS_MASK[i]));
        4'h2: trg_data_hit_rdata[i] = ( busm_rdata_wb >= TRG_CND_TDATA2[i]);
        4'h3: trg_data_hit_rdata[i] = ( busm_rdata_wb <  TRG_CND_TDATA2[i]);
        4'h4: trg_data_hit_rdata[i] = ((busm_rdata_wb[15: 0] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        4'h5: trg_data_hit_rdata[i] = ((busm_rdata_wb[31:16] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        default: trg_data_hit_rdata[i] = 1'b0;
    endcase
end
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    casez(TRG_CND_BUS_MATCH[i])
        4'h0: trg_data_hit_wdata[i] = ( busm_wdata_wb == TRG_CND_TDATA2[i]);
        4'h1: trg_data_hit_wdata[i] = ((busm_wdata_wb & TRG_CND_BUS_MASK[i]) == (TRG_CND_TDATA2[i] & TRG_CND_BUS_MASK[i]));
        4'h2: trg_data_hit_wdata[i] = ( busm_wdata_wb >= TRG_CND_TDATA2[i]);
        4'h3: trg_data_hit_wdata[i] = ( busm_wdata_wb <  TRG_CND_TDATA2[i]);
        4'h4: trg_data_hit_wdata[i] = ((busm_wdata_wb[15: 0] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        4'h5: trg_data_hit_wdata[i] = ((busm_wdata_wb[31:16] & TRG_CND_TDATA2[i][31:16]) == TRG_CND_TDATA2[i][15:0]);
        default: trg_data_hit_wdata[i] = 1'b0;
    endcase
end
//
reg trg_data_hit_08b_raddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_08b_waddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_08b_rdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_08b_wdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_16b_raddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_16b_waddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_16b_rdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_16b_wdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_32b_raddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_32b_waddr[0:`TRG_CH_BUS-1];
reg trg_data_hit_32b_rdata[0:`TRG_CH_BUS-1];
reg trg_data_hit_32b_wdata[0:`TRG_CH_BUS-1];
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        trg_data_hit_08b_raddr[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b00) & trg_data_hit_addr[i];
        trg_data_hit_08b_waddr[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b00) & trg_data_hit_addr[i];
        trg_data_hit_08b_rdata[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b00) & trg_data_hit_rdata[i];
        trg_data_hit_08b_wdata[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b00) & trg_data_hit_wdata[i];
        trg_data_hit_16b_raddr[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b01) & trg_data_hit_addr[i];
        trg_data_hit_16b_waddr[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b01) & trg_data_hit_addr[i];
        trg_data_hit_16b_rdata[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b01) & trg_data_hit_rdata[i];
        trg_data_hit_16b_wdata[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b01) & trg_data_hit_wdata[i];
        trg_data_hit_32b_raddr[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b10) & trg_data_hit_addr[i];
        trg_data_hit_32b_waddr[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b10) & trg_data_hit_addr[i];
        trg_data_hit_32b_rdata[i] = busm_active_wb & ~busm_write_wb
                                  & (busm_size_wb == 2'b10) & trg_data_hit_rdata[i];
        trg_data_hit_32b_wdata[i] = busm_active_wb &  busm_write_wb
                                  & (busm_size_wb == 2'b10) & trg_data_hit_wdata[i];
    end
end
//
reg trg_data_hit[0:`TRG_CH_BUS-1];
//
always @*
begin
    integer i;
    for (i = 0; i < `TRG_CH_BUS; i = i + 1)
    begin
        trg_data_hit[i] = TRG_CND_BUS[i][ 8] & trg_data_hit_08b_raddr[i]
                        | TRG_CND_BUS[i][ 9] & trg_data_hit_08b_waddr[i]
                        | TRG_CND_BUS[i][10] & trg_data_hit_08b_rdata[i]
                        | TRG_CND_BUS[i][11] & trg_data_hit_08b_wdata[i]
                        | TRG_CND_BUS[i][12] & trg_data_hit_16b_raddr[i]
                        | TRG_CND_BUS[i][13] & trg_data_hit_16b_waddr[i]
                        | TRG_CND_BUS[i][14] & trg_data_hit_16b_rdata[i]
                        | TRG_CND_BUS[i][15] & trg_data_hit_16b_wdata[i]
                        | TRG_CND_BUS[i][16] & trg_data_hit_32b_raddr[i]
                        | TRG_CND_BUS[i][17] & trg_data_hit_32b_waddr[i]
                        | TRG_CND_BUS[i][18] & trg_data_hit_32b_rdata[i]
                        | TRG_CND_BUS[i][19] & trg_data_hit_32b_wdata[i];
    end
end

//-------------------------------------------
// Trigger by Instruction and Data Access
//-------------------------------------------
reg trg_cnd_bus_hit_inst[0:`TRG_CH_BUS-1];
reg trg_cnd_bus_hit_data[0:`TRG_CH_BUS-1];
reg [1:0] trg_req_inst; // bit1:action, bit0:hit
reg [1:0] trg_req_data; // bit1:action, bit0:hit
//
always @*
begin
    integer c, b;
    trg_req_inst = 2'b00;
    //
    for (c = 0; c < `TRG_CH_BUS; c = c + 1) trg_cnd_bus_hit_inst[c] = 1'b0;
    //
    begin: LOOP_TRG_REQ_INST_BREAK
        for (c = 0; c < `TRG_CH_BUS; c = c + 1)
        begin
            trg_cnd_bus_hit_inst[c] = |(TRG_CND_BUS_CHAIN[c]);
            for (b = 0; b < `TRG_CH_BUS; b = b + 1)
            begin
                if (TRG_CND_BUS_CHAIN[c][b])
                begin
                    trg_cnd_bus_hit_inst[c]
                    = trg_cnd_bus_hit_inst[c] & trg_inst_hit[b];
                end
            end
            //
            if (trg_cnd_bus_hit_inst[c])
            begin
                if (trg_inst_hit[c] & ~trg_req_inst[0])
                begin
                    trg_req_inst[0] = 1'b1;
                    trg_req_inst[1] = TRG_CND_BUS_ACTION[c];
                end
                //
                disable LOOP_TRG_REQ_INST_BREAK;
            end
        end
    end
end
//
always @*
begin
    integer c, b;
    trg_req_data = 2'b00;
    //
    for (c = 0; c < `TRG_CH_BUS; c = c + 1) trg_cnd_bus_hit_data[c] = 1'b0;
    //
    begin: LOOP_TRG_REQ_DATA_BREAK
        for (c = 0; c < `TRG_CH_BUS; c = c + 1)
        begin
            trg_cnd_bus_hit_data[c] = |(TRG_CND_BUS_CHAIN[c]);
            for (b = 0; b < `TRG_CH_BUS; b = b + 1)
            begin
                if (TRG_CND_BUS_CHAIN[c][b])
                begin
                    trg_cnd_bus_hit_data[c]
                    = trg_cnd_bus_hit_data[c] & trg_data_hit[b];
                end
            end
            //
            if (trg_cnd_bus_hit_data[c])
            begin
                if (trg_data_hit[c] & ~trg_req_data[0])
                begin
                    trg_req_data[0] = 1'b1;
                    trg_req_data[1] = TRG_CND_BUS_ACTION[c];
                end
                //
                disable LOOP_TRG_REQ_DATA_BREAK;
            end
        end
    end
end
//
always @*
begin
    integer c;
    for (c = 0; c < `TRG_CH_BUS; c = c + 1)
    begin
        TRG_CND_BUS_HIT[c] = trg_cnd_bus_hit_inst[c] | trg_cnd_bus_hit_data[c];
    end
end

/*
always @*
begin
    integer c, b;
    trg_req_bus = 1'b0;
    trg_act_bus = 1'b0;
    for (c = 0; c < `TRG_CH_BUS; c = c + 1) TRG_CND_BUS_HIT[c] = 1'b0;
    begin: LOOP_TRG_REQ_BUS_BREAK
        for (c = 0; c < `TRG_CH_BUS; c = c + 1)        
        begin: LOOP_TRG_REQ_BUS_CONTINUE
            trg_req_bus = |(TRG_CND_BUS_CHAIN[c]);
            if (~trg_req_bus) disable LOOP_TRG_REQ_BUS_CONTINUE;
            //
            for (b = c; b < `TRG_CH_BUS; b = b + 1)
            begin
                if (TRG_CND_BUS_CHAIN[c][b])
                begin
                    trg_req_bus = trg_req_bus & (trg_inst_hit[b] | trg_data_hit[b]);
                end
            end
            //
            if (trg_req_bus)
            begin
                trg_act_bus = TRG_CND_BUS_ACTION[c];
                TRG_CND_BUS_HIT[c] = 1'b1;
                disable LOOP_TRG_REQ_BUS_BREAK;
            end
        end
    end
end
*/
//--------------------------------
// Trigger by ICOUNT
//--------------------------------
reg [1:0] trg_req_icnt;
//
always @*
begin
    integer i;
    trg_req_icnt = 2'b00;
    //
    begin: LOOP_TRG_REQ_ICNT_BREAK
        for (i = 0; i < `TRG_CH_BUS; i = i + 1)
        begin
            if (TRG_CND_ICOUNT_HIT)
            begin
                trg_req_icnt[0] = 1'b1;
                trg_req_icnt[1] = TRG_CND_ICOUNT_ACT;
                disable LOOP_TRG_REQ_ICNT_BREAK;
            end
        end
    end
end

//--------------------------------------------------
// Generate Trigger Signal for Pipeline Control
//--------------------------------------------------
reg  [1:0] trg_req_inst_temp;
reg  [1:0] trg_req_data_temp;
wire [1:0] trg_req_inst_temp2;
wire [1:0] trg_req_data_temp2;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        trg_req_inst_temp <= 2'b00;
    else if (TRG_ACK_INST)
        trg_req_inst_temp <= 2'b00;
    else if (DEBUG_MODE)
        trg_req_inst_temp <= 2'b00;
    else if (trg_req_inst[0])
        trg_req_inst_temp <= trg_req_inst;
    else if (trg_req_icnt[0])
        trg_req_inst_temp <= trg_req_icnt;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        trg_req_data_temp <= 2'b00;
    else if (TRG_ACK_DATA)
        trg_req_data_temp <= 2'b00;
    else if (DEBUG_MODE)
        trg_req_data_temp <= 2'b00;
    else if (trg_req_data[0])
        trg_req_data_temp <= trg_req_data;
end
//
assign TRG_REQ_INST[0]
    = (trg_req_inst[0]     )? 1'b1
    : (trg_req_icnt[0]     )? 1'b1
    : (trg_req_inst_temp[0])? 1'b1 : 1'b0;
assign TRG_REQ_INST[1]
    = (trg_req_inst[0]     )? trg_req_inst[1]
    : (trg_req_icnt[0]     )? trg_req_icnt[1]
    : (trg_req_inst_temp[0])? trg_req_inst_temp[1] : 1'b0;
//
assign TRG_REQ_DATA[0]
    = (trg_req_data[0]     )? 1'b1
    : (trg_req_data_temp[0])? 1'b1 : 1'b0;
assign TRG_REQ_DATA[1]
    = (trg_req_data[0]     )? trg_req_data[1]
    : (trg_req_data_temp[0])? trg_req_data_temp[1] : 1'b0;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
