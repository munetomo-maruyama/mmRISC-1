//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_datapath.v
// Description : Datapath of CPU
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.12 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_DATAPATH
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    output reg         BUSM_M_REQ,       // M Stage Memory Access
    input  wire        BUSM_M_ACK,       // M Stage Memory Access
    output reg         BUSM_M_SEQ,       // M Stage Memory Access
    output reg         BUSM_M_CONT,      // M Stage Memory Access
    output reg  [ 2:0] BUSM_M_BURST,     // M Stage Memory Access
    output reg         BUSM_M_LOCK,      // M Stage Memory Access
    output reg  [ 3:0] BUSM_M_PROT,      // M Stage Memory Access
    output reg         BUSM_M_WRITE,     // M Stage Memory Access
    output reg  [ 1:0] BUSM_M_SIZE,      // M Stage Memory Access
    output reg  [31:0] BUSM_M_ADDR,      // M Stage Memory Access
    output reg  [31:0] BUSM_M_WDATA,     // M Stage Memory Access
    input  wire        BUSM_M_LAST,      // M Stage Memory Access
    input  wire [31:0] BUSM_M_RDATA,     // M Stage Memory Access
    input  wire [ 3:0] BUSM_M_DONE,      // M Stage Memory Access
    input  wire [31:0] BUSM_M_RDATA_RAW, // M Stage Memory Access
    input  wire [ 3:0] BUSM_M_DONE_RAW,  // M Stage Memory Access
    //
    `ifdef RISCV_ISA_RV32A
    input  wire        BUSM_S_REQ,   // AHB Monitor for LR/SC
    input  wire        BUSM_S_WRITE, // AHB Monitor for LR/SC
    input  wire [31:0] BUSM_S_ADDR,  // AHB Monitor for LR/SC
    `endif
    //
    input  wire       PIPE_ID_ENABLE,   // Pipeline ID Stage
    input  wire       PIPE_EX_ENABLE,   // Pipeline EX Stage
    input  wire       PIPE_MA_ENABLE,   // Pipeline MA Stage
    input  wire       PIPE_WB_ENABLE,   // Pipeline WB Stage
    //
    input  wire [13:0] ID_DEC_SRC1,  // Decode Source 1 in ID Stage
    input  wire [13:0] ID_DEC_SRC2,  // Decode Source 2 in ID Stage
    input  wire [13:0] ID_ALU_SRC2,  // ALU Source 2 in ID Stage (CSR)
    input  wire [13:0] EX_ALU_SRC1,  // ALU Source 1 in EX Stage
    input  wire [13:0] EX_ALU_SRC2,  // ALU Source 2 in EX Stage
    input  wire [31:0] EX_ALU_IMM,   // ALU Immediate Data in EX Stage
    input  wire [13:0] EX_ALU_DST1,  // ALU Destination 1 in EX Stage
    input  wire [13:0] EX_ALU_DST2,  // ALU Destination 2 in EX Stage
    input  wire [ 4:0] EX_ALU_FUNC,  // ALU Function in EX Stage
    input  wire [ 4:0] EX_ALU_SHAMT, // ALU Shift Amount in EX Stage
    input  wire [31:0] EX_PC,        // Current PC in EX Stage
    input  wire [ 4:0] ID_MACMD,     // Memory Access Command in ID Stage
    input  wire [ 4:0] EX_MACMD,     // Memory Access Command in EX Stage
    input  wire [ 4:0] WB_MACMD,     // Memory Access Command in WB State
    input  wire [13:0] EX_STSRC,     // Memory Store Data Source in EX Stage
    input  wire [13:0] WB_LOAD_DST,  // Memory Load Destination in WB Stage
    output wire        EX_MARDY,     // Memory Address Ready in EX Stage 
    output wire        MA_MDRDY,     // Memory Data Ready in MA Stage
    output wire [31:0] ID_BUSA,      // busA in ID Stage
    output wire [31:0] ID_BUSB,      // busB in ID Stage
    input  wire [ 2:0] ID_CMP_FUNC,  // Comparator Function in ID Stage
    output reg         ID_CMP_RSLT,  // Comparator Result in ID Stage
    input  wire [ 2:0] EX_MUL_FUNC,  // MultiPlier Function in EX Stage
    input  wire [ 2:0] ID_DIV_FUNC,  // Divider Function in ID Stage
    input  wire [ 2:0] EX_DIV_FUNC,  // Divider Function in EX Stage
    input  wire        ID_DIV_EXEC,  // Divider Invoke Execution in ID Stage
    input  wire        ID_DIV_STOP,  // Divider Abort
    output wire        ID_DIV_BUSY,  // Divider in busy
    input  wire        ID_DIV_CHEK,  // DIvision Illegal Check in ID Stage
    output reg         EX_DIV_ZERO,  // Division by Zero in EX Stage
    output reg         EX_DIV_OVER,  // Division Overflow in EX Stage
    //
    input  wire        EX_AMO_1STLD, // AMO 1st Load Access
    input  wire        EX_AMO_2NDST, // AMO 2nd Store Access
    input  wire        EX_AMO_LRSVD, // AMO Load Reserved
    input  wire        EX_AMO_SCOND, // AMO Store Conditional
    //
    input  wire        EXP_ACK,      // Exception Acknowledge
    input  wire        INT_ACK,      // Interrupt Acknowledge from CPU
    //
    output wire [ 1:0] EX_BUSERR_ALIGN, // Memory Bus Access Error by Misalignment (bit1:R/W, bit0:ERR)
    output wire [ 1:0] WB_BUSERR_FAULT, // Memory Bus Access Error by Bus Fault    (bit1:R/W, bit0:ERR)
    output wire [31:0] EX_BUSERR_ADDR,  // Memory Bus Access Error Address in EX Stage 
    output reg  [31:0] WB_BUSERR_ADDR,  // Memory Bus Access Error Address in WB Stage
    //
    output wire        EX_CSR_REQ,   // CSR Access Request
    output wire        EX_CSR_WRITE, // CSR Write
    output wire [11:0] EX_CSR_ADDR,  // CSR Address
    output wire [31:0] EX_CSR_WDATA, // CSR Write Data
    input  wire [31:0] EX_CSR_RDATA, // CSR Read Data
    //
    input  wire        DBGABS_GPR_REQ,   // Debug Abstract Command Request for GPR
    input  wire        DBGABS_GPR_WRITE, // Debug Abstract Command Write   for GPR
    input  wire [11:0] DBGABS_GPR_ADDR,  // Debug Abstract Command Address for GPR
    input  wire [31:0] DBGABS_GPR_WDATA, // Debug Abstract Command Write Data for GPR
    output reg  [31:0] DBGABS_GPR_RDATA  // Debug Abstract Command Read  Data for GPR
    //
    ,
    input  wire [31:0] EX_FPU_SRCDATA,  // FPU Source Data
    output wire [31:0] EX_FPU_DSTDATA,  // FPU Destinaton Data
    input  wire [31:0] EX_FPU_ST_DATA,  // FPU Memory Store Data in EX Stage
    output wire [31:0] WB_FPU_LD_DATA   // FPU Memory Load Data in WB Stage
);

