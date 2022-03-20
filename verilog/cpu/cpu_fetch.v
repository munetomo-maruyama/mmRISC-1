//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_fetch.v
// Description : Instruction Fetch Unit of CPU
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.12 M.Maruyama First Release: 
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================
//
//-----------------------------------------------------
// Decode Stage and Instruction Fetch
//-----------------------------------------------------
//  
// D
//  D
// aFD
//  aFd
//   afD
//    -FD
//
//-----------------------------------------------------
// Combination of buf1 buf2 (Output from Fetch buffer)
//-----------------------------------------------------
// buf1 buf2
//  na   na
//  na  32L0
//  na  16W0
// 32L0 32H0
// 32H0 32L1
// 32H0 16W0
// 16W0 16W1
// 16W0 32L0
//
//-----------------------------------------------------
// Combination of buf0
//-----------------------------------------------------
// buf0
//  na
// 32L
// 16W
//
//-----------------------------------------------------
// Possible State Transition
//-----------------------------------------------------
//
// | J |------ CURRENT ------|------- NEXT --------|---CODE---
// | P | addr buf0 buf1 buf2 | addr buf0 buf1 buf2 |  output
// |---|---------------------|---------------------|----------
// |   |       na   na   na  |                     |
// |   | 4n+2  na   na  32L0 |                     |
// |   | 4n+2  na   na  16W0 |                     |
// |   | 4n    na  32L0 32H0 |                     |
// |   |       na  32H0 32L1 | no such case        |
// |   |       na  32H0 16W0 | no such case        |
// |   | 4n    na  16W0 16W1 |                     |
// |   | 4n    na  16W0 32L0 |                     |
// |   |      32L0  na   na  | no such case        |
// |   |      32L0  na  32L0 | no such case        |
// |   |      32L0  na  16W0 | no such case        |
// |   |      32L0 32L0 32H0 | no such case        |
// |   | 4n   32L0 32H0 32L1 |                     |
// |   | 4n   32L0 32H0 16W0 |                     |
// |   |      32L0 16W0 16W1 | no such case        |
// |   |      32L0 16W0 32L1 | no such case        |
// |   |      16W0  na   na  |                     |
// |   |      16W0  na  32L0 | no such case        |
// |   |      16W0  na  16W1 | no such case        |
// |   | 4n   16W0 32L0 32H0 |                     |
// |   |      16W0 32H0 32L1 | no such case        |
// |   |      16W0 32H0 16W0 | no such case        |
// |   | 4n   16W0 16W1 16W2 |                     |
// |   | 4n   16W0 16W1 32L0 |                     |

