//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_pileline.v
// Description : Pipeline Control of CPU
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.12 M.Maruyama First Release
// Rev.02 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================
//
// Pipeline Stage = 3 to 5 stage for Integer Instructions
//   F:Instruction Fetch
//   D:Decode
//   E:Execution
//   M:Data Access
//   W:Write Back
//
// Forwarding and Stall
//   Register Value
//   None     0x0000
//   XR0-XR31 0x1000-0x101F
//   FR0-FR31 0x2000-0x201F
//   CSR      0x3000-0x3FFF
//
//   id_alu_src1
//   id_alu_src2
//   id_alu_dst
//   ex_alu_src1
//   ex_alu_src2
//   ex_alu_dst1
//   id_load_dst
//   ex_load_dst
//   ma_load_dst
//   wb_load_dst
//   
//
//   Load DEMW
//   ALU   DdE
//
//   ALU  DE
//   CBra  D
//
//   Load DEMW
//   ALU   DdE
//   CBra    D
//
//

//
// Instrution Fetch is issued by previous Decode Stage
//   DE
//    ...
//   ad
//    F
//
// Pipeline and Instruction Fetch
//   AHB   ad
//          ad
//           ad
//            a---d
//             ---ad
//   Pipe   FDE
//           FDE
//            FDE
//             FFFFD
//                 FDE
//
// 32bit/16bit Instruction Fetch
//