integer i;

//-----------------
// Internal Bus
//-----------------
wire [31:0] ex_busX; // ALU Input   X
wire [31:0] ex_busY; // ALU Input   Y
wire [31:0] ex_busZ; // ALU Output1 Z
wire [31:0] ex_busV; // ALU Output2 V 
wire [31:0] ex_busS; // Memory Store Source
wire [31:0] id_busA; // Comparator Input A for Conditional Branch
wire [31:0] id_busB; // Comparator Input B for Conditional Branch
wire [31:0] wb_busW; // Memory Load Write Back

//------------------------------------
// Load Reserved Store Conditional
//------------------------------------
wire        scond_success;     // Store Conditional Success
wire [31:0] scond_dst_data;    // Store Conditional Destination Data
`ifdef RISCV_ISA_RV32A
wire        scond_unspecified; // Store Conditional Unspecified Failure
wire        scond_failure;     // Store Conditional Failure
`endif

//-----------------------
// Register Forwarding 
//-----------------------
wire fwd_wb_ex1;
wire fwd_wb_ex2;
wire fwd_wb_id1;
wire fwd_wb_id2;
wire fwd_wb_sts; // store source
wire fwd_ex_id1;
wire fwd_ex_id2;
wire fwd_ex_id3;
wire fwd_ex_id4;
//
assign fwd_wb_ex1 = WB_LOAD_DST[13] & EX_ALU_SRC1[13] & (WB_LOAD_DST[12:0] == EX_ALU_SRC1[12:0]);
assign fwd_wb_ex2 = WB_LOAD_DST[13] & EX_ALU_SRC2[13] & (WB_LOAD_DST[12:0] == EX_ALU_SRC2[12:0]);
assign fwd_wb_sts = WB_LOAD_DST[13] & EX_STSRC   [13] & (WB_LOAD_DST[12:0] == EX_STSRC   [12:0]);
assign fwd_wb_id1 = WB_LOAD_DST[13] & ID_DEC_SRC1[13] & (WB_LOAD_DST[12:0] == ID_DEC_SRC1[12:0]);
assign fwd_wb_id2 = WB_LOAD_DST[13] & ID_DEC_SRC2[13] & (WB_LOAD_DST[12:0] == ID_DEC_SRC2[12:0]);
assign fwd_ex_id1 = EX_ALU_DST1[13] & ID_DEC_SRC1[13] & (EX_ALU_DST1[12:0] == ID_DEC_SRC1[12:0]);
assign fwd_ex_id2 = EX_ALU_DST1[13] & ID_DEC_SRC2[13] & (EX_ALU_DST1[12:0] == ID_DEC_SRC2[12:0]);
assign fwd_ex_id3 = EX_ALU_DST2[13] & ID_DEC_SRC1[13] & (EX_ALU_DST2[12:0] == ID_DEC_SRC1[12:0]);
assign fwd_ex_id4 = EX_ALU_DST2[13] & ID_DEC_SRC2[13] & (EX_ALU_DST2[12:0] == ID_DEC_SRC2[12:0]);