// |---|---|------ CURRENT ------|------- NEXT --------|---OUTPUT------|-----------|--JUMP---------------|
// |DO |JMP| addr buf0 buf1 buf2 | addr buf0 buf1 buf2 |  CODE         |  ADDR     | buf0 buf1 buf2 OUT  |
// |---|---|---------------------|---------------------|---------------|-----------|---------------------|
// | 0 | x |       ??   ??   ??  |       na   na   na  | none          |           |                     |
// | 1 | 1 | 4n+2  ??   na  32L0 |      32L0 <-UPDAT-> | none          |           | pre2 0    1    0    |
// | 1 | 1 | 4n+2  ??   na  16W0 |       na  <-UPDAT-> | 16W0          | addr_buf2 | pre2 0    1    buf2 |
// | 1 | 1 | 4n *  na  32L0 32H0 |       na  <-UPDAT-> | 32L0,32H0     | addr_buf1 | pre2 1    1    buf1 |
// | 1 | 1 | 4n *  na  16W0 16W1 |      16W1 <-UPDAT-> | 16W0          | addr_buf1 | pre2 1    0    buf1 |
// | 1 | 1 | 4n *  na  16W0 32L0 |      32L0 <-UPDAT-> | 16W0          | addr_buf1 | pre2 1    0    buf1 |
// | 1 | 1 |      32L0 32H0 32L1 | no such case        | 32L0,32H0     |           |                     |
// | 1 | 1 |      32L0 32H0 16W0 | no such case        | 32L0,32H0     |           |                     |
// | 0 | x |      16W0  na   na  |       na  <-UPDAT-> | 16W0 <--note! | addr_buf0 | pre2 0    0    buf0 |
// | 1 | 1 | 4n * 16W0 32L0 32H0 |       na  <-UPDAT-> | 32L0,32H0     | addr_buf1 | pre2 1    1    buf1 |
// | 1 | 1 | 4n * 16W0 16W1 16W2 |      16W2 <-UPDAT-> | 16W1 <--note! | addr_buf1 | pre2 1    0    buf1 |
// | 1 | 1 | 4n * 16W0 16W1 32L0 |      32L0 <-UPDAT-> | 16W1 <--note! | addr_buf1 | pre2 1    0    buf1 |
//              * bug 2021.03.29
//
// |---|---|------ CURRENT ------|------- NEXT --------|---OUTPUT------|-----------|--JUMP---------------|
// |DO |JMP| addr buf0 buf1 buf2 | addr buf0 buf1 buf2 |  CODE         |  ADDR     | buf0 buf1 buf2 OUT  |
// |---|---|---------------------|---------------------|---------------|-----------|---------------------|
// | 0 | x |       ??   ??   ??  |       na   na   na  | none          |           |                     |
// | 1 | 1 | 4n+2  ??   na  32L0 |      32L0 <-UPDAT-> | none          |           | pre2 0    1    0    |
// | 1 | 1 | 4n+2  ??   na  16W0 |       na  <-UPDAT-> | 16W0          | addr_buf2 | pre2 0    1    buf2 |
// | 1 | 1 | 4n *  ??  32L0 32H0 |       na  <-UPDAT-> | 32L0,32H0     | addr_buf1 | pre2 1    1    buf1 |
// | 1 | 1 | 4n *  ??  16W0 16W1 |      16W1 <-UPDAT-> | 16W0          | addr_buf1 | pre2 1    0    buf1 |
// | 1 | 1 | 4n *  ??  16W0 32L0 |      32L0 <-UPDAT-> | 16W0          | addr_buf1 | pre2 1    0    buf1 |
// | 1 | 1 |      32L0 32H0 32L1 | no such case        | 32L0,32H0     |           |                     |
// | 1 | 1 |      32L0 32H0 16W0 | no such case        | 32L0,32H0     |           |                     |
// | 0 | x |      16W0  na   na  |       na  <-UPDAT-> | 16W0 <--note! | addr_buf0 | pre2 0    0    buf0 |
//
// |---|---|------ CURRENT ------|------- NEXT --------|---OUTPUT------|-----------|--JUMP---------------|
// |DO |JMP| addr buf0 buf1 buf2 | addr buf0 buf1 buf2 |  CODE         |  ADDR     | buf0 buf1 buf2 OUT  |
// |---|---|---------------------|---------------------|---------------|-----------|---------------------|
// | 0 | x |       ??   ??   ??  |       na   na   na  | none          |           |                     |
// | 1 | 0 |       na   na  32L0 | no such case        | none          |           |                     |
// | 1 | 0 |       na   na  16W0 | no such case        | none <--note! |           |                     |
// | 1 | 0 | 4n    na  32L0 32H0 |       na  <-UPDAT-> | 32L0,32H0     | addr_buf1 | pre2 0    0    0    |
// | 1 | 0 | 4n    na  16W0 16W1 |      16W1 <-UPDAT-> | 16W0          | addr_buf1 | pre2 0    0    0    |
// | 1 | 0 | 4n    na  16W0 32L0 |      32L0 <-UPDAT-> | 16W0          | addr_buf1 | pre2 0    0    0    |
// | 1 | 0 | 4n   32L0 32H0 32L1 |      32L1 <-UPDAT-> | 32L0,32H0     | addr_buf0 | pre2 pre2 0    buf0 |
// | 1 | 0 | 4n   32L0 32H0 16W0 |      16W0 <-UPDAT-> | 32L0,32H0     | addr_buf0 | pre2 pre2 0    buf0 |
// | 0 | x |      16W0  na   na  |       na  <-UPDAT-> | 16W0          | addr_buf0 | pre2 0    0    buf0 |
// | 1 | 0 | 4n   16W0 32L0 32H0 |       na  32L0 32H0 | 16W0          | addr_buf0 | pre2 0    0    buf0 |
// | 1 | 0 | 4n   16W0 16W1 16W2 |       na  16W1 16W2 | 16W0          | addr_buf0 | pre2 0    0    buf0 |
// | 1 | 0 | 4n   16W0 16W1 32L0 |       na  16W1 32L0 | 16W0          | addr_buf0 | pre2 0    0    buf0 |

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_FETCH
(
    input  wire RES_CPU, // CPU Reset
    input  wire CLK,     // System Clock
    //
    // Instruction Fetch Command
    // FETCH_START/STOP should be negated if FETCH_ACK asserted but no next request.
    input  wire        FETCH_START,      // Instruction Fetch Start Request
    input  wire        FETCH_STOP,       // Instruction Fetch Stop Request
    output wire        FETCH_ACK,        // Instruction Fetch Start Acknowledge
    input  wire [31:0] FETCH_ADDR,       // Instruction Fetch Start Address
    output wire        DECODE_REQ,       // Decode Request
    input  wire        DECODE_ACK,       // Decode Acknowledge
    output reg  [31:0] DECODE_CODE,      // Decode Instruction Code
    output reg  [31:0] DECODE_ADDR,      // Decode Instruction Address
    output reg         DECODE_BERR,      // Decode Instruction Bus Error
    output reg         DECODE_JUMP,      // Decode Instruction Jump Target
    //
    // Instruction Bus
    output wire        BUSI_M_REQ,   // BUS Master Command Request
    input  wire        BUSI_M_ACK,   // BUS Master Command Acknowledge
    output wire        BUSI_M_SEQ,   // Bus Master Command Sequence
    output wire        BUSI_M_CONT,  // Bus Master Command Continuing
    output wire [ 2:0] BUSI_M_BURST, // Bus Master Command Burst
    output wire        BUSI_M_LOCK,  // Bus Master Command Lock
    output wire [ 3:0] BUSI_M_PROT,  // Bus Master Command Protect
    output wire        BUSI_M_WRITE, // Bus Master Command Write (if 0, read)
    output wire [ 1:0] BUSI_M_SIZE,  // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
    output wire [31:0] BUSI_M_ADDR,  // Bus Master Command Address
    output wire [31:0] BUSI_M_WDATA, // Bus Master Command Write Data
    input  wire        BUSI_M_LAST,  // Bus Master Command Last Cycle
    input  wire [31:0] BUSI_M_RDATA, // Bus Master Command Read Data Unclocked
    input  wire [ 3:0] BUSI_M_DONE,  // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked
    input  wire [31:0] BUSI_M_RDATA_RAW, // Bus Master Command Read Data Unclocked
    input  wire [ 3:0] BUSI_M_DONE_RAW   // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked
);