`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_PIPELINE
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    // Stand-by Control
    input  wire STBY_REQ,  // System Stand-by Request
    output reg  STBY_ACK,  // System Stand-by Acknowledge
    //
    // Reset Vector
    input  wire [31:0] RESET_VECTOR,  // Reset Vector
    //
    // Instruction Fetch Command
    output wire        FETCH_START,      // Instruction Fetch Start Request
    output wire        FETCH_STOP,       // Instruction Fetch Stop Request
    input  wire        FETCH_ACK,        // Instruction Fetch Start Acknowledge
    output wire [31:0] FETCH_ADDR,       // Instruction Fetch Start Address
    input  wire        DECODE_REQ,       // Decode Request
    output wire        DECODE_ACK,       // Decode Acknowledge
    input  wire [31:0] DECODE_CODE,      // Decode Instruction Code
    input  wire [31:0] DECODE_ADDR,      // Decode Instruction Address
    input  wire        DECODE_BERR,      // Decode Instruction Bus Error
    input  wire        DECODE_JUMP,      // Decode Instruction Jump Target
    //
    output wire        PIPE_ID_ENABLE,   // Pipeline ID Stage
    output wire        PIPE_EX_ENABLE,   // Pipeline EX Stage
    output wire        PIPE_MA_ENABLE,   // Pipeline MA Stage
    output wire        PIPE_WB_ENABLE,   // Pipeline WB Stage
    //
    output wire [13:0] ID_DEC_SRC1,  // Decode Source 1 in ID Stage
    output wire [13:0] ID_DEC_SRC2,  // Decode Source 2 in ID Stage
    output wire [13:0] ID_ALU_SRC2,  // ALU Source 2 in ID Stage (CSR)
    output wire [13:0] EX_ALU_SRC1,  // ALU Source 1 in EX Stage
    output wire [13:0] EX_ALU_SRC2,  // ALU Source 2 in EX Stage
    output wire [13:0] EX_ALU_SRC3,  // ALU Source 3 in EX Stage (FPU)
    output wire [31:0] EX_ALU_IMM,   // ALU Immediate Data in EX Stage
    output wire [13:0] EX_ALU_DST1,  // ALU Destination 1 in EX Stage
    output wire [13:0] EX_ALU_DST2,  // ALU Destination 2 in EX Stage
    output wire [ 4:0] EX_ALU_FUNC,  // ALU Function in EX Stage
    output wire [ 4:0] EX_ALU_SHAMT, // ALU Shift Amount in EX Stage
    output wire [31:0] EX_PC,        // Current PC in EX Stage
    output wire [ 4:0] ID_MACMD,     // Memory Access Command in ID State
    output wire [ 4:0] EX_MACMD,     // Memory Access Command in EX State
    output wire [ 4:0] WB_MACMD,     // Memory Access Command in WB State
    output wire [13:0] EX_STSRC,     // Memory Store Data Source in EX Stage
    output wire [13:0] WB_LOAD_DST,  // Memory Load Destination in WB Stage
    input  wire        EX_MARDY,     // Memory Address Ready in EX Stage 
    input  wire        MA_MDRDY,     // Memory Data Ready in MA Stage 
    input  wire [31:0] ID_BUSA,      // busA in ID Stage
    input  wire [31:0] ID_BUSB,      // busB in ID Stage
    output wire [ 2:0] ID_CMP_FUNC,  // Comparator Function in ID Stage
    input  wire        ID_CMP_RSLT,  // Comparator Result in ID Stage
    output wire [ 2:0] EX_MUL_FUNC,  // MultiPlier Function in EX Stage
    output wire [ 2:0] ID_DIV_FUNC,  // Divider Function in ID Stage
    output wire [ 2:0] EX_DIV_FUNC,  // Divider Function in EX Stage
    output wire        ID_DIV_EXEC,  // Divider Invoke Execution in ID Stage
    output reg         ID_DIV_STOP,  // Divider Abort
    input  wire        ID_DIV_BUSY,  // Divider in busy
    output wire        ID_DIV_CHEK,  // DIvision Illegal Check in ID Stage
    input  wire        EX_DIV_ZERO,  // Division by Zero in EX Stage
    input  wire        EX_DIV_OVER,  // Division Overflow in EX Stage
    //
    output wire        EX_AMO_1STLD, // AMO 1st Load Access
    output wire        EX_AMO_2NDST, // AMO 2nd Store Access
    output wire        EX_AMO_LRSVD, // AMO Load Reserved
    output wire        EX_AMO_SCOND, // AMO Store Conditional
    //
    input  wire [ 1:0] EX_BUSERR_ALIGN, // Memory Bus Access Error by Misalignment
    input  wire [ 1:0] WB_BUSERR_FAULT, // Memory Bus Access Error by Bus Fault
    input  wire [31:0] EX_BUSERR_ADDR,  // Memory Bus Access Error Address in EX Stage 
    input  wire [31:0] WB_BUSERR_ADDR,  // Memory Bus Access Error Address in WB Stage
    //
    input  wire [31:0] MTVEC_INT,    // Trap Vector for Interrupt
    input  wire [31:0] MTVEC_EXP,    // Trap Vector for Exception
    output reg  [31:0] MTVAL,        // Trap Value
    output reg  [31:0] MEPC_SAVE,    // Exception PC to be saved
    input  wire [31:0] MEPC_LOAD,    // Exception PC to be loaded
    output reg  [31:0] MCAUSE,       // Cause of Exception
    output wire        EXP_ACK,      // Exception Acknowledge
    output wire        MRET_ACK,     // MRET Acknowledge
    input  wire        INT_REQ,      // Interrupt Request to CPU
    output wire        INT_ACK,      // Interrupt Acknowledge from CPU
    //
    output reg         WFI_WAITING,  // WFI Waiting for Interrupt
    input  wire        WFI_THRU_REQ, // WFI Through Request by Interrupt Edge duging MIE=0
    output wire        WFI_THRU_ACK, // WFI Through Acknowledge
    //
    input  wire [ 1:0] TRG_REQ_INST, // Trigger Request by Instruction (bit1:action, bit0:hit)
    input  wire [ 1:0] TRG_REQ_DATA, // Trigger Request by Data Access (bit1:action, bit0:hit)
    output wire        TRG_ACK_INST, // Trigger Acknowledge for TRG_REQ_INST
    output wire        TRG_ACK_DATA, // Trigger Acknowledge for TRG_REQ_DATA
    output wire        TRG_CND_ICOUNT_DEC, // ICOUNT Decrement
    //
    output wire        INSTR_EXEC, // Instruction Retired
    output wire [31:0] INSTR_ADDR, // Instruction Retired Address
    output wire [31:0] INSTR_CODE, // Instruction Retired Code
    //
    input  wire        DBG_HALT_REQ,     // HALT Request
    output wire        DBG_HALT_ACK,     // HALT Acknowledge
    input  wire        DBG_HALT_RESET,   // HALT when Reset
    input  wire        DBG_HALT_EBREAK,  // HALT when EBREAK
    input  wire        DBG_RESUME_REQ,   // Resume Request 
    output wire        DBG_RESUME_ACK,   // Resume Acknowledge 
    output reg  [31:0] DBG_DPC_SAVE,     // Debug PC to be saved
    input  wire [31:0] DBG_DPC_LOAD,     // Debug PC to be loaded
    output reg  [ 2:0] DBG_CAUSE,        // Debug Entry Cause
    output wire        DEBUG_MODE,       // Debug Mode
    output wire        DEBUG_MODE_EMPTY  // Debug Mode with Pipeline Empty
    //
    ,
    output wire [13:0] ID_FPU_SRC1,  // FPU Source 1 in ID Stage
    output wire [13:0] ID_FPU_SRC2,  // FPU Source 2 in ID Stage
    output wire [13:0] ID_FPU_SRC3,  // FPU Source 3 in ID Stage
    output wire [13:0] ID_FPU_DST1,  // FPU Destination 1 in ID Stage
    output wire [ 7:0] ID_FPU_CMD,   // FPU Command in ID Stage
    output wire [ 2:0] ID_FPU_RMODE, // FPU Round Mode in ID Stage
    input  wire        ID_FPU_STALL, // FPU Stall Request in ID Stage    
    input  wire        FPUCSR_DIRTY  // FPU CSR is Dirty
);

//-------------------------
// STBY related Control
//-------------------------
reg  stby_req;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        stby_req <= 1'b0;
    else
        stby_req <= STBY_REQ;
end
//
reg  stby_req_delay;
wire stby_req_rise;
wire stby_req_fall;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        stby_req_delay <= 1'b0;
    else
        stby_req_delay <= stby_req;
end
assign stby_req_rise =  stby_req & ~stby_req_delay;
assign stby_req_fall = ~stby_req &  stby_req_delay;
//
reg  stby_halt_req;
wire stby_halt_ack;
reg  stby_halt_ack_0;
reg  stby_resume_req;
wire stby_resume_ack;
reg  stby_resume_ack_0;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        stby_halt_req <= 1'b0;
    else if (stby_halt_ack)
        stby_halt_req <= 1'b0;
    else if (stby_req & INSTR_EXEC)
        stby_halt_req <= 1'b1;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        stby_resume_req <= 1'b0;
    else if (stby_req_fall)
        stby_resume_req <= 1'b1;
    else if (stby_resume_ack)
        stby_resume_req <= 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        STBY_ACK <= 1'b0;
    else if (stby_halt_ack)
        STBY_ACK <= 1'b1;
    else if (stby_resume_ack)
        STBY_ACK <= 1'b0;
end

//-----------------------------
// Decode Immediate Field
//-----------------------------
function [31:0] IMM_IS; // RV32I I-Type Signed
    input [31:0] CODE;
    begin
        IMM_IS = {{20{CODE[31]}}, CODE[31:20]};
    end
endfunction
//
function [31:0] IMM_SS; // RV32I S-Type Signed
    input [31:0] CODE;
    begin
        IMM_SS = {{20{CODE[31]}}, CODE[31:25], CODE[11:7]};
    end
endfunction
//
function [31:0] IMM_BS; // RV32I B-Type Signed
    input [31:0] CODE;
    begin
        IMM_BS = {{19{CODE[31]}}, CODE[31], CODE[7], CODE[30:25], CODE[11:8], 1'b0};
    end
endfunction
//
function [31:0] IMM_UU; // RV32I U-Type Unsigned
    input [31:0] CODE;
    begin
        IMM_UU = {CODE[31:12], 12'h000};
    end
endfunction
//
function [31:0] IMM_JS; // RV32I J-Type Signed
    input [31:0] CODE;
    begin
        IMM_JS = {{11{CODE[31]}}, CODE[31], CODE[19:12], CODE[20], CODE[30:21], 1'b0};
    end
endfunction
//-------------------------------------------------------------------------------------
function [31:0] IMM_ZCU; // RV32ZICSR CSR-Type Unigned
    input [31:0] CODE;
    begin
        IMM_ZCU = {27'h0, CODE[19:15]};
    end
endfunction
//-------------------------------------------------------------------------------------
function [31:0] IMM_CIS; // RV32C CI-Type Signed
    input [31:0] CODE;
    begin
        IMM_CIS = {{26{CODE[12]}}, CODE[12], CODE[6:2]};
    end
endfunction
//
function [31:0] IMM_CIU; // RV32C CI-Type Unsigned
    input [31:0] CODE;
    begin
        IMM_CIU = {26'b0, CODE[12], CODE[6:2]};
    end
endfunction
//
function [4:0] IMM_CIU5; // RV32C CI-Type Unsigned Lower 6bit
    input [31:0] CODE;
    begin
        IMM_CIU5 = CODE[6:2];
    end
endfunction
//
function [31:0] IMM_CIWU; // RV32C CWI-Type Unsigned (C.ADDI4SPN)
    input [31:0] CODE;
    begin
        IMM_CIWU = {22'b0, CODE[10:7], CODE[12:11], CODE[5], CODE[6], 2'b00};
    end
endfunction
//
function [31:0] IMM_CI16S; // RV32C CI16-Type Signed (C.ADDI16SP)
    input [31:0] CODE;
    begin
        IMM_CI16S = {{22{CODE[12]}}, CODE[12], CODE[4:3], CODE[5], CODE[2], CODE[6], 4'b0000};
    end
endfunction
//
function [31:0] IMM_CLUI; // RV32C CLUI-Type Signed (C.LUI)
    input [31:0] CODE;
    begin
        IMM_CLUI = {{14{CODE[12]}}, CODE[12], CODE[6:2], 12'h000};
    end
endfunction
//
function [31:0] IMM_CLSU; // RV32C CL/CS-Type Unsigned
    input [31:0] CODE;
    begin
        IMM_CLSU = {25'b0, CODE[5], CODE[12:10], CODE[6], 2'b00};
    end
endfunction
//
function [31:0] IMM_CJS; // RV32C CJ-Type Signed
    input [31:0] CODE;
    begin
        IMM_CJS = {{20{CODE[12]}}, CODE[12], CODE[8], CODE[10:9], CODE[6], CODE[7],CODE[2], CODE[11], CODE[5:3], 1'b0};
    end
endfunction
//
function [31:0] IMM_CBS; // RV32C CB-Type Signed
    input [31:0] CODE;
    begin
        IMM_CBS = {{23{CODE[12]}}, CODE[12], CODE[6:5], CODE[2], CODE[11:10], CODE[4:3], 1'b0};
    end
endfunction
//
function [31:0] IMM_CLWSPU; // RV32C CLWSP-Type Unsigned
    input [31:0] CODE;
    begin
        IMM_CLWSPU = {24'b0, CODE[3:2], CODE[12], CODE[6:4], 2'b00};
    end
endfunction
//
function [31:0] IMM_CSWSPU; // RV32C CSWSP-Type Unsigned
    input [31:0] CODE;
    begin
        IMM_CSWSPU = {24'b0, CODE[8:7], CODE[12:9], 2'b00};
    end
endfunction

//---------------------------
// Fetch Start and Stop
//---------------------------
wire slot;
wire stall_cpu;
wire stall;
reg  fetch_start;
reg  fetch_start_by_cond;
reg  fetch_stop;
//
assign FETCH_START = (fetch_start | (fetch_start_by_cond & ID_CMP_RSLT)) & ~stall & slot;
assign FETCH_STOP  = fetch_stop;

//--------------------
// Pipeline Slot
//--------------------
reg  decode_ack; // Decode Acknowledge to Fetch Unit
reg  decode_stp; // Each Decode Stage Step done 
//
//assign slot = (fetch_start)? (EX_MARDY & MA_MDRDY & FETCH_ACK)
//                         : (EX_MARDY & MA_MDRDY);
assign slot = EX_MARDY & MA_MDRDY;

//------------------------
// Memory Access Control
//------------------------
reg [ 4:0] id_macmd;
reg [13:0] id_stsrc;
reg [ 4:0] ex_macmd;
reg [13:0] ex_stsrc;
reg [ 4:0] ma_macmd;
reg [ 4:0] wb_macmd;
reg        id_amo_1stld;
reg        id_amo_2ndst;
reg        id_amo_lrsvd;
reg        id_amo_scond;
reg        ex_amo_1stld;
reg        ex_amo_2ndst;
reg        ex_amo_lrsvd;
reg        ex_amo_scond;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        ex_macmd <= 5'b00000;
        ex_stsrc <= 14'h0000;
        ex_amo_1stld <= 1'b0;
        ex_amo_2ndst <= 1'b0;
        ex_amo_lrsvd <= 1'b0;
        ex_amo_scond <= 1'b0;
    end
  //else if (slot & decode_stp)
    else if (slot & ~stall)
    begin
        ex_macmd <= id_macmd;
        ex_stsrc <= id_stsrc;
        ex_amo_1stld <= id_amo_1stld;
        ex_amo_2ndst <= id_amo_2ndst;
        ex_amo_lrsvd <= id_amo_lrsvd;
        ex_amo_scond <= id_amo_scond;
    end
  //else if (slot & ~decode_stp)
  //begin
  //    ex_macmd <= 5'b00000;
  //    ex_stsrc <= 14'h0000;
  //end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        ma_macmd <= 5'b00000;
        wb_macmd <= 5'b00000;
    end
    else if (slot)
    begin
        ma_macmd <= (EX_BUSERR_ALIGN[0])? 5'b00000 : ex_macmd;
        wb_macmd <= ma_macmd;
    end
end

//------------------------
// Pipeline Control
//------------------------
reg  pipe_id_enable;
reg  pipe_ex_enable;
reg  pipe_ma_enable;
reg  pipe_wb_enable;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        pipe_ex_enable <= 1'b0;
  //else if (slot & decode_stp)
  //else if (slot)
    else if (slot & ~stall)
        pipe_ex_enable <= pipe_id_enable;
  //else if (slot & ~decode_stp)
  //    pipe_ex_enable <= 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        pipe_ma_enable <= 1'b0;
    else if (slot)
        pipe_ma_enable <= (EX_BUSERR_ALIGN[0])? 1'b0
                        : (ex_macmd[4])? pipe_ex_enable : 1'b0;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        pipe_wb_enable <= 1'b0;
    else if (slot)
        pipe_wb_enable <= (ma_macmd[4:3] == 2'b10)? pipe_ma_enable : 1'b0;
end
//
assign PIPE_ID_ENABLE = slot & ~stall & decode_stp & pipe_id_enable;
assign PIPE_EX_ENABLE = pipe_ex_enable;
assign PIPE_MA_ENABLE = pipe_ma_enable;
assign PIPE_WB_ENABLE = pipe_wb_enable;

//-----------------------------------
// Information of Register Usage
//-----------------------------------
reg  [13:0] id_dec_src1;
reg  [13:0] id_dec_src2;
reg  [13:0] id_alu_src1;
reg  [13:0] id_alu_src2;
reg  [13:0] id_alu_src3;
reg  [13:0] id_alu_dst1;
reg  [13:0] id_alu_dst2;
reg  [13:0] ex_alu_src1;
reg  [13:0] ex_alu_src2;
reg  [13:0] ex_alu_src3;
reg  [13:0] ex_alu_dst1;
reg  [13:0] ex_alu_dst2;
reg  [13:0] id_load_dst;
reg  [13:0] ex_load_dst;
reg  [13:0] ma_load_dst;
reg  [13:0] wb_load_dst;
reg  [ 4:0] id_alu_func;
reg  [ 4:0] ex_alu_func;
reg  [31:0] id_alu_imm;
reg  [31:0] ex_alu_imm;
reg  [ 4:0] id_alu_shamt;
reg  [ 4:0] ex_alu_shamt;
reg  [ 2:0] id_mul_func;
reg  [ 2:0] ex_mul_func;
reg  [ 2:0] id_div_func;
reg  [ 2:0] ex_div_func;
reg         id_div_exec;
reg         id_div_chek;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        ex_alu_src1  <= 14'h0000;
        ex_alu_src2  <= 14'h0000;
        ex_alu_src3  <= 14'h0000;
        ex_alu_dst1  <= 14'h0000;
        ex_alu_dst2  <= 14'h0000;
        ex_load_dst  <= 14'h0000;
        ex_alu_func  <=  5'b00000;
        ex_alu_imm   <= 32'h00000000;
        ex_alu_shamt <=  5'b00000;
        ex_mul_func  <=  3'b000;
        ex_div_func  <=  3'b000;
    end
    else if (slot & stall)
    begin
        ex_alu_src1  <= 14'h0000;
        ex_alu_src2  <= 14'h0000;
        ex_alu_src3  <= 14'h0000;
        ex_alu_dst1  <= 14'h0000;
        ex_alu_dst2  <= 14'h0000;
        ex_load_dst  <= 14'h0000;
        ex_alu_func  <=  5'b00000;
        ex_alu_imm   <= 32'h00000000;
        ex_alu_shamt <=  5'b00000;
        ex_mul_func  <=  3'b000;
        ex_div_func  <=  3'b000;
    end
  //else if (decode_stp)
  //else if (slot & decode_stp)
    else if (slot & decode_stp & ~stall)
    begin
        ex_alu_src1  <= id_alu_src1;
        ex_alu_src2  <= id_alu_src2;
        ex_alu_src3  <= id_alu_src3;
        ex_alu_dst1  <= id_alu_dst1;
        ex_alu_dst2  <= id_alu_dst2;
        ex_load_dst  <= id_load_dst;
        ex_alu_func  <= id_alu_func;
        ex_alu_imm   <= id_alu_imm;
        ex_alu_shamt <= id_alu_shamt;
        ex_mul_func  <= id_mul_func;
        ex_div_func  <= id_div_func;
    end
    else if (slot & ~decode_stp)
  //else if (~decode_stp)
    begin
        ex_alu_src1  <= 14'h0000;
        ex_alu_src2  <= 14'h0000;
        ex_alu_src3  <= 14'h0000;
        ex_alu_dst1  <= 14'h0000;
        ex_alu_dst2  <= 14'h0000;
        ex_load_dst  <= 14'h0000;
        ex_alu_func  <=  5'b00000;
        ex_alu_imm   <= 32'h00000000;
        ex_alu_shamt <=  5'b00000;
        ex_mul_func  <=  3'b000;
        ex_div_func  <=  3'b000;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
//      ex_load_dst <= 14'h0000;
        ma_load_dst <= 14'h0000;
        wb_load_dst <= 14'h0000;
    end
    else if (slot)
    begin
//      ex_load_dst <= id_load_dst;
        ma_load_dst <= (~EX_BUSERR_ALIGN[0])? ex_load_dst : 14'h0000;
        wb_load_dst <= ma_load_dst;
    end
end

//-----------------------------------
// Pipeline Stall Control (ID Stage)
//-----------------------------------
//   Load DEMW
//   ALU   dDE
//
//   Load DEMW
//   CBra  ddD
//
//   ALU  DE
//   CBra  D
//
//   Load DEMW
//   ALU   dDE
//   CBra    D
//
assign stall_cpu = id_alu_src1[13] & ex_load_dst[13] & (id_alu_src1[12:0] == ex_load_dst[12:0])
                 | id_alu_src2[13] & ex_load_dst[13] & (id_alu_src2[12:0] == ex_load_dst[12:0])
                 | id_alu_src3[13] & ex_load_dst[13] & (id_alu_src3[12:0] == ex_load_dst[12:0]) // FMADD..
                 | id_alu_dst1[13] & ex_load_dst[13] & (id_alu_dst1[12:0] == ex_load_dst[12:0])
                 | id_alu_dst2[13] & ex_load_dst[13] & (id_alu_dst2[12:0] == ex_load_dst[12:0])
                 | id_dec_src1[13] & ex_load_dst[13] & (id_dec_src1[12:0] == ex_load_dst[12:0])
                 | id_dec_src2[13] & ex_load_dst[13] & (id_dec_src2[12:0] == ex_load_dst[12:0])
                 | id_dec_src1[13] & ma_load_dst[13] & (id_dec_src1[12:0] == ma_load_dst[12:0])
                 | id_dec_src2[13] & ma_load_dst[13] & (id_dec_src2[12:0] == ma_load_dst[12:0])
                 | id_stsrc   [13] & ex_load_dst[13] & (id_stsrc   [12:0] == ex_load_dst[12:0]);
assign stall = stall_cpu | ID_FPU_STALL
             | (FPUCSR_DIRTY & (id_alu_src2 == (`ALU_CSR | `CSR_FFLAGS)))
             | (FPUCSR_DIRTY & (id_alu_src2 == (`ALU_CSR | `CSR_FRM   )))
             | (FPUCSR_DIRTY & (id_alu_src2 == (`ALU_CSR | `CSR_FCSR  )))
             | (FPUCSR_DIRTY & (id_alu_dst2 == (`ALU_CSR | `CSR_FFLAGS)))
             | (FPUCSR_DIRTY & (id_alu_dst2 == (`ALU_CSR | `CSR_FRM   )))
             | (FPUCSR_DIRTY & (id_alu_dst2 == (`ALU_CSR | `CSR_FCSR  )));

//----------------------
// Program Counter
//----------------------
wire [31:0] pipe_id_pc;
reg  [31:0] pipe_ex_pc;
//
assign pipe_id_pc = DECODE_ADDR;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        pipe_ex_pc <= 32'h00000000;
    else if (pipe_id_enable & slot & ~stall &  decode_stp)
        pipe_ex_pc <= pipe_id_pc;
//  else if (slot & ~stall &  decode_stp)
//      pipe_ex_pc <= pipe_id_pc;
//  else if (slot & ~stall & ~decode_stp)
//      pipe_ex_pc <= 32'h00000000;
end

//---------------------
// Instruction Code
//---------------------
wire [31:0] pipe_id_code;
//
assign pipe_id_code = DECODE_CODE;
//
//reg  [31:0] pipe_ex_code;
//
//always @(posedge CLK, posedge RES_CPU)
//begin
//    if (RES_CPU)
//        pipe_ex_code <= 32'h00000000;
//    else if (slot & ~stall &  decode_stp)
//        pipe_ex_code <= pipe_id_code;
//    else if (slot & ~stall & ~decode_stp)
//        pipe_ex_code <= 32'h00000000;
//end

//-----------------------
// Jump and Branch 
//-----------------------
reg       jump_target_reset;
reg       jump_target_jal;
reg       jump_target_jalr;
reg       jump_target_bcc;
reg       jump_target_cj;
reg       jump_target_cbcc;
reg       jump_target_cjr;
reg       jump_target_fencei;
reg       jump_target_exp;
reg       jump_target_int;
reg       jump_target_mret;
reg       jump_target_resume;
reg       jump_target_stby_resume;
reg [2:0] id_cmp_func;       
//
assign FETCH_ADDR = (jump_target_reset )? RESET_VECTOR
                  : (jump_target_jal   )? pipe_id_pc + IMM_JS(pipe_id_code)
                  : (jump_target_jalr  )? ID_BUSA    + IMM_IS(pipe_id_code)
                  : (jump_target_bcc   )? pipe_id_pc + IMM_BS(pipe_id_code)
                  : (jump_target_cj    )? pipe_id_pc + IMM_CJS(pipe_id_code)
                  : (jump_target_cbcc  )? pipe_id_pc + IMM_CBS(pipe_id_code)
                  : (jump_target_cjr   )? ID_BUSA
                  : (jump_target_fencei)? pipe_id_pc + 32'h00000004
                  : (jump_target_exp   )? MTVEC_EXP
                  : (jump_target_int   )? MTVEC_INT
                  : (jump_target_mret  )? MEPC_LOAD
                  : (jump_target_resume)? DBG_DPC_LOAD
                  : (jump_target_stby_resume) ? pipe_id_pc
                  : 32'h00000000;

//------------------------------------------------
// Instruction Decode Request from Fetch Unit
//------------------------------------------------
wire decode_req;
//assign decode_req = DECODE_REQ & slot;
assign decode_req = DECODE_REQ;
assign DECODE_ACK   = decode_ack & ~stall & slot;
//assign DECODE_ACK   = (slot & ~stall)? decode_ack   :  1'b0;
//assign DECODE_ACK = decode_ack;

//------------------------
// FPU Control
//------------------------
reg  [13:0] id_fpu_src1;
reg  [13:0] id_fpu_src2;
reg  [13:0] id_fpu_src3;
reg  [13:0] id_fpu_dst1;
reg  [ 7:0] id_fpu_cmd;      // FPU Command in ID Stage
reg  [ 2:0] id_fpu_rmode;    // FPU Round Mode in ID Stage

//--------------------------
// HALT and RESUME Control
//--------------------------
reg  dbg_halt_ack;   // Debug HALT Acknowledge
reg  dbg_resume_ack; // Debug RESUME Acknowledge 

//-------------------------
// Datapath Interface
//-------------------------
assign ID_DEC_SRC1  = (       ~stall)? id_dec_src1  : 14'h0;
assign ID_DEC_SRC2  = (       ~stall)? id_dec_src2  : 14'h0;
assign ID_ALU_SRC2  = (       ~stall)? id_alu_src2  : 14'h0;
assign ID_CMP_FUNC  = (       ~stall)? id_cmp_func  :  3'h0;
assign EX_ALU_SRC1  = (1'b1         )? ex_alu_src1  : 14'h0;
assign EX_ALU_SRC2  = (1'b1         )? ex_alu_src2  : 14'h0;
assign EX_ALU_SRC3  = (1'b1         )? ex_alu_src3  : 14'h0;
assign EX_ALU_IMM   = (1'b1         )? ex_alu_imm   : 32'h0;
assign EX_ALU_DST1  = (slot         )? ex_alu_dst1  : 14'h0;
assign EX_ALU_DST2  = (slot         )? ex_alu_dst2  : 14'h0;
assign EX_ALU_FUNC  = (1'b1         )? ex_alu_func  :  5'h0;
assign EX_PC        = (1'b1         )? pipe_ex_pc   : 32'h0;
assign EX_ALU_SHAMT = (1'b1         )? ex_alu_shamt :  5'h0;
assign EX_MUL_FUNC  = (1'b1         )? ex_mul_func  :  3'h0;
assign ID_DIV_FUNC  = (1'b1         )? id_div_func  :  3'h0;
assign EX_DIV_FUNC  = (1'b1         )? ex_div_func  :  3'h0;
assign ID_DIV_EXEC  = (slot & ~stall)? id_div_exec  :  1'h0;
assign ID_DIV_CHEK  = (slot & ~stall)? id_div_chek  :  1'h0;
//
assign ID_MACMD     = (slot & ~stall)? id_macmd     :  5'h0;
assign EX_MACMD     = (1'b1         )? ex_macmd     :  5'h0;
assign WB_MACMD     = (1'b1         )? wb_macmd     :  5'h0;
assign EX_STSRC     = (1'b1         )? ex_stsrc     : 14'h0;
assign WB_LOAD_DST  = (1'b1         )? wb_load_dst  : 14'h0;
assign EX_AMO_1STLD = (1'b1         )? ex_amo_1stld :  1'b0;
assign EX_AMO_2NDST = (1'b1         )? ex_amo_2ndst :  1'b0;
assign EX_AMO_LRSVD = (slot         )? ex_amo_lrsvd :  1'b0;
//assign EX_AMO_SCOND = (slot         )? ex_amo_scond :  1'b0;
assign EX_AMO_SCOND = (1'b1         )? ex_amo_scond :  1'b0;
//
assign ID_FPU_SRC1  = (1'b1             )? id_fpu_src1  : 14'h0;
assign ID_FPU_SRC2  = (1'b1             )? id_fpu_src2  : 14'h0;
assign ID_FPU_SRC3  = (1'b1             )? id_fpu_src3  : 14'h0;
assign ID_FPU_DST1  = (1'b1             )? id_fpu_dst1  : 14'h0;
assign ID_FPU_CMD   = (slot & ~stall_cpu)? id_fpu_cmd   :  8'h0;
assign ID_FPU_RMODE = (1'b1             )? id_fpu_rmode :  3'b0;
//
assign DBG_HALT_ACK   = (slot & ~stall)? dbg_halt_ack   : 1'b0;
assign DBG_RESUME_ACK = (slot & ~stall)? dbg_resume_ack : 1'b0;
//
assign stby_halt_ack    = (slot & ~stall)? stby_halt_ack_0   : 1'b0;
assign stby_resume_ack  = (slot & ~stall)? stby_resume_ack_0 : 1'b0;

//------------------------
// ID Stage State
//------------------------
reg [3:0] state_id_ope;
reg       state_id_ope_upd;
reg [3:0] state_id_ope_nxt;
//
reg [3:0] state_id_seq;
reg       state_id_seq_inc;
reg       state_id_seq_upd;
reg [3:0] state_id_seq_nxt;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        state_id_ope <= `STATE_ID_RESET;
    else if (slot & ~stall & decode_stp)
        state_id_ope <= (~state_id_ope_upd)? state_id_ope
                      : (fetch_start_by_cond & ID_CMP_RSLT)? `STATE_ID_DECODE_TARGET
                      : state_id_ope_nxt;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        state_id_seq <= 4'h0;
    else if (slot & ~stall & decode_stp)
        state_id_seq <= (state_id_ope_upd)? 4'h0
                      : (state_id_seq_inc)? state_id_seq + 4'h1
                      : (state_id_seq_upd)? state_id_seq_nxt
                      : state_id_seq;
end
//
assign INSTR_EXEC = slot & ~stall & decode_stp & pipe_id_enable;
assign INSTR_ADDR = pipe_id_pc;
assign INSTR_CODE = pipe_id_code;

//-----------------------------
// Interrupt and Exception
//-----------------------------
reg int_ack;
reg exp_ack;
reg mret_ack;
reg wfi_waiting;
reg wfi_thru_ack;
//
assign INT_ACK      = slot & ~stall & int_ack;
assign EXP_ACK      = slot & ~stall & exp_ack;
assign MRET_ACK     = slot & ~stall & mret_ack;
assign WFI_THRU_ACK = slot & ~stall & wfi_thru_ack;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        WFI_WAITING <= 1'b0;
    else if (INT_ACK)
        WFI_WAITING <= 1'b0;
    else if (WFI_THRU_ACK)
        WFI_WAITING <= 1'b0;
    else if (wfi_waiting)
        WFI_WAITING <= 1'b1;
end

//------------------------------
// Trigger and ICOUNT Decrement
//------------------------------
reg trg_ack_inst;
reg trg_ack_data;
//
assign TRG_CND_ICOUNT_DEC = (INSTR_EXEC | INT_ACK | EXP_ACK) & DECODE_ACK;
assign TRG_ACK_INST = slot & ~stall & trg_ack_inst;
assign TRG_ACK_DATA = slot & ~stall & trg_ack_data;

//----------------------
// Debug Mode
//----------------------
assign DEBUG_MODE = (state_id_ope == `STATE_ID_DEBUG_MODE);
assign DEBUG_MODE_EMPTY = DEBUG_MODE
                & ~pipe_ex_enable & ~pipe_ma_enable & ~pipe_wb_enable;