//-----------------------------------
// General Registers (Integer) XRn
//-----------------------------------
reg signed [31:0] regXR[0:31];
//
always @(posedge CLK, posedge RES_CPU)
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        if (RES_CPU)
            regXR[i] <= 32'h00000000;
        else if (i == 0)
            regXR[i] <= 32'h00000000;
        else
        begin
            if (DBGABS_GPR_REQ & DBGABS_GPR_WRITE & (DBGABS_GPR_ADDR[4:0] == i))
                regXR[i] <= DBGABS_GPR_WDATA;
            else if (((EX_ALU_DST1 & `ALU_MSK) == `ALU_GPR) & (EX_ALU_DST1[4:0] == i))
                regXR[i] <= ex_busZ; // Writing Conflict Priority EX > WB
            else if (((EX_ALU_DST2 & `ALU_MSK) == `ALU_GPR) & (EX_ALU_DST2[4:0] == i) & EX_AMO_SCOND) 
                regXR[i] <= ex_busV; // Writing Conflict Priority EX > WB
            else if (((WB_LOAD_DST & `ALU_MSK) == `ALU_GPR) & (WB_LOAD_DST[4:0] == i))
                regXR[i] <= wb_busW; // Writing Conflict Priority EX > WB        
        end
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        DBGABS_GPR_RDATA <= 32'h00000000;
    else if (DBGABS_GPR_REQ & ~DBGABS_GPR_WRITE)
        DBGABS_GPR_RDATA <= regXR[DBGABS_GPR_ADDR[4:0]];
    else
        DBGABS_GPR_RDATA <= 32'h00000000;
end

//-----------------
// ALU
//-----------------
reg [31:0] aluout1;
reg [31:0] aluout2;
reg signed [31:0] sftout;
//
always @*
begin
    casez(EX_ALU_FUNC)
        `ALUFUNC_BUSX : aluout1 = ex_busX;
        `ALUFUNC_BUSY : aluout1 = ex_busY;
        `ALUFUNC_ADD  : aluout1 = ex_busX + ex_busY;
        `ALUFUNC_SUB  : aluout1 = ex_busX - ex_busY;
        `ALUFUNC_SLL  : aluout1 = $unsigned(sftout);
        `ALUFUNC_SLLI : aluout1 = $unsigned(sftout);
        `ALUFUNC_SLT  : aluout1 = (~(ex_busX[31] ^  ex_busY[31]))? ((ex_busX < ex_busY)? 32'h1 : 32'h0)
                                : ( ~ex_busX[31] &  ex_busY[31] )? 32'h0
                                : (  ex_busX[31] & ~ex_busY[31] )? 32'h1
                                : 32'h0;
        `ALUFUNC_SLTU : aluout1 = (ex_busX < ex_busY)? 32'h1 : 32'h0;
        `ALUFUNC_XOR  : aluout1 = ex_busX ^   ex_busY;
        `ALUFUNC_SRL  : aluout1 = $unsigned(sftout);
        `ALUFUNC_SRLI : aluout1 = $unsigned(sftout);
        `ALUFUNC_SRA  : aluout1 = $unsigned(sftout);
        `ALUFUNC_SRAI : aluout1 = $unsigned(sftout);
        `ALUFUNC_OR   : aluout1 = ex_busX | ex_busY;
        `ALUFUNC_AND  : aluout1 = ex_busX & ex_busY;
        `ALUFUNC_SWAP : aluout1 = ex_busY; // busY(CSR) --> busZ
        `ALUFUNC_SWPS : aluout1 = ex_busY; // busY(CSR) --> busZ
        `ALUFUNC_SWPC : aluout1 = ex_busY; // busY(CSR) --> busZ
        `ALUFUNC_MINS : aluout1 = (~(ex_busX[31] ^  ex_busY[31]))? ((ex_busX < ex_busY)? ex_busX : ex_busY)
                                : ( ~ex_busX[31] &  ex_busY[31] )? ex_busY
                                : (  ex_busX[31] & ~ex_busY[31] )? ex_busX
                                : 32'h0;
        `ALUFUNC_MAXS : aluout1 = (~(ex_busX[31] ^  ex_busY[31]))? ((ex_busX > ex_busY)? ex_busX : ex_busY)
                                : ( ~ex_busX[31] &  ex_busY[31] )? ex_busX
                                : (  ex_busX[31] & ~ex_busY[31] )? ex_busY
                                : 32'h0;
        `ALUFUNC_MINU : aluout1 = (ex_busX < ex_busY)? ex_busX :ex_busY;
        `ALUFUNC_MAXU : aluout1 = (ex_busX > ex_busY)? ex_busX :ex_busY;
        default       : aluout1 = 32'h00000000;
    endcase
end
//
always @*
begin
    casez(EX_ALU_FUNC)
        `ALUFUNC_SWAP : aluout2 =  ex_busX;           //  busX(REG/IMM)             --> CSR
        `ALUFUNC_SWPS : aluout2 =  ex_busX | ex_busY; //  busX(REG/IMM) | busY(CSR) --> CSR
        `ALUFUNC_SWPC : aluout2 = ~ex_busX & ex_busY; // ~busX(REG/IMM) & busY(CSR) --> CSR
        default       : aluout2 = 32'h00000000;
    endcase
end

//--------------------
// Shifter
//--------------------
reg signed [ 5:0] sftamt;
//
always @*
begin
    casez(EX_ALU_FUNC)
        `ALUFUNC_SLL,
        `ALUFUNC_SRL,
        `ALUFUNC_SRA  : sftamt = $signed({1'b0, ex_busY[4:0]});
        `ALUFUNC_SLLI,
        `ALUFUNC_SRLI,
        `ALUFUNC_SRAI : sftamt = $signed({1'b0, EX_ALU_SHAMT});
        default       : sftamt = 6'h0;
    endcase
end
//
always @*
begin
    casez(EX_ALU_FUNC)
        `ALUFUNC_SLL,
        `ALUFUNC_SLLI : sftout = $signed(ex_busX) << $unsigned(sftamt);
        `ALUFUNC_SRL,
        `ALUFUNC_SRLI : sftout = $signed(ex_busX) >> $unsigned(sftamt);
        `ALUFUNC_SRA,
        `ALUFUNC_SRAI : sftout = $signed(ex_busX) >>> $unsigned(sftamt);
        default       : sftout = $signed(ex_busX);
    endcase
end

//--------------------
// Comparator
//--------------------
always @*
begin
    casez(ID_CMP_FUNC)
        `CMPFUNC_EQ  : ID_CMP_RSLT = (id_busA == id_busB);
        `CMPFUNC_NE  : ID_CMP_RSLT = (id_busA != id_busB);
        `CMPFUNC_LT  : ID_CMP_RSLT = (id_busA[31] == id_busB[31])? (id_busA <  id_busB) : id_busA[31];
        `CMPFUNC_GE  : ID_CMP_RSLT = (id_busA[31] == id_busB[31])? (id_busA >= id_busB) : id_busB[31];
        `CMPFUNC_LTU : ID_CMP_RSLT = (id_busA <  id_busB);
        `CMPFUNC_GEU : ID_CMP_RSLT = (id_busA >= id_busB);
        default      : ID_CMP_RSLT = 1'b0;
    endcase
end

//--------------------
// Multipler
//--------------------
reg signed [32:0] mul_inX;
reg signed [32:0] mul_inY;
reg signed [65:0] mul_outZ;
reg        [31:0] mulout; // Multiplier Output
//
assign mul_outZ = mul_inX * mul_inY; // signed 33bit x 33bit --> 66bit
//
always @*
begin
    casez(EX_MUL_FUNC)
        `MULFUNC_MUL   : mul_inX = $signed({ex_busX[31], ex_busX});
        `MULFUNC_MULH  : mul_inX = $signed({ex_busX[31], ex_busX});
        `MULFUNC_MULHU : mul_inX = $signed({1'b0       , ex_busX});
        `MULFUNC_MULHSU: mul_inX = $signed({ex_busX[31], ex_busX});
        default        : mul_inX = 33'h00000000;
    endcase
end
//
always @*
begin
    casez(EX_MUL_FUNC)
        `MULFUNC_MUL   : mul_inY = $signed({ex_busY[31], ex_busY});
        `MULFUNC_MULH  : mul_inY = $signed({ex_busY[31], ex_busY});
        `MULFUNC_MULHU : mul_inY = $signed({1'b0       , ex_busY});
        `MULFUNC_MULHSU: mul_inY = $signed({1'b0       , ex_busY});
        default        : mul_inY = 33'h00000000;
    endcase
end
//
always @*
begin
    casez(EX_MUL_FUNC)
        `MULFUNC_MUL   : mulout = $unsigned(mul_outZ[31: 0]);
        `MULFUNC_MULH  : mulout = $unsigned(mul_outZ[63:32]);
        `MULFUNC_MULHU : mulout = $unsigned(mul_outZ[63:32]);
        `MULFUNC_MULHSU: mulout = $unsigned(mul_outZ[63:32]);
        default        : mulout = 32'h00000000;
    endcase
end

//-----------------------------------------
// Divider (Non-Restoring Method : 33cyc)
//-----------------------------------------
reg         div_busy;
reg  [ 4:0] div_count;
reg  [31:0] dividened;
reg         dividened_sign;
reg  [31:0] divisor;
reg         divisor_sign;
reg  [31:0] quotient;
reg  [31:0] quotient_out;
reg  [32:0] remainder;     // 33bit with Carry
reg  [32:0] remainder_out; // 33bit with Carry
wire [31:0] divout;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        div_busy       <=  1'b0;
        div_count      <=  5'h0;
        divisor        <= 32'h0;
        divisor_sign   <=  1'b0;
        dividened      <= 32'h0;
        dividened_sign <=  1'b0;
        quotient       <= 32'h0;
        remainder      <= 33'h0;
    end
    // Abort
    else if (div_busy & ID_DIV_STOP)
    begin
        div_busy       <=  1'b0;
        div_count      <=  5'h0;    
    end
    // Unsigned Division
    else if (ID_DIV_EXEC &  ID_DIV_FUNC[0]) //0
    begin
        // previous remainder always zero at beginning 
        div_busy       <=  1'b1;
        div_count      <=  5'h0;
        //
        divisor_sign   <= 1'b0;
        divisor        <= {id_busB};
        dividened_sign <=  1'b0;
        dividened      <= {id_busA[30:0], 1'b0};
        //
        remainder      <= {32'h0, id_busA[31]} - {1'b0, id_busB}; // 33bit
        quotient       <= {31'h0, 1'b1};
    end
    // Signed Division
    else if (ID_DIV_EXEC & ~ID_DIV_FUNC[0]) //0
    begin
        div_busy       <=  1'b1;
        div_count      <=  5'h0;
        //
        divisor_sign   <=  id_busB[31];
        divisor        <= {id_busB};
        dividened_sign <=  id_busA[31];
        dividened      <= {id_busA[30:0], 1'b0};
        //
        if (id_busA[31] == id_busB[31])
        begin
            remainder <= {{32{id_busA[31]}}, id_busA[31]} - {id_busB[31], id_busB}; // 33bit
            quotient  <= {31'h0, 1'b1};            
        end
        else
        begin
            remainder <= {{32{id_busA[31]}}, id_busA[31]} + {id_busB[31], id_busB}; // 33bit
            quotient  <= {31'h0, 1'b0};                    
        end
    end
    else if (div_busy & (div_count < 5'd31)) //1...30
    begin
        if (div_count == 5'd30) div_busy  <= 1'b0;
        div_count <= div_count + 5'h1;
        //
        dividened <= {dividened[30:0], 1'b0};
        //
        if (remainder[32] == divisor_sign)
        begin
            remainder <= {remainder[31:0], dividened[31]} - {divisor_sign, divisor}; // 33bit
            quotient  <= {quotient[30:0], 1'b1};                    
        end
        else
        begin
            remainder <= {remainder[31:0], dividened[31]} + {divisor_sign, divisor}; // 33bit
            quotient  <= {quotient[30:0], 1'b0};                            
        end
    end
    else if (div_count == 5'd31) //31
    begin
        div_count <= 5'h0;
    end
end
//
// Post Correction
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        remainder_out <= 33'h0;
        quotient_out  <= 32'h0;
    end
    else if (div_count == 5'd31)
    begin
        reg [32:0] remainder_temp;
        reg [31:0] quotient_temp;
        //
        remainder_temp = remainder;
        quotient_temp  = quotient;
        //
        // Make Quotient
        quotient_temp = {quotient_temp[30:0], 1'b1};
        //
        // Post Correction (1) 
        if ((dividened_sign == 1'b0) && (remainder_temp[32] == 1'b1))
        begin
            if (divisor_sign == 1'b0)
            begin
                remainder_temp = remainder_temp + {divisor_sign, divisor};
                quotient_temp  = quotient_temp - 32'h1;
            end
            else
            begin
                remainder_temp = remainder_temp - {divisor_sign, divisor};
                quotient_temp  = quotient_temp + 32'h1;                
            end
        end
        else if ((dividened_sign == 1'b1) && (remainder_temp[32] == 1'b0))
        begin
            if (divisor_sign == 1'b0)
            begin
                remainder_temp = remainder_temp - {divisor_sign, divisor};
                quotient_temp  = quotient_temp + 32'h1;                
            end
            else
            begin
                remainder_temp = remainder_temp + {divisor_sign, divisor};
                quotient_temp  = quotient_temp - 32'h1;
            end
        end
        //
        // Post Correction (2)
        if ((remainder_temp + {divisor_sign, divisor}) == 0)
        begin
            remainder_temp = 0;
            quotient_temp  = quotient_temp - 32'h1;
        end
        else if ((remainder_temp - {divisor[31], divisor}) == 0)
        begin
            remainder_temp = 0;
            quotient_temp  = quotient_temp + 32'h1;
        end
        //
        // Non Blocking Assignment
        remainder_out <= remainder_temp;
        quotient_out  <= quotient_temp;
    end
end
//
assign ID_DIV_BUSY = div_busy;
//
// Illegal Division
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        EX_DIV_ZERO <= 1'b0;
    else if (ID_DIV_CHEK)
        EX_DIV_ZERO = (id_busB == 32'h00000000); // Division by Zero
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        EX_DIV_OVER <= 1'b0;
    else if (ID_DIV_CHEK)
        EX_DIV_OVER <= ~ID_DIV_FUNC[0]
                     & (id_busA == 32'h80000000)
                     & (id_busB == 32'hffffffff); // Signed Overflow
end
//
// Divider Output
assign divout = ( EX_DIV_ZERO & (EX_DIV_FUNC[1:0] == 2'b01))? 32'hffffffff // DIVU
              : ( EX_DIV_ZERO & (EX_DIV_FUNC[1:0] == 2'b11))? ex_busX      // REMU
              : ( EX_DIV_ZERO & (EX_DIV_FUNC[1:0] == 2'b00))? 32'hffffffff // DIVS
              : ( EX_DIV_ZERO & (EX_DIV_FUNC[1:0] == 2'b10))? ex_busX      // REMS
              : ( EX_DIV_OVER & (EX_DIV_FUNC[1:0] == 2'b00))? 32'h80000000 // DIVS
              : ( EX_DIV_OVER & (EX_DIV_FUNC[1:0] == 2'b10))? 32'h00000000 // REMS
              : (~EX_DIV_FUNC[1])? quotient_out : remainder_out[31:0];

//--------------------
// BUSX
//--------------------
assign ex_busX = ((EX_ALU_SRC1 & `ALU_MSK) == `ALU_FPR)? EX_FPU_SRCDATA // FPU is source
               : ( EX_AMO_2NDST                       )? wb_busW 
               : ( fwd_wb_ex1                         )? wb_busW
               : ((EX_ALU_SRC1 & `ALU_MSK) == `ALU_GPR)? regXR[EX_ALU_SRC1[4:0]]
               : ((EX_ALU_SRC1           ) == `ALU_IMM)? EX_ALU_IMM
               : ((EX_ALU_SRC1           ) == `ALU_PC )? EX_PC
               : 32'h00000000;

//--------------------
// BUSY
//--------------------
reg [31:0] ex_csr_rdata;
//
assign ex_busY = (fwd_wb_ex2                          )? wb_busW
               : ((EX_ALU_SRC2 & `ALU_MSK) == `ALU_GPR)? regXR[EX_ALU_SRC2[4:0]]
               : ((EX_ALU_SRC2           ) == `ALU_IMM)? EX_ALU_IMM
               : ((EX_ALU_SRC2           ) == `ALU_PC )? EX_PC
               : ((EX_ALU_SRC2 & `ALU_CSR) == `ALU_CSR)? ex_csr_rdata
               : 32'h00000000;

//--------------------
// BUSZ
//--------------------
assign ex_busZ = (EX_MUL_FUNC[2])? mulout
               : (EX_DIV_FUNC[2])? divout
               : aluout1;

//--------------------
// BUSV
//--------------------
assign ex_busV = (((EX_ALU_DST2 & `ALU_MSK) == `ALU_GPR) & EX_AMO_SCOND)? scond_dst_data
               : aluout2;

//--------------------
// BUSA
//--------------------
assign id_busA = (fwd_ex_id1                          )? ex_busZ
               : (fwd_ex_id3                          )? ex_busV
               : (fwd_wb_id1                          )? wb_busW
               : ((ID_DEC_SRC1 & `ALU_MSK) == `ALU_GPR)? regXR[ID_DEC_SRC1[4:0]]
               : 32'h00000000;
assign ID_BUSA = id_busA;

//--------------------
// BUSB
//--------------------
assign id_busB = (fwd_ex_id2                          )? ex_busZ
               : (fwd_ex_id4                          )? ex_busV
               : (fwd_wb_id2                          )? wb_busW
               : ((ID_DEC_SRC2 & `ALU_MSK) == `ALU_GPR)? regXR[ID_DEC_SRC2[4:0]]
               : 32'h00000000;
assign ID_BUSB = id_busB;

//--------------------
// BUSS
//--------------------
assign ex_busS = (EX_AMO_2NDST                     )? ex_busZ
               : (fwd_wb_sts                       )? wb_busW
               : ((EX_STSRC & `ALU_MSK) == `ALU_GPR)? regXR[EX_STSRC[4:0]]
               : ((EX_STSRC           ) == `ALU_IMM)? EX_ALU_IMM
               : ((EX_STSRC           ) == `ALU_PC )? EX_PC
               : ((EX_STSRC & `ALU_MSK) == `ALU_FPR)? EX_FPU_ST_DATA
               : 32'h00000000;

//--------------------
// BUSW
//--------------------
reg  [31:0] wb_busW_lat;
wire [31:0] wb_busW_stretch;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        wb_busW_lat <= 32'h00000000;
    else if (BUSM_M_DONE[0])
        wb_busW_lat <= BUSM_M_RDATA;
end
//
assign wb_busW_stretch = (BUSM_M_DONE[0])? BUSM_M_RDATA : wb_busW_lat;
//
assign wb_busW = (WB_MACMD == `MACMD_LW )? wb_busW_stretch
               : (WB_MACMD == `MACMD_LH )? {{16{wb_busW_stretch[15]}}, wb_busW_stretch[15:0]}
               : (WB_MACMD == `MACMD_LB )? {{24{wb_busW_stretch[ 7]}}, wb_busW_stretch[ 7:0]}
               : (WB_MACMD == `MACMD_LHU)? {16'h0000  , wb_busW_stretch[15:0]}
               : (WB_MACMD == `MACMD_LBU)? {24'h000000, wb_busW_stretch[ 7:0]}
               : 32'h00000000;

//--------------------
// Memory Acccess
//--------------------
reg ma_stage;
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        ma_stage <= 1'b0;
    else if (BUSM_M_REQ & BUSM_M_ACK)
        ma_stage <= 1'b1;
    else if (BUSM_M_LAST)
        ma_stage <= 1'b0;
end
//assign EX_MARDY = (PIPE_EX_ENABLE & BUSM_M_REQ)? BUSM_M_ACK : 1'b1;
//assign MA_MDRDY = (PIPE_MA_ENABLE)? BUSM_M_LAST : 1'b1;
assign EX_MARDY = (BUSM_M_REQ)? BUSM_M_ACK : 1'b1;
assign MA_MDRDY = (ma_stage)? BUSM_M_LAST : 1'b1;
//
reg busm_m_req;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        busm_m_req <= 1'b0;
    else if (ID_MACMD[4])
        busm_m_req <= 1'b1; // Assert from beginning of EX stage (The Higher Priority)
    else if (BUSM_M_ACK)
        busm_m_req <= 1'b0; // Avoid multiple memory access commands in one EX stage
    else if (EX_BUSERR_ALIGN[0]) // If misaligned, then Cancel
        busm_m_req <= 1'b0;
end    
//
always @*
begin // If misaligned, then Cancel, but if it is locked AMO, do not cancel
    BUSM_M_REQ   = busm_m_req
                 & ( EX_AMO_1STLD | ~EX_BUSERR_ALIGN[0])
                 & (~EX_AMO_SCOND |  scond_success     );
    BUSM_M_SEQ   = 1'b0;
    BUSM_M_CONT  = 1'b0;
    BUSM_M_BURST = 3'b000;
    BUSM_M_LOCK  = EX_AMO_1STLD; // NOTE: Need treatment for Atomic Access
    BUSM_M_PROT  = 4'b0000;
    BUSM_M_WRITE =  EX_MACMD[4] & EX_MACMD[3];
    BUSM_M_SIZE  = (EX_MACMD[4]               )? EX_MACMD[1:0] : 2'b00;
    BUSM_M_ADDR  = (EX_MACMD[4] & EX_AMO_2NDST)? regXR[EX_ALU_SRC1[4:0]]
                 : (EX_MACMD[4]               )? ex_busZ : 32'h00000000;
    BUSM_M_WDATA = (EX_MACMD[4] & EX_MACMD[3] )? ex_busS : 32'h00000000;
end

//---------------------------
// Memory Bus Access Error
//---------------------------
reg [31:0] ex_buserr_addr;
reg [31:0] ma_buserr_addr;
//
//assign EX_BUSERR_ALIGN = 0;
assign EX_BUSERR_ALIGN[0] = PIPE_EX_ENABLE & EX_MACMD[4] &
                          (((EX_MACMD[1:0] == 2'b10) & (BUSM_M_ADDR[1:0] == 2'b01))
                          |((EX_MACMD[1:0] == 2'b10) & (BUSM_M_ADDR[1:0] == 2'b10))
                          |((EX_MACMD[1:0] == 2'b10) & (BUSM_M_ADDR[1:0] == 2'b11))
                          |((EX_MACMD[1:0] == 2'b01) & (BUSM_M_ADDR[  0] == 1'b1 )));
assign EX_BUSERR_ALIGN[1] = PIPE_EX_ENABLE & EX_MACMD[4] & EX_MACMD[3];
assign WB_BUSERR_FAULT[0] = PIPE_WB_ENABLE & BUSM_M_DONE[3];
assign WB_BUSERR_FAULT[1] = PIPE_WB_ENABLE & BUSM_M_DONE[1];
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        ex_buserr_addr <= 32'h00000000;
    else if (PIPE_EX_ENABLE)
        ex_buserr_addr <= ex_busZ;
end
assign EX_BUSERR_ADDR = (PIPE_EX_ENABLE)? ex_busZ : ex_buserr_addr;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        ma_buserr_addr <= 32'h00000000;
    else if (BUSM_M_REQ & BUSM_M_ACK)
        ma_buserr_addr <= EX_BUSERR_ADDR;
end    
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        WB_BUSERR_ADDR <= 32'h00000000;
    else if (BUSM_M_LAST)
        WB_BUSERR_ADDR <= ma_buserr_addr;
end    

//------------------------
// CSR Interface
//------------------------
assign EX_CSR_REQ   = ((ID_ALU_SRC2 & `ALU_CSR) == `ALU_CSR)
                    | ((EX_ALU_DST2 & `ALU_CSR) == `ALU_CSR);
assign EX_CSR_WRITE = ((EX_ALU_DST2 & `ALU_CSR) == `ALU_CSR);
assign EX_CSR_ADDR  = ((ID_ALU_SRC2 & `ALU_CSR) == `ALU_CSR)? ID_ALU_SRC2[11:0]
                    : ((EX_ALU_DST2 & `ALU_CSR) == `ALU_CSR)? EX_ALU_DST2[11:0]
                    : 12'h000;
assign EX_CSR_WDATA = ex_busV;
//
// to avoid combinational loop
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        ex_csr_rdata <= 32'h00000000;
    else if (((ID_ALU_SRC2 & `ALU_CSR) == `ALU_CSR) & PIPE_ID_ENABLE)
        ex_csr_rdata <= EX_CSR_RDATA;
end

`ifdef RISCV_ISA_RV32A
//------------------------------------------
// Load Reserved and Store Conditional
//------------------------------------------
reg        lrsvd_flag;
reg [31:0] lrsvd_addr;
reg        lrsvd_pollute;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        lrsvd_flag <= 1'b0;
        lrsvd_addr <= 32'h00000000;
    end
    else if (EXP_ACK | INT_ACK)
    begin
        lrsvd_flag <= 1'b0;
        lrsvd_addr <= 32'h00000000;    
    end
    else if (EX_AMO_SCOND)
    begin
        lrsvd_flag <= 1'b0;
        lrsvd_addr <= 32'h00000000;    
    end
    else if (EX_AMO_LRSVD & busm_m_req)
    begin
        lrsvd_flag <= BUSM_M_REQ;
        lrsvd_addr <= BUSM_M_ADDR;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        lrsvd_pollute <= 1'b0;
    else if (EXP_ACK | INT_ACK)
        lrsvd_pollute <= 1'b0;
    else if (EX_AMO_SCOND)
        lrsvd_pollute <= 1'b0;
    else if (lrsvd_flag & BUSM_S_REQ & BUSM_S_WRITE & (lrsvd_addr[31:2] == BUSM_S_ADDR[31:2]))
        lrsvd_pollute <= 1'b1;
end
//
assign scond_unspecified = EX_AMO_SCOND & ~lrsvd_flag;
assign scond_success = (EX_AMO_SCOND & ~EX_BUSERR_ALIGN[0] & lrsvd_flag & ~lrsvd_pollute);
assign scond_failure = (EX_AMO_SCOND & ~EX_BUSERR_ALIGN[0] & lrsvd_flag &  lrsvd_pollute)
                     | (EX_AMO_SCOND &  EX_BUSERR_ALIGN[0] & lrsvd_flag);
assign scond_dst_data = (scond_unspecified)? 32'h00000001
                      : (scond_success    )? 32'h00000000
                      : (scond_failure    )? 32'hffffffff
                      : 32'h00000000;
`else
assign scond_success = 1'b1;
assign scond_dst_data = 32'h00000000;
`endif

//--------------------------------------------
// FPU Operation
//--------------------------------------------
//assign EX_FPU_DSTDATA = ((EX_ALU_DST1 & `ALU_MSK) == `ALU_FPR)? ex_busZ
//                    : 32'h00000000;
assign EX_FPU_DSTDATA = ex_busZ;
assign WB_FPU_LD_DATA = wb_busW;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