//----------------------------
// Fetch Start Buffer
//----------------------------
reg        fetch_start_buf;
reg [31:0] fetch_addr_buf;
//
reg        if_busy;
reg        if_jump;
reg [31:0] if_addr;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        fetch_start_buf <= 1'b0;
        fetch_addr_buf  <= 32'h00000000;
    end
  //else if (FETCH_START & if_busy) // & ~BUSI_M_LAST)
    else if (FETCH_START) // & if_busy) // & ~BUSI_M_LAST)
    begin
        fetch_start_buf <= 1'b1;
        fetch_addr_buf  <= {FETCH_ADDR[31:1], 1'b0};
    end
    else if (fetch_start_buf & BUSI_M_REQ & BUSI_M_ACK)
    begin
        fetch_start_buf <= 1'b0;
        fetch_addr_buf  <= 32'h00000000;
    end
end
//
wire        fetch_start_pending;
wire [31:0] fetch_addr_pending;
wire        fetch_start_ack;
//
assign fetch_start_pending = fetch_start_buf; //(FETCH_START)? 1'b1 : fetch_start_buf;
assign fetch_addr_pending  = fetch_addr_buf; //(FETCH_START)? FETCH_ADDR : fetch_addr_buf;
assign fetch_start_ack = fetch_start_pending & BUSI_M_REQ & BUSI_M_ACK;
//
assign FETCH_ACK = FETCH_START;
//assign FETCH_ACK = (FETCH_START & BUSI_M_REQ & BUSI_M_ACK)
//                 | (FETCH_STOP);


//----------------------------------------
// Instruction Fetch Start/Stop Control
//----------------------------------------
reg fetch_req;
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        fetch_req <= 1'b0;
    else if (fetch_start_pending)
        fetch_req <= 1'b1;
    else if (FETCH_STOP)
        fetch_req <= 1'b0;
end

//-----------------------------------------
// Pipeline of Instruction Fetch Bus Access
//-----------------------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
       if_busy <= 1'b0;
       if_jump <= 1'b0;
       if_addr <= 32'h00000000;
    end
    else if (BUSI_M_REQ & BUSI_M_ACK)
    begin
       if_busy <=  BUSI_M_REQ;
       if_jump <= ~BUSI_M_SEQ;
       if_addr <=  (fetch_start_pending)? fetch_addr_pending
                            : ((if_addr & ~32'h03) + 32'h04);
    end
    else if (BUSI_M_LAST)
    begin
       if_busy <= 1'b0;
       if_addr <= if_addr;
       if_jump <= 1'b0;
    end
end

//----------------------------------------
// Issue an Instruction Fetch Bus Access
//----------------------------------------
//wire fifo_room_empty_issue;
wire fifo_room_empty_body;
wire fifo_room_full_issue;
wire fifo_room_full_body;
reg  [31:0] busi_m_addr_next;
//
assign BUSI_M_REQ = (fetch_start_pending | (fetch_req & ~fifo_room_full_issue)) & ~FETCH_STOP;
//assign BUSI_M_REQ = (fetch_start_pending | fetch_req) & ~FETCH_STOP & ~fifo_room_full_issue;
//assign BUSI_M_REQ = fetch_start_pending | (fetch_req & ~FETCH_STOP & ~fifo_room_full_issue);
assign BUSI_M_SEQ   = ~fetch_start_pending;
assign BUSI_M_CONT  = fetch_req;
assign BUSI_M_BURST = 3'b001; // INCR: undefined length including single burst. 
assign BUSI_M_LOCK  = 1'b0;
assign BUSI_M_PROT  = 4'b0000;
assign BUSI_M_WRITE = 1'b0;
assign BUSI_M_SIZE  = (BUSI_M_ADDR[1] == 1'b0)? 2'b10 : 2'b01; // W or H
assign BUSI_M_ADDR  = (fetch_start_pending)? fetch_addr_pending :busi_m_addr_next;
assign BUSI_M_WDATA = 32'h00000000;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        busi_m_addr_next <= 32'h00000000;
    else if (BUSI_M_REQ & BUSI_M_ACK & ~BUSI_M_SEQ)
        busi_m_addr_next <= (fetch_addr_pending & ~32'h03) + 32'h00000004;
    else if (BUSI_M_REQ & BUSI_M_ACK)
        busi_m_addr_next <= (busi_m_addr_next & ~32'h03) + 32'h00000004;
end

//------------------------------
// Instructon Fetch FIFO Buffer
//------------------------------
reg  [31:0] fifo_dbuf[0:7];
reg  [31:0] fifo_abuf[0:7];
reg  [ 1:0] fifo_cbuf[0:7]; // bit0:Jump(Load), bit1:Error
//
reg  [ 2:0] fifo_wp_body, fifo_rp_body; // FIFO Pointer
reg  [ 3:0] fifo_count_issue; // FIFO Count by issuing BUSI_M_REQ
reg  [ 3:0] fifo_count_body; // FIFO Count by receiving BUSI_M_LAST
wire fifo_we_issue, fifo_we_body;
wire fifo_re_issue, fifo_re_body;
wire fifo_cw_issue, fifo_cw_body; // clear and write (jump)
wire fifo_cl_issue, fifo_cl_body; // clear
//
wire        fetch_done;       // An Instruction has fetched
wire [31:0] fetch_done_addr;  // Fetched Address
wire [31:0] fetch_done_code;  // Fetched Code
wire        fetch_done_jump;  // Fetched Code is Jump target
wire        fetch_done_ack;   // Decoder Received it
wire        fetch_done_berr;  // Bus Error during Fetch
//
//assign fifo_room_empty_issue = (fifo_count_issue == 4'b0000);
assign fifo_room_empty_body  = (fifo_count_body  == 4'b0000);
assign fifo_room_full_issue  = (fifo_count_issue >= 4'b1000);
assign fifo_room_full_body   = (fifo_count_body  >= 4'b1000);
//
assign fifo_we_issue = BUSI_M_REQ & BUSI_M_ACK; // including ~fifo_room_full_issue
assign fifo_re_issue = fifo_re_body;
assign fifo_cw_issue = fetch_start_ack; //FETCH_START & FETCH_ACK; //fifo_we_issue & ~BUSI_M_SEQ;
assign fifo_cl_issue = 1'b0; //FETCH_STOP;
//
//assign fifo_we_body = BUSI_M_LAST & if_busy; // must not be full state
assign fifo_we_body = BUSI_M_LAST & if_busy & ~fifo_room_full_body;
assign fifo_re_body = fetch_done & fetch_done_ack
                    & ~fifo_room_empty_body;
assign fifo_cw_body = fifo_we_body & if_jump; //1'b0;
assign fifo_cl_body = fetch_start_ack; //FETCH_START & FETCH_ACK;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        fifo_count_issue <= 4'b0000;
    else if (fifo_cl_issue)
        fifo_count_issue <= 4'b0000;
    else if (fifo_cw_issue)
        fifo_count_issue <= 4'b0001;
    else if (fifo_we_issue & fifo_re_issue)
        fifo_count_issue <= fifo_count_issue + 4'b0000;
    else if (fifo_we_issue)
        fifo_count_issue <= fifo_count_issue + 4'b0001;
    else if (fifo_re_issue)
        fifo_count_issue <= fifo_count_issue - 4'b0001;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        fifo_wp_body <= 3'b000;
        fifo_rp_body <= 3'b000;
        fifo_count_body <= 4'b0000;
    end
  //else if (fifo_cl_body | fifo_cw_issue)
    else if (fifo_cl_body)
    begin
        fifo_wp_body <= 3'b000;
        fifo_rp_body <= 3'b000;
        fifo_count_body <= 4'b0000;
    end
    else if (fifo_cw_body)
    begin
        fifo_wp_body <= fifo_rp_body + 3'b001; //3'b001;
        fifo_rp_body <= fifo_rp_body;          //3'b000;
        fifo_count_body <= 4'b0001;
    end
    else if (fifo_we_body & fifo_re_body)
    begin
        fifo_wp_body <= fifo_wp_body + 3'b001;
        fifo_rp_body <= fifo_rp_body + 3'b001;
    end
    else if (fifo_we_body)
    begin
        fifo_wp_body <= fifo_wp_body + 3'b001;
        fifo_count_body <= fifo_count_body + 4'b0001;        
    end    
    else if (fifo_re_body)
    begin
        fifo_rp_body <= fifo_rp_body + 3'b001;
        fifo_count_body <= fifo_count_body - 4'b0001;        
    end    
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        integer i;
        for (i = 0; i < 8; i = i + 1)
        begin
            fifo_dbuf[i] <= 32'h00000000;
            fifo_abuf[i] <= 32'h00000000;
            fifo_cbuf[i] <= 2'b00;        
        end
    end
    else if (fifo_cl_body)
    begin
        integer i;
        for (i = 0; i < 8; i = i + 1)
        begin
            fifo_dbuf[i] <= 32'h00000000;
            fifo_abuf[i] <= 32'h00000000;
            fifo_cbuf[i] <= 2'b00;        
        end
    end    
    else if (fifo_cw_body) // clear and write to rp
    begin
        fifo_dbuf[fifo_rp_body] <= BUSI_M_RDATA_RAW;
        fifo_abuf[fifo_rp_body] <= if_addr;
        fifo_cbuf[fifo_rp_body] <= {BUSI_M_DONE_RAW[3], if_jump};
    end
    else if (fifo_we_body)
    begin
        fifo_dbuf[fifo_wp_body] <= BUSI_M_RDATA_RAW;
        fifo_abuf[fifo_wp_body] <= if_addr;
        fifo_cbuf[fifo_wp_body] <= {BUSI_M_DONE_RAW[3], if_jump};
    end
end

//---------------------------------
// Instruction Fetch Output
//---------------------------------
assign fetch_done = ~fifo_room_empty_body;
assign fetch_done_addr = fifo_abuf[fifo_rp_body];
assign fetch_done_code = fifo_dbuf[fifo_rp_body];
assign fetch_done_jump = fifo_cbuf[fifo_rp_body][0];
assign fetch_done_berr = fifo_cbuf[fifo_rp_body][1];

//---------------------------------------
// Code Width Arrangement (32bit/16bit)
//---------------------------------------
reg  [15:0] code_buf0;
wire [15:0] code_buf1;
wire [15:0] code_buf2;
wire [ 1:0] code_buf1_size;
wire [ 1:0] code_buf2_size;
//
reg  [ 1:0] code_buf0_stat_next;
reg  [ 1:0] code_buf0_stat;
reg  [ 1:0] code_buf1_stat;
reg  [ 1:0] code_buf2_stat;
//
reg  [31:0] addr_buf0;
wire [31:0] addr_buf1;
wire [31:0] addr_buf2;
reg         berr_buf0;
wire        berr_buf1;
wire        berr_buf2;
reg         jump_buf0;
wire        jump_buf1;
wire        jump_buf2;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        code_buf0      <= 16'h0000;
        code_buf0_stat <= `CODE_NON;
        addr_buf0      <= 32'h00000000;
        berr_buf0      <= 1'b0;
        jump_buf0      <= 1'b0;
    end
    else if (DECODE_ACK & (code_buf0_stat_next == `CODE_NON))
    begin
        code_buf0      <= 16'h0000;
        code_buf0_stat <= `CODE_NON;
        addr_buf0      <= 32'h00000000;
        berr_buf0      <= 1'b0;
        jump_buf0      <= 1'b0;
    end
    else if (DECODE_ACK)
    begin
        code_buf0      <= code_buf2;
        code_buf0_stat <= code_buf0_stat_next;
        addr_buf0      <= addr_buf2;
        berr_buf0      <= berr_buf2;
        jump_buf0      <= jump_buf2;
    end
end
//
assign code_buf1 = fetch_done_code[15: 0];
assign code_buf2 = fetch_done_code[31:16];
assign code_buf1_size = (code_buf1[1:0] == 2'b11)? `CODE_32L : `CODE_16W;
assign code_buf2_size = (code_buf2[1:0] == 2'b11)? `CODE_32L : `CODE_16W;
//
assign addr_buf1 = {fetch_done_addr[31:2], 2'b00};
assign addr_buf2 = {fetch_done_addr[31:2], 2'b10};
assign berr_buf1 = fetch_done_berr;
assign berr_buf2 = fetch_done_berr;
//
assign jump_buf1 = fetch_done &  fetch_done_jump & ~fetch_done_addr[1] & (code_buf1_stat == `CODE_32L)
                 | fetch_done &  fetch_done_jump & ~fetch_done_addr[1] & (code_buf1_stat == `CODE_16W)
                 | fetch_done & ~fetch_done_jump & ~fetch_done_addr[1] & (code_buf1_stat == `CODE_32H) & jump_buf0;
assign jump_buf2 = fetch_done &  fetch_done_jump &  fetch_done_addr[1] & (code_buf2_stat == `CODE_32L)
                 | fetch_done &  fetch_done_jump &  fetch_done_addr[1] & (code_buf2_stat == `CODE_16W)
                 | fetch_done &  fetch_done_jump & ~fetch_done_addr[1] & (code_buf2_stat == `CODE_32H);
                 
//---------------------------------
// code_buf0_stat_next
//---------------------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, fetch_done_addr[1], code_buf0_stat, code_buf1_stat, code_buf2_stat})
        {1'b0, 1'b?, 1'b?, `CODE_NON, 2'b??    , 2'b??    } : code_buf0_stat_next = `CODE_NON;
        {1'b0, 1'b?, 1'b?, `CODE_16W, 2'b??    , 2'b??    } : code_buf0_stat_next = `CODE_NON;
        //
      //{1'b1, 1'b1, 1'b1, `CODE_NON, `CODE_NON, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
      //{1'b1, 1'b1, 1'b1, `CODE_NON, `CODE_NON, `CODE_16W} : code_buf0_stat_next = `CODE_NON;
        {1'b1, 1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        {1'b1, 1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_16W} : code_buf0_stat_next = `CODE_NON;
        //
      //{1'b1, 1'b1, 1'b?, `CODE_NON, `CODE_32L, `CODE_32H} : code_buf0_stat_next = `CODE_NON;
      //{1'b1, 1'b1, 1'b?, `CODE_NON, `CODE_16W, `CODE_16W} : code_buf0_stat_next = `CODE_16W;
      //{1'b1, 1'b1, 1'b?, `CODE_NON, `CODE_16W, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        {1'b1, 1'b1, 1'b?, 2'b??    , `CODE_32L, `CODE_32H} : code_buf0_stat_next = `CODE_NON;
        {1'b1, 1'b1, 1'b?, 2'b??    , `CODE_16W, `CODE_16W} : code_buf0_stat_next = `CODE_16W;
        {1'b1, 1'b1, 1'b?, 2'b??    , `CODE_16W, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        //
      //{1'b1, 1'b1, 1'b?, `CODE_16W, `CODE_32L, `CODE_32H} : code_buf0_stat_next = `CODE_NON;
      //{1'b1, 1'b1, 1'b?, `CODE_16W, `CODE_16W, `CODE_16W} : code_buf0_stat_next = `CODE_16W;
      //{1'b1, 1'b1, 1'b?, `CODE_16W, `CODE_16W, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        //
        {1'b1, 1'b0, 1'b?, `CODE_NON, `CODE_32L, `CODE_32H} : code_buf0_stat_next = `CODE_NON;
        {1'b1, 1'b0, 1'b?, `CODE_NON, `CODE_16W, `CODE_16W} : code_buf0_stat_next = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_NON, `CODE_16W, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        //
        {1'b1, 1'b0, 1'b?, `CODE_32L, `CODE_32H, `CODE_32L} : code_buf0_stat_next = `CODE_32L;
        {1'b1, 1'b0, 1'b?, `CODE_32L, `CODE_32H, `CODE_16W} : code_buf0_stat_next = `CODE_16W;
        //
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_32L, `CODE_32H} : code_buf0_stat_next = `CODE_NON;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_16W, `CODE_16W} : code_buf0_stat_next = `CODE_NON;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_16W, `CODE_32L} : code_buf0_stat_next = `CODE_NON;
        //
        default : code_buf0_stat_next = `CODE_NON;
    endcase
end

//---------------------------------
// code_buf1_stat
//---------------------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, fetch_done_addr[1], code_buf0_stat, code_buf1_size})
        {1'b0, 1'b?, 1'b?, 2'b??    , 2'b??    } : code_buf1_stat = `CODE_NON;
        {1'b1, 1'b1, 1'b1, 2'b??    , 2'b??    } : code_buf1_stat = `CODE_NON;
        {1'b1, 1'b1, 1'b0, 2'b??    , `CODE_32L} : code_buf1_stat = `CODE_32L;
        {1'b1, 1'b1, 1'b0, 2'b??    , `CODE_16W} : code_buf1_stat = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_NON, `CODE_32L} : code_buf1_stat = `CODE_32L;
        {1'b1, 1'b0, 1'b?, `CODE_NON, `CODE_16W} : code_buf1_stat = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_32L} : code_buf1_stat = `CODE_32L;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_16W} : code_buf1_stat = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_32L, 2'b??    } : code_buf1_stat = `CODE_32H;
        default : code_buf1_stat = `CODE_NON;
    endcase
end

//---------------------------------
// code_buf2_stat
//---------------------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, fetch_done_addr[1], code_buf1_stat, code_buf2_size})
        {1'b0, 1'b?, 1'b?, 2'b??    , 2'b??    } : code_buf2_stat = `CODE_NON;
        {1'b1, 1'b1, 1'b1, 2'b??    , `CODE_32L} : code_buf2_stat = `CODE_32L;
        {1'b1, 1'b1, 1'b1, 2'b??    , `CODE_16W} : code_buf2_stat = `CODE_16W;
        {1'b1, 1'b1, 1'b0, `CODE_32L, 2'b??    } : code_buf2_stat = `CODE_32H;
        {1'b1, 1'b1, 1'b0, `CODE_16W, `CODE_32L} : code_buf2_stat = `CODE_32L;
        {1'b1, 1'b1, 1'b0, `CODE_16W, `CODE_16W} : code_buf2_stat = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_32L, 2'b??    } : code_buf2_stat = `CODE_32H;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_32L} : code_buf2_stat = `CODE_32L;
        {1'b1, 1'b0, 1'b?, `CODE_16W, `CODE_16W} : code_buf2_stat = `CODE_16W;
        {1'b1, 1'b0, 1'b?, `CODE_32H, `CODE_32L} : code_buf2_stat = `CODE_32L;
        {1'b1, 1'b0, 1'b?, `CODE_32H, `CODE_16W} : code_buf2_stat = `CODE_16W;
        default : code_buf2_stat = `CODE_NON;
    endcase
end

//-----------------------
// DECODE_CODE
//-----------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, code_buf0_stat, code_buf1_stat, code_buf2_stat})
        {1'b0, 1'b?, `CODE_NON, 2'b??    , 2'b??    } : DECODE_CODE = 32'h00000000;
        {1'b0, 1'b?, `CODE_32L, 2'b??    , 2'b??    } : DECODE_CODE = 32'h00000000;
        {1'b0, 1'b?, `CODE_32H, 2'b??    , 2'b??    } : DECODE_CODE = 32'h00000000;
        {1'b0, 1'b?, `CODE_16W, 2'b??    , 2'b??    } : DECODE_CODE = {16'h0000 , code_buf0};
        //
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_32L} : DECODE_CODE = 32'h00000000;
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_16W} : DECODE_CODE = {16'h0000 , code_buf2};
        {1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_CODE = {code_buf2, code_buf1};
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_CODE = {16'h0000 , code_buf1};
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_CODE = {16'h0000 , code_buf1};
      //{1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_CODE = {code_buf2, code_buf1};
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_CODE = {16'h0000 , code_buf1};
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_CODE = {16'h0000 , code_buf1};
        //
        {1'b1, 1'b0, `CODE_NON, `CODE_32L, `CODE_32H} : DECODE_CODE = {code_buf2, code_buf1};
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_16W} : DECODE_CODE = {16'h0000 , code_buf1};
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_32L} : DECODE_CODE = {16'h0000 , code_buf1};
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_32L} : DECODE_CODE = {code_buf1, code_buf0};
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_16W} : DECODE_CODE = {code_buf1, code_buf0};
        {1'b1, 1'b0, `CODE_16W, `CODE_32L, `CODE_32H} : DECODE_CODE = {16'h0000 , code_buf0};
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_16W} : DECODE_CODE = {16'h0000 , code_buf0};
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_32L} : DECODE_CODE = {16'h0000 , code_buf0};
        //
        default : DECODE_CODE = 32'h00000000;
    endcase
end

//-----------------------
// DECODE_ADDR
//-----------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, code_buf0_stat, code_buf1_stat, code_buf2_stat})
        {1'b0, 1'b?, `CODE_NON, 2'b??    , 2'b??    } : DECODE_ADDR = 32'h00000000;
        {1'b0, 1'b?, `CODE_32L, 2'b??    , 2'b??    } : DECODE_ADDR = 32'h00000000;
        {1'b0, 1'b?, `CODE_32H, 2'b??    , 2'b??    } : DECODE_ADDR = 32'h00000000;
        {1'b0, 1'b?, `CODE_16W, 2'b??    , 2'b??    } : DECODE_ADDR = addr_buf0;
        //
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_32L} : DECODE_ADDR = 32'h00000000;
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_16W} : DECODE_ADDR = addr_buf2;
        {1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_ADDR = addr_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_ADDR = addr_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_ADDR = addr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_ADDR = addr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_ADDR = addr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_ADDR = addr_buf1;
        //
        {1'b1, 1'b0, `CODE_NON, `CODE_32L, `CODE_32H} : DECODE_ADDR = addr_buf1;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_16W} : DECODE_ADDR = addr_buf1;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_32L} : DECODE_ADDR = addr_buf1;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_32L} : DECODE_ADDR = addr_buf0;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_16W} : DECODE_ADDR = addr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_32L, `CODE_32H} : DECODE_ADDR = addr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_16W} : DECODE_ADDR = addr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_32L} : DECODE_ADDR = addr_buf0;
        //
        default : DECODE_ADDR = 32'h00000000;
    endcase
end

//-----------------------
// DECODE_BERR
//-----------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, code_buf0_stat, code_buf1_stat, code_buf2_stat})
        {1'b0, 1'b?, `CODE_NON, 2'b??    , 2'b??    } : DECODE_BERR = 1'b0;
        {1'b0, 1'b?, `CODE_32L, 2'b??    , 2'b??    } : DECODE_BERR = 1'b0;
        {1'b0, 1'b?, `CODE_32H, 2'b??    , 2'b??    } : DECODE_BERR = 1'b0;
        {1'b0, 1'b?, `CODE_16W, 2'b??    , 2'b??    } : DECODE_BERR = berr_buf0;
        //
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_32L} : DECODE_BERR = 1'b0;
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_16W} : DECODE_BERR = berr_buf2;
        {1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_BERR = berr_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_BERR = berr_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_BERR = berr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_BERR = berr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_BERR = berr_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_BERR = berr_buf1;
        //
        {1'b1, 1'b0, `CODE_NON, `CODE_32L, `CODE_32H} : DECODE_BERR = berr_buf1;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_16W} : DECODE_BERR = berr_buf1;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_32L} : DECODE_BERR = berr_buf1;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_32L} : DECODE_BERR = berr_buf0;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_16W} : DECODE_BERR = berr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_32L, `CODE_32H} : DECODE_BERR = berr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_16W} : DECODE_BERR = berr_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_32L} : DECODE_BERR = berr_buf0;
        //
        default : DECODE_BERR = 1'b0;
    endcase
end

//-----------------------
// DECODE_JUMP
//-----------------------
always @*
begin
    casez ({fetch_done, fetch_done_jump, code_buf0_stat, code_buf1_stat, code_buf2_stat})
        {1'b0, 1'b?, `CODE_NON, 2'b??    , 2'b??    } : DECODE_JUMP = 1'b0;
        {1'b0, 1'b?, `CODE_32L, 2'b??    , 2'b??    } : DECODE_JUMP = 1'b0;
        {1'b0, 1'b?, `CODE_32H, 2'b??    , 2'b??    } : DECODE_JUMP = 1'b0;
        {1'b0, 1'b?, `CODE_16W, 2'b??    , 2'b??    } : DECODE_JUMP = jump_buf0;
        //
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_32L} : DECODE_JUMP = 1'b0;
        {1'b1, 1'b1, 2'b??    , `CODE_NON, `CODE_16W} : DECODE_JUMP = jump_buf2;
        {1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_JUMP = jump_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_JUMP = jump_buf1;
        {1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_JUMP = jump_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_32L, `CODE_32H} : DECODE_JUMP = jump_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_16W} : DECODE_JUMP = jump_buf1;
      //{1'b1, 1'b1, 2'b??    , `CODE_16W, `CODE_32L} : DECODE_JUMP = jump_buf1;
        //
        {1'b1, 1'b0, `CODE_NON, `CODE_32L, `CODE_32H} : DECODE_JUMP = 1'b0;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_16W} : DECODE_JUMP = 1'b0;
        {1'b1, 1'b0, `CODE_NON, `CODE_16W, `CODE_32L} : DECODE_JUMP = 1'b0;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_32L} : DECODE_JUMP = jump_buf0;
        {1'b1, 1'b0, `CODE_32L, `CODE_32H, `CODE_16W} : DECODE_JUMP = jump_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_32L, `CODE_32H} : DECODE_JUMP = jump_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_16W} : DECODE_JUMP = jump_buf0;
        {1'b1, 1'b0, `CODE_16W, `CODE_16W, `CODE_32L} : DECODE_JUMP = jump_buf0;
        //
        default : DECODE_JUMP = 1'b0;
    endcase
end

//------------------------------------
// Decode Request and Acknowledge
//------------------------------------
assign DECODE_REQ = fetch_done | (code_buf0_stat == `CODE_16W);
assign fetch_done_ack = DECODE_ACK & fetch_done &
    ((fetch_done_jump) | (~fetch_done_jump & (code_buf0_stat != `CODE_16W)));

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
