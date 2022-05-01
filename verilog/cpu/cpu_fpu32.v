//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_fpu32.v
// Description : 32bit Single Precision FPU
//-----------------------------------------------------------
// History :
// Rev.01 2021.07.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

//===========================================================
// CSR for FPU32 Floating Point Control and Status Register
//-----------------------------------------------------------
// FCSR : 0x003
//   bit[31:8] R   (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 7:5] R/W  FRM    Floating Point Dynamic Rounding Mode
//                  FRM  Mnemonic  Meaning
//                  000  RNE       Round to Nearest, tied to even
//                  001  RTZ       Round to Zero
//                  010  RDN       Round Down towards minus infinite
//                  011  RUP       Round Up towards plus infinite
//                  100  RMM       Round to Nearest, ties to Max Magnitude
//                  101  Reserved
//                  110  Reserved
//                  111  DYN       In instruction’s rm field, 
//                                 selects dynamic rounding mode;
//                                 In Rounding Mode register, Invalid.
//   bit[ 4:0] R/W  FFLAGS Floating Point Acquired Exception Flags
//                  bit4 : NV  Invalid Operation
//                  bit3 : DZ  Divide by Zero
//                  bit2 : OF  Overflow
//                  bit1 : UF  Underflow
//                  bit0 : NX  Inexact
//===========================================================

//===========================================================
// CSR for FPU32 Floating Point Dynamic Rounding Mode
//-----------------------------------------------------------
// FRM : 0x002
//   bit[31:3] R   (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 2:0] R/W  FRM    Floating Point Dynamic Rounding Mode
//                  FRM  Mnemonic  Meaning
//                  000  RNE       Round to Nearest, tied to even
//                  001  RTZ       Round to Zero
//                  010  RDN       Round Down towards minus infinite
//                  011  RUP       Round Up towards plus infinite
//                  100  RMM       Round to Nearest, ties to Max Magnitude
//                  101  Reserved
//                  110  Reserved
//                  111  DYN       In instruction’s rm field, 
//                                 selects dynamic rounding mode;
//                                 In Rounding Mode register, Invalid.
//===========================================================

//===========================================================
// CSR for FPU32 Floating Point Acquired Exception Flags
//-----------------------------------------------------------
// FFLAGS : 0x001
//   bit[31:5] R   (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 4:0] R/W  FFLAGS Floating Point Acquired Exception Flags
//                  bit4 : NV  Invalid Operation
//                  bit3 : DZ  Divide by Zero
//                  bit2 : OF  Overflow
//                  bit1 : UF  Underflow
//                  bit0 : NX  Inexact
//===========================================================

//===========================================================
// CSR for FPU32 Convergence Loop Count for FDIV/FSQRT
//-----------------------------------------------------------
// CSR_FPU32CONV : 0xbe0
//   bit[31:8] WIRI (Reserved Writes Ignored, Reads Ignore Values)
//   bit[ 7:4] R/W  FSQRT Convergence Loop Count (default 4)
//   bit[ 3:0] R/W  FDIV  Convergence Loop Count (default 4)
//===========================================================

`include "defines_core.v"

//=====================================================================
//---------------------------------------------------------------------
// FPU32 Main Body
//---------------------------------------------------------------------
//=====================================================================
//----------------------
// Define Module
//----------------------
module CPU_FPU32
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    input  wire        CSR_FPU_DBG_REQ,   // FPU CSR Access Request
    input  wire        CSR_FPU_DBG_WRITE, // FPU CSR Access Write
    input  wire [11:0] CSR_FPU_DBG_ADDR,  // FPU CSR Access Address
    input  wire [31:0] CSR_FPU_DBG_WDATA, // FPU CSR Access Write Data
    output wire [31:0] CSR_FPU_DBG_RDATA, // FPU CSR Access Read Data
    input  wire        CSR_FPU_CPU_REQ,   // FPU CSR Access Request
    input  wire        CSR_FPU_CPU_WRITE, // FPU CSR Access Write
    input  wire [11:0] CSR_FPU_CPU_ADDR,  // FPU CSR Access Address
    input  wire [31:0] CSR_FPU_CPU_WDATA, // FPU CSR Access Write Data
    output wire [31:0] CSR_FPU_CPU_RDATA, // FPU CSR Access Read Data
    //
    input  wire        DBGABS_FPR_REQ,   // Debug Abstract Command Request for FPR
    input  wire        DBGABS_FPR_WRITE, // Debug Abstract Command Write   for FPR
    input  wire [11:0] DBGABS_FPR_ADDR,  // Debug Abstract Command Address for FPR
    input  wire [31:0] DBGABS_FPR_WDATA, // Debug Abstract Command Write Data for FPR
    output reg  [31:0] DBGABS_FPR_RDATA, // Debug Abstract Command Read  Data for FPR
    //
    input  wire [ 7:0] ID_FPU_CMD,      // FPU Command in ID Stage
    input  wire [ 2:0] ID_FPU_RMODE,    // FPU Round Mode in ID Stage
    output wire        ID_FPU_STALL,    // FPU Stall Request in ID Stage    
    input  wire [13:0] ID_FPU_SRC1,     // FPU Source Register 1 in ID Stage
    input  wire [13:0] ID_FPU_SRC2,     // FPU Source Register 2 in ID Stage
    input  wire [13:0] ID_FPU_SRC3,     // FPU Source Register 3 in ID Stage
    input  wire [13:0] ID_FPU_DST1,     // FPU Destination Register in ID Stage
    input  wire [13:0] EX_ALU_SRC1,     // FPU Source Register 1 in EX Stage
    input  wire [13:0] EX_ALU_SRC2,     // FPU Source Register 2 in EX Stage
    input  wire [13:0] EX_ALU_SRC3,     // FPU Source Register 3 in EX Stage (FPU)
    input  wire [13:0] EX_ALU_DST1,     // FPU Destinaton Register in EX stage
    input  wire [13:0] EX_STSRC,        // FPU Memory Store Data Source in EX Stage
    input  wire [13:0] WB_LOAD_DST,     // FPU Memory Load Destination in WB Stage
    //
    output wire [31:0] EX_FPU_SRCDATA,  // FPU Source Data in EX Stage
    input  wire [31:0] EX_FPU_DSTDATA,  // FPU Destinaton Data in EX Stage
    output wire [31:0] EX_FPU_ST_DATA,  // FPU Memory Store Data in EX Stage
    input  wire [31:0] WB_FPU_LD_DATA,  // FPU Memory Load Data in WB Stage
    //
    output reg         FPUCSR_DIRTY,        // FPU CSR is Dirty
    output wire        SET_MSTATUS_FS_DIRTY // Set MSTATUS FS Field as Dirty
);

//----------------------------------------------------------------------
// If RISCV_ISA_RV32F is defined....
//----------------------------------------------------------------------
`ifdef RISCV_ISA_RV32F

integer i;
reg  div_sel; // datapath is used for FDIV
reg  sqr_sel; // datapath is used for FSQRT

//--------------------------
// CSR FCSR/FRM/FFLAGS
// CSR_FPU32CONV
//--------------------------
reg  [2:0] csr_frm;
reg  [4:0] csr_fflags;
wire       csr_fflags_set;
wire [4:0] fflag_out_final;
//
reg  [3:0] csr_sqr_loop;
reg  [3:0] csr_div_loop;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        csr_frm <= 3'b000;
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FRM))
        csr_frm <= CSR_FPU_DBG_WDATA[2:0];
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FCSR))
        csr_frm <= CSR_FPU_DBG_WDATA[7:5];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FRM))
        csr_frm <= CSR_FPU_CPU_WDATA[2:0];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FCSR))
        csr_frm <= CSR_FPU_CPU_WDATA[7:5];
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        csr_fflags <= 5'b00000;
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FFLAGS))
        csr_fflags <= CSR_FPU_DBG_WDATA[4:0];
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FCSR))
        csr_fflags <= CSR_FPU_DBG_WDATA[4:0];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FFLAGS))
        csr_fflags <= CSR_FPU_CPU_WDATA[4:0];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FCSR))
        csr_fflags <= CSR_FPU_CPU_WDATA[4:0];
    else if (csr_fflags_set)
        csr_fflags <= csr_fflags | fflag_out_final; // OR
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        csr_div_loop <= `FPU32_DIV_LOOP_INIT;
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FPU32CONV))
        csr_div_loop <= CSR_FPU_DBG_WDATA[3:0];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FPU32CONV))
        csr_div_loop <= CSR_FPU_CPU_WDATA[3:0];
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        csr_sqr_loop <= `FPU32_SQR_LOOP_INIT;
    else if (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FPU32CONV))
        csr_sqr_loop <= CSR_FPU_DBG_WDATA[7:4];
    else if (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FPU32CONV))
        csr_sqr_loop <= CSR_FPU_CPU_WDATA[7:4];