//---------------------------------
// Bus Error Exception Request
//---------------------------------
reg  [1:0] buserr_req_align_temp;
reg  [1:0] buserr_req_fault_temp;
wire [1:0] buserr_req_align;
wire [1:0] buserr_req_fault;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        buserr_req_align_temp <= 2'b00;
        buserr_req_fault_temp <= 2'b00;
    end
    else if (exp_ack)
    begin
        buserr_req_align_temp <= 2'b00;
        buserr_req_fault_temp <= 2'b00;
    end
    else
    begin
        buserr_req_align_temp <= (EX_BUSERR_ALIGN[0])? EX_BUSERR_ALIGN
                               : buserr_req_align_temp;
        buserr_req_fault_temp <= (WB_BUSERR_FAULT[0])? WB_BUSERR_FAULT
                               : buserr_req_fault_temp;
    end
end
//
assign buserr_req_align = (EX_BUSERR_ALIGN[0])? EX_BUSERR_ALIGN
                        : buserr_req_align_temp;
assign buserr_req_fault = (WB_BUSERR_FAULT[0])? WB_BUSERR_FAULT
                        : buserr_req_fault_temp;

//------------------------
// ID Stage Control
//------------------------
always @*
begin
    // Default Value
    state_id_ope_upd = 1'b0;
    state_id_ope_nxt = `STATE_ID_RESET;
    state_id_seq_inc = 1'b0;
    state_id_seq_upd = 1'b0;
    state_id_seq_nxt = 4'h0;
    //
    fetch_start         = 1'b0;
    fetch_start_by_cond = 1'b0;
    fetch_stop          = 1'b0;
    //
    decode_ack = 1'b0;
    decode_stp = 1'b0;
    //
    jump_target_reset  = 1'b0;
    jump_target_jal    = 1'b0;
    jump_target_jalr   = 1'b0;
    jump_target_bcc    = 1'b0;
    jump_target_cj     = 1'b0;
    jump_target_cbcc   = 1'b0;
    jump_target_cjr    = 1'b0;
    jump_target_fencei = 1'b0;
    jump_target_exp    = 1'b0;
    jump_target_int    = 1'b0;
    jump_target_mret   = 1'b0;
    jump_target_resume = 1'b0;
    jump_target_stby_resume = 1'b0;
    //
    pipe_id_enable = 1'b0;
    //
    id_dec_src1  = 14'h0000;
    id_dec_src2  = 14'h0000;
    id_alu_src1  = 14'h0000;
    id_alu_src2  = 14'h0000;
    id_alu_src3  = 14'h0000;
    id_alu_dst1  = 14'h0000;
    id_alu_dst2  = 14'h0000;
    id_alu_func  =  5'b00000;
    id_load_dst  = 14'h0000;
    id_alu_imm   = 32'h00000000;
    id_cmp_func  =  3'b000;
    id_alu_shamt =  5'b00000;
    id_mul_func  =  3'b000;
    id_div_func  =  3'b000;
    id_div_exec  =  1'b0;
    id_div_chek  =  1'b0;
    ID_DIV_STOP  =  1'b0;
    //
    id_macmd = 5'b00000;
    id_stsrc = 14'h0;
    id_amo_1stld = 1'b0;
    id_amo_2ndst = 1'b0;
    id_amo_lrsvd = 1'b0;
    id_amo_scond = 1'b0;
    //
    MTVAL     = 32'h00000000;
    MEPC_SAVE = 32'h00000000;
    MCAUSE    = 32'h00000000;
    int_ack   = 1'b0;
    exp_ack   = 1'b0;
    mret_ack  = 1'b0;
    wfi_waiting  = 1'b0;
    wfi_thru_ack = 1'b0;
    trg_ack_inst = 1'b0;
    trg_ack_data = 1'b0;
    //
    dbg_halt_ack   = 1'b0;
    dbg_resume_ack = 1'b0;
    DBG_DPC_SAVE   = 32'h00000000;
    DBG_CAUSE      = 3'b000;
    //
    id_fpu_src1  = 14'h0000;
    id_fpu_src2  = 14'h0000;
    id_fpu_src3  = 14'h0000;
    id_fpu_dst1  = 14'h0000;
    id_fpu_cmd   = 8'h00;
    id_fpu_rmode = 3'b000;
    //
    stby_halt_ack_0   = 1'b0;
    stby_resume_ack_0 = 1'b0;
    //
    // Switch State
    casez (state_id_ope) // FF
        //***************************************************
        // STATE_ID_RESET
        //***************************************************
        `STATE_ID_RESET:
        begin
            casez (state_id_seq) // FF
                4'h0: begin
                          if (DBG_HALT_RESET) // FF
                          begin
                              dbg_halt_ack   = 1'b1;
                              DBG_DPC_SAVE   = RESET_VECTOR; // FIXED
                              DBG_CAUSE      = `DBG_CAUSE_RESETHALT;
                              state_id_ope_nxt = `STATE_ID_DEBUG_MODE;
                              state_id_ope_upd = 1'b1;
                              decode_stp   = 1'b1;
                          end
                          else
                          begin                          
                              state_id_seq_inc = 1'b1;
                              decode_stp = 1'b1;
                          end
                      end
                4'h1: begin
                          fetch_start = 1'b1;
                          jump_target_reset = 1'b1;
                          state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                          state_id_ope_upd = 1'b1; //FETCH_ACK;
                          decode_stp   = 1'b1; //FETCH_ACK;           
                          decode_ack   = 1'b0; //FETCH_ACK;
                      end
                default : 
                      begin
                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                          state_id_ope_upd = 1'b1;
                          decode_stp = 1'b1;
                      end
            endcase
        end
        //***************************************************
        // STATE_ID_DEBUG_MODE
        //***************************************************
        `STATE_ID_DEBUG_MODE:
        begin
            if (DBG_RESUME_REQ) // FF
            begin
                dbg_resume_ack = 1'b1;
                //
                fetch_start = 1'b1;
                jump_target_resume = 1'b1;
                state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                state_id_ope_upd = 1'b1;
                decode_stp   = 1'b1;
                decode_ack   = 1'b1;
            end
        end
        //***************************************************
        // STATE_ID_STBY_MODE
        //***************************************************
        `STATE_ID_STBY_MODE: 
        begin
            if (stby_resume_req)
            begin
                stby_resume_ack_0 = 1'b1;
                //
                fetch_start = 1'b1;
                jump_target_stby_resume = 1'b1;
                state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                state_id_ope_upd = 1'b1;
                decode_stp   = 1'b1;
                decode_ack   = 1'b1;
            end
        end
        //***************************************************
        // STATE_ID_DECODE
        //***************************************************
        `STATE_ID_DECODE: // `STATE_ID_DECODE_NORMAL + `STATE_ID_DECODE_TARGET
        begin
            if (decode_req) // FF
            begin
                //-------------------------------------------------
                // Set enable_id so far
                //-------------------------------------------------
                pipe_id_enable = 1'b1; //~stall; //1'b1; // LOOP
                //-------------------------------------------------
                // Skip until Jump Target (Skip Delayed Branch Slot)
                //-------------------------------------------------
                if ((state_id_ope == `STATE_ID_DECODE_TARGET) & (~DECODE_JUMP)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1;
                    decode_stp   = 1'b1;                
                    decode_ack   = 1'b1;                
                end
                //-------------------------------------------------
                // If Debug HALT requested, Goto Debug Mode
                //-------------------------------------------------
                else if (DBG_HALT_REQ & (state_id_seq == 4'h0)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    dbg_halt_ack   = 1'b1;
                    DBG_DPC_SAVE   = pipe_id_pc; // FF
                    DBG_CAUSE      = `DBG_CAUSE_HALTREQ;
                    state_id_ope_nxt = `STATE_ID_DEBUG_MODE;
                    state_id_ope_upd = 1'b1;
                    decode_stp   = 1'b1;                                
                end
                //-------------------------------------------------
                // STBY Request
                //-------------------------------------------------
                else if (stby_halt_req & (state_id_seq == 4'h0))
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    //
                    if (~pipe_ex_enable & ~pipe_ma_enable & ~pipe_wb_enable)
                    begin
                        stby_halt_ack_0 = 1'b1;
                        state_id_ope_nxt = `STATE_ID_STBY_MODE;
                        state_id_ope_upd = 1'b1;
                        decode_stp   = 1'b1;
                    end
                end
                //-------------------------------------------------
                // Interrupt, WFI waiting for
                //-------------------------------------------------
                else if (WFI_WAITING) // FF
                begin
                    if (INT_REQ) // Interrupt (MIE=1) to wakeup // FF
                    begin
                        pipe_id_enable = 1'b0; // disabled stage
                        fetch_start = 1'b1;
                        jump_target_int = 1'b1;
                        state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                        state_id_ope_upd = 1'b1; //FETCH_ACK;
                        decode_stp   = 1'b1; //FETCH_ACK;          
                        decode_ack   = 1'b1; //FETCH_ACK;
                        //
                        MTVAL     = 32'h00000000;
                        // Return to next address (WFI is 4byte instruction)
                        MEPC_SAVE = pipe_id_pc + 32'h00000004; // FF
                        int_ack   = 1'b1; //FETCH_ACK;                    
                    end
                    else if (WFI_THRU_REQ) // Interrupt Edge (MIE=0) to pass through // FF
                    begin
                        state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                        state_id_ope_upd = 1'b1;
                        decode_stp   = 1'b1;                
                        decode_ack   = 1'b1;
                        wfi_thru_ack = 1'b1;                    
                    end
                end
                //-------------------------------------------------
                // Interrupt
                //-------------------------------------------------
                else if (INT_REQ & (state_id_seq == 4'h0)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    fetch_start = 1'b1;
                    jump_target_int = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = 32'h00000000;
                    // Return to current address.
                    MEPC_SAVE = pipe_id_pc; // FF
                    int_ack   = 1'b1; //FETCH_ACK;
                end
                //-----------------------------------------------------
                // Trigger by Instruction Fetch or ICOUNT
                //-----------------------------------------------------
                else if (TRG_REQ_INST[0] & (state_id_seq == 4'h0)) // FF
                begin
                    if (TRG_REQ_INST[1] == 1'b0) // Break Exception // FF
                    begin
                        pipe_id_enable = 1'b0; // disabled stage
                        fetch_start = 1'b1;
                        jump_target_exp = 1'b1;
                        state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                        state_id_ope_upd = 1'b1; //FETCH_ACK;
                        decode_stp   = 1'b1; //FETCH_ACK;          
                        decode_ack   = 1'b1; //FETCH_ACK;
                        //
                        MTVAL     = pipe_id_pc; // FF
                        MEPC_SAVE = pipe_id_pc; // FF
                        MCAUSE    = `MCAUSE_BREAK_POINT;
                        exp_ack   = 1'b1; //FETCH_ACK;
                        trg_ack_inst = 1'b1;                                     
                    end
                    else // Goto Debug Mode
                    begin
                        pipe_id_enable = 1'b0; // disabled stage
                        dbg_halt_ack   = 1'b1;
                        DBG_DPC_SAVE   = pipe_id_pc; // FF
                        DBG_CAUSE      = `DBG_CAUSE_HALTREQ;
                        state_id_ope_nxt = `STATE_ID_DEBUG_MODE;
                        state_id_ope_upd = 1'b1;
                        decode_stp   = 1'b1;
                        trg_ack_inst = 1'b1;                 
                    end                
                end
                //-----------------------------------------------------
                // Instruction Fetch Fault
                //-----------------------------------------------------
                else if (DECODE_BERR & (state_id_seq == 4'h0)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    fetch_start = 1'b1;
                    jump_target_exp = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = pipe_id_pc; // FF
                    MEPC_SAVE = pipe_id_pc; // FF
                    MCAUSE    = `MCAUSE_INSTR_ACCESS_FAULT;
                    exp_ack   = 1'b1; //FETCH_ACK;                
                end
                //-----------------------------------------------------
                // RV32C : Illegal Instruction
                //-----------------------------------------------------
                else if (pipe_id_code[15:0] == 16'b000_0_00_000_00_000_00) // FF
                begin
                    fetch_start = 1'b1;
                    jump_target_exp = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = 32'h00000000;
                    MEPC_SAVE = pipe_id_pc; // FF
                    MCAUSE    = `MCAUSE_ILLEGAL_INSTRUCTION;
                    exp_ack   = 1'b1; //FETCH_ACK;
                end
                //-----------------------------------------------------
                // RV32I : ECALL : Environment Call
                //-----------------------------------------------------
                else if (pipe_id_code[31:0] == 32'b0000000_00000_00000_000_00000_1110011) // FF
                begin
                    fetch_start = 1'b1;
                    jump_target_exp = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = 32'h00000000;
                    MEPC_SAVE = pipe_id_pc; // FF
                    MCAUSE    = `MCAUSE_ENVIRONMENT_CALL;
                    exp_ack   = 1'b1; //FETCH_ACK;
                end                        
                //-----------------------------------------------------
                // RV32I : EBREAK  : Environment Break
                // RV32C : CEBREAK : Environment Break
                //-----------------------------------------------------
                else if ((pipe_id_code[31:0] == 32'b0000000_00001_00000_000_00000_1110011)
                        |(pipe_id_code[15:0] == 16'b100_1_00_000_00_000_10)) // FF
                begin
                    if (DBG_HALT_EBREAK)
                    begin
                        dbg_halt_ack   = 1'b1;
                        DBG_DPC_SAVE   = pipe_id_pc; // FF
                        DBG_CAUSE      = `DBG_CAUSE_EBRREK;
                        state_id_ope_nxt = `STATE_ID_DEBUG_MODE;
                        state_id_ope_upd = 1'b1;
                        decode_stp   = 1'b1;                                                            
                    end
                    else
                    begin                            
                        fetch_start = 1'b1;
                        jump_target_exp = 1'b1;
                        state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                        state_id_ope_upd = 1'b1; //FETCH_ACK;
                        decode_stp   = 1'b1; //FETCH_ACK;          
                        decode_ack   = 1'b1; //FETCH_ACK;
                        //
                        MTVAL     = pipe_id_pc; // FF
                        MEPC_SAVE = pipe_id_pc; // FF
                        MCAUSE    = `MCAUSE_BREAK_POINT;
                        exp_ack   = 1'b1; //FETCH_ACK;
                    end
                end
                //-----------------------------------------------------
                // Trigger by Data Access
                //-----------------------------------------------------
                else if (TRG_REQ_DATA[0] & (state_id_seq == 4'h0)) // FF
                begin
                    if (TRG_REQ_DATA[1] == 1'b0) // Break Exception // FF
                    begin
                        pipe_id_enable = 1'b0; // disabled stage
                        fetch_start = 1'b1;
                        jump_target_exp = 1'b1;
                        state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                        state_id_ope_upd = 1'b1; //FETCH_ACK;
                        decode_stp   = 1'b1; //FETCH_ACK;          
                        decode_ack   = 1'b1; //FETCH_ACK;
                        //
                        MTVAL     = pipe_id_pc; // FF
                        MEPC_SAVE = pipe_id_pc; // FF
                        MCAUSE    = `MCAUSE_BREAK_POINT;
                        exp_ack   = 1'b1; //FETCH_ACK;
                        trg_ack_data = 1'b1;                                     
                    end
                    else // Goto Debug Mode
                    begin
                        pipe_id_enable = 1'b0; // disabled stage
                        dbg_halt_ack   = 1'b1;
                        DBG_DPC_SAVE   = pipe_id_pc; // FF
                        DBG_CAUSE      = `DBG_CAUSE_HALTREQ;
                        state_id_ope_nxt = `STATE_ID_DEBUG_MODE;
                        state_id_ope_upd = 1'b1;
                        decode_stp   = 1'b1;
                        trg_ack_data = 1'b1;                 
                    end                
                end
                //-----------------------------------------------------
                // Data Access Misaligned
                //-----------------------------------------------------
                else if (buserr_req_align[0] & (state_id_seq == 4'h0)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    fetch_start = 1'b1;
                    jump_target_exp = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = EX_BUSERR_ADDR; // FF
                    MEPC_SAVE = pipe_ex_pc; // PC Address in EX Stage (load/store itself) // FF
                    MCAUSE    = (buserr_req_align[1])? // FF
                       `MCAUSE_ST_AMO_ADDR_MISALIGN :
                       `MCAUSE_LD_ADDR_MISALIGN;
                    exp_ack   = 1'b1; //FETCH_ACK;                
                end
                //-----------------------------------------------------
                // Data Access Fault
                //-----------------------------------------------------
                else if (buserr_req_fault[0] & (state_id_seq == 4'h0)) // FF
                begin
                    pipe_id_enable = 1'b0; // disabled stage
                    fetch_start = 1'b1;
                    jump_target_exp = 1'b1;
                    state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                    state_id_ope_upd = 1'b1; //FETCH_ACK;
                    decode_stp   = 1'b1; //FETCH_ACK;          
                    decode_ack   = 1'b1; //FETCH_ACK;
                    //
                    MTVAL     = EX_BUSERR_ADDR; // FF
                    MEPC_SAVE = pipe_id_pc;     // FF
                    MCAUSE    = (buserr_req_fault[1])? // FF 
                        `MCAUSE_ST_AMO_ACCESS_FAULT :
                        `MCAUSE_LD_ACCESS_FAULT;
                    exp_ack   = 1'b1; //FETCH_ACK;                
                end
                //-------------------------------------------------
                // Instruction Decode
                //-------------------------------------------------
                else
                begin
                    casez(pipe_id_code) // FF
                        //=======================================================================
                        // RV32I
                        //=======================================================================
                        //
                        // RV32I LUI : Load Upper Immediate
                        //
                        32'b???????_?????_?????_???_?????_0110111:
                        begin
                            id_alu_src1 = `ALU_GPR; // Zero
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_UU(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end                        
                        //
                        // RV32I AUIPC : Add Upper Immediate to PC
                        //
                        32'b???????_?????_?????_???_?????_0010111:
                        begin
                            id_alu_src1 = `ALU_PC; 
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_UU(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end                        
                        //
                        // RV32I JAL : Jump and Link
                        //
                        32'b???????_?????_?????_???_?????_1101111:
                        begin
                            id_alu_src1 = `ALU_PC; 
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = 32'h00000004;
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            fetch_start = 1'b1;
                            jump_target_jal = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;           
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32I JALR: Jump and Link Register
                        //
                        32'b???????_?????_?????_000_?????_1100111:
                        begin
                            id_alu_src1 = `ALU_PC; 
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = 32'h00000004;
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            fetch_start = 1'b1;
                            id_dec_src1 = `ALU_GPR | {9'h0, pipe_id_code[19: 15]}; // FF
                            jump_target_jalr = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;          
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32I BEQ/BNE/BLT/BGE/BLTU/BGEU: Conditional Branch
                        //
                        32'b???????_?????_?????_000_?????_1100011,
                        32'b???????_?????_?????_001_?????_1100011,
                        32'b???????_?????_?????_100_?????_1100011,
                        32'b???????_?????_?????_101_?????_1100011,
                        32'b???????_?????_?????_110_?????_1100011,
                        32'b???????_?????_?????_111_?????_1100011:
                        begin
                            id_dec_src1 = `ALU_GPR | {9'h0, pipe_id_code[19: 15]}; // FF
                            id_dec_src2 = `ALU_GPR | {9'h0, pipe_id_code[24: 20]}; // FF
                            id_cmp_func = pipe_id_code[14:12]; // FF
                            fetch_start_by_cond = 1'b1;
                            jump_target_bcc = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32I LB/LH/LW/LHB/LWU : Load Data
                        //
                        32'b???????_?????_?????_000_?????_0000011,
                        32'b???????_?????_?????_001_?????_0000011,
                        32'b???????_?????_?????_010_?????_0000011,
                        32'b???????_?????_?????_100_?????_0000011,
                        32'b???????_?????_?????_101_?????_0000011:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_IS(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = {2'b10, pipe_id_code[14:12]}; // FF
                            id_load_dst = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end                        
                        //
                        // RV32I SB/SH/SW : Store Data
                        //
                        32'b???????_?????_?????_000_?????_0100011,
                        32'b???????_?????_?????_001_?????_0100011,
                        32'b???????_?????_?????_010_?????_0100011:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_SS(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = {2'b11, pipe_id_code[14:12]}; // FF
                            id_stsrc    = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32I ADDI/SLTI/SLTIU/XORI/ORI/ANDI : ALU R-Imm
                        //
                        32'b???????_?????_?????_000_?????_0010011,
                        32'b???????_?????_?????_010_?????_0010011,
                        32'b???????_?????_?????_011_?????_0010011,
                        32'b???????_?????_?????_100_?????_0010011,
                        32'b???????_?????_?????_110_?????_0010011,
                        32'b???????_?????_?????_111_?????_0010011:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_IS(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = {2'b0, pipe_id_code[14:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32I SLLI/SRLI/SRAI : Shift Immediate
                        //
                        32'b0000000_?????_?????_001_?????_0010011,
                        32'b0000000_?????_?????_101_?????_0010011,
                        32'b0100000_?????_?????_101_?????_0010011:
                        begin
                            id_alu_src1  = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_shamt = pipe_id_code[24:20]; // FF
                            id_alu_dst1  = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func  = {1'b1, pipe_id_code[30], pipe_id_code[14:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32I : ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND : ALU R-R
                        //
                        32'b0000000_?????_?????_???_?????_0110011,
                        32'b0100000_?????_?????_000_?????_0110011,
                        32'b0100000_?????_?????_101_?????_0110011:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = {1'b0, pipe_id_code[30], pipe_id_code[14:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32I : FENCE (NOP)
                        //
                        32'b???????_?????_?????_000_?????_0001111:
                        begin
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //=======================================================================
                        // RV32M Multiplication and Division
                        //=======================================================================
                        //
                        // RV32M : MUL/MULH/MULHU/MULHSU : Multiplication
                        //
                        32'b0000001_?????_?????_000_?????_0110011,
                        32'b0000001_?????_?????_001_?????_0110011,
                        32'b0000001_?????_?????_010_?????_0110011,
                        32'b0000001_?????_?????_011_?????_0110011:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_mul_func = {1'b1, pipe_id_code[13:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32M : DIV/DIVU/REM/REMU : Division
                        //
                        32'b0000001_?????_?????_100_?????_0110011,
                        32'b0000001_?????_?????_101_?????_0110011,
                        32'b0000001_?????_?????_110_?????_0110011,
                        32'b0000001_?????_?????_111_?????_0110011:
                        begin
                            casez (state_id_seq) // FF
                                4'h0: begin
                                          id_dec_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                          id_dec_src2 = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF
                                          id_div_func = {1'b1, pipe_id_code[13:12]}; // FF
                                          id_div_chek = 1'b1;
                                          id_div_exec =  1'b1;
                                          state_id_seq_inc = 1'b1;
                                          decode_stp   = 1'b1;                
                                      end
                                4'h1: begin
                                          if (EX_DIV_ZERO | EX_DIV_OVER) // if error, finish // FF
                                          begin
                                              ID_DIV_STOP = 1'b1;
                                              id_div_func = {1'b1, pipe_id_code[13:12]}; // FF
                                              id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                              id_alu_src2 = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF
                                              id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                              state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                              state_id_ope_upd = 1'b1;
                                              decode_stp   = 1'b1;                
                                              decode_ack   = 1'b1;                                        
                                          end
                                          else // no error, continue
                                          begin
                                              id_div_func = {1'b1, pipe_id_code[13:12]}; // FF
                                              state_id_seq_inc = 1'b1;
                                              decode_stp   = 1'b1;                
                                          end
                                      end
                                4'h2: begin
                                          id_div_func = {1'b1, pipe_id_code[13:12]}; // FF
                                          if (ID_DIV_BUSY == 1'b0) // finished // FF
                                          begin
                                              id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                              state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                              state_id_ope_upd = 1'b1;
                                              decode_stp   = 1'b1;                
                                              decode_ack   = 1'b1;                                        
                                          end
                                          else // continued
                                          begin
                                              decode_stp   = 1'b1;                
                                          end
                                      end
                                default:
                                      begin
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                                        
                                      end
                            endcase
                        end
                        //=======================================================================
                        // RV32 Zifencei
                        //=======================================================================
                        //
                        // RV32ZIFENCEI : FENCE.I (Flush Instruction Queue)
                        //
                        32'b???????_?????_?????_001_?????_0001111:
                        begin
                            fetch_start = 1'b1;
                            jump_target_fencei = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;           
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //=======================================================================
                        // RV32 Zicsr (2cyc instruction to reflect CSR change for next exception)
                        //=======================================================================
                        //
                        // RV32ZICSR : CSRRW (CSR Read/Write with Swap)
                        //
                        32'b???????_?????_?????_001_?????_1110011:
                        begin
                            casez (state_id_seq) // FF
                                4'h0: begin
                                          id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                          id_alu_src2 = (pipe_id_code[11:7] != 5'b0)?  
                                                        `ALU_CSR | {2'b0, pipe_id_code[31:20]} // FF
                                                       : 14'h0000;
                                          id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          id_alu_dst2 = `ALU_CSR | {2'b0, pipe_id_code[31:20]}; // FF
                                          id_alu_func = `ALUFUNC_SWAP;
                                          state_id_seq_inc = 1'b1;
                                          decode_stp   = 1'b1;                
                                      end                        
                                default: 
                                      begin
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                
                                      end
                            endcase
                        end
                        //
                        // RV32ZICSR : CSRRS/CSRRC (CSR Set/Clear with Swap)
                        //
                        32'b???????_?????_?????_01?_?????_1110011:
                        begin
                            casez (state_id_seq) // FF
                                4'h0: begin
                                          id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                          id_alu_src2 = `ALU_CSR | {2'b0, pipe_id_code[31:20]}; // FF
                                          id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          id_alu_dst2 = (pipe_id_code[19:15] != 5'b0)?  
                                                        `ALU_CSR | {2'b0, pipe_id_code[31:20]} // FF
                                                      : 14'h0000;
                                          id_alu_func = `ALUFUNC_SWPS | pipe_id_code[12]; // FF
                                          state_id_seq_inc = 1'b1;
                                          decode_stp   = 1'b1;                
                                      end                        
                                default: 
                                      begin
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                
                                      end
                            endcase
                        end
                        //
                        // RV32ZICSR : CSRRWI (CSR Read/Write with Swap and Immediate)
                        //
                        32'b???????_?????_?????_101_?????_1110011:
                        begin
                            casez (state_id_seq)
                                4'h0: begin
                                          id_alu_src1 = `ALU_IMM;
                                          id_alu_src2 = (pipe_id_code[11:7] != 5'b0)?   // FF
                                                        `ALU_CSR | {2'b0, pipe_id_code[31:20]} // FF
                                                      : 14'h0000;
                                          id_alu_imm  = IMM_ZCU(pipe_id_code); // FF
                                          id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          id_alu_dst2 = `ALU_CSR | {2'b0, pipe_id_code[31:20]}; // FF
                                          id_alu_func = `ALUFUNC_SWAP;
                                          state_id_seq_inc = 1'b1;
                                          decode_stp   = 1'b1;                
                                      end                        
                                default: 
                                      begin
                                        //id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                
                                      end
                            endcase
                        end
                        //
                        // RV32ZICSR : CSRRSI/CSRRCI (CSR Set/Clear with Swap and Immediate)
                        //
                        32'b???????_?????_?????_11?_?????_1110011:
                        begin
                            casez (state_id_seq)
                                4'h0: begin
                                          id_alu_src1 = `ALU_IMM;
                                          id_alu_src2 = `ALU_CSR | {2'b0, pipe_id_code[31:20]}; // FF
                                          id_alu_imm  = IMM_ZCU(pipe_id_code); // FF
                                          id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          id_alu_dst2 = (pipe_id_code[19:15] != 5'b0)?  
                                                        `ALU_CSR | {2'b0, pipe_id_code[31:20]} // FF
                                                      : 14'h0000;
                                          id_alu_func = `ALUFUNC_SWPS | pipe_id_code[12]; // FF
                                          state_id_seq_inc = 1'b1;
                                          decode_stp   = 1'b1;                
                                      end                        
                                default: 
                                      begin
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                
                                      end
                            endcase
                        end
                        //=======================================================================
                        // RV32 Privileged
                        //=======================================================================
                        //
                        // RV32I : MRET : Trap Return
                        //
                        32'b0011000_00010_00000_000_00000_1110011:
                        begin
                            fetch_start = 1'b1;
                            jump_target_mret = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;          
                            decode_ack   = 1'b1; //FETCH_ACK;
                            //
                            mret_ack   = 1'b1; //FETCH_ACK;                        
                        end
                        //
                        // RV32I : WFI : Wait for Interrupt
                        //
                        32'b0001000_00101_00000_000_00000_1110011:
                        begin
                            wfi_waiting = 1'b1;
                        end                        
                        //=======================================================================
                        // RV32C
                        //=======================================================================
                        //
                        // RV32C : C.ADDI4SPN : Add Imm*4 to Stack Pointer Nondestructive
                        //
                        32'b????????????????_000_1_??_???_??_???_00,
                        32'b????????????????_000_?_1?_???_??_???_00,
                        32'b????????????????_000_?_?1_???_??_???_00,
                        32'b????????????????_000_?_??_1??_??_???_00,
                        32'b????????????????_000_?_??_?1?_??_???_00,
                        32'b????????????????_000_?_??_??1_??_???_00,
                        32'b????????????????_000_?_??_???_1?_???_00,
                        32'b????????????????_000_?_??_???_?1_???_00:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'h2}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CIWU(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C C.LW : Load Data
                        //
                        32'b????????????????_010_?_??_???_??_???_00:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLSU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = `MACMD_LW;
                            id_load_dst = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end                        
                        //
                        // RV32C C.SW : Store Data
                        //
                        32'b????????????????_110_?_??_???_??_???_00:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLSU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = `MACMD_SW;
                            id_stsrc    = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C : C.NOP : No Operation (HINT : imm != 0)
                        //
                        32'b????????????????_000_?_00_000_??_???_01:
                        begin
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C : C.ADDI : Add Immediate (HINT: IMM==0)
                        //
                        32'b????????????????_000_?_??_???_??_???_01:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CIS(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C C.JAL : Jump and Link
                        //
                        32'b????????????????_001_?_??_???_??_???_01:
                        begin
                            id_alu_src1 = `ALU_PC; 
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = 32'h00000002;
                            id_alu_dst1 = `ALU_GPR | {9'h0, 5'b00001}; //x1
                            id_alu_func = `ALUFUNC_ADD;
                            fetch_start = 1'b1;
                            jump_target_cj = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;           
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32C : C.LI Load Immediate (HINT:Rd==0)
                        //
                        32'b????????????????_010_?_??_???_??_???_01:
                        begin
                            id_alu_src1 = `ALU_GPR; // Zero
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CIS(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C : C.ADDI16SP : Add Imm*16 to Stack Pointer
                        //
                        32'b????????????????_011_1_00_010_??_???_01,
                        32'b????????????????_011_?_00_010_1?_???_01,
                        32'b????????????????_011_?_00_010_?1_???_01,
                        32'b????????????????_011_?_00_010_??_1??_01,
                        32'b????????????????_011_?_00_010_??_?1?_01,
                        32'b????????????????_011_?_00_010_??_??1_01:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'h2}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CI16S(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, 5'h2}; // x2
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C : C.LUI : Load Upper Immediate (HINT:Rd==0)
                        //
                        32'b????????????????_011_1_??_???_??_???_01,
                        32'b????????????????_011_?_??_???_1?_???_01,
                        32'b????????????????_011_?_??_???_?1_???_01,
                        32'b????????????????_011_?_??_???_??_1??_01,
                        32'b????????????????_011_?_??_???_??_?1?_01,
                        32'b????????????????_011_?_??_???_??_??1_01:
                        begin
                            id_alu_src1 = `ALU_GPR; // Zero
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLUI(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C C.SRLI/C.SRAI : Shift Right Immediate
                        //
                        32'b????????????????_100_0_0?_???_??_???_01:
                        begin
                            id_alu_src1  = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_shamt = IMM_CIU5(pipe_id_code); // FF
                            id_alu_dst1  = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_func  = {1'b1, pipe_id_code[10], 3'b101}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;      
                        end
                        //
                        // RV32C C.ANDI : And Immediate
                        //
                        32'b????????????????_100_?_10_???_??_???_01:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CIS(pipe_id_code); // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_func = `ALUFUNC_AND;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C : C.SUB/C.XOR/C.OR/C.AND : ALU R-R
                        //
                        32'b????????????????_100_0_11_???_??_???_01:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_func = (pipe_id_code[6:5] == 2'b00)? `ALUFUNC_SUB // FF
                                        : (pipe_id_code[6:5] == 2'b01)? `ALUFUNC_XOR // FF
                                        : (pipe_id_code[6:5] == 2'b10)? `ALUFUNC_OR // FF
                                        :                               `ALUFUNC_AND; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;
                        end                        
                        //
                        // RV32C : C.J : Unconditional Jump
                        //
                        32'b????????????????_101_?_??_???_??_???_01:
                        begin
                            fetch_start = 1'b1;
                            jump_target_cj = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;                
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32C C.BEQZ/C.BNEZ : Conditional Branch
                        //
                        32'b????????????????_11?_?_??_???_??_???_01:
                        begin
                            id_dec_src1 = `ALU_GPR; // Zero
                            id_dec_src2 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_cmp_func = {2'b00, pipe_id_code[13]}; // FF
                            fetch_start_by_cond = 1'b1;
                            jump_target_cbcc = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C C.SLLI : Shift Left Immediate (HINT:Rd==0)
                        //
                        32'b????????????????_000_0_??_???_??_???_10:
                        begin
                            id_alu_src1  = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_alu_shamt = IMM_CIU5(pipe_id_code); // FF
                            id_alu_dst1  = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_alu_func  = `ALUFUNC_SLLI;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;      
                        end
                        //
                        // RV32C C.LWSP : Load Data using Stack Pointer
                        //
                        32'b????????????????_010_?_1?_???_??_???_10,
                        32'b????????????????_010_?_?1_???_??_???_10,
                        32'b????????????????_010_?_??_1??_??_???_10,
                        32'b????????????????_010_?_??_?1?_??_???_10,
                        32'b????????????????_010_?_??_??1_??_???_10:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'b00010}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLWSPU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = `MACMD_LW;
                            id_load_dst = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32C C.JR : Jump Register
                        //
                        32'b????????????????_100_0_1?_???_00_000_10,
                        32'b????????????????_100_0_?1_???_00_000_10,
                        32'b????????????????_100_0_??_1??_00_000_10,
                        32'b????????????????_100_0_??_?1?_00_000_10,
                        32'b????????????????_100_0_??_??1_00_000_10:
                        begin
                            fetch_start = 1'b1;
                            id_dec_src1 = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            jump_target_cjr = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;          
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32C : C.MV : Move R-R (HINT:Rd==0)
                        //
                        32'b????????????????_100_0_??_???_1?_???_10,
                        32'b????????????????_100_0_??_???_?1_???_10,
                        32'b????????????????_100_0_??_???_??_1??_10,
                        32'b????????????????_100_0_??_???_??_?1?_10,
                        32'b????????????????_100_0_??_???_??_??1_10:
                        begin
                            id_alu_src1 = `ALU_GPR; // Zero
                            id_alu_src2 = `ALU_GPR | {9'h0, pipe_id_code[ 6:2]}; // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;
                        end                        
                        //
                        // RV32C C.JALR : Jump and Link Register
                        //
                        32'b????????????????_100_1_1?_???_00_000_10,
                        32'b????????????????_100_1_?1_???_00_000_10,
                        32'b????????????????_100_1_??_1??_00_000_10,
                        32'b????????????????_100_1_??_?1?_00_000_10,
                        32'b????????????????_100_1_??_??1_00_000_10:
                        begin
                            id_alu_src1 = `ALU_PC; 
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = 32'h00000002;
                            id_alu_dst1 = `ALU_GPR | {9'h0, 5'b00001}; // x1
                            id_alu_func = `ALUFUNC_ADD;
                            fetch_start = 1'b1;
                            id_dec_src1 = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            jump_target_cjr = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_TARGET;
                            state_id_ope_upd = 1'b1; //FETCH_ACK;
                            decode_stp   = 1'b1; //FETCH_ACK;          
                            decode_ack   = 1'b1; //FETCH_ACK;
                        end
                        //
                        // RV32C : C.ADD : ALU R-R (HINT:Rd==0)
                        //
                        32'b????????????????_100_1_??_???_1?_???_10,
                        32'b????????????????_100_1_??_???_?1_???_10,
                        32'b????????????????_100_1_??_???_??_1??_10,
                        32'b????????????????_100_1_??_???_??_?1?_10,
                        32'b????????????????_100_1_??_???_??_??1_10:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_alu_src2 = `ALU_GPR | {9'h0, pipe_id_code[ 6:2]}; // FF
                            id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_alu_func = `ALUFUNC_ADD;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;
                        end                        
                        //
                        // RV32C C.SWSP : Store Data using Stack Pointer
                        //
                        32'b????????????????_110_?_??_???_??_???_10:
                        begin
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'b00010}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CSWSPU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = `MACMD_SW;
                            id_stsrc    = `ALU_GPR | {9'h0, pipe_id_code[6:2]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        `ifdef RISCV_ISA_RV32A
                        //=======================================================================
                        // RV32A
                        //=======================================================================
                        //
                        // RV32A AMOSWAP.W/AMOADD.W/AMOAND.W/AMOOR.W/AMOXOR.W
                        //       AMOMAX.W/AMOMAXU.W/AMOMIN.W/AMOMINU.W
                        // The aq and rl are ignored because memory access order is very sequential.
                        // [Pipeline]  FDEMW  (load)
                        //               D
                        //                DEM (store)
                        //
                        32'b00001??_?????_?????_010_?????_0101111,
                        32'b???00??_?????_?????_010_?????_0101111:
                        begin
                            casez (state_id_seq)
                                4'h0: begin
                                          id_alu_src1  = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // addr // FF
                                          id_alu_src2  = `ALU_GPR; // Zero
                                          id_alu_func  = `ALUFUNC_ADD;
                                          id_macmd     = `MACMD_LW;
                                          id_amo_1stld = 1'b1; // To Lock
                                          id_load_dst  = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                          state_id_seq_inc = 1'b1;
                                          decode_stp       = 1'b1;                
                                      end                        
                                4'h1: begin
                                          state_id_seq_inc = 1'b1;
                                          decode_stp       = 1'b1;                
                                      end
                                default:    // busX = busW, busZ = ALU(busX, busY)
                                      begin // busS = busZ, addr = ex_alu_src1
                                          id_alu_src1  = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // addr // FF 
                                          id_alu_src2  = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // rs2 FF
                                          id_alu_func 
                                              = (pipe_id_code[31:27] == 5'b00001)? `ALUFUNC_BUSY
                                              : (pipe_id_code[31:29] == 3'b000  )? `ALUFUNC_ADD
                                              : (pipe_id_code[31:29] == 3'b001  )? `ALUFUNC_XOR
                                              : (pipe_id_code[31:29] == 3'b011  )? `ALUFUNC_AND
                                              : (pipe_id_code[31:29] == 3'b010  )? `ALUFUNC_OR
                                              : (pipe_id_code[31:29] == 3'b100  )? `ALUFUNC_MINS
                                              : (pipe_id_code[31:29] == 3'b101  )? `ALUFUNC_MAXS
                                              : (pipe_id_code[31:29] == 3'b110  )? `ALUFUNC_MINU
                                              : (pipe_id_code[31:29] == 3'b111  )? `ALUFUNC_MAXU
                                              : `ALUFUNC_ADD;
                                          id_amo_2ndst = 1'b1; // ex_busS = ex_busZ
                                          id_macmd     = `MACMD_SW;
                                          state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                          state_id_ope_upd = 1'b1;
                                          decode_stp   = 1'b1;                
                                          decode_ack   = 1'b1;                
                                      end
                            endcase                        
                        end
                        //
                        // RV32A LR.W
                        // [Pipeline] FDEMW (me  )
                        //              DEM (post)
                        32'b00010??_00000_?????_010_?????_0101111:
                        begin
                            id_alu_src1  = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2  = `ALU_GPR; // Zero
                            id_alu_func  = `ALUFUNC_ADD;
                            id_macmd     = `MACMD_LW;
                            id_load_dst  = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_amo_lrsvd = 1'b1;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;
                            decode_ack   = 1'b1;
                        end
                        //
                        // RV32A SC.W
                        // [Pipeline] FDEMx  (pre )
                        //       SC.W  FDEM  (me  )
                        //               DEM (post)
                        32'b00011??_?????_?????_010_?????_0101111:
                        begin // addr = busZ = ALU(busX, busY), Reg[] = busV = scond_dst_data
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_GPR; // Zero
                            id_alu_func = `ALUFUNC_ADD;
                            id_macmd    = `MACMD_SW;
                            id_stsrc    = `ALU_GPR | {9'h0, pipe_id_code[24:20]}; // FF                            
                            id_amo_scond = 1'b1;
                            id_alu_dst2 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        `endif
                        //=======================================================================
                        // RV32F / RF32FC
                        //=======================================================================
                        `ifdef RISCV_ISA_RV32F
                        //
                        // RV32F FMV.W.X (FRn<--XRn)
                        //
                        32'b1111000_00000_?????_000_?????_1010011:
                        begin
                            id_fpu_cmd  = {pipe_id_code[31:27], pipe_id_code[14:12]};
                            id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_GPR; // Zero
                            id_alu_func = `ALUFUNC_ADD;
                            id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FMV.X.W  (XRn<--FRn)
                        // RV32F FCLASS.S (XRn<--FRn)
                        //
                        32'b1110000_00000_?????_000_?????_1010011,
                        32'b1110000_00000_?????_001_?????_1010011:
                        begin
                            // Destination data output is from F/F to meeet STA;
                            // that is EX_FPU_SRCDATA is clocked output.
                            casez (state_id_seq)
                                4'h0:
                                begin
                                    id_fpu_cmd   = {pipe_id_code[31:27], pipe_id_code[14:12]};
                                    id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                  //id_alu_func = `ALUFUNC_ADD;
                                  //id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                  state_id_seq_inc = 1'b1;
                                  decode_stp   = 1'b1;                
                                end
                                //
                                4'h1:
                                begin
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                    id_alu_func = `ALUFUNC_ADD;
                                    id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                                //
                                default:
                                begin
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                            endcase
                        end
                        //
                        // RV32F FADD.S/FSUB.S/FMUL.S/FDIV.S
                        //
                        32'b0000000_?????_?????_???_?????_1010011,
                        32'b0000100_?????_?????_???_?????_1010011,
                        32'b0001000_?????_?????_???_?????_1010011,
                        32'b0001100_?????_?????_???_?????_1010011:
                        begin
                            id_fpu_cmd   = {pipe_id_code[31:27], pipe_id_code[4:2]};
                            id_fpu_rmode = pipe_id_code[14:12];
                            id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_fpu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FMADD.S/FMSUB.S/FNMSUB.S/FNMADD.S
                        //
                        32'b?????00_?????_?????_???_?????_1000011,
                        32'b?????00_?????_?????_???_?????_1000111,
                        32'b?????00_?????_?????_???_?????_1001011,
                        32'b?????00_?????_?????_???_?????_1001111:
                        begin
                            id_fpu_cmd   = {5'b11111, pipe_id_code[4:2]};
                            id_fpu_rmode = pipe_id_code[14:12];
                            id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_fpu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_fpu_src3 = `ALU_FPR | {9'h0, pipe_id_code[31:27]}; // FF
                            id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_src3 = `ALU_FPR | {9'h0, pipe_id_code[31:27]}; // FF
                            id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FSQRT.S
                        //
                        32'b0101100_00000_?????_???_?????_1010011:
                        begin
                            id_fpu_cmd   = {pipe_id_code[31:27], pipe_id_code[4:2]};
                            id_fpu_rmode = pipe_id_code[14:12];
                            id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FLW : Load Floating Point Data
                        //
                        32'b???????_?????_?????_010_?????_0000111:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FLW;
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_IS(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_load_dst = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_macmd    = {2'b10, pipe_id_code[14:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FSW : Store Floating Point Data
                        //
                        32'b???????_?????_?????_010_?????_0100111:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FSW;
                            id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_SS(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_stsrc    = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_macmd    = {2'b11, pipe_id_code[14:12]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FMIN.S/FMAX.S
                        // RV32F FSGNJ.S/FSGNJN.S/FSGNJX.S
                        //
                        32'b0010100_?????_?????_00?_?????_1010011,
                        32'b0010000_?????_?????_000_?????_1010011,
                        32'b0010000_?????_?????_001_?????_1010011,
                        32'b0010000_?????_?????_010_?????_1010011:
                        begin
                            id_fpu_cmd  = {pipe_id_code[31:27], pipe_id_code[14:12]};
                            id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_fpu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                            id_alu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                            id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32F FCVT.W.S/FCVT.WU.S   (XRn<--FRn)
                        //
                        32'b1100000_0000?_?????_???_?????_1010011:
                        begin
                            // Destination data output is from F/F to meeet STA;
                            // that is EX_FPU_SRCDATA is clocked output.
                            casez (state_id_seq)
                                4'h0:
                                begin
                                    id_fpu_cmd   = {pipe_id_code[31:27], pipe_id_code[22:20]};
                                    id_fpu_rmode = pipe_id_code[14:12];
                                    id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    state_id_seq_inc = 1'b1;
                                    decode_stp       = 1'b1;                
                                end
                                //
                                4'h1:
                                begin
                                    id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                  //id_alu_func = `ALUFUNC_ADD;
                                  //id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_seq_inc = 1'b1;
                                    decode_stp       = 1'b1;                
                                end
                                //
                                4'h2:
                                begin
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                    id_alu_func = `ALUFUNC_ADD;
                                    id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                                //
                                default:
                                begin
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                            endcase                            
                        end
                        //
                        // RV32F FCVT.S.W/FCVT.S.WU   (FRn<--XRn)
                        //
                        32'b1101000_0000?_?????_???_?????_1010011:
                        begin
                            casez (state_id_seq)
                                4'h0:
                                begin
                                    id_fpu_cmd   = {pipe_id_code[31:27], pipe_id_code[22:20]};
                                    id_fpu_rmode = pipe_id_code[14:12];
                                    id_fpu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                    id_alu_func = `ALUFUNC_ADD;
                                    id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_seq_inc = 1'b1;
                                    decode_stp       = 1'b1;                
                                end
                                //
                                4'h1:
                                begin
                                    id_fpu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_fpu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    id_alu_src1 = `ALU_GPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_GPR; // Zero
                                    id_alu_func = `ALUFUNC_ADD;
                                    id_alu_dst1 = `ALU_FPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                                //
                                default:
                                begin
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                            endcase                            
                        end
                        //
                        // RV32F FCMP.S(FEQ.S/FLT.S/FLE.S)
                        //
                        32'b1010000_?????_?????_010_?????_1010011,
                        32'b1010000_?????_?????_001_?????_1010011,
                        32'b1010000_?????_?????_000_?????_1010011:
                        begin
                            // Destination data output is from F/F to meeet STA;
                            // that is EX_FPU_SRCDATA is clocked output.
                            casez (state_id_seq)
                                4'h0:
                                begin
                                    id_fpu_cmd  = {pipe_id_code[31:27], pipe_id_code[14:12]};
                                    id_fpu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_fpu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                                  //id_alu_func = `ALUFUNC_BUSX;
                                  //id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_seq_inc = 1'b1;
                                    decode_stp       = 1'b1;                
                                end
                                //
                                4'h1:
                                begin
                                    id_alu_src1 = `ALU_FPR | {9'h0, pipe_id_code[19:15]}; // FF
                                    id_alu_src2 = `ALU_FPR | {9'h0, pipe_id_code[24:20]}; // FF
                                    id_alu_func = `ALUFUNC_BUSX;
                                    id_alu_dst1 = `ALU_GPR | {9'h0, pipe_id_code[11: 7]}; // FF
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                                //
                                default:
                                begin
                                    state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                                    state_id_ope_upd = 1'b1;
                                    decode_stp   = 1'b1;                
                                    decode_ack   = 1'b1;                
                                end
                            endcase
                        end
                        //
                        // RV32FC C.FLW : Load Floating Data
                        //
                        32'b????????????????_011_?_??_???_??_???_00:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FLW;
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLSU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_load_dst = `ALU_FPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            id_macmd    = `MACMD_LW;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end                        
                        //
                        // RV32FC C.FLWSP : Load Floating Data using Stack Pointer
                        //
                        32'b????????????????_011_?_??_???_??_???_10:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FLW;
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'b00010}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLWSPU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_load_dst = `ALU_FPR | {9'h0, pipe_id_code[11:7]}; // FF
                            id_macmd    = `MACMD_LW;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32FC C.FSW : Store Floating Point Data
                        //
                        32'b????????????????_111_?_??_???_??_???_00:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FSW;
                            id_fpu_src1 = `ALU_FPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            id_alu_src1 = `ALU_GPR | {9'h0, 2'b01, pipe_id_code[9:7]}; // FF
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CLSU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_stsrc    = `ALU_FPR | {9'h0, 2'b01, pipe_id_code[4:2]}; // FF
                            id_macmd    = `MACMD_SW;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        //
                        // RV32FC C.FSWSP : Store Floating Data using Stack Pointer
                        //
                        32'b????????????????_111_?_??_???_??_???_10:
                        begin
                            id_fpu_cmd  = `FPU32_CMD_FSW;
                            id_fpu_src1 = `ALU_GPR | {9'h0, 5'b00010}; // x2
                            id_alu_src1 = `ALU_GPR | {9'h0, 5'b00010}; // x2
                            id_alu_src2 = `ALU_IMM;
                            id_alu_imm  = IMM_CSWSPU(pipe_id_code); // FF
                            id_alu_func = `ALUFUNC_ADD;
                            id_stsrc    = `ALU_FPR | {9'h0, pipe_id_code[6:2]}; // FF
                            id_macmd    = `MACMD_SW;
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                        `endif // RISCV_ISA_RV32F
                        //=======================================================================
                        // Default : NOP (Hint)
                        //=======================================================================
                        default:
                        begin
                            state_id_ope_nxt = `STATE_ID_DECODE_NORMAL;
                            state_id_ope_upd = 1'b1;
                            decode_stp   = 1'b1;                
                            decode_ack   = 1'b1;                
                        end
                    endcase
                end
            end
        end
        //
        // Default
        //
        default:
        begin
        
        end        
    endcase
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