end
//
assign CSR_FPU_DBG_RDATA = (~CSR_FPU_DBG_REQ | CSR_FPU_DBG_WRITE)? 32'h00000000
            : (CSR_FPU_DBG_ADDR == `CSR_FRM   )? {29'h0, csr_frm   }
            : (CSR_FPU_DBG_ADDR == `CSR_FFLAGS)? {27'h0, csr_fflags}
            : (CSR_FPU_DBG_ADDR == `CSR_FCSR  )? {24'h0, csr_frm, csr_fflags}
            : (CSR_FPU_DBG_ADDR == `CSR_FPU32CONV)? {24'h0, csr_sqr_loop, csr_div_loop} 
            :  32'h00000000;
assign CSR_FPU_CPU_RDATA = (~CSR_FPU_CPU_REQ | CSR_FPU_CPU_WRITE)? 32'h00000000
            : (CSR_FPU_CPU_ADDR == `CSR_FRM   )? {29'h0, csr_frm   }
            : (CSR_FPU_CPU_ADDR == `CSR_FFLAGS)? {27'h0, csr_fflags}
            : (CSR_FPU_CPU_ADDR == `CSR_FCSR  )? {24'h0, csr_frm, csr_fflags}
            : (CSR_FPU_CPU_ADDR == `CSR_FPU32CONV)? {24'h0, csr_sqr_loop, csr_div_loop} 
            :  32'h00000000;

//-----------------------------------
// Floating Point Registers FRn
//-----------------------------------
reg [31:0] regFR[0:31]; // FPU Registers

//--------------------------
// FRx Debug Read Access
//--------------------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        DBGABS_FPR_RDATA <= 32'h00000000;
    else if (DBGABS_FPR_REQ & ~DBGABS_FPR_WRITE)
        DBGABS_FPR_RDATA <= regFR[DBGABS_FPR_ADDR[4:0]];
    else
        DBGABS_FPR_RDATA <= 32'h00000000;
end

//-------------------------------------
// [i]   Handle Special Number
//-------------------------------------
wire [31:0] mspecial_float_in1;
wire [31:0] mspecial_float_in2;
wire [31:0] mspecial_float_out;
wire [ 2:0] mspecial_rmode;
wire [ 4:0] mspecial_flg_in;
wire [ 4:0] mspecial_flg_out;
wire        mspecial_special;
FMUL_SPECIAL_NUMBER U_FMUL_SPECIAL_NUMBER
(
    .FDATA_IN1 (mspecial_float_in1),
    .FDATA_IN2 (mspecial_float_in2),
    .FDATA_OUT (mspecial_float_out),
    .RMODE     (mspecial_rmode),
    .FLG_IN    (mspecial_flg_in),
    .FLG_OUT   (mspecial_flg_out),
    .SPECIAL   (mspecial_special)
);
//
wire [31:0] aspecial_float_in1;
wire [31:0] aspecial_float_in2;
wire [31:0] aspecial_float_out;
wire [ 2:0] aspecial_rmode;
wire [ 4:0] aspecial_flg_in;
wire [ 4:0] aspecial_flg_out;
wire        aspecial_special;
FADD_SPECIAL_NUMBER U_FADD_SPECIAL_NUMBER
(
    .FDATA_IN1 (aspecial_float_in1),
    .FDATA_IN2 (aspecial_float_in2),
    .FDATA_OUT (aspecial_float_out),
    .RMODE     (aspecial_rmode),
    .FLG_IN    (aspecial_flg_in),
    .FLG_OUT   (aspecial_flg_out),
    .SPECIAL   (aspecial_special)
);
//
wire [31:0] maspecial_float_in1;
wire [31:0] maspecial_float_in2;
wire [31:0] maspecial_float_in3;
wire [31:0] maspecial_float_out;
wire        maspecial_negate;
wire [ 2:0] maspecial_rmode;
wire [ 4:0] maspecial_flg_in;
wire [ 4:0] maspecial_flg_out;
wire [ 1:0] maspecial_special;
FMADD_SPECIAL_NUMBER U_FMADD_SPECIAL_NUMBER
(
    .FDATA_IN1  (maspecial_float_in1),
    .FDATA_IN2  (maspecial_float_in2),
    .FDATA_IN3  (maspecial_float_in3),
    .FDATA_OUT  (maspecial_float_out),
    .NEGATE     (maspecial_negate),
    .RMODE      (maspecial_rmode),
    .FLG_IN     (maspecial_flg_in),
    .FLG_OUT    (maspecial_flg_out),
    .SPECIAL_MA (maspecial_special)
);
//
wire [31:0] dspecial_float_in1;
wire [31:0] dspecial_float_in2;
wire [31:0] dspecial_float_out;
wire [ 2:0] dspecial_rmode;
wire [ 4:0] dspecial_flg_in;
wire [ 4:0] dspecial_flg_out;
wire        dspecial_special;
FDIV_SPECIAL_NUMBER U_FDIV_SPECIAL_NUMBER
(
    .FDATA_IN1 (dspecial_float_in1),
    .FDATA_IN2 (dspecial_float_in2),
    .FDATA_OUT (dspecial_float_out),
    .RMODE     (dspecial_rmode),
    .FLG_IN    (dspecial_flg_in),
    .FLG_OUT   (dspecial_flg_out),
    .SPECIAL   (dspecial_special)
);
//
wire [31:0] sspecial_float_in1;
wire [31:0] sspecial_float_out;
wire [ 2:0] sspecial_rmode;
wire [ 4:0] sspecial_flg_in;
wire [ 4:0] sspecial_flg_out;
wire        sspecial_special;
FSQRT_SPECIAL_NUMBER U_FSQRT_SPECIAL_NUMBER
(
    .FDATA_IN1 (sspecial_float_in1),
    .FDATA_OUT (sspecial_float_out),
    .RMODE     (sspecial_rmode),
    .FLG_IN    (sspecial_flg_in),
    .FLG_OUT   (sspecial_flg_out),
    .SPECIAL   (sspecial_special)
);

//-------------------------------------
// [i]   Convert Float to Inner
//-------------------------------------
wire [31:0] idata_float_in1;
wire [31:0] idata_float_in2;
wire [31:0] idata_float_in3;
wire [78:0] idata_inner_out1;
wire [78:0] idata_inner_out2;
wire [78:0] idata_inner_out3;
reg  [ 2:0] imode;
//
INNER79_FROM_FLOAT32 U_INNER79_FROM_FLOAT32_1
(
    .FLOAT32 (idata_float_in1 ),
    .INNER79 (idata_inner_out1)
);
INNER79_FROM_FLOAT32 U_INNER79_FROM_FLOAT32_2
(
    .FLOAT32 (idata_float_in2 ),
    .INNER79 (idata_inner_out2)
);
INNER79_FROM_FLOAT32 U_INNER79_FROM_FLOAT32_3
(
    .FLOAT32 (idata_float_in3 ),
    .INNER79 (idata_inner_out3)
);

//-------------------------------------
// [m] FMUL Core
//-------------------------------------
reg  [78:0] mdata_inner_in1;
reg  [78:0] mdata_inner_in2;
reg  [78:0] mdata_inner_in3; // for FMADD etc.
wire [78:0] mdata_inner_out;
reg  [ 2:0] mmode;
reg  [ 4:0] mflag_in;
wire [ 4:0] mflag_out;
//
reg  [78:0] div_mdata_inner_in1;
reg  [78:0] div_mdata_inner_in2;
wire [78:0] div_mdata_inner_out;
reg  [ 2:0] div_mmode;
reg  [ 4:0] div_mflag_in;
wire [ 4:0] div_mflag_out;
//
reg  [78:0] sqr_mdata_inner_in1;
reg  [78:0] sqr_mdata_inner_in2;
wire [78:0] sqr_mdata_inner_out;
reg  [ 2:0] sqr_mmode;
reg  [ 4:0] sqr_mflag_in;
wire [ 4:0] sqr_mflag_out;
//
wire [78:0] fmul_core_in1;
wire [78:0] fmul_core_in2;
wire [78:0] fmul_core_out;
wire [ 2:0] fmul_core_mmode;
wire [ 4:0] fmul_core_mflag_in;
wire [ 4:0] fmul_core_mflag_out;
//
assign fmul_core_in1 = (div_sel)? div_mdata_inner_in1
                     : (sqr_sel)? sqr_mdata_inner_in1
                     : mdata_inner_in1;
assign fmul_core_in2 = (div_sel)? div_mdata_inner_in2
                     : (sqr_sel)? sqr_mdata_inner_in2
                     : mdata_inner_in2;
assign fmul_core_mmode    = (div_sel)? div_mmode : (sqr_sel)? sqr_mmode : mmode;
assign fmul_core_mflag_in = (div_sel)? div_mflag_in : (sqr_sel)? sqr_mflag_in : mflag_in; 
//
assign mdata_inner_out = fmul_core_out;
assign mflag_out       = fmul_core_mflag_out;
//
assign div_mdata_inner_out = fmul_core_out;
assign div_mflag_out       = fmul_core_mflag_out;
//
assign sqr_mdata_inner_out = fmul_core_out;
assign sqr_mflag_out       = fmul_core_mflag_out;
//
FMUL_CORE U_FMUL_CORE
(
    .INNER79_IN1 (fmul_core_in1),
    .INNER79_IN2 (fmul_core_in2),
    .INNER79_OUT (fmul_core_out),
    .RMODE       (fmul_core_mmode),
    .FLG_IN      (fmul_core_mflag_in),
    .FLG_OUT     (fmul_core_mflag_out)
);

//-------------------------------------
// [a] FADD Core
//-------------------------------------
reg  [78:0] adata_inner_in1;
reg  [78:0] adata_inner_in2;
wire [78:0] adata_inner_out;
reg  [ 2:0] amode;
reg  [ 4:0] aflag_in;
wire [ 4:0] aflag_out;
//
reg  [78:0] div_adata_inner_in1;
reg  [78:0] div_adata_inner_in2;
wire [78:0] div_adata_inner_out;
reg  [ 2:0] div_amode;
reg  [ 4:0] div_aflag_in;
wire [ 4:0] div_aflag_out;
//
reg  [78:0] sqr_adata_inner_in1;
reg  [78:0] sqr_adata_inner_in2;
wire [78:0] sqr_adata_inner_out;
reg  [ 2:0] sqr_amode;
reg  [ 4:0] sqr_aflag_in;
wire [ 4:0] sqr_aflag_out;
//
wire [78:0] fadd_core_in1;
wire [78:0] fadd_core_in2;
wire [78:0] fadd_core_out;
wire [ 2:0] fadd_core_amode;
wire [ 4:0] fadd_core_aflag_in;
wire [ 4:0] fadd_core_aflag_out;
//
assign fadd_core_in1 = (div_sel)? div_adata_inner_in1
                     : (sqr_sel)? sqr_adata_inner_in1
                     : adata_inner_in1;
assign fadd_core_in2 = (div_sel)? div_adata_inner_in2
                     : (sqr_sel)? sqr_adata_inner_in2
                     : adata_inner_in2;
assign fadd_core_amode    = (div_sel)? div_amode : (sqr_sel)? sqr_amode : amode;
assign fadd_core_aflag_in = (div_sel)? div_aflag_in : (sqr_sel)? sqr_aflag_in : aflag_in; 
//
//
assign adata_inner_out = fadd_core_out;
assign aflag_out       = fadd_core_aflag_out;
//
assign div_adata_inner_out = fadd_core_out;
assign div_aflag_out       = fadd_core_aflag_out;
//
assign sqr_adata_inner_out = fadd_core_out;
assign sqr_aflag_out       = fadd_core_aflag_out;
//
FADD_CORE U_FADD_CORE_ADD
(
    .INNER79_IN1 (fadd_core_in1),
    .INNER79_IN2 (fadd_core_in2),
    .INNER79_OUT (fadd_core_out),
    .RMODE       (fadd_core_amode),
    .FLG_IN      (fadd_core_aflag_in),
    .FLG_OUT     (fadd_core_aflag_out)
);

//-------------------------------------
// [f] Convert Inner to Float
//-------------------------------------
reg  [78:0] fdata_inner_in;
wire [31:0] fdata_float_out;
reg  [ 2:0] fmode;
reg  [ 4:0] fflag_in;
wire [ 4:0] fflag_out;
//
FLOAT32_FROM_INNER79 U_FLOAT32_FROM_INNER79
(
    .INNER79  (fdata_inner_in),
    .FLOAT32  (fdata_float_out),
    .RMODE    (fmode),
    .FLAG_IN  (fflag_in),
    .FLAG_OUT (fflag_out)
);

//-------------------------------------
// [i] Convert Float to Integer
//-------------------------------------
wire [31:0] fcvt_f2i_float_in;
wire [31:0] fcvt_f2i_int_out;
wire        fcvt_f2i_signed;
wire [ 2:0] fcvt_f2i_rmode;
wire [ 4:0] fcvt_f2i_flg_out;
//
FCVT_F2I U_FCVT_F2I
(
    .FLOAT_IN (fcvt_f2i_float_in),
    .INT_OUT  (fcvt_f2i_int_out),
    .SIGNED   (fcvt_f2i_signed),
    .RMODE    (fcvt_f2i_rmode),
    .FLG_OUT  (fcvt_f2i_flg_out)
);

//-------------------------------------
// [i] Convert Integer to Float
//-------------------------------------
reg  [31:0] fcvt_i2f_int_in;
wire [31:0] fcvt_i2f_float_out;
reg         fcvt_i2f_signed;
reg  [ 2:0] fcvt_i2f_rmode;
wire [ 4:0] fcvt_i2f_flg_out;
//
FCVT_I2F U_FCVT_I2F
(
    .INT_IN    (fcvt_i2f_int_in),
    .FLOAT_OUT (fcvt_i2f_float_out),
    .SIGNED    (fcvt_i2f_signed),
    .RMODE     (fcvt_i2f_rmode),
    .FLG_OUT   (fcvt_i2f_flg_out)
);

//-------------------------------------
// [i] Classify Float
//-------------------------------------
wire [31:0] chk_ftype_float_in;
wire [ 3:0] chk_ftype_out;
//
CHECK_FTYPE U_CHECK_FTYPE
(
    .FDATA (chk_ftype_float_in),
    .FTYPE (chk_ftype_out)
);

//--------------------------------
// Control Pipeline
//--------------------------------
// [FPU Pipeline]
//
// DE
//  DE (FMV.W.X)
//   Diaf (FADD/FSUB/FMUL)
//    Diaf (FADD/FSUB/FMUL)
//     -Diaf (FADD/FSUB/FMUL) register conflict (f-->i)
//       Dimaf (FMADD/FMSUB)
//        Dimaf (FMADD/FMSUB
//         -Diaf (FADD/FSUB/FMUL) resource conflict
//           Dimaf (FMADD/FMSUB)
//            --Dimf (FMUL) register conflict
//              -DixxxxxxxxBRxf (FDIV/FSQRT) B:clear busy, R:clear register usage
//                DE
//                 DE
//                  --------Diaf resource conflict
//                           --DE (FMV.X.W) register conflict (f-->EX)
//                              DE
//
// FADD   ID --> pipe_i --> pipe_a --> pipe_f
// FSUB   ID --> pipe_i --> pipe_a --> pipe_f
// FMUL   ID --> pipe_i --> pipe_m --> pipe_f
// FMADD  ID --> pipe_i --> pipe_m --> pipe_a --> pipe_f
// FMSUB  ID --> pipe_i --> pipe_m --> pipe_a --> pipe_f
// FNMADD ID --> pipe_i --> pipe_m --> pipe_a --> pipe_f
// FNMSUB ID --> pipe_i --> pipe_m --> pipe_a --> pipe_f
// FDIV   ID --> pipe_i --> pipe_d --> pipe_d --> ... ---> pipe_d --> pipe_f
// FSQRT  ID --> pipe_i --> pipe_s --> pipe_s --> ... ---> pipe_s --> pipe_f
// FCVTWS ID --> pipe-i --> pipe-c
// FCVTSW ID --> pipe-i --> pipe-c
//
// Pipe Control Token
//     [35:30] FRn Src1 {EN, FRn}
//     [29:24] FRn Src2 {EN, FRn}
//     [23:18] FRn Src3 {EN, FRn}
//     [17:12] FRn Dest {EN, FRn}
//     [11   ] 0
//     [10: 8] RMode
//     [ 7: 0] Command
//
//
// [ALU Timing]
// DE    (FMV.W.X)
//  Di..
//
// Diaf
//  --DE (FMV.X.W, with conflict)
//
// Dimaf
//  ---DE (FMV.X.W, with conflict)
//
// DidddddddRf
//  ---------DE (FMV.X.W, with conflict)
//
// Diaf (FPU Operation)
//  --DE (ALU Operation without forwardings from f to E due to STA issue)
//
// [FLW Timing]
//
// DEMW (FLW)
//  Diaf  (no conflict)
//  -Diaf (with conflict) controlled by pipeline.v
//
// Diaf (FADD/FSUB/FMUL)
//  DEMW
//
// Dimaf (FMADD)
//  DEMW
//
// DiddddRdddf
//  DEMW       (FLW, no conflict)
//  ------DEMW (FLW, with conflict)
//
reg  [35:0] pipe_i_token; // Input
reg  [35:0] pipe_m_token; // Mult
reg  [35:0] pipe_a_token; // Add/Sub
reg  [35:0] pipe_f_token; // Finalize
reg  [35:0] pipe_d_token; // Div
reg  [35:0] pipe_s_token; // Sqrt
reg  [35:0] pipe_c_token; // Convert

//------------------
// Busy Status
//------------------
reg  pipe_ma_busy; // FMADD/FMSUB/FNMADD/FNMSUB Busy, cleared at pipe-m (after pipe-i)
reg  pipe_dv_busy; // FDIV  Busy, cleared at last pipe-d followed by pipe-f
reg  pipe_sq_busy; // FSQRT Busy, cleared at last pipe-d followed by pipe-f
reg  pipe_cv_busy; // FCVT Busy, cleared at pipe-i before pipe-c
wire pipe_ma_busy_set;
wire pipe_ma_busy_clr;
wire pipe_dv_busy_set;
wire pipe_dv_busy_clr;
wire pipe_sq_busy_set;
wire pipe_sq_busy_clr;
wire pipe_cv_busy_set;
wire pipe_cv_busy_clr;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_ma_busy <= 1'b0;
        pipe_dv_busy <= 1'b0;
        pipe_sq_busy <= 1'b0;
        pipe_cv_busy <= 1'b0;
    end
    else 
    begin
        pipe_ma_busy <= (pipe_ma_busy_set)? 1'b1 : (pipe_ma_busy_clr)? 1'b0 : pipe_ma_busy;
        pipe_dv_busy <= (pipe_dv_busy_set)? 1'b1 : (pipe_dv_busy_clr)? 1'b0 : pipe_dv_busy;
        pipe_sq_busy <= (pipe_sq_busy_set)? 1'b1 : (pipe_sq_busy_clr)? 1'b0 : pipe_sq_busy;
        pipe_cv_busy <= (pipe_cv_busy_set)? 1'b1 : (pipe_cv_busy_clr)? 1'b0 : pipe_cv_busy;
    end
end

//----------------------------
// Register Bypassing
//----------------------------
wire fpubyp_f_i1; // pipe-f   --> pipe-i
wire fpubyp_f_i2; // pipe-f   --> pipe-i
wire fpubyp_f_i3; // pipe-f   --> pipe-i
//
assign fpubyp_f_i1 = (pipe_f_token[17   ] &  pipe_i_token[35   ])
                   & (pipe_f_token[16:12] == pipe_i_token[34:30]);
assign fpubyp_f_i2 = (pipe_f_token[17   ] &  pipe_i_token[29   ])
                   & (pipe_f_token[16:12] == pipe_i_token[28:24]);
assign fpubyp_f_i3 = (pipe_f_token[17   ] &  pipe_i_token[23   ])
                   & (pipe_f_token[16:12] == pipe_i_token[22:18]);
//
wire fpubyp_w_i1; // WB-Stage --> pipe-i
wire fpubyp_w_i2; // WB-Stage --> pipe-i
wire fpubyp_w_i3; // WB-Stage --> pipe-i
//
assign fpubyp_w_i1 = ((WB_LOAD_DST & `ALU_MSK) == `ALU_FPR) & pipe_i_token[35]
                   &  (WB_LOAD_DST[4:0] == pipe_i_token[34:30]);
assign fpubyp_w_i2 = ((WB_LOAD_DST & `ALU_MSK) == `ALU_FPR) & pipe_i_token[29]
                   &  (WB_LOAD_DST[4:0] == pipe_i_token[28:24]);
assign fpubyp_w_i3 = ((WB_LOAD_DST & `ALU_MSK) == `ALU_FPR) & pipe_i_token[23]
                   &  (WB_LOAD_DST[4:0] == pipe_i_token[22:18]);
//
//Due to Result of Static Timing Analysis, forwardings shown below are gave up.
//wire fpubyp_e_i1; // EX-Stage --> pipe-i
//wire fpubyp_e_i2; // EX-Stage --> pipe-i
//wire fpubyp_e_i3; // EX-Stage --> pipe-i
//wire fpubyp_f_e;  // pipe-f   --> EX-Stage
//
//assign fpubyp_e_i1 = ((EX_ALU_DST1 & `ALU_MSK) == `ALU_FPR) & pipe_i_token[35]
//                   &  (EX_ALU_DST1[4:0] == pipe_i_token[34:30]);
//assign fpubyp_e_i2 = ((EX_ALU_DST1 & `ALU_MSK) == `ALU_FPR) & pipe_i_token[29]
//                   &  (EX_ALU_DST1[4:0] == pipe_i_token[28:24]);
//assign fpubyp_e_i3 = ((EX_ALU_DST1 & `ALU_MSK) == `ALU_FPR) & pipe_i_token[23]
//                   &  (EX_ALU_DST1[4:0] == pipe_i_token[22:18]);
//assign fpubyp_f_e  =  pipe_f_token[17] & ((EX_ALU_DST1 & `ALU_MSK) == `ALU_GPR);

//------------
// ID-Stage
//------------
wire fpu_ack;
wire id_fpu_ope_f2f_rdy; // FPU Ready for Arithmetic Operation FRn-->FRn
wire id_fpu_mac_f2f_rdy; // FPU Ready for Multiplication and Addition FRn-->FRn
wire id_fpu_exe_f2x_rdy; // FPU Ready for 1cyc Execution FRn-->XRn 
wire id_fpu_exe_x2f_rdy; // FPU Ready for 1cyc Execution XRn-->FRn 
wire id_fpu_exe_f2f_rdy; // FPU Ready for 1cyc Execution FRn-->FRn 
wire id_fpu_cvt_f2x_rdy; // FPU Ready for Conversion FRn-->XRn 
wire id_fpu_cvt_x2f_rdy; // FPU Ready for Conversion XRn-->FRn 
wire id_fpu_flw_x2f_rdy; // FPU Ready for Floating Load XRn-->FRn 
//
assign fpu_ack = (ID_FPU_CMD == `FPU32_CMD_FADD   ) & id_fpu_ope_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSUB   ) & id_fpu_ope_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMUL   ) & id_fpu_ope_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FDIV   ) & id_fpu_ope_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSQRT  ) & id_fpu_ope_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMADD  ) & id_fpu_mac_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMSUB  ) & id_fpu_mac_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FNMADD ) & id_fpu_mac_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FNMSUB ) & id_fpu_mac_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMVWX  ) & id_fpu_exe_x2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMVXW  ) & id_fpu_exe_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FLW    ) & id_fpu_flw_x2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSW    ) & id_fpu_exe_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMIN   ) & id_fpu_exe_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FMAX   ) & id_fpu_exe_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FCVTWS ) & id_fpu_cvt_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FCVTWUS) & id_fpu_cvt_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FCVTSW ) & id_fpu_cvt_x2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FCVTSWU) & id_fpu_cvt_x2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSGNJS ) & id_fpu_exe_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSGNJNS) & id_fpu_exe_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FSGNJXS) & id_fpu_exe_f2f_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FEQ    ) & id_fpu_exe_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FLT    ) & id_fpu_exe_f2x_rdy
               | (ID_FPU_CMD == `FPU32_CMD_FLE    ) & id_fpu_exe_f2x_rdy 
               | (ID_FPU_CMD == `FPU32_CMD_FCLASS ) & id_fpu_exe_f2x_rdy;
//
assign ID_FPU_STALL = (ID_FPU_CMD == `FPU32_CMD_NOP)? 1'b0 : ~fpu_ack;
//
reg    conflict_fpu;
reg    conflict_alu;
reg    conflict_flw;
//
wire   div_complete;
wire   sqr_complete;
//
reg  [31:0] fpureg_dirty_fpu;
reg  [31:0] fpureg_dirty_alu;
reg  [31:0] fpureg_dirty_flw;
//
// FPU Ready for Arithmetic Operation FRn-->FRn
assign id_fpu_ope_f2f_rdy
    = ~(pipe_dv_busy | pipe_sq_busy | pipe_ma_busy | pipe_cv_busy | conflict_fpu);
//
// FPU Ready for Multiplication and Addition FRn-->FRn
assign id_fpu_mac_f2f_rdy 
    = ~(pipe_dv_busy | pipe_sq_busy | pipe_cv_busy | conflict_fpu);
//
// FPU Ready for 1cyc Execution FRn-->XRn 
assign id_fpu_exe_f2x_rdy 
    = ~(conflict_alu);
//
// FPU Ready for 1cyc Execution XRn-->FRn 
assign id_fpu_exe_x2f_rdy 
    = ~(conflict_fpu);
//
// FPU Ready for 1cyc Execution FRn-->FRn
assign id_fpu_exe_f2f_rdy 
    = ~(conflict_fpu);
//
// FPU Ready for Conversion FRn-->XRn 
assign id_fpu_cvt_f2x_rdy
    = ~(pipe_dv_busy | pipe_sq_busy | pipe_ma_busy | pipe_cv_busy | conflict_alu);
//
// FPU Ready for Conversion XRn-->FRn 
assign id_fpu_cvt_x2f_rdy
    = ~(pipe_dv_busy | pipe_sq_busy | pipe_ma_busy | pipe_cv_busy | conflict_fpu);
//
// FPU Ready for Floating Load XRn-->FRn 
assign id_fpu_flw_x2f_rdy
    = ~ (conflict_flw);
//
// Register Conflict
// DE (FMV.W.X)
//  Diaf
//    Diaf
//     --DE (FMV.X.W)
always @*
begin
    conflict_fpu = 1'b0;
    for (i = 0; i < 32; i = i + 1)
    begin
        begin
            conflict_fpu = conflict_fpu | (((ID_FPU_SRC1 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_SRC1[4:0] == i) & fpureg_dirty_fpu[i]);
            conflict_fpu = conflict_fpu | (((ID_FPU_SRC2 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_SRC2[4:0] == i) & fpureg_dirty_fpu[i]);
            conflict_fpu = conflict_fpu | (((ID_FPU_SRC3 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_SRC3[4:0] == i) & fpureg_dirty_fpu[i]);
            conflict_fpu = conflict_fpu | (((ID_FPU_DST1 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_DST1[4:0] == i) & fpureg_dirty_fpu[i]);
        end
    end
end
//
always @*
begin
    conflict_alu = 1'b0;
    for (i = 0; i < 32; i = i + 1)
    begin
        begin
            conflict_alu = conflict_alu | (((ID_FPU_SRC1 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_SRC1[4:0] == i) & fpureg_dirty_alu[i]);
            conflict_alu = conflict_alu | (((ID_FPU_SRC2 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_SRC2[4:0] == i) & fpureg_dirty_alu[i]);
        end
    end
end
//
// Stall for overwrite by FLW 
always @* 
begin
    conflict_flw = 1'b0;
    for (i = 0; i < 32; i = i + 1)
    begin
        begin
            conflict_flw = conflict_flw | (((ID_FPU_DST1 & `ALU_MSK) == `ALU_FPR) & (ID_FPU_DST1[4:0] == i) & fpureg_dirty_flw[i]);
        end
    end
end
//
// Busy Control
assign pipe_ma_busy_set = id_fpu_mac_f2f_rdy & (ID_FPU_CMD[7:3] == 5'b11111   ); // FMADD etc.
assign pipe_dv_busy_set = id_fpu_ope_f2f_rdy & (ID_FPU_CMD == `FPU32_CMD_FDIV );
assign pipe_sq_busy_set = id_fpu_ope_f2f_rdy & (ID_FPU_CMD == `FPU32_CMD_FSQRT);
assign pipe_cv_busy_set = id_fpu_cvt_f2x_rdy & (ID_FPU_CMD[7:1] == 7'b1100000 )
                        | id_fpu_cvt_x2f_rdy & (ID_FPU_CMD[7:1] == 7'b1101000 );
//assign pipe_ma_busy_set = id_fpu_ope_f2f_rdy & (ID_FPU_CMD[7:3] == 5'b11111   ); // FMADD etc.
//assign pipe_dv_busy_set = id_fpu_ope_f2f_rdy & (ID_FPU_CMD == `FPU32_CMD_FDIV );
//assign pipe_sq_busy_set = id_fpu_ope_f2f_rdy & (ID_FPU_CMD == `FPU32_CMD_FSQRT);
//assign pipe_cv_busy_set = id_fpu_cvt_f2x_rdy & (ID_FPU_CMD[7:1] == 7'b1100000 )
//                        | id_fpu_cvt_x2f_rdy & (ID_FPU_CMD[7:1] == 7'b1101000 );

//--------------------------------------------------
// FRx Register Usage and Conflict Control for FPU
//--------------------------------------------------
reg  [31:0] fpureg_dirty_fpu_set;
reg  [31:0] fpureg_dirty_fpu_clr;
//
reg  [ 3:0] div_seq;
wire [ 3:0] div_cnt_plus_one;
reg  [ 3:0] sqr_seq;
wire [ 3:0] sqr_cnt_plus_one;
//
// Flag Body
always @(posedge CLK, posedge RES_CPU)
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        if (RES_CPU)
            fpureg_dirty_fpu[i] <= 1'b0;
        else if (fpureg_dirty_fpu_set[i])
            fpureg_dirty_fpu[i] <= 1'b1;
        else if (fpureg_dirty_fpu_clr[i])
            fpureg_dirty_fpu[i] <= 1'b0;
    end        
end
//
// Set Conditions in Stage-ID
always @*
begin
    fpureg_dirty_fpu_set = 32'h0;
    begin
        for (i = 0; i < 32; i = i + 1)
        begin
            if (~fpu_ack)
            begin
                fpureg_dirty_fpu_set[i] = 1'b0;
            end
            else if ((ID_FPU_CMD == `FPU32_CMD_FMUL )
                   | (ID_FPU_CMD == `FPU32_CMD_FADD )
                   | (ID_FPU_CMD == `FPU32_CMD_FSUB )
                   | (ID_FPU_CMD[7:3] == 5'b11111   ) // FMADD etc.
                   | (ID_FPU_CMD == `FPU32_CMD_FDIV )
                   | (ID_FPU_CMD == `FPU32_CMD_FSQRT))
            begin
                fpureg_dirty_fpu_set[i] = (ID_FPU_DST1[4:0] == i);
            end
        end
    end
end
//
// Clear Conditions in each pipe
always @*
begin
    fpureg_dirty_fpu_clr = 32'h0;
    for (i = 0; i < 32; i = i + 1)
    begin
        // pipe-i
        if (pipe_i_token[7:0] == `FPU32_CMD_FADD)
            fpureg_dirty_fpu_clr[i] = (pipe_i_token[16:12] == i);
        else if (pipe_i_token[7:0] == `FPU32_CMD_FSUB)
            fpureg_dirty_fpu_clr[i] = (pipe_i_token[16:12] == i);
        else if (pipe_i_token[7:0] == `FPU32_CMD_FMUL)
            fpureg_dirty_fpu_clr[i] = (pipe_i_token[16:12] == i);
        // pipe-m
        else if (pipe_m_token[7:3] == 5'b11111) // FMADD etc.
            fpureg_dirty_fpu_clr[i] = (pipe_m_token[16:12] == i);
        // pipe-d
        else if ((div_seq == 4'h4) & (div_cnt_plus_one == csr_div_loop))
            fpureg_dirty_fpu_clr[i] = (pipe_d_token[16:12] == i);
        // pipe-s
        else if ((sqr_seq == 4'h6) & (sqr_cnt_plus_one == csr_sqr_loop))
            fpureg_dirty_fpu_clr[i] = (pipe_s_token[16:12] == i);
    end
end

//--------------------------------------------------
// FRx Register Usage and Conflict Control for ALU
//--------------------------------------------------
reg  [31:0] fpureg_dirty_alu_set;
reg  [31:0] fpureg_dirty_alu_clr;
//
// Flag Body
always @(posedge CLK, posedge RES_CPU)
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        if (RES_CPU)
            fpureg_dirty_alu[i] <= 1'b0;
        else if (fpureg_dirty_alu_set[i])
            fpureg_dirty_alu[i] <= 1'b1;
        else if (fpureg_dirty_alu_clr[i])
            fpureg_dirty_alu[i] <= 1'b0;
    end        
end
//
// Set Conditions in Stage-ID
always @*
begin
    fpureg_dirty_alu_set = 32'h0;
    begin
        for (i = 0; i < 32; i = i + 1)
        begin
            if (~fpu_ack)
            begin
                fpureg_dirty_alu_set[i] = 1'b0;
            end
            else if ((ID_FPU_CMD == `FPU32_CMD_FMUL)
                   | (ID_FPU_CMD == `FPU32_CMD_FADD)
                   | (ID_FPU_CMD == `FPU32_CMD_FSUB)
                   | (ID_FPU_CMD[7:3] == 5'b11111) // FMADD etc.
                   | (ID_FPU_CMD == `FPU32_CMD_FDIV)
                   | (ID_FPU_CMD == `FPU32_CMD_FSQRT))
            begin
                fpureg_dirty_alu_set[i] = (ID_FPU_DST1[4:0] == i);
            end
        end    
    end
end
//
// Clear Conditions in each pipe
//    Diaf
//     --DE (no forwardings from f to E due to STA issue)
always @*
begin
    fpureg_dirty_alu_clr = 32'h0;
    for (i = 0; i < 32; i = i + 1)
    begin
        // pipe-m
        if (pipe_m_token[7:0] == `FPU32_CMD_FMUL)
            fpureg_dirty_alu_clr[i] = (pipe_m_token[16:12] == i);
        // pipe-a
        else if (pipe_a_token[7:0] == `FPU32_CMD_FADD)
            fpureg_dirty_alu_clr[i] = (pipe_a_token[16:12] == i);
        else if (pipe_a_token[7:0] == `FPU32_CMD_FSUB)
            fpureg_dirty_alu_clr[i] = (pipe_a_token[16:12] == i);
        else if (pipe_a_token[7:3] == 5'b11111) // FMADD etc.
            fpureg_dirty_alu_clr[i] = (pipe_a_token[16:12] == i);
        // pipe-d
        else if (div_complete)
            fpureg_dirty_alu_clr[i] = (pipe_d_token[16:12] == i);
        // pipe-s
        else if (sqr_complete)
            fpureg_dirty_alu_clr[i] = (pipe_s_token[16:12] == i);
    end
end

//--------------------------------------------------
// FRx Register Usage and Conflict Control for FLW
//--------------------------------------------------
reg  [31:0] fpureg_dirty_flw_set;
reg  [31:0] fpureg_dirty_flw_clr;
//
// Flag Body
always @(posedge CLK, posedge RES_CPU)
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        if (RES_CPU)
            fpureg_dirty_flw[i] <= 1'b0;
        else if (fpureg_dirty_flw_set[i])
            fpureg_dirty_flw[i] <= 1'b1;
        else if (fpureg_dirty_flw_clr[i])
            fpureg_dirty_flw[i] <= 1'b0;
    end        
end
//
// Set Conditions in Stage-ID
always @*
begin
    fpureg_dirty_flw_set = 32'h0;
    begin
        for (i = 0; i < 32; i = i + 1)
        begin
            if (~fpu_ack)
                fpureg_dirty_flw_set[i] = 1'b0;
            else if (ID_FPU_CMD == `FPU32_CMD_FDIV)
                fpureg_dirty_flw_set[i] = (ID_FPU_DST1[4:0] == i);
            else if (ID_FPU_CMD == `FPU32_CMD_FSQRT)
                fpureg_dirty_flw_set[i] = (ID_FPU_DST1[4:0] == i);
        end    
    end
end
//
// Clear Conditions in each pipe
// DiddddRdddf
//  DEMW       (FLW, no conflict)
//  ------DEMW (FLW, with conflict) : Stall overwrite by FLW
always @*
begin
    fpureg_dirty_flw_clr = 32'h0;
    for (i = 0; i < 32; i = i + 1)
    begin
        // pipe-d
        if ((div_seq == 4'h4) & (div_cnt_plus_one == 4'h1) & (csr_div_loop == 4'h1)) // extra 1cyc
            fpureg_dirty_flw_clr[i] = (pipe_d_token[16:12] == i);
        else if ((div_seq == 4'h4) & (div_cnt_plus_one == csr_div_loop))
            fpureg_dirty_flw_clr[i] = (pipe_d_token[16:12] == i);
        // pipe-s
        else if ((sqr_seq == 4'h4) & (sqr_cnt_plus_one == 4'h1) & (csr_sqr_loop == 4'h1)) // extra 1cyc
            fpureg_dirty_flw_clr[i] = (pipe_s_token[16:12] == i);
        else if ((sqr_seq == 4'h4) & (sqr_cnt_plus_one == csr_sqr_loop))
            fpureg_dirty_flw_clr[i] = (pipe_s_token[16:12] == i);
    end
end

//--------------------------------------------------
// FPU CSR Usage and Conflict Control for ZICSR
//--------------------------------------------------
reg  fpucsr_dirty_set;
reg  fpucsr_dirty_clr;
//
// FPU CSR Dirty Flag
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        FPUCSR_DIRTY <= 1'b0;
    else if (fpucsr_dirty_set)
        FPUCSR_DIRTY <= 1'b1;
    else if (fpucsr_dirty_clr)
        FPUCSR_DIRTY <= 1'b0;
end
//
// FPU CSR Dirty Set in Stage-ID
always @*
begin
    fpucsr_dirty_set = 1'b0;
    begin
        if (~fpu_ack)
        begin
            fpucsr_dirty_set = 1'b0;
        end
        else if ((ID_FPU_CMD == `FPU32_CMD_FMUL   )
               | (ID_FPU_CMD == `FPU32_CMD_FADD   )
               | (ID_FPU_CMD == `FPU32_CMD_FSUB   )
               | (ID_FPU_CMD[7:3] == 5'b11111     ) // FMADD etc.
               | (ID_FPU_CMD == `FPU32_CMD_FDIV   )
               | (ID_FPU_CMD == `FPU32_CMD_FSQRT  )
               | (ID_FPU_CMD == `FPU32_CMD_FCVTWS )
               | (ID_FPU_CMD == `FPU32_CMD_FCVTWUS)
               | (ID_FPU_CMD == `FPU32_CMD_FCVTSW )
               | (ID_FPU_CMD == `FPU32_CMD_FCVTSWU))
        begin
            fpucsr_dirty_set = 1'b1;
        end
    end
end
//
// FPU CSR Dirty Clear in Stage-ID
always @*
begin
    fpucsr_dirty_clr = 1'b0;
    begin
        if (pipe_f_token[7:0] != `FPU32_CMD_NOP)
            fpucsr_dirty_clr = 1'b1;
        else if (pipe_c_token[7:0] != `FPU32_CMD_NOP)
            fpucsr_dirty_clr = 1'b1;
    end
end

//-----------------
// pipe-i (initial)
//-----------------
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_i_token <= 36'h0;
        imode <= 3'b000;
        
    end
    else if (fpu_ack)
    begin
        pipe_i_token <= {((ID_FPU_SRC1 & `ALU_MSK) == `ALU_FPR), ID_FPU_SRC1[4:0],
                         ((ID_FPU_SRC2 & `ALU_MSK) == `ALU_FPR), ID_FPU_SRC2[4:0],
                         ((ID_FPU_SRC3 & `ALU_MSK) == `ALU_FPR), ID_FPU_SRC3[4:0],
                         ((ID_FPU_DST1 & `ALU_MSK) == `ALU_FPR), ID_FPU_DST1[4:0],
                         1'b0,
                         ID_FPU_RMODE[2:0],
                         ID_FPU_CMD  [7:0]};
        imode <= ((ID_FPU_RMODE[2:0] == `FPU32_RMODE_DYN)
               && (csr_frm == `FPU32_RMODE_DYN          ))? `FPU32_RMODE_RNE
               : (ID_FPU_RMODE[2:0] == `FPU32_RMODE_DYN  )?  csr_frm
               : ID_FPU_RMODE[2:0];
    end
    else
    begin
        pipe_i_token <= 36'h0;
        imode <= 3'b000;
    end
end
//
// Source Data with Forwarding
assign idata_float_in1 = (fpubyp_f_i1     )? fdata_float_out
                       : (fpubyp_w_i1     )? WB_FPU_LD_DATA
                       : (pipe_i_token[35])? regFR[pipe_i_token[34:30]]
                       : 32'h0;
assign idata_float_in2 = (fpubyp_f_i2     )? fdata_float_out
                       : (fpubyp_w_i2     )? WB_FPU_LD_DATA
                       : (pipe_i_token[29])? regFR[pipe_i_token[28:24]]
                       : 32'h0;
assign idata_float_in3 = (fpubyp_f_i3     )? fdata_float_out
                       : (fpubyp_w_i3     )? WB_FPU_LD_DATA
                       : (pipe_i_token[23])? regFR[pipe_i_token[22:18]]
                       : 32'h0;
//
// Busy Control
assign pipe_ma_busy_clr = (pipe_i_token[7:3] == 5'b11111  ); // FMADD etc.
assign pipe_cv_busy_clr = (pipe_i_token[7:1] == 7'b1100000)  // FCVT.W.S/FCVT.WU.S
                        | (pipe_i_token[7:1] == 7'b1101000); // FCVT.S.W/FCVT.S.WU
//
// Handle Specal Number
assign mspecial_float_in1 = idata_float_in1;
assign mspecial_float_in2 = idata_float_in2;
assign mspecial_rmode     = imode;
assign mspecial_flg_in    = `FPU32_FLAG_OK;
//
assign aspecial_float_in1 = idata_float_in1;
assign aspecial_float_in2 = (pipe_i_token[7:0] == `FPU32_CMD_FSUB)? idata_float_in2 ^ 32'h80000000
                          : idata_float_in2;
assign aspecial_rmode     = imode;
assign aspecial_flg_in    = `FPU32_FLAG_OK;
//
assign maspecial_float_in1 = idata_float_in1;
assign maspecial_float_in2 = idata_float_in2;
assign maspecial_float_in3 = (pipe_i_token[7:0] == `FPU32_CMD_FMSUB )? idata_float_in3 ^ 32'h80000000
                           : (pipe_i_token[7:0] == `FPU32_CMD_FNMSUB)? idata_float_in3 ^ 32'h80000000
                           : idata_float_in3;
assign maspecial_negate    = (pipe_i_token[7:0] == `FPU32_CMD_FNMADD)
                           | (pipe_i_token[7:0] == `FPU32_CMD_FNMSUB);
assign maspecial_rmode     = imode;
assign maspecial_flg_in    = `FPU32_FLAG_OK;
//
assign dspecial_float_in1 = idata_float_in1;
assign dspecial_float_in2 = idata_float_in2;
assign dspecial_rmode     = imode;
assign dspecial_flg_in    = `FPU32_FLAG_OK;
//
assign sspecial_float_in1 = idata_float_in1;
assign sspecial_rmode     = imode;
assign sspecial_flg_in    = `FPU32_FLAG_OK;

//--------------------------------------------------
// FPU Execution in pipe-i, destination is FRn
//--------------------------------------------------
wire        pipe_i_cmd_fmin;
wire        pipe_i_cmd_fmax;
wire        pipe_i_cmd_fsgnjs;
wire        pipe_i_cmd_fsgnjns;
wire        pipe_i_cmd_fsgnjxs;
wire        pipe_i_fr_dst;
reg  [31:0] pipe_i_fr_dst_data;
wire        idata_float_in1_nan;
wire        idata_float_in2_nan;
wire        idata_float_in1_snan;
wire        idata_float_in2_snan;
//
assign pipe_i_cmd_fmin    = (pipe_i_token[7:0] == `FPU32_CMD_FMIN   );
assign pipe_i_cmd_fmax    = (pipe_i_token[7:0] == `FPU32_CMD_FMAX   );
assign pipe_i_cmd_fsgnjs  = (pipe_i_token[7:0] == `FPU32_CMD_FSGNJS );
assign pipe_i_cmd_fsgnjns = (pipe_i_token[7:0] == `FPU32_CMD_FSGNJNS);
assign pipe_i_cmd_fsgnjxs = (pipe_i_token[7:0] == `FPU32_CMD_FSGNJXS);
//
assign pipe_i_fr_dst = (pipe_i_token[7:0] == `FPU32_CMD_FMVWX)
                     | pipe_i_cmd_fmin | pipe_i_cmd_fmax
                     | pipe_i_cmd_fsgnjs | pipe_i_cmd_fsgnjns | pipe_i_cmd_fsgnjxs;
//
assign idata_float_in1_nan = (idata_float_in1[30:23] == 8'hff) & (idata_float_in1[22:0] != 23'h0);
assign idata_float_in2_nan = (idata_float_in2[30:23] == 8'hff) & (idata_float_in2[22:0] != 23'h0);
assign idata_float_in1_snan = idata_float_in1_nan & ~idata_float_in1[22];
assign idata_float_in2_snan = idata_float_in2_nan & ~idata_float_in2[22];
//
always @*
begin
    pipe_i_fr_dst_data = 32'h00000000;
    //------------------------------------------------
    // FMV.W.X
    //------------------------------------------------
    if (pipe_i_token[7:0] == `FPU32_CMD_FMVWX)
    begin
        pipe_i_fr_dst_data = EX_FPU_DSTDATA;
    end
    //------------------------------------------------
    // FMIN/FMAX
    //------------------------------------------------
    else if (pipe_i_cmd_fmin | pipe_i_cmd_fmax)
    begin
        if (idata_float_in1_nan & idata_float_in2_nan)
            pipe_i_fr_dst_data = 32'h7fc00000;
        else if (idata_float_in1_nan)
            pipe_i_fr_dst_data = idata_float_in2;
        else if (idata_float_in2_nan)
            pipe_i_fr_dst_data = idata_float_in1;
        else if ((idata_float_in1[31] == 1'b0) & (idata_float_in2[31] == 1'b1)) 
            pipe_i_fr_dst_data
            = (pipe_i_cmd_fmin)? idata_float_in2 : idata_float_in1;
        else if ((idata_float_in1[31] == 1'b1) & (idata_float_in2[31] == 1'b0)) 
            pipe_i_fr_dst_data
            = (pipe_i_cmd_fmin)? idata_float_in1 : idata_float_in2;
        else if ((idata_float_in1[31] == 1'b0) & (idata_float_in2[31] == 1'b0)) 
            pipe_i_fr_dst_data
            = (idata_float_in1[30:0] < idata_float_in2[30:0])?
                  ((pipe_i_cmd_fmin)? idata_float_in1 : idata_float_in2)
                : ((pipe_i_cmd_fmin)? idata_float_in2 : idata_float_in1);
        else if ((idata_float_in1[31] == 1'b1) & (idata_float_in2[31] == 1'b1)) 
            pipe_i_fr_dst_data
            = (idata_float_in1[30:0] < idata_float_in2[30:0])?
                  ((pipe_i_cmd_fmin)? idata_float_in2 : idata_float_in1)
                : ((pipe_i_cmd_fmin)? idata_float_in1 : idata_float_in2);
    end
    //------------------------------------------------
    // FSGNJ.S/FSGNJN.S/FSGNJX.S
    //------------------------------------------------
    else if (pipe_i_cmd_fsgnjs)
    begin
        pipe_i_fr_dst_data = {idata_float_in2[31], idata_float_in1[30:0]};
    end
    else if (pipe_i_cmd_fsgnjns)
    begin
        pipe_i_fr_dst_data = {~idata_float_in2[31], idata_float_in1[30:0]};
    end
    else if (pipe_i_cmd_fsgnjxs)
    begin
        pipe_i_fr_dst_data = {idata_float_in1[31] ^ idata_float_in2[31], idata_float_in1[30:0]};
    end 
end

//-----------------------------------------------
// FPU Execution in pipe-i/c, destination is XRn
//-----------------------------------------------
wire        pipe_i_cmd_feq;
wire        pipe_i_cmd_flt;
wire        pipe_i_cmd_fle;
wire        pipe_i_cmd_fclass;
//
wire [31:0] pipe_i_float_src1;
wire [31:0] pipe_i_float_src2;
wire        pipe_i_float_src1_nan;
wire        pipe_i_float_src2_nan;
//
reg  [31:0] pipe_c_int_out;
//
assign pipe_i_cmd_feq    = (pipe_i_token[7:0] == `FPU32_CMD_FEQ   );
assign pipe_i_cmd_flt    = (pipe_i_token[7:0] == `FPU32_CMD_FLT   );
assign pipe_i_cmd_fle    = (pipe_i_token[7:0] == `FPU32_CMD_FLE   );
assign pipe_i_cmd_fclass = (pipe_i_token[7:0] == `FPU32_CMD_FCLASS);
//
//assign pipe_i_float_src1 = (pipe_i_token[35])? regFR[pipe_i_token[34:30]] : 32'h0;
//assign pipe_i_float_src2 = (pipe_i_token[29])? regFR[pipe_i_token[28:24]] : 32'h0;
assign pipe_i_float_src1 = idata_float_in1;
assign pipe_i_float_src2 = idata_float_in2;
//
assign pipe_i_float_src1_nan = (pipe_i_float_src1[30:23] == 8'hff) & (pipe_i_float_src1[22:0] != 23'h0);
assign pipe_i_float_src2_nan = (pipe_i_float_src2[30:23] == 8'hff) & (pipe_i_float_src2[22:0] != 23'h0);
//
assign chk_ftype_float_in = (pipe_i_cmd_fclass)? pipe_i_float_src1 : 32'h00000000;
//
reg        ex_fpu_srcdata_update;
reg [31:0] ex_fpu_srcdata_root;
reg [31:0] ex_fpu_srcdata_keep;
//
always @*
begin
    ex_fpu_srcdata_root        = 32'h00000000;
    ex_fpu_srcdata_update      = 1'b0;
    //--------------------------------------
    // FMV.X.W
    //--------------------------------------
    if ((pipe_i_token[7:0] == `FPU32_CMD_FMVXW  ) & ((EX_ALU_SRC1 & `ALU_MSK) == `ALU_FPR))
    begin
      //ex_fpu_srcdata_root   = regFR[EX_ALU_SRC1[4:0]];
        ex_fpu_srcdata_root   = idata_float_in1;
        ex_fpu_srcdata_update = 1'b1;
    end
    //--------------------------------------
    // FEQ.S/FLT.S/FLE.S
    //--------------------------------------
    else if (pipe_i_cmd_feq)
    begin
        ex_fpu_srcdata_root = (pipe_i_float_src1_nan)? 32'h00000000
                            : (pipe_i_float_src2_nan)? 32'h00000000
                            : (pipe_i_float_src1 == pipe_i_float_src2)? 32'h00000001
                            : 32'h00000000;
        ex_fpu_srcdata_update = 1'b1;
    end
    else if (pipe_i_cmd_flt)
    begin
        ex_fpu_srcdata_root = (pipe_i_float_src1_nan)? 32'h00000000
                            : (pipe_i_float_src2_nan)? 32'h00000000
                            : ( pipe_i_float_src1[31] & ~pipe_i_float_src2[31])? 32'h00000001
                            : (~pipe_i_float_src1[31] &  pipe_i_float_src2[31])? 32'h00000000
                            : (~pipe_i_float_src1[31] & ~pipe_i_float_src2[31])? 
                                ((pipe_i_float_src1 < pipe_i_float_src2) ? 32'h00000001 : 32'h00000000)
                            : ( pipe_i_float_src1[31] &  pipe_i_float_src2[31])? 
                                ((pipe_i_float_src1 > pipe_i_float_src2) ? 32'h00000001 : 32'h00000000)                        
                            : 32'h00000000;
        ex_fpu_srcdata_update = 1'b1;
    end
    else if (pipe_i_cmd_fle)
    begin
        ex_fpu_srcdata_root = (pipe_i_float_src1_nan)? 32'h00000000
                            : (pipe_i_float_src2_nan)? 32'h00000000
                            : ( pipe_i_float_src1[31] & ~pipe_i_float_src2[31])? 32'h00000001
                            : (~pipe_i_float_src1[31] &  pipe_i_float_src2[31])? 32'h00000000
                            : (~pipe_i_float_src1[31] & ~pipe_i_float_src2[31])? 
                                ((pipe_i_float_src1 <= pipe_i_float_src2) ? 32'h00000001 : 32'h00000000)
                            : ( pipe_i_float_src1[31] &  pipe_i_float_src2[31])? 
                                ((pipe_i_float_src1 >= pipe_i_float_src2) ? 32'h00000001 : 32'h00000000)                        
                            : 32'h00000000;
        ex_fpu_srcdata_update = 1'b1;
    end
    //--------------------------------------
    // FCLASS.S
    //--------------------------------------
    else if (pipe_i_cmd_fclass)
    begin
        ex_fpu_srcdata_root = (chk_ftype_out == `FPU32_FT_NEGQNA)? 32'h00000001 << `FPU32_FT_POSQNA
                            : (chk_ftype_out == `FPU32_FT_NEGSNA)? 32'h00000001 << `FPU32_FT_POSSNA
                            : 32'h00000001 << chk_ftype_out;
        ex_fpu_srcdata_update = 1'b1;
    end
    //--------------------------------------
    // FCVT.W.S/FCVT.WU.S
    //--------------------------------------
    else if ((pipe_c_token[7:1] == 7'b1100000) & ((EX_ALU_SRC1 & `ALU_MSK) == `ALU_FPR)) // FCVT.W.S/FCVT.WU.S
  //else if ((EX_ALU_SRC1 & `ALU_MSK) == `ALU_FPR)
    begin
        ex_fpu_srcdata_root   = pipe_c_int_out;
        ex_fpu_srcdata_update = 1'b1;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        ex_fpu_srcdata_keep <= 32'b00000000;
    else if (ex_fpu_srcdata_update)
        ex_fpu_srcdata_keep <= ex_fpu_srcdata_root;
end
//
assign EX_FPU_SRCDATA = ex_fpu_srcdata_keep;
//  = (ex_fpu_srcdata_update)? ex_fpu_srcdata_root : ex_fpu_srcdata_keep;
//
//always @*
//begin
//    EX_FPU_ST_DATA = 32'h00000000;
//    //--------------------------------------
//    // FSW
//    //--------------------------------------
//    if ((EX_STSRC & `ALU_MSK) == `ALU_FPR)
//        EX_FPU_ST_DATA = regFR[EX_STSRC[4:0]];
//end
//
//--------------------------------------
// FSW
//--------------------------------------
assign EX_FPU_ST_DATA = regFR[EX_STSRC[4:0]];

//-----------------------------------------------
// FPU Execution sets Flags
//-----------------------------------------------
reg         pipe_i_fflags_set;
reg  [ 4:0] pipe_i_fflags_data;
//
always @*
begin
    pipe_i_fflags_set  = 1'b0;
    pipe_i_fflags_data = `FPU32_FLAG_OK;
    //------------------------------------------------
    // FMIN/FMAX Flags
    //------------------------------------------------
    if ((pipe_i_cmd_fmin | pipe_i_cmd_fmax) & (idata_float_in1_snan | idata_float_in2_snan))
    begin
        pipe_i_fflags_set  = 1'b1;
        pipe_i_fflags_data = `FPU32_FLAG_NV;
    end
    //--------------------------------------
    // FEQ.S/FLT.S/FLE.S
    //--------------------------------------
    else if (pipe_i_cmd_feq & (idata_float_in1_snan | idata_float_in2_snan))
    begin
        pipe_i_fflags_set  = 1'b1;
        pipe_i_fflags_data = `FPU32_FLAG_NV;
    end
    else if (pipe_i_cmd_flt & (idata_float_in1_nan | idata_float_in2_nan))
    begin
        pipe_i_fflags_set  = 1'b1;
        pipe_i_fflags_data = `FPU32_FLAG_NV;
    end
    else if (pipe_i_cmd_fle & (idata_float_in1_nan | idata_float_in2_nan))
    begin
        pipe_i_fflags_set  = 1'b1;
        pipe_i_fflags_data = `FPU32_FLAG_NV;
    end
end

//-----------------------------------
// Floating Point Registers FRn
//-----------------------------------
// [Note] 
// DEMW   FLW
//  -DEM  FSW
// forwarding from W to E is handled in datapath.v
//
wire [31:0] fdata_float_out_final;
//
always @(posedge CLK, posedge RES_CPU)
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        if (RES_CPU)
            regFR[i] <= 32'h00000000;
        else
        begin
            if (DBGABS_FPR_REQ & DBGABS_FPR_WRITE & (DBGABS_FPR_ADDR[4:0] == i))
                regFR[i] <= DBGABS_FPR_WDATA;
            else if (((WB_LOAD_DST & `ALU_MSK) == `ALU_FPR) & (WB_LOAD_DST[4:0] == i))
                regFR[i] <= WB_FPU_LD_DATA; // Writing Conflict Priority FPU < WB        
            else if (pipe_i_fr_dst & (pipe_i_token[16:12] == i))
                regFR[i] <= pipe_i_fr_dst_data;
            else if (pipe_f_token[17] & (pipe_f_token[16:12] == i))
                regFR[i] <= fdata_float_out_final;
            else if ((pipe_c_token[7:1] == 7'b1101000) & (pipe_c_token[16:12] == i))
                regFR[i] <= fcvt_i2f_float_out;
        end
    end
end
//
// Set MSTATUS FS Field as Dirty
assign SET_MSTATUS_FS_DIRTY
    = (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FRM))
    | (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FRM))
    | (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FCSR))
    | (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FCSR))
    | (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FFLAGS))
    | (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FFLAGS))
    | (CSR_FPU_DBG_REQ & CSR_FPU_DBG_WRITE & (CSR_FPU_DBG_ADDR == `CSR_FPU32CONV))
    | (CSR_FPU_CPU_REQ & CSR_FPU_CPU_WRITE & (CSR_FPU_CPU_ADDR == `CSR_FPU32CONV))
    | (DBGABS_FPR_REQ & DBGABS_FPR_WRITE)
    | ((WB_LOAD_DST & `ALU_MSK) == `ALU_FPR)
    | (pipe_i_fr_dst)
    | (pipe_f_token[17])
    | (pipe_c_token[7:1] == 7'b1101000);

//------------------------------------
// pipe-c (conversion float b/w int)
//------------------------------------
reg  [ 4:0] pipe_c_fflags_data;
//
assign fcvt_f2i_float_in   = (pipe_i_token[7:1] == 7'b1100000)? idata_float_in1  : 32'h00000000;
assign fcvt_f2i_signed     = (pipe_i_token[7:1] == 7'b1100000)? ~pipe_i_token[0] : 1'b0;
assign fcvt_f2i_rmode      = (pipe_i_token[7:1] == 7'b1100000)? imode : 3'b000;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_c_token       <= 36'h0;
        //
        pipe_c_int_out     <= 32'h0;
        pipe_c_fflags_data <= 3'b000;
        //
        fcvt_i2f_int_in    <= 32'h00000000;
        fcvt_i2f_signed    <= 1'b0;
        fcvt_i2f_rmode     <= 3'b000;
    end
    else if (pipe_i_token[7:1] == 7'b1100000) // FCVT.W.S/FCVT.WU.S
    begin
        pipe_c_token       <= pipe_i_token;
        //
        pipe_c_int_out     <= fcvt_f2i_int_out;
        pipe_c_fflags_data <= fcvt_f2i_flg_out;    
    end
    else if (pipe_i_token[7:1] == 7'b1101000) // FCVT.S.W/FCVT.S.WU
    begin
        pipe_c_token    <= pipe_i_token;
        //
        fcvt_i2f_int_in <= EX_FPU_DSTDATA;
        fcvt_i2f_signed <= ~pipe_i_token[0];
        fcvt_i2f_rmode  <= imode;
    end
    else
    begin
        pipe_c_token       <= 36'h0;
        //
      //pipe_c_int_out     <= 32'h0;
      //pipe_c_fflags_data <= 3'b000;
        //
      //fcvt_i2f_int_in    <= 32'h00000000;
      //fcvt_i2f_signed    <= 1'b0;
      //fcvt_i2f_rmode     <= 3'b000;
    end
end

//-------------------------
// pipe-m (multiplication)
//-------------------------
reg [ 1:0] pipe_m_special;
reg [31:0] pipe_m_special_data;
reg [ 4:0] pipe_m_special_flag;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_m_token    <= 36'h0;
        mdata_inner_in1 <= 79'h0;
        mdata_inner_in2 <= 79'h0;
        mdata_inner_in3 <= 79'h0;
        mmode    <= 3'b000;
        mflag_in <= 5'b00000;
        //
        pipe_m_special      <= 2'b00;
        pipe_m_special_data <= 32'h00000000;
        pipe_m_special_flag <= 5'b00000;
    end
    else if (pipe_i_token[7:0] == `FPU32_CMD_FMUL)
    begin
        pipe_m_token    <= pipe_i_token;
        mdata_inner_in1 <= idata_inner_out1;
        mdata_inner_in2 <= idata_inner_out2;
        mdata_inner_in3 <= 79'h0;
        mmode    <= imode;
        mflag_in <= `FPU32_FLAG_OK;
        //
        pipe_m_special      <= {mspecial_special, mspecial_special};
        pipe_m_special_data <= mspecial_float_out;
        pipe_m_special_flag <= mspecial_flg_out;
    end
    else if (pipe_i_token[7:3] == 5'b11111) // FMADD etc.
    begin
        pipe_m_token    <= pipe_i_token;
        mdata_inner_in1 <= idata_inner_out1;
        mdata_inner_in2 <= idata_inner_out2;
        mdata_inner_in3 <= idata_inner_out3;
        mmode    <= imode;
        mflag_in <= `FPU32_FLAG_OK;
        //
        pipe_m_special      <= maspecial_special;
        pipe_m_special_data <= maspecial_float_out;
        pipe_m_special_flag <= maspecial_flg_out;
    end
    else
    begin
        pipe_m_token    <= 36'h0;
      //mdata_inner_in1 <= 79'h0;
      //mdata_inner_in2 <= 79'h0;
      //mdata_inner_in3 <= 79'h0;
      //mmode    <= 3'b000;
      //mflag_in <= 5'b00000;
        //
        pipe_m_special      <= 2'b00;
      //pipe_m_special_data <= 32'h00000000;
      //pipe_m_special_flag <= 5'b00000;
    end
end

//---------------------
// pipe-a (addition)
//---------------------
reg [ 1:0] pipe_a_special;
reg [31:0] pipe_a_special_data;
reg [ 4:0] pipe_a_special_flag;
reg [78:0] adata_inner_out2; // IN1 x IN2
reg [ 4:0] aflag_out2;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_a_token    <= 36'h0;
        adata_inner_in1 <= 79'h0;
        adata_inner_in2 <= 79'h0;
        amode    <= 3'b000;
        aflag_in <= 5'b00000;
        //
        pipe_a_special      <= 2'b00;
        pipe_a_special_data <= 32'h00000000;
        pipe_a_special_flag <= 5'b00000;
        adata_inner_out2    <= 79'h0;
        aflag_out2          <= 5'b00000;
    end
    else if (pipe_m_token[7:0] == `FPU32_CMD_FMADD)
    begin
        pipe_a_token    <= pipe_m_token;
        adata_inner_in1 <= mdata_inner_out;
        adata_inner_in2 <= mdata_inner_in3;
        amode    <= mmode;
        aflag_in <= mflag_out;
        //
        pipe_a_special      <= pipe_m_special;
        pipe_a_special_data <= pipe_m_special_data;
        pipe_a_special_flag <= pipe_m_special_flag;
        adata_inner_out2    <= mdata_inner_out;
        aflag_out2          <= pipe_m_special_flag;
    end
    else if (pipe_m_token[7:0] == `FPU32_CMD_FMSUB)
    begin
        pipe_a_token    <= pipe_m_token;
        adata_inner_in1 <= mdata_inner_out;
        adata_inner_in2 <= {~mdata_inner_in3[78], mdata_inner_in3[77:0]};
        amode    <= mmode;
        aflag_in <= mflag_out;
        //
        pipe_a_special      <= pipe_m_special;
        pipe_a_special_data <= pipe_m_special_data;
        pipe_a_special_flag <= pipe_m_special_flag;
        adata_inner_out2    <= mdata_inner_out;
        aflag_out2          <= pipe_m_special_flag;
    end
    else if (pipe_m_token[7:0] == `FPU32_CMD_FNMADD)
    begin
        pipe_a_token    <= pipe_m_token;
        adata_inner_in1 <= {~mdata_inner_out[78], mdata_inner_out[77:0]};
        adata_inner_in2 <= {~mdata_inner_in3[78], mdata_inner_in3[77:0]};
        amode    <= mmode;
        aflag_in <= mflag_out;
        //
        pipe_a_special      <= pipe_m_special;
        pipe_a_special_data <= pipe_m_special_data;
        pipe_a_special_flag <= pipe_m_special_flag;
        adata_inner_out2    <= {~mdata_inner_out[78], mdata_inner_out[77:0]};
        aflag_out2          <= pipe_m_special_flag;
    end
    else if (pipe_m_token[7:0] == `FPU32_CMD_FNMSUB)
    begin
        pipe_a_token    <= pipe_m_token;
        adata_inner_in1 <= {~mdata_inner_out[78], mdata_inner_out[77:0]};
        adata_inner_in2 <= mdata_inner_in3;
        amode    <= mmode;
        aflag_in <= mflag_out;
        //
        pipe_a_special      <= pipe_m_special;
        pipe_a_special_data <= pipe_m_special_data;
        pipe_a_special_flag <= pipe_m_special_flag;
        adata_inner_out2    <= {~mdata_inner_out[78], mdata_inner_out[77:0]};
        aflag_out2          <= pipe_m_special_flag;
    end
    else if (pipe_i_token[7:0] == `FPU32_CMD_FADD)
    begin
        pipe_a_token    <= pipe_i_token;
        adata_inner_in1 <= idata_inner_out1;
        adata_inner_in2 <= idata_inner_out2;
        amode    <= imode;
        aflag_in <= `FPU32_FLAG_OK;
        //
        pipe_a_special      <= {aspecial_special, aspecial_special};
        pipe_a_special_data <= aspecial_float_out;
        pipe_a_special_flag <= aspecial_flg_out;
        adata_inner_out2    <= 79'h0;
        aflag_out2          <= aspecial_flg_out;
    end
    else if (pipe_i_token[7:0] == `FPU32_CMD_FSUB)
    begin
        pipe_a_token    <= pipe_i_token;
        adata_inner_in1 <= idata_inner_out1;
        adata_inner_in2 <= {~idata_inner_out2[78], idata_inner_out2[77:0]};
        amode    <= imode;
        aflag_in <= `FPU32_FLAG_OK;
        //
        pipe_a_special      <= {aspecial_special, aspecial_special};
        pipe_a_special_data <= aspecial_float_out;
        pipe_a_special_flag <= aspecial_flg_out;
        adata_inner_out2    <= 79'h0;
        aflag_out2          <= aspecial_flg_out;
    end
    else
    begin
        pipe_a_token    <= 36'h0;
      //adata_inner_in1 <= 79'h0;
      //adata_inner_in2 <= 79'h0;
      //amode    <= 3'b000;
      //aflag_in <= 5'b00000;
        //
        pipe_a_special      <= 2'b00;
      //pipe_a_special_data <= 32'h00000000;
      //pipe_a_special_flag <= 5'b00000;
      //adata_inner_out2    <= 79'h0;
      //aflag_out2          <= 5'b00000;
    end
end

//-------------------
// pipe-d (division)
//-------------------
// Goldschmidt's Algorithm
// Keep Exponent
//     a_expo_keep = a_expo
//     b_expo_keep = b_expo
//     a_expo = 1023; // a_expo = (a_expo -1023) - (a_expo - 1023) + 1023
//     b_expo = 1023; // b_expo = (b_expo -1023) - (b_expo - 1023) + 1023
// a = fin1
// b = fin2
// y = 1.4571 - b / 2
// q = a * y
// e = 1 - b * y
// repeat
//     q = q * e + q
//     e = e * e
// Revert Exponent
//     q_expo = (q_expo - 1023) + (a_expo_keep - 1023) - (b_expo_keep - 1023) + 1023
//
reg  [ 3:0] div_cnt;
reg         div_da_sign_keep;
reg         div_db_sign_keep;
reg  [11:0] div_da_expo_keep;
reg  [11:0] div_db_expo_keep;
reg  [78:0] div_da_inner;
reg  [78:0] div_db_inner;
reg  [78:0] div_dy_inner;
reg  [78:0] div_dq_inner;
reg  [78:0] div_de_inner;
//
reg  [ 1:0] pipe_d_special;
reg  [31:0] pipe_d_special_data;
reg  [ 4:0] pipe_d_special_flag;
//
assign div_cnt_plus_one = div_cnt + 4'h1;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_d_token <= 36'h0;
        //
        div_seq <= 4'h0;
        div_cnt <= 4'h0;
        div_sel <= 1'b0;
        //
        div_da_sign_keep <= 1'b0;
        div_db_sign_keep <= 1'b0;
        div_da_expo_keep <= 12'h000;
        div_db_expo_keep <= 12'h000;
        //
        div_da_inner <= 79'h0;
        div_db_inner <= 79'h0;
        div_dy_inner <= 79'h0;
        div_dq_inner <= 79'h0;
        div_de_inner <= 79'h0;
        //
        div_mdata_inner_in1 <= 79'h0;
        div_mdata_inner_in2 <= 79'h0;
        div_adata_inner_in1 <= 79'h0;
        div_adata_inner_in2 <= 79'h0;
        //
        div_mmode <= 3'b000;
        div_amode <= 3'b000;
        div_mflag_in <= 5'b00000;
        div_aflag_in <= 5'b00000;
        //
        pipe_d_special      <= 2'b00;
        pipe_d_special_data <= 32'h00000000;
        pipe_d_special_flag <= 5'b00000;
    end
    else if ((div_seq == 4'h0) && (pipe_i_token[7:0] == `FPU32_CMD_FDIV))
    begin
        pipe_d_token  <= pipe_i_token;
        //
        div_seq <= 4'h1;
        div_cnt <= 4'h0;
        div_sel <= 1'b1;
        //
        div_da_sign_keep <= idata_inner_out1[78];
        div_db_sign_keep <= idata_inner_out2[78];
        div_da_expo_keep <= idata_inner_out1[77:66];
        div_db_expo_keep <= idata_inner_out2[77:66];
        //
        div_da_inner <= {1'b0, 12'd1023, idata_inner_out1[65:0]};
        div_db_inner <= {1'b0, 12'd1023, idata_inner_out2[65:0]};
        //
        // fadd  = 1.4571 - 0.5 * b
        div_adata_inner_in1 <= {1'b0, 12'd1023, 66'h05D41205BC01A36E2};  // 1.4571
        div_adata_inner_in2 <= {1'b1, 12'd1022, idata_inner_out2[65:0]}; // 0.5 * b
        //
        div_mmode <= imode;
        div_amode <= imode;
        div_mflag_in <= `FPU32_FLAG_OK;
        div_aflag_in <= `FPU32_FLAG_OK;
        //
        pipe_d_special      <= {dspecial_special, dspecial_special};
        pipe_d_special_data <= dspecial_float_out;
        pipe_d_special_flag <= dspecial_flg_out;
    end
    else if (div_seq == 4'h1)
    begin
        div_seq <= 4'h2;
        //
        // y = fadd
        div_dy_inner <= div_adata_inner_out; // fadd
        //
        // fmul = b * fadd (= b * y)
        div_mdata_inner_in1 <= div_db_inner;        // b
        div_mdata_inner_in2 <= div_adata_inner_out; // fadd
    end
    else if (div_seq == 4'h2)
    begin
        div_seq <= 4'h3;
        //
        // fmul = a * y
        div_mdata_inner_in1 <= div_da_inner; // a
        div_mdata_inner_in2 <= div_dy_inner; // y
        //
        // fadd = 1 - fmul (= 1 - b * y)
        div_adata_inner_in1 <= {1'b0, 12'd1023, 66'h04000000000000000}; // 1.0
        div_adata_inner_in2 <= {~div_mdata_inner_out[78], div_mdata_inner_out[77:0]}; // -fmul    
    end
    else if (div_seq == 4'h3)
    begin
        div_seq <= 4'h4;
        //
        // q = fmul (= a * y)
        div_dq_inner <= div_mdata_inner_out;
        //
        // e = fadd (= 1 - b * y)
        div_de_inner <= div_adata_inner_out;
        //
        // fmul  = fmul * fadd (= q * e)
        div_mdata_inner_in1 <= div_mdata_inner_out; // q
        div_mdata_inner_in2 <= div_adata_inner_out; // e
    end
    else if (div_seq == 4'h4) // Loop Step1
    begin
        div_seq <= 4'h5;
        //
        // fadd = fmul + q (= q * e + q)
        div_adata_inner_in1 <= div_mdata_inner_out; // q * e
        div_adata_inner_in2 <= div_dq_inner;        // q
        //
        // fmul = e * e
        div_mdata_inner_in1 <= div_de_inner; // e
        div_mdata_inner_in2 <= div_de_inner; // e
    end
    else if (div_seq == 4'h5) // Loop Step2
    begin
        // Answer is in div_adata_inner_out (= div_dq_inner)
        //
        // q = fadd (= q * e + q)
        div_dq_inner <= div_adata_inner_out;
        //
        // e = fmul (= e * e)
        div_de_inner <= div_mdata_inner_out;
        //
        // fmul  = fadd * fmul (= q * e)
        div_mdata_inner_in1 <= div_adata_inner_out; // q
        div_mdata_inner_in2 <= div_mdata_inner_out; // e
        //
        // Finished, Next FDIV exists?
        if ((pipe_i_token[7:0] == `FPU32_CMD_FDIV) && (div_cnt_plus_one == csr_div_loop))
        begin
            pipe_d_token  <= pipe_i_token;
            //
            div_seq <= 4'h1;
            div_cnt <= 4'h0;
            div_sel <= 1'b1;
            //
            div_da_sign_keep <= idata_inner_out1[78];
            div_db_sign_keep <= idata_inner_out2[78];
            div_da_expo_keep <= idata_inner_out1[77:66];
            div_db_expo_keep <= idata_inner_out2[77:66];
            //
            div_da_inner <= {1'b0, 12'd1023, idata_inner_out1[65:0]};
            div_db_inner <= {1'b0, 12'd1023, idata_inner_out2[65:0]};
            //
            // fadd  = 1.4571 - 0.5 * b
            div_adata_inner_in1 <= {1'b0, 12'd1023, 66'h05D41205BC01A36E2};  // 1.4571
            div_adata_inner_in2 <= {1'b1, 12'd1022, idata_inner_out2[65:0]}; // 0.5 * b
            //
            div_mmode <= imode;
            div_amode <= imode;
            div_mflag_in <= `FPU32_FLAG_OK;
            div_aflag_in <= `FPU32_FLAG_OK;
            //
            pipe_d_special      <= {dspecial_special, dspecial_special};
            pipe_d_special_data <= dspecial_float_out;
            pipe_d_special_flag <= dspecial_flg_out;        
        end
        // Continue, or Finished but No Next FDIV
        else
        begin
            div_seq <= (div_cnt_plus_one == csr_div_loop)? 4'h0 : 4'h4;
            div_cnt <= (div_cnt_plus_one == csr_div_loop)? 4'h0 : div_cnt_plus_one;
            div_sel <= (div_cnt_plus_one == csr_div_loop)? 1'b0 : div_sel;
            //
          //div_mmode    <= (div_cnt_plus_one == csr_div_loop)? 3'b000   : div_mmode;
          //div_amode    <= (div_cnt_plus_one == csr_div_loop)? 3'b000   : div_amode;
          //div_mflag_in <= (div_cnt_plus_one == csr_div_loop)? 5'b00000 : div_mflag_in; 
          //div_aflag_in <= (div_cnt_plus_one == csr_div_loop)? 5'b00000 : div_aflag_in;
        end
    end
end
//
// Busy Control
assign pipe_dv_busy_clr = (csr_div_loop == 4'h1)? 
                          (div_seq == 4'h5) & (div_cnt_plus_one == 4'h1) // extra 1 cyc
                        : (div_seq == 4'h5) & (div_cnt_plus_one == (csr_div_loop - 4'h1));
//
// Complete
assign div_complete = (div_seq == 4'h5) & (div_cnt_plus_one == csr_div_loop);

//----------------------
// pipe-s (square root)
//----------------------
// Goldschmidt's Algorithm
// Adjust Exponent to Even Value and make it Square Root
//     frac=[1.0, 2.0) expo=2n   --> frac=[1.0, 2.0) --> expo=n
//     frac=[1.0, 2.0) expo=2n+1 --> frac=[2.0, 4.0) --> expo=n
// Keep Exponent
//     b_expo_keep = 1023; // b_expo_keep= (b_expo -1023) - (b_expo - 1023) + 1023;    
// y = 1.2739 - 0.292 * b
// g = b * y
// h = y * 0.5
// repeat
//     (1 + r) = 1 + (0.5 - h * g)
//     h = h + h * r = h * (1 + r)
//     g = g + g * r = g * (1 + r)
//    
// Revert Exponent
//     g_expo = (g_expo - 1023) + (b_expo_keep - 1023) + 1023
//
reg  [ 3:0] sqr_cnt;
reg         sqr_db_sign_keep;
reg  [11:0] sqr_db_expo_keep;
reg  [78:0] sqr_db_inner;
reg  [78:0] sqr_dy_inner;
reg  [78:0] sqr_dg_inner;
reg  [78:0] sqr_dh_inner;
reg  [78:0] sqr_dr_inner; // (1+r)
//
reg  [ 1:0] pipe_s_special;
reg  [31:0] pipe_s_special_data;
reg  [ 4:0] pipe_s_special_flag;
//
assign sqr_cnt_plus_one = sqr_cnt + 4'h1;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_s_token <= 36'h0;
        //
        sqr_seq <= 4'h0;
        sqr_cnt <= 4'h0;
        sqr_sel <= 1'b0;
        //
        sqr_db_sign_keep <= 1'b0;
        sqr_db_expo_keep <= 12'h000;
        //
        sqr_db_inner <= 79'h0;
        sqr_dy_inner <= 79'h0;
        sqr_dg_inner <= 79'h0;
        sqr_dh_inner <= 79'h0;
        sqr_dr_inner <= 79'h0;
        //
        sqr_mdata_inner_in1 <= 79'h0;
        sqr_mdata_inner_in2 <= 79'h0;
        sqr_adata_inner_in1 <= 79'h0;
        sqr_adata_inner_in2 <= 79'h0;
        //
        sqr_mmode <= 3'b000;
        sqr_amode <= 3'b000;
        sqr_mflag_in <= 5'b00000;
        sqr_aflag_in <= 5'b00000;
        //
        pipe_s_special      <= 2'b00;
        pipe_s_special_data <= 32'h00000000;
        pipe_s_special_flag <= 5'b00000;
    end
    else if ((sqr_seq == 4'h0) && (pipe_i_token[7:0] == `FPU32_CMD_FSQRT))
    begin
        reg [78:0] sqr_db_inner_temp; // blocking assignment
        //
        sqr_db_inner_temp = 79'h0;
        pipe_s_token  <= pipe_i_token;
        //
        sqr_seq <= 4'h1;
        sqr_cnt <= 4'h0;
        sqr_sel <= 1'b1;
        //
        sqr_db_sign_keep <= idata_inner_out1[78];
        sqr_db_expo_keep <= (idata_inner_out1[66])? // (b_expo - 1023) is even?
                            {1'b0, idata_inner_out1[77:67]} + 12'd512  // (db_expo     - 1023) / 2 + 1023
                          : {1'b0, idata_inner_out1[77:67]} + 12'd511; // (db_expo - 1 - 1023) / 2 + 1023
        sqr_db_inner_temp = (idata_inner_out1[66])? // (b_expo - 1023) is even?
                            {1'b0, 12'd1023, idata_inner_out1[65:0]      }  // frac
                          : {1'b0, 12'd1023, idata_inner_out1[64:0], 1'b0}; // frac << 1
        sqr_db_inner <= sqr_db_inner_temp;
        //
        // fmul = -0.292 * b
        sqr_mdata_inner_in1 <= {1'b1, 12'd1021, 66'h04AC083126E978D50}; // -0.292
        sqr_mdata_inner_in2 <= sqr_db_inner_temp; // b
        //
        sqr_mmode <= imode;
        sqr_amode <= imode;
        sqr_mflag_in <= `FPU32_FLAG_OK;
        sqr_aflag_in <= `FPU32_FLAG_OK;
        //
        pipe_s_special      <= {sspecial_special, sspecial_special};
        pipe_s_special_data <= sspecial_float_out;
        pipe_s_special_flag <= sspecial_flg_out;
    end
    else if (sqr_seq == 4'h1)
    begin
        sqr_seq <= 4'h2;
        //
        // fadd = 1.2739 + fmul (= 1.2739 - 0.292 * b)
        sqr_adata_inner_in1 <= {1'b0, 12'd1023, 66'h0518793DD97F62B6B}; // 1.2739
        sqr_adata_inner_in2 <= sqr_mdata_inner_out;
    end
    else if (sqr_seq == 4'h2)
    begin
        sqr_seq <= 4'h3;
        //
        // y = fadd (= 1.2739 - 0.292 * b)
        sqr_dy_inner <= sqr_adata_inner_out;
        //
        // fmul = b * fadd (= b * y)
        sqr_mdata_inner_in1 <= sqr_db_inner;
        sqr_mdata_inner_in2 <= sqr_adata_inner_out;
        //        
        // h = fadd * 0.5 (= y * 0.5)
        sqr_dh_inner <= {sqr_adata_inner_out[78], 
                         sqr_adata_inner_out[77:66] - 12'd1,
                         sqr_adata_inner_out[65:0]}; 
    end
    else if (sqr_seq == 4'h3)
    begin
        sqr_seq <= 4'h4;
        //
        // g = fmul (= b * y)
        sqr_dg_inner <= sqr_mdata_inner_out;
        //
        // fmul = h * fmul (= h * g)
        sqr_mdata_inner_in1 <= sqr_dh_inner;
        sqr_mdata_inner_in2 <= sqr_mdata_inner_out;
    end
    else if (sqr_seq == 4'h4) // Loop Step1
    begin
        sqr_seq <= 4'h5;
        //
        // fadd = 1.5 - fmul (= 1.5 - h * g)
        sqr_adata_inner_in1 <= {1'b0, 12'd1023, 66'h06000000000000000}; // 1.5
        sqr_adata_inner_in2 <= {~sqr_mdata_inner_out[78], sqr_mdata_inner_out[77:0]};
    end
    else if (sqr_seq == 4'h5) // Loop Step2
    begin
        sqr_seq <= 4'h6;
        //
        // r1 = fadd (= 1.5 - h * g)
        sqr_dr_inner <= sqr_adata_inner_out;
        //
        // fmul = h * fadd (= h * r1)
        sqr_mdata_inner_in1 <= sqr_dh_inner;
        sqr_mdata_inner_in2 <= sqr_adata_inner_out;
    end
    else if (sqr_seq == 4'h6) // Loop Step3
    begin
        sqr_seq <= 4'h7;
        //
        // h = fmul (= h * r1)
        sqr_dh_inner <= sqr_mdata_inner_out;
        //
        // fmul = g * r1
        sqr_mdata_inner_in1 <= sqr_dg_inner;
        sqr_mdata_inner_in2 <= sqr_dr_inner;
    end
    else if (sqr_seq == 4'h7) // Loop Step4
    begin
        // Answer is in sqr_dg_inner
        //
        // g = fmul (= g * r1)
        sqr_dg_inner <= sqr_mdata_inner_out;
        //
        // fmul = h * fmul (= h * g)
        if (sqr_cnt_plus_one != csr_sqr_loop) // if last, no operation
        begin
            sqr_mdata_inner_in1 <= sqr_dh_inner;
            sqr_mdata_inner_in2 <= sqr_mdata_inner_out;    
        end
        //
        // Finished, Next FSQRT exists?
        if ((pipe_i_token[7:0] == `FPU32_CMD_FSQRT) && (sqr_cnt_plus_one == csr_sqr_loop))
        begin
            reg [78:0] sqr_db_inner_temp; // blocking assignment
            //
            pipe_s_token  <= pipe_i_token;
            //
            sqr_seq <= 4'h1;
            sqr_cnt <= 4'h0;
            sqr_sel <= 1'b1;
            //
            sqr_db_sign_keep <= idata_inner_out1[78];
            sqr_db_expo_keep <= (idata_inner_out1[66])? // (b_expo - 1023) is even?
                                {1'b0, idata_inner_out1[77:67]} + 12'd512  // (db_expo     - 1023) / 2 + 1023
                              : {1'b0, idata_inner_out1[77:67]} + 12'd511; // (db_expo - 1 - 1023) / 2 + 1023
            sqr_db_inner_temp = (idata_inner_out1[66])? // (b_expo - 1023) is even?
                                {1'b0, 12'd1023, idata_inner_out1[65:0]      }  // frac
                              : {1'b0, 12'd1023, idata_inner_out1[64:0], 1'b0}; // frac << 1
            sqr_db_inner <= sqr_db_inner_temp;
            //
            // fmul = -0.292 * b
            sqr_mdata_inner_in1 <= {1'b1, 12'd1021, 66'h04AC083126E978D50}; // -0.292
            sqr_mdata_inner_in2 <= sqr_db_inner_temp; // b
            //
            sqr_mmode <= imode;
            sqr_amode <= imode;
            sqr_mflag_in <= `FPU32_FLAG_OK;
            sqr_aflag_in <= `FPU32_FLAG_OK;
            //
            pipe_s_special      <= {sspecial_special, sspecial_special};
            pipe_s_special_data <= sspecial_float_out;
            pipe_s_special_flag <= sspecial_flg_out;
        end
        // Continue, or Finished but No Next FSQRT
        else
        begin
            sqr_seq <= (sqr_cnt_plus_one == csr_sqr_loop)? 4'h0 : 4'h4;
            sqr_cnt <= (sqr_cnt_plus_one == csr_sqr_loop)? 4'h0 : sqr_cnt_plus_one;
            sqr_sel <= (sqr_cnt_plus_one == csr_sqr_loop)? 1'b0 : sqr_sel;
            //
          //sqr_mmode    <= (sqr_cnt_plus_one == csr_sqr_loop)? 3'b000   : sqr_mmode;
          //sqr_amode    <= (sqr_cnt_plus_one == csr_sqr_loop)? 3'b000   : sqr_amode;
          //sqr_mflag_in <= (sqr_cnt_plus_one == csr_sqr_loop)? 5'b00000 : sqr_mflag_in; 
          //sqr_aflag_in <= (sqr_cnt_plus_one == csr_sqr_loop)? 5'b00000 : sqr_aflag_in;
        end
    end
end
//
// Busy Control
assign pipe_sq_busy_clr = (csr_sqr_loop == 4'h1)? 
                          (sqr_seq == 4'h5) & (sqr_cnt_plus_one == 4'h1) // extra 1 cyc
                        : (sqr_seq == 4'h5) & (sqr_cnt_plus_one == csr_sqr_loop);
//
// Complete
assign sqr_complete = (sqr_seq == 4'h7) & (sqr_cnt_plus_one == csr_sqr_loop);

//-------------------
// pipe-f (finalize)
//-------------------
reg [ 1:0] pipe_f_special;
reg [31:0] pipe_f_special_data;
reg [ 4:0] pipe_f_special_flag;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        pipe_f_token   <= 36'h0;
        fdata_inner_in <= 79'h0;
        fmode    <= 3'b000;
        fflag_in <= 5'b00000;
        //
        pipe_f_special      <= 2'b00;
        pipe_f_special_data <= 32'h00000000;
        pipe_f_special_flag <= 5'b00000;
    end
    else if (pipe_m_token[7:0] == `FPU32_CMD_FMUL)
    begin
        pipe_f_token   <= pipe_m_token;
        fdata_inner_in <= mdata_inner_out;
        fmode    <= mmode;
        fflag_in <= mflag_out;
        //
        pipe_f_special      <= pipe_m_special;
        pipe_f_special_data <= pipe_m_special_data;
        pipe_f_special_flag <= pipe_m_special_flag;
    end
    else if (pipe_a_token[7:0] == `FPU32_CMD_FADD)
    begin
        pipe_f_token   <= pipe_a_token;
        fdata_inner_in <= adata_inner_out;
        fmode    <= amode;
        fflag_in <= aflag_out;
        //
        pipe_f_special      <= pipe_a_special;
        pipe_f_special_data <= pipe_a_special_data;
        pipe_f_special_flag <= pipe_a_special_flag;
    end
    else if (pipe_a_token[7:0] == `FPU32_CMD_FSUB)
    begin
        pipe_f_token   <= pipe_a_token;
        fdata_inner_in <= adata_inner_out;
        fmode    <= amode;
        fflag_in <= aflag_out;
        //
        pipe_f_special      <= pipe_a_special;
        pipe_f_special_data <= pipe_a_special_data;
        pipe_f_special_flag <= pipe_a_special_flag;
    end
    else if (pipe_a_token[7:3] == 5'b11111) // FMADD etc.
    begin
        pipe_f_token   <= pipe_a_token;
        fdata_inner_in <= (pipe_a_special == 2'b01)? adata_inner_out2
                        : adata_inner_out;
        fmode    <= amode;
        fflag_in <= aflag_out;
        //
        pipe_f_special      <= pipe_a_special;
        pipe_f_special_data <= pipe_a_special_data;
        pipe_f_special_flag <= (pipe_a_special == 2'b01)? aflag_out2
                             : pipe_a_special_flag;
    end
    else if (div_complete) // FDIV
    begin
        pipe_f_token   <= pipe_d_token;
        fdata_inner_in <= {div_da_sign_keep ^ div_db_sign_keep,
                           div_adata_inner_out[77:66] + div_da_expo_keep - div_db_expo_keep,
                           div_adata_inner_out[65:0]};        
        fmode    <= div_amode;
        fflag_in <= div_aflag_out;
        //
        pipe_f_special      <= pipe_d_special;
        pipe_f_special_data <= pipe_d_special_data;
        pipe_f_special_flag <= pipe_d_special_flag;
    end
    else if (sqr_complete) // FSQRT
    begin
        pipe_f_token   <= pipe_s_token;
        fdata_inner_in <= {sqr_db_sign_keep,
                           sqr_dg_inner[77:66] + sqr_db_expo_keep - 12'd1023,
                           sqr_dg_inner[65:0]};
        fmode    <= sqr_mmode;
        fflag_in <= sqr_mflag_out;
        //
        pipe_f_special      <= pipe_s_special;
        pipe_f_special_data <= pipe_s_special_data;
        pipe_f_special_flag <= pipe_s_special_flag;
    end
    else
    begin
        pipe_f_token   <= 36'h0;
      //fdata_inner_in <= 79'h0;
      //fmode    <= 3'b000;
      //fflag_in <= 5'b00000;
        //
        pipe_f_special      <= 2'b00;
      //pipe_f_special_data <= 32'h00000000;
      //pipe_f_special_flag <= 5'b00000;
    end
end

//----------------------------------------
// CSR FFLAGS
//----------------------------------------
assign csr_fflags_set = pipe_f_token[17] | pipe_i_fflags_set
                      | (pipe_c_token[7:1] == 7'b1100000)  // FCVT.W.S/FCVT.WU.S
                      | (pipe_c_token[7:1] == 7'b1101000); // FCVT.S.W/FCVT.S.WU
assign fflag_out_final = (pipe_f_special == 2'b11)? pipe_f_special_flag
                       : (pipe_i_fflags_set      )? pipe_i_fflags_data
                       : (pipe_c_token[7:1] == 7'b1100000)? pipe_c_fflags_data // FCVT.W.S/FCVT.WU.S
                       : (pipe_c_token[7:1] == 7'b1101000)? fcvt_i2f_flg_out   // FCVT.S.W/FCVT.S.WU
                       : fflag_out;

//----------------------------------------
// Make Final Result
//----------------------------------------
assign fdata_float_out_final = (pipe_f_special == 2'b11)? pipe_f_special_data
                             : fdata_float_out;

//----------------------------------------------------------------------
// If RISCV_ISA_RV32F is not defined....
//----------------------------------------------------------------------
`else // RISCV_ISA_RV32F
assign CSR_FPU_DBG_RDATA = 32'h00000000;
assign CSR_FPU_CPU_RDATA = 32'h00000000;
assign ID_FPU_STALL  = 1'b0;
assign SET_MSTATUS_FS_DIRTY = 1'b0;
assign EX_FPU_SRCDATA = 32'h00000000;
assign EX_FPU_ST_DATA = 32'h00000000;
initial
begin
    DBGABS_FPR_RDATA = 32'h00000000;
    FPUCSR_DIRTY     = 1'b0;
end
`endif // RISCV_ISA_RV32F

//------------------------
// End of Module
//------------------------
endmodule

`ifdef RISCV_ISA_RV32F
//=====================================================================
// [MODULE] Check Floating Number Type
//=====================================================================
module CHECK_FTYPE
(
    input  wire [31:0] FDATA,
    output reg  [ 3:0] FTYPE
);
wire sign;
wire ex00;
wire exFF;
wire fr00;
wire fmsb;
assign sign = (FDATA[31]);
assign ex00 = (FDATA[30:23] != 8'h00);
assign exFF = (FDATA[30:23] == 8'hff);
assign fr00 = (FDATA[22: 0] != 23'h0);
assign fmsb = (FDATA[22]);
//
always @*
begin
    casez ({sign, ex00, exFF, fr00, fmsb})
        6'b0_0_0_0_? : FTYPE = `FPU32_FT_POSZRO;
        6'b1_0_0_0_? : FTYPE = `FPU32_FT_NEGZRO;
        //
        6'b0_1_1_0_? : FTYPE = `FPU32_FT_POSINF;
        6'b1_1_1_0_? : FTYPE = `FPU32_FT_NEGINF;
        //
        6'b0_1_1_1_1 : FTYPE = `FPU32_FT_POSQNA;
        6'b1_1_1_1_1 : FTYPE = `FPU32_FT_NEGQNA;
        //
        6'b0_1_1_1_0 : FTYPE = `FPU32_FT_POSSNA;
        6'b1_1_1_1_0 : FTYPE = `FPU32_FT_NEGSNA;
        //
        6'b0_0_0_1_? : FTYPE = `FPU32_FT_POSSUB;
        6'b1_0_0_1_? : FTYPE = `FPU32_FT_NEGSUB;
        //
        6'b0_1_0_?_? : FTYPE = `FPU32_FT_POSNOR;
        6'b1_1_0_?_? : FTYPE = `FPU32_FT_NEGNOR;
        //
        default      : FTYPE = `FPU32_FT_ERROR;
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FADD Handle Special Number
//=====================================================================
module FADD_SPECIAL_NUMBER
(
    input  wire [31:0] FDATA_IN1,
    input  wire [31:0] FDATA_IN2,
    output reg  [31:0] FDATA_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT,
    output reg         SPECIAL
);
wire [3:0] ftype_in1;
wire [3:0] ftype_in2;
//
CHECK_FTYPE U_CHECK_FTYPE_1
(
    .FDATA (FDATA_IN1),
    .FTYPE (ftype_in1)
);
CHECK_FTYPE U_CHECK_FTYPE_2
(
    .FDATA (FDATA_IN2),
    .FTYPE (ftype_in2)
);
//
always @*
begin
    casez({ftype_in1, ftype_in2})
        {`FPU32_FT_POSQNA, `FPU32_FT_POSQNA}, // add
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGQNA}, // add
        {`FPU32_FT_POSQNA, `FPU32_FT_POSSNA}, // add
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGSNA}, // add
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSQNA}, // add
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGQNA}, // add
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSSNA}, // add
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGSNA}, // add
        {`FPU32_FT_POSSNA, `FPU32_FT_POSQNA}, // add
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGQNA}, // add
        {`FPU32_FT_POSSNA, `FPU32_FT_POSSNA}, // add
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGSNA}, // add
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSQNA}, // add
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGQNA}, // add
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSSNA}, // add
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGSNA}: // add
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN2 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSQNA, 4'b????}, // add
        {`FPU32_FT_NEGQNA, 4'b????}, // add
        {`FPU32_FT_POSSNA, 4'b????}, // add
        {`FPU32_FT_NEGSNA, 4'b????}: // add
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN1 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSQNA}, // add
        {4'b????, `FPU32_FT_NEGQNA}, // add
        {4'b????, `FPU32_FT_POSSNA}, // add
        {4'b????, `FPU32_FT_NEGSNA}: // add
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN2 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, `FPU32_FT_NEGINF}, // add
        {`FPU32_FT_NEGINF, `FPU32_FT_POSINF}: // add
        begin
            FDATA_OUT = 32'h7fc00000; //32'hffc00000; // -QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, 4'b????}, // add
        {`FPU32_FT_NEGINF, 4'b????}: // add
        begin
            FDATA_OUT = FDATA_IN1;
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSINF}, // add
        {4'b????, `FPU32_FT_NEGINF}: // add
        begin
            FDATA_OUT = FDATA_IN2;
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, `FPU32_FT_POSZRO}: // add
        begin
            FDATA_OUT = 32'h00000000;
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_NEGZRO, `FPU32_FT_NEGZRO}: // add
        begin
            FDATA_OUT = 32'h80000000;
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, `FPU32_FT_NEGZRO}, // add
        {`FPU32_FT_NEGZRO, `FPU32_FT_POSZRO}: // add
        begin
            FDATA_OUT = (RMODE == `FPU32_RMODE_RUP)? 32'h00000000
                      : (RMODE == `FPU32_RMODE_RDN)? 32'h80000000
                      :                              32'h00000000;
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, 4'b????}, // add
        {`FPU32_FT_NEGZRO, 4'b????}: // add
        begin
            FDATA_OUT = FDATA_IN2;
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSZRO}, // add
        {4'b????, `FPU32_FT_NEGZRO}: // add
        begin
            FDATA_OUT = FDATA_IN1;
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        default: // Others
        begin
            FDATA_OUT = 32'h3f800000; // 1.0
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b0;
        end
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule


//=====================================================================
// [MODULE] FMUL Handle Special Number
//=====================================================================
module FMUL_SPECIAL_NUMBER
(
    input  wire [31:0] FDATA_IN1,
    input  wire [31:0] FDATA_IN2,
    output reg  [31:0] FDATA_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT,
    output reg         SPECIAL
);
wire [3:0] ftype_in1;
wire [3:0] ftype_in2;
//
CHECK_FTYPE U_CHECK_FTYPE_1
(
    .FDATA (FDATA_IN1),
    .FTYPE (ftype_in1)
);
CHECK_FTYPE U_CHECK_FTYPE_2
(
    .FDATA (FDATA_IN2),
    .FTYPE (ftype_in2)
);
//
always @*
begin
    casez({ftype_in1, ftype_in2})
        {`FPU32_FT_POSQNA, `FPU32_FT_POSQNA}, // mul
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGQNA}, // mul
        {`FPU32_FT_POSQNA, `FPU32_FT_POSSNA}, // mul
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGSNA}, // mul
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSQNA}, // mul
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGQNA}, // mul
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSSNA}, // mul
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGSNA}, // mul
        {`FPU32_FT_POSSNA, `FPU32_FT_POSQNA}, // mul
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGQNA}, // mul
        {`FPU32_FT_POSSNA, `FPU32_FT_POSSNA}, // mul
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGSNA}, // mul
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSQNA}, // mul
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGQNA}, // mul
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSSNA}, // mul
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGSNA}: // mul
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN2 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSQNA, 4'b????}, // mul
        {`FPU32_FT_NEGQNA, 4'b????}, // mul
        {`FPU32_FT_POSSNA, 4'b????}, // mul
        {`FPU32_FT_NEGSNA, 4'b????}: // mul
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN1 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSQNA}, // mul
        {4'b????, `FPU32_FT_NEGQNA}, // mul
        {4'b????, `FPU32_FT_POSSNA}, // mul
        {4'b????, `FPU32_FT_NEGSNA}: // mul
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN2 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, `FPU32_FT_POSINF}, // mul
        {`FPU32_FT_POSINF, `FPU32_FT_NEGINF}, // mul
        {`FPU32_FT_NEGINF, `FPU32_FT_POSINF}, // mul
        {`FPU32_FT_NEGINF, `FPU32_FT_NEGINF}: // mul
        begin
            FDATA_OUT = 32'h7f800000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???INF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, `FPU32_FT_POSZRO}, // mul
        {`FPU32_FT_POSINF, `FPU32_FT_NEGZRO}, // mul
        {`FPU32_FT_NEGINF, `FPU32_FT_POSZRO}, // mul
        {`FPU32_FT_NEGINF, `FPU32_FT_NEGZRO}, // mul
        {`FPU32_FT_POSZRO, `FPU32_FT_POSINF}, // mul
        {`FPU32_FT_POSZRO, `FPU32_FT_NEGINF}, // mul
        {`FPU32_FT_NEGZRO, `FPU32_FT_POSINF}, // mul
        {`FPU32_FT_NEGZRO, `FPU32_FT_NEGINF}: // mul
        begin
            FDATA_OUT = 32'h7fc00000; //32'h7fc00000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, 4'b????}, // mul
        {`FPU32_FT_NEGINF, 4'b????}, // mul
        {4'b????, `FPU32_FT_POSINF}, // mul
        {4'b????, `FPU32_FT_NEGINF}: // mul
        begin
            FDATA_OUT = 32'h7f800000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???INF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, `FPU32_FT_POSZRO}, // mul
        {`FPU32_FT_POSZRO, `FPU32_FT_NEGZRO}, // mul
        {`FPU32_FT_NEGZRO, `FPU32_FT_POSZRO}, // mul
        {`FPU32_FT_NEGZRO, `FPU32_FT_NEGZRO}: // mul
        begin
            FDATA_OUT = 32'h00000000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???ZRO
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, 4'b????}, // mul
        {`FPU32_FT_NEGZRO, 4'b????}, // mul
        {4'b????, `FPU32_FT_POSZRO}, // mul
        {4'b????, `FPU32_FT_NEGZRO}: // mul
        begin
            FDATA_OUT = 32'h00000000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???ZRO
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        default: // Others
        begin
            FDATA_OUT = 32'h3f800000; // 1.0
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b0;
        end
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FMADD Handle Special Number
//=====================================================================
// SPECIAL_FMADD  Operation
// IN1   IN2   IN3   Output
// xNAN  *     *     QNAN (SPECIAL)
// *     xNAN  *     QNAN (SPECIAL)
// *     *     xNAN  QNAN (SPECIAL)
// xINF  *     *     xINF (SPECIAL)
// *     xINF  *     xINF (SPECIAL)
// *     *     xINF  xINF (SPECIAL)
// NUM   NUM   NUM   IN1 x IN2 + IN3
// xZRO  NUM   NUM   IN3  (SPECIAL)
// NUM   xZRO  NUM   IN3  (SPECIAL)
// xZRO  xZRO  NUM   IN3  (SPECIAL)
// NUM   NUM   xZRO  IN1 x IN2
// xZRO  NUM   xZRO  xZRO (SPECIAL) 
// NUM   xZRO  xZRO  xZRO (SPECIAL)
// xZRO  xZRO  xZRO  xZRO (SPECIAL)
//
module FMADD_SPECIAL_NUMBER
(
    input  wire [31:0] FDATA_IN1,
    input  wire [31:0] FDATA_IN2,
    input  wire [31:0] FDATA_IN3,
    output wire [31:0] FDATA_OUT,
    input  wire        NEGATE,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output wire [ 4:0] FLG_OUT,
    output wire [ 1:0] SPECIAL_MA // 00:(Use IN1xIN2+IN3), 01:(Use IN1xIN2), 11:(Use Special)
);

wire [31:0] fmul_fdata_out;
wire [ 4:0] fmul_flg_out;
wire        fmul_special;
wire [31:0] fadd_fdata_in;
wire        fadd_special;
//
FMUL_SPECIAL_NUMBER U_FMUL_SPECIAL_NUMBER
(
    .FDATA_IN1 (FDATA_IN1),
    .FDATA_IN2 (FDATA_IN2),
    .FDATA_OUT (fmul_fdata_out),
    .RMODE     (RMODE),
    .FLG_IN    (FLG_IN),
    .FLG_OUT   (fmul_flg_out),
    .SPECIAL   (fmul_special)
);
//
assign fadd_fdata_in = (NEGATE)? fmul_fdata_out ^ 32'h80000000
                     : fmul_fdata_out;
//
FADD_SPECIAL_NUMBER U_FADD_SPECIAL_NUMBER
(
    .FDATA_IN1 (fadd_fdata_in),
    .FDATA_IN2 (FDATA_IN3),
    .FDATA_OUT (FDATA_OUT),
    .RMODE     (RMODE),
    .FLG_IN    (fmul_flg_out),
    .FLG_OUT   (FLG_OUT),
    .SPECIAL   (fadd_special)
);
//
assign SPECIAL_MA = ((~fmul_special) & (~fadd_special))? 2'b00
                  : ((~fmul_special) & (FDATA_IN3[30:0] == 31'h00000000))? 2'b01
                  : 2'b11;

//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FDIV Handle Special Number
//=====================================================================
module FDIV_SPECIAL_NUMBER
(
    input  wire [31:0] FDATA_IN1,
    input  wire [31:0] FDATA_IN2,
    output reg  [31:0] FDATA_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT,
    output reg         SPECIAL
);
wire [3:0] ftype_in1;
wire [3:0] ftype_in2;
//
CHECK_FTYPE U_CHECK_FTYPE_1
(
    .FDATA (FDATA_IN1),
    .FTYPE (ftype_in1)
);
CHECK_FTYPE U_CHECK_FTYPE_2
(
    .FDATA (FDATA_IN2),
    .FTYPE (ftype_in2)
);
//
always @*
begin
    casez({ftype_in1, ftype_in2})
        {`FPU32_FT_POSQNA, `FPU32_FT_POSQNA}, // div
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGQNA}, // div
        {`FPU32_FT_POSQNA, `FPU32_FT_POSSNA}, // div
        {`FPU32_FT_POSQNA, `FPU32_FT_NEGSNA}, // div
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSQNA}, // div
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGQNA}, // div
        {`FPU32_FT_NEGQNA, `FPU32_FT_POSSNA}, // div
        {`FPU32_FT_NEGQNA, `FPU32_FT_NEGSNA}, // div
        {`FPU32_FT_POSSNA, `FPU32_FT_POSQNA}, // div
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGQNA}, // div
        {`FPU32_FT_POSSNA, `FPU32_FT_POSSNA}, // div
        {`FPU32_FT_POSSNA, `FPU32_FT_NEGSNA}, // div
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSQNA}, // div
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGQNA}, // div
        {`FPU32_FT_NEGSNA, `FPU32_FT_POSSNA}, // div
        {`FPU32_FT_NEGSNA, `FPU32_FT_NEGSNA}: // div
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN1 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSQNA, 4'b????}, // div
        {`FPU32_FT_NEGQNA, 4'b????}, // div
        {`FPU32_FT_POSSNA, 4'b????}, // div
        {`FPU32_FT_NEGSNA, 4'b????}: // div
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN1 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSQNA}, // div
        {4'b????, `FPU32_FT_NEGQNA}, // div
        {4'b????, `FPU32_FT_POSSNA}, // div
        {4'b????, `FPU32_FT_NEGSNA}: // div
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN2 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, `FPU32_FT_POSINF}, // div
        {`FPU32_FT_POSINF, `FPU32_FT_NEGINF}, // div
        {`FPU32_FT_NEGINF, `FPU32_FT_POSINF}, // div
        {`FPU32_FT_NEGINF, `FPU32_FT_NEGINF}: // div
        begin
            FDATA_OUT = 32'h7fc00000; //32'h7fc00000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, `FPU32_FT_POSZRO}, // div
        {`FPU32_FT_POSINF, `FPU32_FT_NEGZRO}, // div
        {`FPU32_FT_NEGINF, `FPU32_FT_POSZRO}, // div
        {`FPU32_FT_NEGINF, `FPU32_FT_NEGZRO}: // div
        begin
            FDATA_OUT = 32'h7f800000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???INF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF | `FPU32_FLAG_DZ;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, `FPU32_FT_POSINF}, // div
        {`FPU32_FT_POSZRO, `FPU32_FT_NEGINF}, // div
        {`FPU32_FT_NEGZRO, `FPU32_FT_POSINF}, // div
        {`FPU32_FT_NEGZRO, `FPU32_FT_NEGINF}: // div
        begin
            FDATA_OUT = 32'h00000000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???ZRO
            FLG_OUT   = FLG_IN | `FPU32_FLAG_UF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF, 4'b????}, // div
        {`FPU32_FT_NEGINF, 4'b????}: // div
        begin
            FDATA_OUT = 32'h7f800000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???INF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSINF}, // div
        {4'b????, `FPU32_FT_NEGINF}: // div
        begin
            FDATA_OUT = 32'h00000000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0};; // ???ZRO
            FLG_OUT   = FLG_IN | `FPU32_FLAG_UF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, `FPU32_FT_POSZRO}, // div
        {`FPU32_FT_POSZRO, `FPU32_FT_NEGZRO}, // div
        {`FPU32_FT_NEGZRO, `FPU32_FT_POSZRO}, // div
        {`FPU32_FT_NEGZRO, `FPU32_FT_NEGZRO}: // div
        begin
            FDATA_OUT = 32'h7fc00000; //32'h7fc00000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO, 4'b????}, // div
        {`FPU32_FT_NEGZRO, 4'b????}: // div
        begin
            FDATA_OUT = 32'h00000000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???ZRO
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {4'b????, `FPU32_FT_POSZRO}, // div
        {4'b????, `FPU32_FT_NEGZRO}: // div
        begin
            FDATA_OUT = 32'h7f800000 | {(FDATA_IN1[31] ^ FDATA_IN2[31]), 31'h0}; // ???INF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF | `FPU32_FLAG_DZ;
            SPECIAL = 1'b1;
        end
        default: // Others
        begin
            FDATA_OUT = 32'h3f800000; // 1.0
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b0;
        end
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FSQRT Handle Special Number
//=====================================================================
module FSQRT_SPECIAL_NUMBER
(
    input  wire [31:0] FDATA_IN1,
    output reg  [31:0] FDATA_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT,
    output reg         SPECIAL
);
wire [3:0] ftype_in1;
//
CHECK_FTYPE U_CHECK_FTYPE_1
(
    .FDATA (FDATA_IN1),
    .FTYPE (ftype_in1)
);
//
always @*
begin
    casez(ftype_in1)
        {`FPU32_FT_POSQNA}, // sqrt
        {`FPU32_FT_NEGQNA}, // sqrt
        {`FPU32_FT_POSSNA}, // sqrt
        {`FPU32_FT_NEGSNA}: // sqrt
        begin
            FDATA_OUT = 32'h7fc00000; //FDATA_IN1 | 32'h00400000; // QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSINF}: // sqrt
        begin
            FDATA_OUT = 32'h7f800000; // POSINF
            FLG_OUT   = FLG_IN | `FPU32_FLAG_OF;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_NEGINF}: // sqrt
        begin
            FDATA_OUT = 32'h7fc00000; //32'hffc00000; // -QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_POSZRO}: // sqrt
        begin
            FDATA_OUT = 32'h00000000; // POSZRO
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_NEGZRO}: // sqrt
        begin
            FDATA_OUT = 32'h80000000; // NEGZRO
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        {`FPU32_FT_NEGNOR}, // sqrt
        {`FPU32_FT_NEGSUB}: // sqrt
        begin
            FDATA_OUT = 32'h7fc00000; //32'hffc00000; // -QNAN
            FLG_OUT   = FLG_IN | `FPU32_FLAG_NV;
            SPECIAL = 1'b1;
        end
        default: // Others
        begin
            FDATA_OUT = 32'h3f800000; // 1.0
            FLG_OUT   = FLG_IN;
            SPECIAL = 1'b0;
        end
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Find 1st One in Frac27
//=====================================================================
// FRAC27 : [b26][b25][b24][b23].[b22][b21].....[b00]
module FIND_1ST_ONE_IN_FRAC27
(
    input  wire [26:0] FRAC27,
    output reg  [11:0] POS
);
integer i;
always @*
begin : BLOCK_TO_BREAK
    for (i = 0; i < 27; i = i + 1)
    begin
        POS = 12'hffd + i;
        if (FRAC27[26 - i]) disable BLOCK_TO_BREAK;
    end
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Find 1st One in Frac66
//=====================================================================
// frac66 : [b65][b64][b63][b62].[b61][b60][b59].....[b39]....
module FIND_1ST_ONE_IN_FRAC66
(
    input  wire [65:0] FRAC66,
    output reg  [11:0] POS
);
integer i;
always @*
begin : BLOCK_TO_BREAK
    for (i = 0; i < 66; i = i + 1)
    begin
        POS = 12'hffd + i;
        if (FRAC66[65 - i]) disable BLOCK_TO_BREAK;
    end
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Find 1st One in Frac70
//=====================================================================
// FRAC70  : [b69][b68][b67][b66][b65][b64][b63][b62].[b61][b60].....[b00]
module FIND_1ST_ONE_IN_FRAC70
(
    input  wire [69:0] FRAC70,
    output reg  [11:0] POS
);
integer i;
always @*
begin : BLOCK_TO_BREAK
    for (i = 0; i < 69; i = i + 1)
    begin
        POS = 12'hff9 + i;
        if (FRAC70[69 - i]) disable BLOCK_TO_BREAK;
    end
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Shift Right Frac27 (Maintain Sticky bit)
//=====================================================================
// FRAC27 : [b26][b25][b24][b23].[b22][b21].....[b00]
module SHIFT_RIGHT_FRAC27
(
    input  wire [11:0] SHIFT,
    input  wire [26:0] FRAC27_IN,
    output wire [26:0] FRAC27_OUT
);
//
// Internal Signals
wire [ 4:0] shift_inner;
wire [26:0] mask;
wire        sticky;
wire [26:0] frac27;
//
assign shift_inner = (SHIFT > 12'd26)? 5'd31 : SHIFT[4:0];
assign mask   = ~(27'h7ffffff << shift_inner);
assign sticky = (mask & FRAC27_IN)? 1'b1 : 1'b0;
assign frac27 = FRAC27_IN >> shift_inner;
assign FRAC27_OUT = {frac27[26:1], frac27[0] | sticky};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Shift Right Frac66 (Maintain Sticky bit)
//=====================================================================
// FRAC66 : [b65][b64][b63][b62].[b61]...[b39]...
module SHIFT_RIGHT_FRAC66
(
    input  wire [11:0] SHIFT,
    input  wire [65:0] FRAC66_IN,
    output wire [65:0] FRAC66_OUT
);
//
// Internal Signals
wire [ 6:0] shift_inner;
wire [65:0] mask;
wire        sticky;
wire [65:0] frac66;
//
assign shift_inner = (SHIFT > 12'd65)? 7'd127 : SHIFT[6:0];
assign mask   = ~(66'h3ffffffffffffffff << shift_inner);
assign sticky = (mask & FRAC66_IN)? 1'b1 : 1'b0;
assign frac66 = FRAC66_IN >> shift_inner;
assign FRAC66_OUT = {frac66[65:1], frac66[0] | sticky};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Shift Right Frac70 (Maintain Sticky bit)
//=====================================================================
// FRAC70  : [b69][b68][b67][b66][b65][b64][b63][b62].[b61][b60].....[b00]
module SHIFT_RIGHT_FRAC70
(
    input  wire [11:0] SHIFT,
    input  wire [69:0] FRAC70_IN,
    output wire [69:0] FRAC70_OUT
);
//
// Internal Signals
wire [ 6:0] shift_inner;
wire [69:0] mask;
wire        sticky;
wire [69:0] frac70;
//
assign shift_inner = (SHIFT > 12'd69)? 7'd127 : SHIFT[6:0];
assign mask   = ~(70'h3fffffffffffffffff << shift_inner);
assign sticky = (mask & FRAC70_IN)? 1'b1 : 1'b0;
assign frac70 = FRAC70_IN >> shift_inner;
assign FRAC70_OUT = {frac70[69:1], frac70[0] | sticky};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Round Judgment
//=====================================================================
module ROUND_JUDGMENT
(
    input  wire       SIGN,
    input  wire       LSB,
    input  wire       GUARD,
    input  wire       ROUND,
    input  wire       STICK,
    output reg        ROUND_ADD,
    input  wire [2:0] RMODE,
    input  wire [4:0] FLAG_IN,
    output wire [4:0] FLAG_OUT
);
//
// Internal Signals
wire [2:0] round_cond;
assign round_cond = {GUARD, ROUND, STICK};
//
// FLAG
assign FLAG_OUT = (round_cond)? (FLAG_IN | `FPU32_FLAG_NX) : (FLAG_IN);  
//
// Judgment
always @*
begin
    casez(round_cond)
        3'b000: ROUND_ADD = 1'b0;
        3'b001: ROUND_ADD = (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b010: ROUND_ADD = (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b011: ROUND_ADD = (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b100: ROUND_ADD = (RMODE == `FPU32_RMODE_RNE)?  LSB  :
                            (RMODE == `FPU32_RMODE_RMM)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RTZ)?  1'b0 :
                            (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b101: ROUND_ADD = (RMODE == `FPU32_RMODE_RNE)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RMM)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RTZ)?  1'b0 :
                            (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b110: ROUND_ADD = (RMODE == `FPU32_RMODE_RNE)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RMM)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RTZ)?  1'b0 :
                            (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        3'b111: ROUND_ADD = (RMODE == `FPU32_RMODE_RNE)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RMM)?  1'b1 :
                            (RMODE == `FPU32_RMODE_RTZ)?  1'b0 :
                            (RMODE == `FPU32_RMODE_RUP)? ~SIGN :
                            (RMODE == `FPU32_RMODE_RDN)?  SIGN :
                            1'b0;
        default: ROUND_ADD = 1'b0;
    endcase
end
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Round Fraction Frac66 to Frac27
//=====================================================================
// FRAC66 : [b65][b64][b63][b62].[b61][b60].....[b39][ G ][ R ][ S ]
// FRAC27 : [b26][b25][b24][b23].[b22][b21].....[b00]
module FRAC27_ROUND_FRAC66
(
    input  wire        SIGN,
    input  wire [65:0] FRAC66,
    output wire [26:0] FRAC27,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLAG_IN,
    output wire [ 4:0] FLAG_OUT
);
//
// Internal Signals
wire lsb;
wire guard;
wire round;
wire stick;
wire round_add;
//
// Extract Conditions
assign lsb   = FRAC66[39];
assign guard = FRAC66[38];
assign round = FRAC66[37];
assign stick = |(FRAC66[36:0]);
//
// Judgement
ROUND_JUDGMENT U_ROUND_JUDGMENT
(
    .SIGN      (SIGN),
    .LSB       (lsb),
    .GUARD     (guard),
    .ROUND     (round),
    .STICK     (stick),
    .ROUND_ADD (round_add),
    .RMODE     (RMODE),
    .FLAG_IN   (FLAG_IN),
    .FLAG_OUT  (FLAG_OUT)
);
//
// Rounding
assign FRAC27 = FRAC66[65:39] + {26'b0, round_add};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Round Fraction Frac132 to Frac70
//=====================================================================
// FRAC132 : [131][130][129][128][127][126][125][124].[123][122].....[b62][ G ][ R ][ S ]
// FRAC70  : [b69][b68][b67][b66][b65][b64][b63][b62].[b61][b60].....[b00]
module FRAC70_ROUND_FRAC132
(
    input  wire         SIGN,
    input  wire [131:0] FRAC132,
    output wire [ 69:0] FRAC70,
    input  wire [  2:0] RMODE,
    input  wire [  4:0] FLAG_IN,
    output wire [  4:0] FLAG_OUT
);
//
// Internal Signals
wire lsb;
wire guard;
wire round;
wire stick;
wire round_add;
//
// Extract Conditions
assign lsb   = FRAC132[62];
assign guard = FRAC132[61];
assign round = FRAC132[60];
assign stick = |(FRAC132[59:0]);
//
// Judgement
ROUND_JUDGMENT U_ROUND_JUDGMENT
(
    .SIGN      (SIGN),
    .LSB       (lsb),
    .GUARD     (guard),
    .ROUND     (round),
    .STICK     (stick),
    .ROUND_ADD (round_add),
    .RMODE     (RMODE),
    .FLAG_IN   (FLAG_IN),
    .FLAG_OUT  (FLAG_OUT)
);
//
// Rounding
assign FRAC70 = FRAC132[131:62] + {69'b0, round_add};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] Make inner79_from_float32
//=====================================================================
// Input : float32[31   ] : sign  1bit
//         float32[30:23] : expo  8bit offset=127 (126 for Subnormal)
//         float32[22: 0] : frac 23bit with Implicit  (b23).[b22]...[b00]
// Output: inner79[78   ] : sign  1bit
//         inner79[77:66] : expo 12bit offset=1023
//         inner79[65: 0] : frac 66bit [b65][b64][b63][b62].[b61]...[b39]...
module INNER79_FROM_FLOAT32
(
    input  wire [31:0] FLOAT32,
    output wire [78:0] INNER79
);
//
// Internal Signals
wire        float32_sign;
wire [ 7:0] float32_expo;
wire [22:0] float32_frac;
wire        inner79_sign;
reg  [11:0] inner79_expo;
reg  [65:0] inner79_frac;
wire [11:0] pos;
//
// Input
assign float32_sign = FLOAT32[31];
assign float32_expo = FLOAT32[30:23];
assign float32_frac = FLOAT32[22: 0]; // bit23 implicit
//
// Sign Bit
assign inner79_sign = float32_sign;
//
// Find 1st One in Frac66 for Subnormal Float32
FIND_1ST_ONE_IN_FRAC66 U_FIND_1ST_ONE_IN_FRAC66
(
    .FRAC66      ({4'b0000, float32_frac, 39'h0}),
    .POS         (pos)
);
//
// Expo and Frac
always @*
begin
    // Subnormal Value
    if (float32_expo == 8'h0)
    begin
        inner79_frac = {4'b0000, float32_frac, 39'h0} << pos;
        inner79_expo = {4'b0000, float32_expo} - 12'd126 + 12'd1023 - pos;
        inner79_frac[62] = 1'b1; // add implicit
    end
    // Normal Value
    else
    begin
        inner79_frac = {4'b0001, float32_frac, 39'h0}; // add implicit
        inner79_expo = {4'h0, float32_expo} - 12'd127 + 12'd1023;
    end
end
//
// Output
assign INNER79 = {inner79_sign, inner79_expo, inner79_frac};
//------------------------
// End of Module
//------------------------
endmodule

//---------------------------------------------------------
// [MODULE] Make Float(32bit) from Inner Representation
//---------------------------------------------------------
// Input : inner79[78   ] : sign  1bit
//         inner79[77:66] : expo 12bit offset=1023
//         inner79[65: 0] : frac 66bit [b65][b64][b63][b62].[b61]...[b00]
// Output: float32[31   ] : sign  1bit
//         float32[30:23] : expo  8bit offset=127 (126 for Subnormal)
//         float32[22: 0] : frac 23bit with Implicit  (b23).[b22]...[b00]
module FLOAT32_FROM_INNER79
(
    input  wire [78:0] INNER79,
    output wire [31:0] FLOAT32,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLAG_IN,
    output wire [ 4:0] FLAG_OUT
);
//
// Internal Signals
wire        inner79_sign;
wire [11:0] inner79_expo;
wire [65:0] inner79_frac;
//
// Input
assign inner79_sign = INNER79[78];
assign inner79_expo = INNER79[77:66];
assign inner79_frac = INNER79[65: 0];
//
// SIGN BIT
wire float32_sign;
assign float32_sign = inner79_sign;
//
// Float32 Zero
wire        float32_zero_select;
wire [11:0] float32_zero_expo;
wire [26:0] float32_zero_frac;
wire [ 4:0] float32_zero_flag;
//assign float32_zero_select = (inner79_expo == 12'd0) & (inner79_frac == 66'd0);
assign float32_zero_select = (inner79_frac == 66'd0);
assign float32_zero_expo = 0;
assign float32_zero_frac = 0;
assign float32_zero_flag = FLAG_IN;
//
// Float32 Too Small Subnormal
wire        float32_toosmall_select;
wire [11:0] float32_toosmall_expo;
wire [26:0] float32_toosmall_frac;
wire [ 4:0] float32_toosmall_flag;
assign float32_toosmall_select = (inner79_expo == 12'd0);
assign float32_toosmall_expo = 0;
assign float32_toosmall_frac = 0;
assign float32_toosmall_flag = FLAG_IN | `FPU32_FLAG_UF;
//
// Inner79 Normal
wire [65:0] inner79_normal_frac;
wire [11:0] float32_sofar_expo;
assign inner79_normal_frac = inner79_frac | 66'h04000000000000000; // add implicit
assign float32_sofar_expo  = inner79_expo - 12'd1023 + 12'd127;
//
// Float32 Overflow
// (float32_sofar_expo >= 255)
wire        float32_overflow_select;
wire [11:0] float32_overflow_expo;
wire [26:0] float32_overflow_frac;
wire [ 4:0] float32_overflow_flag;
assign float32_overflow_select = (float32_sofar_expo[11] == 0) & (float32_sofar_expo >= 12'd255);
assign float32_overflow_expo = ((RMODE == `FPU32_RMODE_RTZ))? 12'd254
                             : ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b1))? 12'd254
                             : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b0))? 12'd254
                             : 12'd255;
assign float32_overflow_frac = ((RMODE == `FPU32_RMODE_RTZ))? 27'h0ffffff
                             : ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b1))? 27'h0ffffff
                             : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b0))? 27'h0ffffff
                             : 24'h000000;
assign float32_overflow_flag = ((RMODE == `FPU32_RMODE_RTZ))? FLAG_IN | `FPU32_FLAG_NX
                             : ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b1))? FLAG_IN | `FPU32_FLAG_NX
                             : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b0))? FLAG_IN | `FPU32_FLAG_NX
                             : FLAG_IN | `FPU32_FLAG_OF;
//
// Float32 Underflow
// frac24 : [b23].[b22][b21].....[b00]
//                                    [   ][b23][b22]....
// (float32_sofar_expo < -24) : -25, -26, ... 
wire        float32_underflow_select;
wire [11:0] float32_underflow_expo;
wire [26:0] float32_underflow_frac;
wire [ 4:0] float32_underflow_flag;
assign float32_underflow_select = (float32_sofar_expo[11]) & (float32_sofar_expo < 12'd4072); // 4096-24
assign float32_underflow_expo = ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b0))? 12'd0
                              : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b1))? 12'd0
                              : 12'd0;
assign float32_underflow_frac = ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b0))? 27'h0000001
                              : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b1))? 27'h0000001
                              : 27'h0000000;
assign float32_underflow_flag = ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b0))?  FLAG_IN | `FPU32_FLAG_NX
                              : ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b1))?  FLAG_IN | `FPU32_FLAG_NX
                              :  FLAG_IN | `FPU32_FLAG_UF;
//
// Float32 Subnormal
// frac64 : [b63][b62].[b61][b60].....[b39]....
// frac24 :      [b23].[b22][b21].....[b00]
//                     [b23][b22]....
//                                         [b23][b22]....
// (float32_sofar_expo < 1)
wire        float32_subnormal_select;
reg  [11:0] float32_subnormal_expo;
reg  [26:0] float32_subnormal_frac;
wire [26:0] float32_subnormal_frac_temp;
wire [26:0] float32_subnormal_frac_temp2;
reg  [ 4:0] float32_subnormal_flag;
wire [ 4:0] float32_subnormal_flag_temp;
//
assign float32_subnormal_select = (float32_sofar_expo[11] & (float32_sofar_expo >= 12'd4072)) | (float32_sofar_expo == 12'd0);
//
wire [11:0] inner79_frac_right_shift;
wire [65:0] inner79_subnormal_frac;
assign inner79_frac_right_shift = 12'd1 - float32_sofar_expo;
SHIFT_RIGHT_FRAC66 U_SHIFT_RIGHT_FRAC66
(
    .SHIFT      (inner79_frac_right_shift),
    .FRAC66_IN  (inner79_normal_frac),
    .FRAC66_OUT (inner79_subnormal_frac)
);
//
FRAC27_ROUND_FRAC66 U_FRAC27_ROUND_FRAC66_SUBNORMAL
(
    .SIGN     (float32_sign),
    .FRAC66   (inner79_subnormal_frac),
    .FRAC27   (float32_subnormal_frac_temp),
    .RMODE    (RMODE),
    .FLAG_IN  (FLAG_IN),
    .FLAG_OUT (float32_subnormal_flag_temp)
);
//
wire [11:0] float32_subnormal_pos;
FIND_1ST_ONE_IN_FRAC27 U_FIND_1ST_ONE_IN_FRAC27_SUBNORMAL
(
    .FRAC27 (float32_subnormal_frac_temp),
    .POS    (float32_subnormal_pos)
);
//
SHIFT_RIGHT_FRAC27 U_SHIFT_RIGHT_FRAC27_SUBNORMAL
(
    .SHIFT      (12'd0 - float32_subnormal_pos), // -pos
    .FRAC27_IN  (float32_subnormal_frac_temp  ),
    .FRAC27_OUT (float32_subnormal_frac_temp2 )
);
//
always @*
begin
    if (float32_subnormal_pos[11]) // float32_subnormal_pos < 0
    begin
        float32_subnormal_expo = 12'd1 - float32_subnormal_pos;
        float32_subnormal_frac = float32_subnormal_frac_temp2;
        float32_subnormal_flag = float32_subnormal_flag_temp;
    end
    else if (float32_subnormal_pos > 12'd0)
    begin
        if (float32_subnormal_frac_temp == 27'd0)
        begin
            float32_subnormal_expo = 8'h0;
            float32_subnormal_frac = 27'd0;
            float32_subnormal_flag = float32_subnormal_flag_temp | `FPU32_FLAG_UF;
        end
        else
        begin
            float32_subnormal_expo = 8'h0;
            float32_subnormal_frac = float32_subnormal_frac_temp;
            float32_subnormal_flag = float32_subnormal_flag_temp;
        end
    end
    else
    begin
        float32_subnormal_expo = 8'h1;
        float32_subnormal_frac = float32_subnormal_frac_temp;
        float32_subnormal_flag = float32_subnormal_flag_temp;
    end
end
//
// Float32 Normal
reg  [11:0] float32_normal_expo;
wire [11:0] float32_normal_expo_temp;
reg  [26:0] float32_normal_frac;
reg  [26:0] float32_normal_frac_temp;
reg  [26:0] float32_normal_frac_temp2;
reg  [ 4:0] float32_normal_flag;
wire [ 4:0] float32_normal_flag_temp;
//
FRAC27_ROUND_FRAC66 U_FRAC27_ROUND_FRAC66_NORMAL
(
    .SIGN     (float32_sign),
    .FRAC66   (inner79_normal_frac),
    .FRAC27   (float32_normal_frac_temp),
    .RMODE    (RMODE),
    .FLAG_IN  (FLAG_IN),
    .FLAG_OUT (float32_normal_flag_temp)
);
//
wire [11:0] float32_normal_pos;
FIND_1ST_ONE_IN_FRAC27 U_FIND_1ST_ONE_IN_FRAC27_NORMAL
(
    .FRAC27 (float32_normal_frac_temp),
    .POS    (float32_normal_pos)
);
//
SHIFT_RIGHT_FRAC27 U_SHIFT_RIGHT_FRAC27_NORMAL
(
    .SHIFT      (12'd1), // 1
    .FRAC27_IN  (float32_normal_frac_temp ),
    .FRAC27_OUT (float32_normal_frac_temp2)
);
assign float32_normal_expo_temp = float32_sofar_expo + 12'd1;
//
always @*
begin
    if (float32_normal_pos[11]) // float32_normal_pos < 0
    begin
        if (float32_normal_expo_temp > 12'd254) // Inf
        begin
            if (RMODE == `FPU32_RMODE_RTZ)
            begin
                float32_normal_expo = 12'd254;
                float32_normal_frac = 27'h0ffffff;
                float32_normal_flag = float32_normal_flag_temp | `FPU32_FLAG_NX;
            end
            else if ((RMODE == `FPU32_RMODE_RUP) && (float32_sign == 1'b1))
            begin
                float32_normal_expo = 12'd254;
                float32_normal_frac = 27'h0ffffff;
                float32_normal_flag = float32_normal_flag_temp | `FPU32_FLAG_NX;
            end
            else if ((RMODE == `FPU32_RMODE_RDN) && (float32_sign == 1'b0))
            begin
                float32_normal_expo = 12'd254;
                float32_normal_frac = 27'h0ffffff;
                float32_normal_flag = float32_normal_flag_temp | `FPU32_FLAG_NX;
            end
            else // Overflow
            begin
                float32_normal_expo = 12'd255;
                float32_normal_frac = 27'h0;
                float32_normal_flag = float32_normal_flag_temp | `FPU32_FLAG_OF;
            end
        end
        else
        begin
            float32_normal_expo = float32_normal_expo_temp;
            float32_normal_frac = float32_normal_frac_temp;
            float32_normal_flag = float32_normal_flag_temp;
        end
    end
    else
    begin
        float32_normal_expo = float32_sofar_expo;
        float32_normal_frac = float32_normal_frac_temp;
        float32_normal_flag = float32_normal_flag_temp;    
    end
end
//
// Final Selection
wire [11:0] float32_expo;
wire [26:0] float32_frac;
wire [ 4:0] float32_flag;
//
assign float32_expo 
    = (float32_zero_select     )? float32_zero_expo
    : (float32_toosmall_select )? float32_toosmall_expo
    : (float32_overflow_select )? float32_overflow_expo
    : (float32_underflow_select)? float32_underflow_expo
    : (float32_subnormal_select)? float32_subnormal_expo
    :                             float32_normal_expo;
assign float32_frac 
    = (float32_zero_select     )? float32_zero_frac
    : (float32_toosmall_select )? float32_toosmall_frac
    : (float32_overflow_select )? float32_overflow_frac
    : (float32_underflow_select)? float32_underflow_frac
    : (float32_subnormal_select)? float32_subnormal_frac
    :                             float32_normal_frac;
assign FLAG_OUT 
    = (float32_zero_select     )? float32_zero_flag
    : (float32_toosmall_select )? float32_toosmall_flag
    : (float32_overflow_select )? float32_overflow_flag
    : (float32_underflow_select)? float32_underflow_flag
    : (float32_subnormal_select)? float32_subnormal_flag
    :                             float32_normal_flag;
//
assign FLOAT32 = {float32_sign, float32_expo[7:0], float32_frac[22:0]};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FADD_CORE
//=====================================================================
// inner79[78   ] : sign  1bit
// inner79[77:66] : expo 12bit offset=1023
// inner79[65: 0] : frac 66bit [b65][b64][b63][b62].[b61]...[b00]
module FADD_CORE
(
    input  wire [78:0] INNER79_IN1,
    input  wire [78:0] INNER79_IN2,
    output wire [78:0] INNER79_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT
);
reg        din1_sign;
reg [11:0] din1_expo;
reg [65:0] din1_frac;
reg        din2_sign;
reg [11:0] din2_expo;
reg [65:0] din2_frac;
reg        dout_sign;
reg [11:0] dout_expo;
reg [65:0] dout_frac;
reg        temp_sign;
reg [11:0] temp_expo;
reg [65:0] temp_frac;
//
reg [1:0] mag; // 0: |din1|=|din2|, 1:|din1|>|din2|, -1:|din1|<|din2|
//
// Shift Fraction to match Exponent 
reg  [11:0] match_expo_shift;
reg  [65:0] match_expo_frac66_in;
wire [65:0] match_expo_frac66_out;
SHIFT_RIGHT_FRAC66 U_SHIFT_RIGHT_FRAC66_MATCH_EXPO
(
    .SHIFT      (match_expo_shift),
    .FRAC66_IN  (match_expo_frac66_in),
    .FRAC66_OUT (match_expo_frac66_out)
);
//
// Normalization
reg  [65:0] normalize_frac66_in;
wire [65:0] normalize_frac66_out;
wire [11:0] normalize_pos;
wire [11:0] normalize_pos_neg;
FIND_1ST_ONE_IN_FRAC66 U_FIND_1ST_ONE_IN_FRAC66_NORMALIZE
(
    .FRAC66 (normalize_frac66_in),
    .POS    (normalize_pos)
);
assign normalize_pos_neg = ~normalize_pos + 12'h1;
SHIFT_RIGHT_FRAC66 U_SHIFT_RIGHT_FRAC66_NORMALIZE
(
    .SHIFT      (normalize_pos_neg),
    .FRAC66_IN  (normalize_frac66_in),
    .FRAC66_OUT (normalize_frac66_out)
);
//
// Main Body of FADD
always @*
begin
    din1_sign = INNER79_IN1[78   ];
    din1_expo = INNER79_IN1[77:66];
    din1_frac = INNER79_IN1[65: 0];
    din2_sign = INNER79_IN2[78   ];
    din2_expo = INNER79_IN2[77:66];
    din2_frac = INNER79_IN2[65: 0];
    dout_sign = 1'b0;
    dout_expo = 12'h0;
    dout_frac = 66'h0;
    temp_sign = 1'b0;
    temp_expo = 12'h0;
    temp_frac = 66'h0;
    FLG_OUT   = FLG_IN; 
    //
    //
    // Compare Magnitude
    if (din1_expo == din2_expo)
    begin
        mag = (din1_frac > din2_frac)? 2'b01
            : (din1_frac < din2_frac)? 2'b11 : 2'b00;
    end
    else
    begin
        mag = (din1_expo > din2_expo)? 2'b01 : 2'b11;
    end
    //
    // Zero Handling
    if (((din1_sign ^ din2_sign) == 1'b1) && (mag == 2'b00))
    begin
        dout_expo = 12'h0;
        dout_frac = 66'h0;
        dout_sign = (RMODE == `FPU32_RMODE_RDN)? 
                    1'b1  // neg zero
                  : 1'b0; // pos zero
    end
    //
    // Non Zero
    else
    begin
        //
        // Preparation for Subtraction
        if (mag == 2'b01)
        begin
            dout_sign = din1_sign;
        end
        else
        // Swap din1 and din2
        begin
            temp_sign = din1_sign; din1_sign = din2_sign; din2_sign = temp_sign;
            temp_expo = din1_expo; din1_expo = din2_expo; din2_expo = temp_expo;
            temp_frac = din1_frac; din1_frac = din2_frac; din2_frac = temp_frac;
            dout_sign = din1_sign;
        end
    end
    //
    // Shift Fraction to match Exponent    
    if (din1_expo > din2_expo)
    begin
        match_expo_shift     = din1_expo - din2_expo;
        match_expo_frac66_in = din2_frac;
        din2_frac = match_expo_frac66_out;
        dout_expo = din1_expo;
    end
    else if (din1_expo < din2_expo)
    begin
        match_expo_shift     = din2_expo - din1_expo;
        match_expo_frac66_in = din1_frac;
        din1_frac = match_expo_frac66_out;
        dout_expo = din2_expo;
    end
    else // if (fin1_expo == fin2_expo)
    begin
        match_expo_shift     = 0;
        match_expo_frac66_in = 0;
        dout_expo = din1_expo;
    end
    //
    // Add/Sub Fractions
    //
    if ((din1_sign ^ din2_sign) == 0)
    begin
        dout_frac =  din1_frac + din2_frac;
    end
    else
    begin
        dout_frac =  din1_frac - din2_frac;
    end
    //
    // Normalization
    normalize_frac66_in = dout_frac;
    // Normal? (from ">= 2.0")
    if (normalize_pos[11]) // if (pos < 0)
    begin
        dout_expo = dout_expo - normalize_pos;
        dout_frac = normalize_frac66_out;
    end
    // Normal? (from "< 1.0")
    else if (dout_expo > normalize_pos)
    begin
        dout_expo = dout_expo - normalize_pos;
        dout_frac = dout_frac << normalize_pos[6:0];
    end
    // Subnormal?
    else if (dout_expo > 0)
    begin
        dout_expo = 12'h1;
        dout_frac = dout_frac << (dout_expo - 12'h1);
    end
end
//
// Output
assign INNER79_OUT = {dout_sign, dout_expo, dout_frac};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FMUL_CORE
//=====================================================================
// inner79[78   ] : sign  1bit
// inner79[77:66] : expo 12bit offset=1023
// inner79[65: 0] : frac 66bit [b65][b64][b63][b62].[b61]...[b00]
module FMUL_CORE
(
    input  wire [78:0] INNER79_IN1,
    input  wire [78:0] INNER79_IN2,
    output wire [78:0] INNER79_OUT,
    input  wire [ 2:0] RMODE,
    input  wire [ 4:0] FLG_IN,
    output reg  [ 4:0] FLG_OUT
);
reg        din1_sign;
reg [11:0] din1_expo;
reg [65:0] din1_frac;
reg        din2_sign;
reg [11:0] din2_expo;
reg [65:0] din2_frac;
reg        dout_sign;
reg [11:0] dout_expo;
reg [65:0] dout_frac;
//
// Round Fraction Frac132 to Frac70
reg          round_sign;
reg  [131:0] round_frac132_in;
wire [ 69:0] round_frac70_out;
//
FRAC70_ROUND_FRAC132 U_FRAC70_ROUND_FRAC132
(
    .SIGN     (round_sign),
    .FRAC132  (round_frac132_in),
    .FRAC70   (round_frac70_out),
    .RMODE    (RMODE),
    .FLAG_IN  (FLG_IN),
    .FLAG_OUT (FLG_OUT)
);
//
// Normalization
reg  [69:0] normalize_frac70_in;
wire [69:0] normalize_frac70_out;
wire [11:0] normalize_pos;
reg  [11:0] normalize_shift;
//
FIND_1ST_ONE_IN_FRAC70 U_FIND_1ST_ONE_IN_FRAC70
(
    .FRAC70 (normalize_frac70_in),
    .POS    (normalize_pos)
);
SHIFT_RIGHT_FRAC70 U_SHIFT_RIGHT_FRAC70
(
    .SHIFT      (normalize_shift),
    .FRAC70_IN  (normalize_frac70_in),
    .FRAC70_OUT (normalize_frac70_out)
);
//
// Main Body of FMUL
always @*
begin
    din1_sign = INNER79_IN1[78   ];
    din1_expo = INNER79_IN1[77:66];
    din1_frac = INNER79_IN1[65: 0];
    din2_sign = INNER79_IN2[78   ];
    din2_expo = INNER79_IN2[77:66];
    din2_frac = INNER79_IN2[65: 0];
    dout_sign = 1'b0;
    dout_expo = 12'h0;
    dout_frac = 66'h0;
    //
    // Sign
    dout_sign = din1_sign ^ din2_sign;
    //
    // Exponent
    dout_expo = din1_expo + din2_expo - 12'd1023;
    //
    // Fraction
    round_frac132_in =  din1_frac * din2_frac;
    //
    // Rounding from 132bit to 70bit
    round_sign = dout_sign;
    //
    // Normalization
    normalize_frac70_in = round_frac70_out;
    normalize_shift = 12'd0 - normalize_pos;
    if (normalize_pos[11]) // whole num > 1.0?
    begin
        dout_expo   = dout_expo - normalize_pos;
        dout_frac = normalize_frac70_out[65:0];
    end
    else
    begin
        dout_frac = round_frac70_out[65:0];
    end
    //
    // Too Small
    if ((din1_expo + din2_expo) < 12'd1023)
    begin
        dout_expo = 12'h0;
        dout_frac = 66'h0;
    end
end
//
// Output
assign INNER79_OUT = {dout_sign, dout_expo, dout_frac};
//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FCVT.W.S / FCVT.WU.S
//=====================================================================
// [FRAC Range]
// 2222 222   000000
// 6543 210   543210
// xxxx.xxxxxxxxxxxx
// 000G.RSx...xxxxxx pos= 0 expo=126 sft=-24 --> 0x00000000 + round
// 0001.GRS...xxxxxx pos= 0 expo=127 sft=-23 --> 0x00000001 + round
// 0001.xxx...xxxGRS pos= 0 expo=147 sft= -3 --> 0x001xxxxx + round
// 0001.xxx...xxxxGR pos= 0 expo=148 sft= -2 --> 0x002xxxxx + round
// 0001.xxx...xxxxxG pos= 0 expo=149 sft= -1 --> 0x004xxxxx + round
// 0001.xxx...xxxxxx pos= 0 expo=150 sft=  0 --> 0x008xxxxx
// 0001.xxx...xxxxxx pos= 0 expo=157 sft= +7 --> 0x4xxxxxxx (S)
// 0001.xxx...xxxxxx pos= 0 expo=158 sft= +8 --> 0x8xxxxxxx (U)
//
// 0000.GRS...xxxxxx pos= 1 expo=127 sft=-23 --> 0x00000000 + round
// 0000.1GRS..xxxxxx pos= 1 expo=128 sft=-22 --> 0x00000001 + round
// 0000.1xGRS.xxxxxx pos= 1 expo=129 sft=-21 --> 0x00000002 + round
// 0000.1xx...xxxGRS pos= 1 expo=147 sft= -3 --> 0x0008xxxx + round
// 0000.1xx...xxxxGR pos= 1 expo=148 sft= -2 --> 0x001xxxxx + round
// 0000.1xx...xxxxxG pos= 1 expo=149 sft= -1 --> 0x002xxxxx + round
// 0000.1xx...xxxxxx pos= 1 expo=150 sft=  0 --> 0x004xxxxx
// 0000.1xx...xxxxxx pos= 1 expo=158 sft= +8 --> 0x4xxxxxxx (S)
// 0000.1xx...xxxxxx pos= 1 expo=159 sft= +9 --> 0x8xxxxxxx (U)
//
// 0000.000...000GRS pos=21 expo=147 sft= -3 --> 0x00000000 + round
// 0000.000...0001GR pos=21 expo=148 sft= -2 --> 0x00000001 + round
// 0000.000...0001xG pos=21 expo=149 sft= -1 --> 0x00000002 + round
// 0000.000...0001xx pos=21 expo=150 sft=  0 --> 0x00000004
// 0000.000...0001xx pos=21 expo=178 sft=+28 --> 0x4xxxxxxx (S)
// 0000.000...0001xx pos=21 expo=179 sft=+29 --> 0x8xxxxxxx (U)
//
// 0000.000...0000GR pos=22 expo=148 sft= -2 --> 0x00000000 + round
// 0000.000...00001G pos=22 expo=149 sft= -1 --> 0x00000001 + round
// 0000.000...00001x pos=22 expo=149 sft=  0 --> 0x00000002
// 0000.000...00001x pos=22 expo=179 sft=+29 --> 0x4xxxxxxx (S)
// 0000.000...00001x pos=22 expo=180 sft=+30 --> 0x8xxxxxxx (U)
//
// 0000.000...00000G pos=23 expo=149 sft= -1 --> 0x00000000 + round
// 0000.000...000001 pos=23 expo=150 sft=  0 --> 0x00000001
// 0000.000...000001 pos=23 expo=180 sft=+30 --> 0x4xxxxxxx (S)
// 0000.000...000001 pos=23 expo=181 sft=+31 --> 0x8xxxxxxx (U)
//
// expo < pos + 126 --> 0x00000000
//      expo        --> sft = expo - 150
// expo > pos + 157 --> 0x7fffffff or 0x80000000 (S)
// expo > pos + 158 --> 0xffffffff (U)
//
module FCVT_F2I
(
    input  wire [31:0] FLOAT_IN,
    output reg  [31:0] INT_OUT,
    input  wire        SIGNED,
    input  wire [ 2:0] RMODE,
    output reg  [ 4:0] FLG_OUT
);
//
wire        sign;
wire [11:0] expo;
wire [26:0] frac;
//
assign sign = FLOAT_IN[31];
assign expo = (FLOAT_IN[30:23] == 8'h00)? 12'h01 : {4'b0000, FLOAT_IN[30:23]};
assign frac = (FLOAT_IN[30:23] == 8'h00)? 
    {4'b0000, FLOAT_IN[22:0]}
  : {4'b0001, FLOAT_IN[22:0]};
//
wire [11:0] pos;
//
FIND_1ST_ONE_IN_FRAC27 U_FIND_1ST_ONE_IN_FRAC27
(
    .FRAC27 (frac),
    .POS    (pos)
);
//
wire judge_zro;
wire judge_inf_s;
wire judge_inf_u;
wire judge_gen_s;
wire judge_gen_u;
//
assign judge_zro   = expo < (pos + 12'd126);
assign judge_inf_s = expo > (pos + 12'd157);
assign judge_inf_u = expo > (pos + 12'd158);
assign judge_gen_s = ~judge_zro & ~judge_inf_s;
assign judge_gen_u = ~judge_zro & ~judge_inf_u;
//
wire [31:0] uint32_data;
assign uint32_data = (expo > 12'd150)? {5'h0, frac} << (expo - 12'd150)
                   : (expo < 12'd150)? {5'h0, frac} >> (12'd150 - expo)
                   : {5'h0, frac};
//
wire [11:0] bit_lsb;
wire [11:0] bit_guard;
wire [11:0] bit_round;
wire [11:0] bit_stick;
//
assign bit_lsb   = (12'd150 >= expo)? 12'd150 - expo : 12'hfff;
assign bit_guard = (12'd149 >= expo)? 12'd149 - expo : 12'hfff;
assign bit_round = (12'd148 >= expo)? 12'd148 - expo : 12'hfff;
assign bit_stick = (12'd147 >= expo)? 12'd147 - expo : 12'hfff;
//
wire        lsb;
wire        guard;
wire        round;
wire        stick;
wire [26:0] stick_mask;
//
assign lsb   = (bit_lsb   < 12'd27)? frac[bit_lsb  ] : 1'b0;
assign guard = (bit_guard < 12'd27)? frac[bit_guard] : 1'b0;
assign round = (bit_round < 12'd27)? frac[bit_round] : 1'b0;
assign stick_mask = (bit_stick < 12'd27)? 27'h7ffffff >> (12'd26 - bit_stick) : 27'h0;
assign stick = |(frac & stick_mask);
//
wire        inexact;
wire [26:0] inexact_mask;
assign inexact_mask = (bit_guard < 12'd27)? 27'h7ffffff >>  (12'd26 - bit_guard) : 27'h0;
assign inexact = |(frac & inexact_mask);
//
wire        round_add;
wire [ 4:0] round_flg;
//
ROUND_JUDGMENT U_ROUND_JUDGMENT
(
    .SIGN      (sign),
    .LSB       (lsb),
    .GUARD     (guard),
    .ROUND     (round),
    .STICK     (stick),
    .ROUND_ADD (round_add),
    .RMODE     (RMODE),
    .FLAG_IN   (`FPU32_FLAG_OK),
    .FLAG_OUT  (round_flg)
);
//
wire [31:0] uint32_data_round;
assign uint32_data_round = uint32_data + {31'h0, round_add};
// Is above correct? --> OK, because frac is 24bit and uint32 is 32bit.
//
wire [ 3:0] ftype;
//
CHECK_FTYPE U_CHECK_FTYPE
(
    .FDATA (FLOAT_IN),
    .FTYPE (ftype)
);
//
always @*
begin
    if (SIGNED) // signed 
    begin
             if (ftype == `FPU32_FT_POSINF) INT_OUT = 32'h7fffffff;
        else if (ftype == `FPU32_FT_POSQNA) INT_OUT = 32'h7fffffff;
        else if (ftype == `FPU32_FT_POSSNA) INT_OUT = 32'h7fffffff;
        else if (ftype == `FPU32_FT_NEGINF) INT_OUT = 32'h80000000;
        else if (ftype == `FPU32_FT_NEGQNA) INT_OUT = 32'h7fffffff;
        else if (ftype == `FPU32_FT_NEGSNA) INT_OUT = 32'h7fffffff;
        else if (ftype == `FPU32_FT_POSZRO) INT_OUT = 32'h00000000;
        else if (ftype == `FPU32_FT_NEGZRO) INT_OUT = 32'h00000000;
        else if (judge_zro                ) INT_OUT = 32'h00000000;
        else if (judge_inf_s & ~sign      ) INT_OUT = 32'h7fffffff;
        else if (judge_inf_s &  sign      ) INT_OUT = 32'h80000000;
        else if (~sign) INT_OUT = uint32_data_round;
        else if ( sign) INT_OUT = 32'h0 - uint32_data_round;
        else INT_OUT = 32'h00000000;
    end
    else // unsigned
    begin
             if (ftype == `FPU32_FT_POSINF) INT_OUT = 32'hffffffff;
        else if (ftype == `FPU32_FT_POSQNA) INT_OUT = 32'hffffffff;
        else if (ftype == `FPU32_FT_POSSNA) INT_OUT = 32'hffffffff;
        else if (ftype == `FPU32_FT_NEGINF) INT_OUT = 32'h00000000;
        else if (ftype == `FPU32_FT_NEGQNA) INT_OUT = 32'hffffffff;
        else if (ftype == `FPU32_FT_NEGSNA) INT_OUT = 32'hffffffff;
        else if (ftype == `FPU32_FT_POSZRO) INT_OUT = 32'h00000000;
        else if (ftype == `FPU32_FT_NEGZRO) INT_OUT = 32'h00000000;
        else if (judge_zro                ) INT_OUT = 32'h00000000;
        else if (judge_inf_u & ~sign      ) INT_OUT = 32'hffffffff;
        else if (judge_inf_u &  sign      ) INT_OUT = 32'h00000000;
        else if (~sign) INT_OUT = uint32_data_round;
        else if ( sign) INT_OUT = 32'h00000000;
        else INT_OUT = 32'h00000000;
    end
end
//
always @*
begin
    if (SIGNED) // signed 
    begin
             if (ftype == `FPU32_FT_POSINF) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSQNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSSNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGINF) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGQNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGSNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSZRO) FLG_OUT = `FPU32_FLAG_OK;
        else if (ftype == `FPU32_FT_NEGZRO) FLG_OUT = `FPU32_FLAG_OK;
        else if (judge_zro                ) FLG_OUT = `FPU32_FLAG_OK;
        else if (judge_inf_s              ) FLG_OUT = `FPU32_FLAG_NV;
        else if (inexact                  ) FLG_OUT = `FPU32_FLAG_NX;
        else FLG_OUT = `FPU32_FLAG_OK;
    end
    else // unsigned
    begin
             if (ftype == `FPU32_FT_POSINF) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSQNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSSNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGINF) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGQNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_NEGSNA) FLG_OUT = `FPU32_FLAG_NV;
        else if (ftype == `FPU32_FT_POSZRO) FLG_OUT = `FPU32_FLAG_OK;
        else if (ftype == `FPU32_FT_NEGZRO) FLG_OUT = `FPU32_FLAG_OK;
        else if (judge_zro                ) FLG_OUT = `FPU32_FLAG_OK;
        else if (judge_inf_u              ) FLG_OUT = `FPU32_FLAG_NV;
        else if (inexact                  ) FLG_OUT = `FPU32_FLAG_NX;
        else if (sign                     ) FLG_OUT = `FPU32_FLAG_NV;
        else FLG_OUT = `FPU32_FLAG_OK;
    end
end

//------------------------
// End of Module
//------------------------
endmodule

//=====================================================================
// [MODULE] FCVT.S.W / FCVT.S.WU
//=====================================================================
// Unsigned Integer : 0x00000000 - 0xffffffff sign=0
// Signed Integer(+): 0x00000000 - 0x7fffffff sign=0
// Signed Integer(-): 0x00000001 - 0x80000000 sign=1
//
// 33222222222211111111110000000000
// 10987654321098765432109876543210
// --------------------------------
// 00000000000000000000000000000000 -->        expo=  0 frac=0x000000 (include decimal point)
// 00000000000000000000000000000001 --> pos= 0 expo=127 frac=0x800000
// 00000000000000000000000000000010 --> pos= 1 expo=128 frac=0x800000
// 00000000000000000000000000000100 --> pos= 2 expo=129 frac=0x800000
// ....
// 00000000010000000000000000000000 --> pos=22 expo=149 frac=0x800000
// 0000000010000000000000000000000L --> pos=23 expo=150 frac=0x800000 + round
// 000000010000000000000000000000LG --> pos=24 expo=151 frac=0x800000 + round
// 00000010000000000000000000000LGR --> pos=25 expo=152 frac=0x800000 + round
// 0000010000000000000000000000LGRS --> pos=26 expo=153 frac=0x800000 + round
// 000010000000000000000000000LGRSx --> pos=27 expo=154 frac=0x800000 + round
// 00010000000000000000000000LGRSxx --> pos=28 expo=155 frac=0x800000 + round
// 0010000000000000000000000LGRSxxx --> pos=29 expo=156 frac=0x800000 + round
// 010000000000000000000000LGRSxxxx --> pos=30 expo=157 frac=0x800000 + round
// 10000000000000000000000LGRSxxxxx --> pos=31 expo=158 frac=0x800000 + round
//
module FCVT_I2F
(
    input  wire [31:0] INT_IN,
    output reg  [31:0] FLOAT_OUT,
    input  wire        SIGNED,
    input  wire [ 2:0] RMODE,
    output wire [ 4:0] FLG_OUT
);
//
integer i;
//
// Pre Process
wire        sign;
wire [31:0] uint32_data;
assign sign        = (SIGNED)? INT_IN[31] : 1'b0;
assign uint32_data = (SIGNED & sign)? (32'h0 - INT_IN) : INT_IN;
//
// Find 1st One
reg  [4:0] pos;
always @*
begin : BLOCK_TO_BREAK
    for (i = 0; i < 32; i = i + 1)
    begin
        pos = 5'd31 - i;
        if (uint32_data[31 - i]) disable BLOCK_TO_BREAK;
    end
end
//
// Exponent
wire [7:0] expo;
assign expo = 8'd127 + pos;
//
// Fraction
wire [31:0] frac32;
wire [23:0] frac;
assign frac32 = uint32_data << (5'd31 - pos);
assign frac   = frac32[31:8];
//
// Rounding
wire lsb;
wire guard;
wire round;
wire stick;
wire stick_mask;
assign lsb   = (pos >= 5'd23)? uint32_data[pos - 5'd23] : 1'b0;
assign guard = (pos >= 5'd24)? uint32_data[pos - 5'd24] : 1'b0;
assign round = (pos >= 5'd25)? uint32_data[pos - 5'd25] : 1'b0;
assign stick_mask = (pos >= 5'd26)? 32'h3f >> (5'd31 - pos) : 32'h0;
assign stick = |(uint32_data & stick_mask);
//
wire        round_add;
wire [ 4:0] round_flg;
//
ROUND_JUDGMENT U_ROUND_JUDGMENT
(
    .SIGN      (sign),
    .LSB       (lsb),
    .GUARD     (guard),
    .ROUND     (round),
    .STICK     (stick),
    .ROUND_ADD (round_add),
    .RMODE     (RMODE),
    .FLAG_IN   (`FPU32_FLAG_OK),
    .FLAG_OUT  (round_flg)
);
//
wire [24:0] frac_round;
wire [23:0] frac_round2;
assign frac_round  = {1'b0, frac} + {24'h0, round_add};
assign frac_round2 = (frac_round[24])? frac_round[24:1] : frac_round[23:0];
wire [ 7:0] expo2;
assign expo2 = (frac_round[24])? expo + 8'h01 : expo;
//
// Output
assign FLOAT_OUT = (INT_IN == 32'h0)? 32'h00000000
                 : {sign, expo2, frac_round2[22:0]};
assign FLG_OUT = (INT_IN == 32'h0)? `FPU32_FLAG_OK
               : round_flg;

//------------------------
// End of Module
//------------------------
endmodule
`endif // RISCV_ISA_RV32F

//********************************************************
// Data Format
//********************************************************


// inner79[78   ] : sign  1bit
// inner79[77:66] : expo 12bit offset=1023
// inner79[65: 0] : frac 66bit [b65][b64][b63][b62].[b61]...[b00]
//
// 777 7777 7766 6666 6666
// 876 5432 1098 7654 3210
// see eeee eeee eeff ffff
// 000 1111 1111 1100 0100 

//===========================================================
// End of File
//===========================================================
