//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_top.v
// Description : Top Layer of CPU
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================

`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module CPU_TOP
(
    input wire RES_SYS, // System Reset
    input wire CLK,     // System Clock
    //
    input  wire STBY_REQ,  // System Stand-by Request
    output wire STBY_ACK,  // System Stand-by Acknowledge
    //
    input  wire [31:0] HART_ID,       // Hart ID
    input  wire [31:0] RESET_VECTOR,  // Reset Vecotr
    //
    output wire DEBUG_MODE,  // Debug Mode
    //
    input  wire HART_HALT_REQ,      // HART Halt Command
    output reg  HART_STATUS,        // HART Status (0:Run, 1:Halt) 
    input  wire HART_RESET,         // HART Reset Signal
    input  wire HART_HALT_ON_RESET, // HART Halt on Reset Request    
    input  wire HART_RESUME_REQ,    // HART Resume Request
    output reg  HART_RESUME_ACK,    // HART Resume Acknowledge
    output wire HART_AVAILABLE,     // HART_Available
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
    output wire        BUSI_M_REQ,       // CPU Instruction
    input  wire        BUSI_M_ACK,       // CPU Instruction
    output wire        BUSI_M_SEQ,       // CPU Instruction
    output wire        BUSI_M_CONT,      // CPU Instruction
    output wire [ 2:0] BUSI_M_BURST,     // CPU Instruction
    output wire        BUSI_M_LOCK,      // CPU Instruction
    output wire [ 3:0] BUSI_M_PROT,      // CPU Instruction
    output wire        BUSI_M_WRITE,     // CPU Instruction
    output wire [ 1:0] BUSI_M_SIZE,      // CPU Instruction
    output wire [31:0] BUSI_M_ADDR,      // CPU Instruction
    output wire [31:0] BUSI_M_WDATA,     // CPU Instruction
    input  wire        BUSI_M_LAST,      // CPU Instruction
    input  wire [31:0] BUSI_M_RDATA,     // CPU Instruction
    input  wire [ 3:0] BUSI_M_DONE,      // CPU Instruction
    input  wire [31:0] BUSI_M_RDATA_RAW, // CPU Instruction
    input  wire [ 3:0] BUSI_M_DONE_RAW,  // CPU Instruction
    //
    output wire        BUSD_M_REQ,       // CPU Data
    input  wire        BUSD_M_ACK,       // CPU Data
    output wire        BUSD_M_SEQ,       // CPU Data
    output wire        BUSD_M_CONT,      // CPU Data
    output wire [ 2:0] BUSD_M_BURST,     // CPU Data
    output wire        BUSD_M_LOCK,      // CPU Data
    output wire [ 3:0] BUSD_M_PROT,      // CPU Data
    output wire        BUSD_M_WRITE,     // CPU Data
    output wire [ 1:0] BUSD_M_SIZE,      // CPU Data
    output wire [31:0] BUSD_M_ADDR,      // CPU Data
    output wire [31:0] BUSD_M_WDATA,     // CPU Data
    input  wire        BUSD_M_LAST,      // CPU Data
    input  wire [31:0] BUSD_M_RDATA,     // CPU Data
    input  wire [ 3:0] BUSD_M_DONE,      // CPU Data
    input  wire [31:0] BUSD_M_RDATA_RAW, // CPU Data
    input  wire [ 3:0] BUSD_M_DONE_RAW,  // CPU Data
    //
    `ifdef RISCV_ISA_RV32A
    input  wire        BUSM_S_REQ,   // AHB Monitor for LR/SC
    input  wire        BUSM_S_WRITE, // AHB Monitor for LR/SC
    input  wire [31:0] BUSM_S_ADDR,  // AHB Monitor for LR/SC
    `endif
    //
    input  wire        IRQ_EXT,    // External Interrupt
    input  wire        IRQ_MSOFT,  // Machine SOftware Interrupt
    input  wire        IRQ_MTIME,  // Machine Timer Interrupt
    input  wire [63:0] IRQ,        // Interrupt Request    
    //
    input  wire [31:0] MTIME,  // Timer Counter LSB
    input  wire [31:0] MTIMEH, // Timer Counter MSB
    output wire        DBG_STOP_TIMER  // Stop Timer due to Debug Mode
);

//----------------
// Reset
//----------------
wire res_cpu;

//----------------
// STBY related
//----------------
wire debug_mode_empty;

//------------------
// Data Bus Signals
//------------------
wire        busm_m_req;       // Data Access
wire        busm_m_ack;       // Data Access
wire        busm_m_seq;       // Data Access
wire        busm_m_cont;      // Data Access
wire [ 2:0] busm_m_burst;     // Data Access
wire        busm_m_lock;      // Data Access
wire [ 3:0] busm_m_prot;      // Data Access
wire        busm_m_write;     // Data Access
wire [ 1:0] busm_m_size;      // Data Access
wire [31:0] busm_m_addr;      // Data Access
wire [31:0] busm_m_wdata;     // Data Access
wire        busm_m_last;      // Data Access
wire [31:0] busm_m_rdata;     // Data Access
wire [ 3:0] busm_m_done;      // Data Access
wire [31:0] busm_m_rdata_raw; // Data Access
wire [ 3:0] busm_m_done_raw;  // Data Access
//
wire        busa_m_req;       // Abstract Command Memory Access
wire        busa_m_ack;       // Abstract Command Memory Access
wire        busa_m_seq;       // Abstract Command Memory Access
wire        busa_m_cont;      // Abstract Command Memory Access
wire [ 2:0] busa_m_burst;     // Abstract Command Memory Access
wire        busa_m_lock;      // Abstract Command Memory Access
wire [ 3:0] busa_m_prot;      // Abstract Command Memory Access
wire        busa_m_write;     // Abstract Command Memory Access
wire [ 1:0] busa_m_size;      // Abstract Command Memory Access
wire [31:0] busa_m_addr;      // Abstract Command Memory Access
wire [31:0] busa_m_wdata;     // Abstract Command Memory Access
wire        busa_m_last;      // Abstract Command Memory Access
wire [31:0] busa_m_rdata;     // Abstract Command Memory Access
wire [ 3:0] busa_m_done;      // Abstract Command Memory Access
wire [31:0] busa_m_rdata_raw; // Abstract Command Memory Access
wire [ 3:0] busa_m_done_raw;  // Abstract Command Memory Access

//-----------------------------
// Instruction Fetch Command
//-----------------------------
wire        fetch_start;      // Instruction Fetch Start Request
wire        fetch_stop;       // Instruction Fetch Stop Request
wire        fetch_ack;        // Instruction Fetch Acknowledge
wire [31:0] fetch_addr;       // Instruction Fetch Start Address
wire        decode_req;       // Decode Request
wire        decode_ack;       // Decode Acknowledge
wire [31:0] decode_code;      // Decode Instruction Code
wire [31:0] decode_addr;      // Decode Instruction Address
wire        decode_berr;      // Decode Instruction Bus Error
wire        decode_jump;      // Decode Instruction Jump Target

//---------------------
// Pipeline Stage
//---------------------
wire pipe_id_enable;  // Pipeline ID Stage
wire pipe_ex_enable;  // Pipeline EX Stage
wire pipe_ma_enable;  // Pipeline MA Stage
wire pipe_wb_enable;  // Pipeline WB Stage

//--------------------------------
// Datapath Command and Response
//--------------------------------
wire [13:0] id_dec_src1;  // Decode Source 1 in ID Stage
wire [13:0] id_dec_src2;  // Decode Source 2 in ID Stage
wire [13:0] id_alu_src2;  // ALU Source 2 in ID Stage (CSR)
wire [13:0] ex_alu_src1;  // ALU Source 1 in EX Stage
wire [13:0] ex_alu_src2;  // ALU Source 2 in EX Stage
wire [13:0] ex_alu_src3;  // ALU Source 3 in EX Stage
wire [31:0] ex_alu_imm;   // ALU Immediate Data in EX Stage
wire [13:0] ex_alu_dst1;  // ALU Destination 1 in EX Stage
wire [13:0] ex_alu_dst2;  // ALU Destination 2 in EX Stage
wire [ 4:0] ex_alu_func;  // ALU Function in EX Stage
wire [ 4:0] ex_alu_shamt; // ALU Shift Amount in EX Stage
wire [31:0] ex_pc;        // Current PC in EX Stage
wire [ 4:0] id_macmd;     // Memory Access Command in ID Stage
wire [ 4:0] ex_macmd;     // Memory Access Command in EX Stage
wire [ 4:0] wb_macmd;     // Memory Access Command in WB Stage
wire [13:0] ex_stsrc;     // Memory Store Source in EX Stage
wire [13:0] wb_load_dst;  // Memory Load Destination in WB Stage
wire        ex_mardy;     // Memory Address Ready in EX Stage 
wire        ma_mdrdy;     // Memory Data Ready in MA Stage 
wire [31:0] id_busa;      // busA in ID Stage
wire [31:0] id_busb;      // busB in ID Stage
wire [ 2:0] id_cmp_func;  // Comparator Function in ID Stage
wire        id_cmp_rslt;  // Comparator Result in ID Stage
wire [ 2:0] ex_mul_func;  // MultiPlier Function in EX Stage
wire [ 2:0] id_div_func;  // Divider Function in ID Stage
wire [ 2:0] ex_div_func;  // Divider Function in EX Stage
wire        id_div_exec;  // Divider Invoke Execution in ID Stage
wire        id_div_stop;  // Divider Abort
wire        id_div_busy;  // Divider in busy
wire        id_div_chek;  // DIvision Illegal Check in ID Stage
wire        ex_div_zero;  // Division by Zero in EX Stage
wire        ex_div_over;  // Division Overflow in EX Stage
//
wire        ex_amo_1stld; // AMO 1st Load Access
wire        ex_amo_2ndst; // AMO 2nd Store Access
wire        ex_amo_lrsvd; // AMO Load Reserved
wire        ex_amo_scond; // AMO Store Conditional
//
wire [ 1:0] ex_buserr_align; // Memory Bus Access Error by Misalignment (bit1:R/W, bit0:ERR)
wire [ 1:0] wb_buserr_fault; // Memory Bus Access Error by Bus Fault    (bit1:R/W, bit0:ERR)
wire [31:0] ex_buserr_addr;  // Memory Bus Access Error Address in EX Stage 
wire [31:0] wb_buserr_addr;  // Memory Bus Access Error Address in WB Stage

//------------------------------
// CSR Access
//------------------------------
wire        ex_csr_req;   // CSR Access Request
wire        ex_csr_write; // CSR Write
wire [11:0] ex_csr_addr;  // CSR Address
wire [31:0] ex_csr_wdata; // CSR Write Data
wire [31:0] ex_csr_rdata; // CSR Read Data
//
wire        dbgabs_csr_req;   // Debug Abstract Command Request for CSR
wire        dbgabs_csr_write; // Debug Abstract Command Write   for CSR
wire [11:0] dbgabs_csr_addr;  // Debug Abstract Command Address for CSR
wire [31:0] dbgabs_csr_wdata; // Debug Abstract Command Write Data for CSR
wire [31:0] dbgabs_csr_rdata; // Debug Abstract Command Read  Data for CSR
//
wire        csr_int_dbg_req;   // Request for CSR_INT
wire        csr_int_dbg_write; // Write   for CSR_INT
wire [11:0] csr_int_dbg_addr;  // Address for CSR_INT
wire [31:0] csr_int_dbg_wdata; // Write Data for CSR_INT
wire [31:0] csr_int_dbg_rdata; // Read  Data for CSR_INT
wire        csr_int_cpu_req;   // Request for CSR_INT
wire        csr_int_cpu_write; // Write   for CSR_INT
wire [11:0] csr_int_cpu_addr;  // Address for CSR_INT
wire [31:0] csr_int_cpu_wdata; // Write Data for CSR_INT
wire [31:0] csr_int_cpu_rdata; // Read  Data for CSR_INT
//
wire        csr_dbg_dbg_req;   // Request for CSR_DBG
wire        csr_dbg_dbg_write; // Write   for CSR_DBG
wire [11:0] csr_dbg_dbg_addr;  // Address for CSR_DBG
wire [31:0] csr_dbg_dbg_wdata; // Write Data for CSR_DBG
wire [31:0] csr_dbg_dbg_rdata; // Read  Data for CSR_DBG
wire        csr_dbg_cpu_req;   // Request for CSR_DBG
wire        csr_dbg_cpu_write; // Write   for CSR_DBG
wire [11:0] csr_dbg_cpu_addr;  // Address for CSR_DBG
wire [31:0] csr_dbg_cpu_wdata; // Write Data for CSR_DBG
wire [31:0] csr_dbg_cpu_rdata; // Read  Data for CSR_DBG

//--------------------------
// CPU Register Access
//--------------------------
wire        dbgabs_gpr_req;   // Debug Abstract Command Request for GPR
wire        dbgabs_gpr_write; // Debug Abstract Command Write   for GPR
wire [11:0] dbgabs_gpr_addr;  // Debug Abstract Command Address for GPR
wire [31:0] dbgabs_gpr_wdata; // Debug Abstract Command Write Data for GPR
wire [31:0] dbgabs_gpr_rdata; // Debug Abstract Command Read  Data for GPR
//
wire        dbgabs_fpr_req;   // Debug Abstract Command Request for FPR
wire        dbgabs_fpr_write; // Debug Abstract Command Write   for FPR
wire [11:0] dbgabs_fpr_addr;  // Debug Abstract Command Address for FPR
wire [31:0] dbgabs_fpr_wdata; // Debug Abstract Command Write Data for FPR
wire [31:0] dbgabs_fpr_rdata; // Debug Abstract Command Read  Data for FPR

//----------------------
// Interrupt
//----------------------
wire        intctrl_req; // Interrupt Controller Request
wire [ 5:0] intctrl_num; // Interrupt Controller Request Number
wire        intctrl_ack; // Interrupt Controller Acknowledge

//----------------------
// Exception
//----------------------
wire [31:0] mtvec_int;    // Trap Vector for Interrupt
wire [31:0] mtvec_exp;    // Trap Vector for Exception
wire [31:0] mtval;        // Trap Value
wire [31:0] mepc_save;    // Exception PC to be saved
wire [31:0] mepc_load;    // Exception PC to be loaded
wire [31:0] mcause;       // Cause of Exception
wire        exp_ack;      // Exception Acknowledge
wire        mret_ack;     // MRET Acknowledge
wire        int_req;      // Interrupt Request to CPU
wire        int_ack;      // Interrupt Acknowledge from CPU
wire        wfi_waiting;  // WFI Waiting for Interrupt
wire        wfi_thru_req; // WFI Through Request by Interrupt Edge duging MIE=0
wire        wfi_thru_ack; // WFI Through Acknowledge

//----------------------
// Debug Control
//----------------------
wire        dbg_stop_count;  // Stop Counter due to Debug Mode
wire        dbg_mie_step;    // Master Interrupt Enable during Step
wire        dbg_halt_req;    // HALT Request
wire        dbg_halt_ack;    // HALT Acknowledge
wire        dbg_halt_reset;  // HALT when Reset
wire        dbg_halt_ebreak; // HALT when EBREAK
wire        dbg_resume_req;  // Resume Request 
wire        dbg_resume_ack;  // Resume Acknowledge 
wire [31:0] dbg_dpc_save;    // Debug PC to be saved
wire [31:0] dbg_dpc_load;    // Debug PC to be loaded
wire [ 2:0] dbg_cause;       // Debug Entry Cause
//
wire        csr_dcsr_step;   // Step bit in CSR_DCSR

//-------------------------
// Instruction Retired
//-------------------------
wire        instr_exec; // Instruction Retired
wire [31:0] instr_addr; // Instruction Retired Address
wire [31:0] instr_code; // Instruction Retired Code

//-------------------
// Trigger Function
//-------------------
wire [19:0]            trg_cnd_bus        [0:`TRG_CH_BUS-1];
wire [`TRG_CH_BUS-1:0] trg_cnd_bus_chain  [0:`TRG_CH_BUS-1];
wire                   trg_cnd_bus_action [0:`TRG_CH_BUS-1];
wire [ 3:0]            trg_cnd_bus_match  [0:`TRG_CH_BUS-1];
wire [31:0]            trg_cnd_bus_mask   [0:`TRG_CH_BUS-1];
wire                   trg_cnd_bus_hit    [0:`TRG_CH_BUS-1];
wire [31:0]            trg_cnd_tdata2     [0:`TRG_CH_BUS-1];
wire                   trg_cnd_icount_hit;
wire                   trg_cnd_icount_act;
wire                   trg_cnd_icount_dec;
//
wire [ 1:0] trg_req_inst; // Trigger Request by Instruction (bit1:action, bit0:hit)
wire [ 1:0] trg_req_data; // Trigger Request by Data Access (bit1:action, bit0:hit)
wire        trg_ack_inst; // Trigger Acknowledge for TRG_REQ_INST
wire        trg_ack_data; // Trigger Acknowledge for TRG_REQ_DATA
wire        trg_req_inst_mask;  // Mask Trigger Request by Instruction


//-------------------
// FPU Interface
//-------------------
wire [13:0] id_fpu_src1;  // FPU Source 1 in ID Stage
wire [13:0] id_fpu_src2;  // FPU Source 2 in ID Stage
wire [13:0] id_fpu_src3;  // FPU Source 3 in ID Stage
wire [13:0] id_fpu_dst1;  // FPU Destination 1 in ID Stage
wire [ 7:0] id_fpu_cmd;   // FPU Command in ID Stage
wire [ 2:0] id_fpu_rmode; // FPU Round Mode in ID Stage
wire        id_fpu_stall; // FPU Stall Request in ID Stage
//
wire [31:0] ex_fpu_srcdata; // FPU Source Data
wire [31:0] ex_fpu_dstdata; // FPU Destinaton Data
wire [31:0] ex_fpu_st_data; // FPU Memory Store Data in EX Stage
wire [31:0] wb_fpu_ld_data; // FPU Memory Load Data in WB Stage
//
wire        csr_fpu_dbg_req;   // FPU CSR Access Request
wire        csr_fpu_dbg_write; // FPU CSR Access Write
wire [11:0] csr_fpu_dbg_addr;  // FPU CSR Access Address
wire [31:0] csr_fpu_dbg_wdata; // FPU CSR Access Write Data
wire [31:0] csr_fpu_dbg_rdata; // FPU CSR Access Read Data
wire        csr_fpu_cpu_req;   // FPU CSR Access Request
wire        csr_fpu_cpu_write; // FPU CSR Access Write
wire [11:0] csr_fpu_cpu_addr;  // FPU CSR Access Address
wire [31:0] csr_fpu_cpu_wdata; // FPU CSR Access Write Data
wire [31:0] csr_fpu_cpu_rdata; // FPU CSR Access Read Data
//
wire        fpucsr_dirty;         // FPU CSR is Dirty
wire        set_mstatus_fs_dirty; // Set MSTATUS FS Field as Dirty

//-------------------------
// Instruction Fetch Unit
//-------------------------
CPU_FETCH U_CPU_FETCH
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    // Instruction Fetch Command
    .FETCH_START      (fetch_start),      // Instruction Fetch Start Request
    .FETCH_STOP       (fetch_stop),       // Instruction Fetch Stop Request
    .FETCH_ACK        (fetch_ack),        // Instruction Fetch Acknowledge
    .FETCH_ADDR       (fetch_addr),       // Instruction Fetch Start Address
    .DECODE_REQ       (decode_req),       // Decode Request
    .DECODE_ACK       (decode_ack),       // Decode Acknowledge
    .DECODE_CODE      (decode_code),      // Decode Instruction Code
    .DECODE_ADDR      (decode_addr),      // Decode Instruction Address
    .DECODE_BERR      (decode_berr),      // Decode Instruction Bus Error
    .DECODE_JUMP      (decode_jump),      // Decode Instruction Jump Target
    //
    // Instruction Bus
    .BUSI_M_REQ   (BUSI_M_REQ),   // BUS Master Command Request
    .BUSI_M_ACK   (BUSI_M_ACK),   // BUS Master Command Acknowledge
    .BUSI_M_SEQ   (BUSI_M_SEQ),   // Bus Master Command Sequence
    .BUSI_M_CONT  (BUSI_M_CONT),  // Bus Master Command Continuing
    .BUSI_M_BURST (BUSI_M_BURST), // Bus Master Command Burst
    .BUSI_M_LOCK  (BUSI_M_LOCK),  // Bus Master Command Lock
    .BUSI_M_PROT  (BUSI_M_PROT),  // Bus Master Command Protect
    .BUSI_M_WRITE (BUSI_M_WRITE), // Bus Master Command Write (if 0, read)
    .BUSI_M_SIZE  (BUSI_M_SIZE),  // Bus Master Command Size (0:byte, 1:HWord, 2:Word)
    .BUSI_M_ADDR  (BUSI_M_ADDR),  // Bus Master Command Address
    .BUSI_M_WDATA (BUSI_M_WDATA), // Bus Master Command Write Data
    .BUSI_M_LAST  (BUSI_M_LAST),  // Bus Master Command Last Cycle
    .BUSI_M_RDATA (BUSI_M_RDATA), // Bus Master Command Read Data
    .BUSI_M_DONE  (BUSI_M_DONE),  // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE})
    .BUSI_M_RDATA_RAW (BUSI_M_RDATA_RAW), // Bus Master Command Read Data Unclocked
    .BUSI_M_DONE_RAW  (BUSI_M_DONE_RAW)   // Bus Master Command Done ({BUSERR, EXCEPTION, WRITE, DONE}) Unclocked
);

//----------------------------------
// Datapath Unit
//----------------------------------
CPU_DATAPATH U_CPU_DATAPATH
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    .BUSM_M_REQ       (busm_m_req),       // M Stage Memory Access
    .BUSM_M_ACK       (busm_m_ack),       // M Stage Memory Access
    .BUSM_M_SEQ       (busm_m_seq),       // M Stage Memory Access
    .BUSM_M_CONT      (busm_m_cont),      // M Stage Memory Access
    .BUSM_M_BURST     (busm_m_burst),     // M Stage Memory Access
    .BUSM_M_LOCK      (busm_m_lock),      // M Stage Memory Access
    .BUSM_M_PROT      (busm_m_prot),      // M Stage Memory Access
    .BUSM_M_WRITE     (busm_m_write),     // M Stage Memory Access
    .BUSM_M_SIZE      (busm_m_size),      // M Stage Memory Access
    .BUSM_M_ADDR      (busm_m_addr),      // M Stage Memory Access
    .BUSM_M_WDATA     (busm_m_wdata),     // M Stage Memory Access
    .BUSM_M_LAST      (busm_m_last),      // M Stage Memory Access
    .BUSM_M_RDATA     (busm_m_rdata),     // M Stage Memory Access
    .BUSM_M_DONE      (busm_m_done),      // M Stage Memory Access
    .BUSM_M_RDATA_RAW (busm_m_rdata_raw), // M Stage Memory Access
    .BUSM_M_DONE_RAW  (busm_m_done_raw),  // M Stage Memory Access
    //
    `ifdef RISCV_ISA_RV32A
    .BUSM_S_REQ   (BUSM_S_REQ),   // AHB Monitor for LR/SC
    .BUSM_S_WRITE (BUSM_S_WRITE), // AHB Monitor for LR/SC
    .BUSM_S_ADDR  (BUSM_S_ADDR),  // AHB Monitor for LR/SC
    `endif
    //
    .PIPE_ID_ENABLE (pipe_id_enable), // Pipeline ID Stage
    .PIPE_EX_ENABLE (pipe_ex_enable), // Pipeline EX Stage
    .PIPE_MA_ENABLE (pipe_ma_enable), // Pipeline MA Stage
    .PIPE_WB_ENABLE (pipe_wb_enable), // Pipeline WB Stage
    //
    .ID_DEC_SRC1 (id_dec_src1), // Decode Source 1 in ID Stage
    .ID_DEC_SRC2 (id_dec_src2), // Decode Source 2 in ID Stage
    .ID_ALU_SRC2 (id_alu_src2), // ALU Source 2 in ID Stage (CSR)
    .EX_ALU_SRC1 (ex_alu_src1), // ALU Source 1 in EX Stage
    .EX_ALU_SRC2 (ex_alu_src2), // ALU Source 2 in EX Stage
    .EX_ALU_IMM  (ex_alu_imm),  // ALU Immediate Data in EX Stage
    .EX_ALU_DST1 (ex_alu_dst1), // ALU Destination 1 in EX Stage
    .EX_ALU_DST2 (ex_alu_dst2), // ALU Destination 2 in EX Stage
    .EX_ALU_FUNC (ex_alu_func), // ALU Function in EX Stage
    .EX_ALU_SHAMT(ex_alu_shamt),// ALU Shift Amount in EX Stage
    .EX_PC       (ex_pc),       // Current PC in EX Stage
    .ID_MACMD    (id_macmd),    // Memory Access Command in ID Stage
    .EX_MACMD    (ex_macmd),    // Memory Access Command in EX Stage
    .WB_MACMD    (wb_macmd),    // Memory Access Command in WB Stage
    .EX_STSRC    (ex_stsrc),    // Memory Store Source in EX Stage
    .WB_LOAD_DST (wb_load_dst), // Memory Load Destination in WB Stage
    .EX_MARDY    (ex_mardy),    // Memory Address Ready in EX Stage 
    .MA_MDRDY    (ma_mdrdy),    // Memory Data Ready in MA Stage 
    .ID_BUSA     (id_busa),     // busA in ID Stage
    .ID_BUSB     (id_busb),     // busB in ID Stage
    .ID_CMP_FUNC (id_cmp_func), // Comparator Function in ID Stage
    .ID_CMP_RSLT (id_cmp_rslt), // Comparator Result in ID Stage
    .EX_MUL_FUNC (ex_mul_func), // MultiPlier Function in EX Stage
    .ID_DIV_FUNC (id_div_func),  // Divider Function in ID Stage
    .EX_DIV_FUNC (ex_div_func),  // Divider Function in EX Stage
    .ID_DIV_EXEC (id_div_exec),  // Divider Invoke Execution in ID Stage
    .ID_DIV_STOP (id_div_stop),  // Divider Abort
    .ID_DIV_BUSY (id_div_busy),  // Divider in busy
    .ID_DIV_CHEK (id_div_chek),  // Division Illegal Check in ID Stage
    .EX_DIV_ZERO (ex_div_zero),  // Division by Zero in EX Stage
    .EX_DIV_OVER (ex_div_over),  // Division Overflow in EX Stage
    //
    .EX_AMO_1STLD (ex_amo_1stld), // AMO 1st Load Access
    .EX_AMO_2NDST (ex_amo_2ndst), // AMO 2nd Store Access
    .EX_AMO_LRSVD (ex_amo_lrsvd), // AMO Load Reserved
    .EX_AMO_SCOND (ex_amo_scond), // AMO Store Conditional
    //
    .EXP_ACK   (exp_ack),      // Exception Acknowledge
    .INT_ACK   (int_ack),      // Interrupt Acknowledge from CPU
    //
    .EX_BUSERR_ALIGN (ex_buserr_align), // Memory Bus Access Error by Misalignment
    .WB_BUSERR_FAULT (wb_buserr_fault), // Memory Bus Access Error by Bus Fault
    .EX_BUSERR_ADDR  (ex_buserr_addr),  // Memory Bus Access Error Address in EX Stage 
    .WB_BUSERR_ADDR  (wb_buserr_addr),  // Memory Bus Access Error Address in WB Stage
    //
    .EX_CSR_REQ   (ex_csr_req),   // CSR Access Request
    .EX_CSR_WRITE (ex_csr_write), // CSR Write
    .EX_CSR_ADDR  (ex_csr_addr),  // CSR Address
    .EX_CSR_WDATA (ex_csr_wdata), // CSR Write Data
    .EX_CSR_RDATA (ex_csr_rdata), // CSR Read Data
    //
    .DBGABS_GPR_REQ   (dbgabs_gpr_req),   // Debug Abstract Command Request for GPR
    .DBGABS_GPR_WRITE (dbgabs_gpr_write), // Debug Abstract Command Write   for GPR
    .DBGABS_GPR_ADDR  (dbgabs_gpr_addr),  // Debug Abstract Command Address for GPR
    .DBGABS_GPR_WDATA (dbgabs_gpr_wdata), // Debug Abstract Command Write Data for GPR
    .DBGABS_GPR_RDATA (dbgabs_gpr_rdata)  // Debug Abstract Command Read  Data for GPR
    //
    ,
    .EX_FPU_SRCDATA (ex_fpu_srcdata), // FPU Source Data
    .EX_FPU_DSTDATA (ex_fpu_dstdata), // FPU Destinaton Data
    .EX_FPU_ST_DATA (ex_fpu_st_data), // FPU Memory Store Data in EX Stage
    .WB_FPU_LD_DATA (wb_fpu_ld_data)  // FPU Memory Load Data in WB Stage
);

//----------------------------------
// Pipeline Unit
//----------------------------------
CPU_PIPELINE U_CPU_PIPELINE
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    // Stand-by Control
    .STBY_REQ (STBY_REQ), // System Stand-by Request
    .STBY_ACK (STBY_ACK), // System Stand-by Acknowledge
    //
    // Reset Vector
    .RESET_VECTOR (RESET_VECTOR),  // Reset Vector
    //
    // Instruction Fetch Command
    .FETCH_START      (fetch_start),      // Instruction Fetch Start Request
    .FETCH_STOP       (fetch_stop),       // Instruction Fetch Stop Request
    .FETCH_ACK        (fetch_ack),        // Instruction Fetch Acknowledge
    .FETCH_ADDR       (fetch_addr),       // Instruction Fetch Start Address
    .DECODE_REQ       (decode_req),       // Decode Request
    .DECODE_ACK       (decode_ack),       // Decode Acknowledge
    .DECODE_CODE      (decode_code),      // Decode Instruction Code
    .DECODE_ADDR      (decode_addr),      // Decode Instruction Address
    .DECODE_BERR      (decode_berr),      // Decode Instruction Bus Error
    .DECODE_JUMP      (decode_jump),      // Decode Instruction Jump Target
    //
    .PIPE_ID_ENABLE (pipe_id_enable), // Pipeline ID Stage
    .PIPE_EX_ENABLE (pipe_ex_enable), // Pipeline EX Stage
    .PIPE_MA_ENABLE (pipe_ma_enable), // Pipeline MA Stage
    .PIPE_WB_ENABLE (pipe_wb_enable), // Pipeline WB Stage
    //
    .ID_DEC_SRC1 (id_dec_src1), // Decode Source 1 in ID Stage
    .ID_DEC_SRC2 (id_dec_src2), // Decode Source 2 in ID Stage
    .ID_ALU_SRC2 (id_alu_src2), // ALU Source 2 in ID Stage (CSR)
    .EX_ALU_SRC1 (ex_alu_src1), // ALU Source 1 in EX Stage
    .EX_ALU_SRC2 (ex_alu_src2), // ALU Source 2 in EX Stage
    .EX_ALU_SRC3 (ex_alu_src3), // ALU Source 3 in EX Stage (FPU)
    .EX_ALU_IMM  (ex_alu_imm),  // ALU Immediate Data in EX Stage
    .EX_ALU_DST1 (ex_alu_dst1), // ALU Destination 1 in EX Stage
    .EX_ALU_DST2 (ex_alu_dst2), // ALU Destination 2 in EX Stage
    .EX_ALU_FUNC (ex_alu_func), // ALU Function in EX Stage
    .EX_ALU_SHAMT(ex_alu_shamt),// ALU Shift Amount in EX Stage
    .EX_PC       (ex_pc),       // Current PC in EX Stage
    .ID_MACMD    (id_macmd),    // Memory Access Command in ID Stage
    .EX_MACMD    (ex_macmd),    // Memory Access Command in EX Stage
    .WB_MACMD    (wb_macmd),    // Memory Access Command in WB Stage
    .EX_STSRC    (ex_stsrc),    // Memory Store Source in EX Stage
    .WB_LOAD_DST (wb_load_dst), // Memory Load Destination in WB Stage
    .EX_MARDY    (ex_mardy),    // Memory Address Ready in EX Stage 
    .MA_MDRDY    (ma_mdrdy),    // Memory Data Ready in MA Stage 
    .ID_BUSA     (id_busa),     // busA in ID Stage
    .ID_BUSB     (id_busb),     // busB in ID Stage
    .ID_CMP_FUNC (id_cmp_func), // Comparator Function in ID Stage
    .ID_CMP_RSLT (id_cmp_rslt), // Comparator Result in ID Stage
    .EX_MUL_FUNC (ex_mul_func), // MultiPlier Function in EX Stage
    .ID_DIV_FUNC (id_div_func),  // Divider Function in ID Stage
    .EX_DIV_FUNC (ex_div_func),  // Divider Function in EX Stage
    .ID_DIV_EXEC (id_div_exec),  // Divider Invoke Execution in ID Stage
    .ID_DIV_STOP (id_div_stop),  // Divider Abort
    .ID_DIV_BUSY (id_div_busy),  // Divider in busy
    .ID_DIV_CHEK (id_div_chek),  // Division Illegal Check in ID Stage
    .EX_DIV_ZERO (ex_div_zero),  // Division by Zero in EX Stage
    .EX_DIV_OVER (ex_div_over),  // Division Overflow in EX Stage
    //
    .EX_AMO_1STLD (ex_amo_1stld), // AMO 1st Load Access
    .EX_AMO_2NDST (ex_amo_2ndst), // AMO 2nd Store Access
    .EX_AMO_LRSVD (ex_amo_lrsvd), // AMO Load Reserved
    .EX_AMO_SCOND (ex_amo_scond), // AMO Store Conditional
    //
    .EX_BUSERR_ALIGN (ex_buserr_align), // Memory Bus Access Error by Misalignment
    .WB_BUSERR_FAULT (wb_buserr_fault), // Memory Bus Access Error by Bus Fault
    .EX_BUSERR_ADDR  (ex_buserr_addr),  // Memory Bus Access Error Address in EX Stage 
    .WB_BUSERR_ADDR  (wb_buserr_addr),  // Memory Bus Access Error Address in WB Stage
    //
    .MTVEC_INT (mtvec_int),    // Trap Vector for Interrupt
    .MTVEC_EXP (mtvec_exp),    // Trap Vector for Exception
    .MTVAL     (mtval),        // Trap Value
    .MEPC_SAVE (mepc_save),    // Exception PC to be saved
    .MEPC_LOAD (mepc_load),    // Exception PC to be loaded
    .MCAUSE    (mcause),       // Cause of Exception
    .EXP_ACK   (exp_ack),      // Exception Acknowledge
    .MRET_ACK  (mret_ack),     // MRET Acknowledge
    .INT_REQ   (int_req),      // Interrupt Request to CPU
    .INT_ACK   (int_ack),      // Interrupt Acknowledge from CPU
    //
    .WFI_WAITING  (wfi_waiting),  // WFI Waiting for Interrupt
    .WFI_THRU_REQ (wfi_thru_req), // WFI Through Request by Interrupt Edge duging MIE=0
    .WFI_THRU_ACK (wfi_thru_ack), // WFI Through Acknowledge
    //
    .TRG_REQ_INST (trg_req_inst), // Trigger Request by Instruction (bit1:action, bit0:hit)
    .TRG_REQ_DATA (trg_req_data), // Trigger Request by Data Access (bit1:action, bit0:hit)
    .TRG_ACK_INST (trg_ack_inst), // Trigger Acknowledge for TRG_REQ_INST
    .TRG_ACK_DATA (trg_ack_data), // Trigger Acknowledge for TRG_REQ_DATA
    .TRG_CND_ICOUNT_DEC (trg_cnd_icount_dec), // ICOUNT Decrement
    .TRG_REQ_INST_MASK (trg_req_inst_mask),   // Mask Trigger Request by Instruction
    //
    .INSTR_EXEC (instr_exec), // Instruction Retired
    .INSTR_ADDR (instr_addr), // Instruction Retired Address
    .INSTR_CODE (instr_code), // Instruction Retired Code
    //
    .DBG_HALT_REQ     (dbg_halt_req),    // HALT Request
    .DBG_HALT_ACK     (dbg_halt_ack),    // HALT Acknowledge
    .DBG_HALT_RESET   (dbg_halt_reset),  // HALT when Reset
    .DBG_HALT_EBREAK  (dbg_halt_ebreak), // HALT when EBREAK
    .DBG_RESUME_REQ   (dbg_resume_req),  // Resume Request 
    .DBG_RESUME_ACK   (dbg_resume_ack),  // Resume Acknowledge 
    .DBG_DPC_SAVE     (dbg_dpc_save),    // Debug PC to be saved
    .DBG_DPC_LOAD     (dbg_dpc_load),    // Debug PC to be loaded
    .DBG_CAUSE        (dbg_cause),       // Debug Entry Cause
    .DEBUG_MODE       (DEBUG_MODE),      // Debug Mode
    .DEBUG_MODE_EMPTY (debug_mode_empty) // Debug Mode with Pipeline Empty
    //
    ,
    .ID_FPU_SRC1    (id_fpu_src1),  // FPU Source 1 in ID Stage
    .ID_FPU_SRC2    (id_fpu_src2),  // FPU Source 2 in ID Stage
    .ID_FPU_SRC3    (id_fpu_src3),  // FPU Source 3 in ID Stage
    .ID_FPU_DST1    (id_fpu_dst1),  // FPU Destination 1 in ID Stage
    .ID_FPU_CMD     (id_fpu_cmd),   // FPU Command in ID Stage
    .ID_FPU_RMODE   (id_fpu_rmode), // FPU Round Mode in ID Stage
    .ID_FPU_STALL   (id_fpu_stall), // FPU Stall Request in ID Stage
    .FPUCSR_DIRTY   (fpucsr_dirty)  // FPU CSR is Dirty
);

//---------------------
// CSR
//---------------------
CPU_CSR U_CPU_CSR
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    .HART_ID (HART_ID), // HartID
    //
    .EX_CSR_REQ   (ex_csr_req),   // CSR Access Request
    .EX_CSR_WRITE (ex_csr_write), // CSR Write
    .EX_CSR_ADDR  (ex_csr_addr),  // CSR Address
    .EX_CSR_WDATA (ex_csr_wdata), // CSR Write Data
    .EX_CSR_RDATA (ex_csr_rdata), // CSR Read Data
    //
    .DBGABS_CSR_REQ   (dbgabs_csr_req),   // Debug Abstract Command Request for CSR
    .DBGABS_CSR_WRITE (dbgabs_csr_write), // Debug Abstract Command Write   for CSR
    .DBGABS_CSR_ADDR  (dbgabs_csr_addr),  // Debug Abstract Command Address for CSR
    .DBGABS_CSR_WDATA (dbgabs_csr_wdata), // Debug Abstract Command Write Data for CSR
    .DBGABS_CSR_RDATA (dbgabs_csr_rdata), // Debug Abstract Command Read  Data for CSR
    //
    .CSR_INT_DBG_REQ   (csr_int_dbg_req),   // Request for CSR_INT
    .CSR_INT_DBG_WRITE (csr_int_dbg_write), // Write   for CSR_INT
    .CSR_INT_DBG_ADDR  (csr_int_dbg_addr),  // Address for CSR_INT
    .CSR_INT_DBG_WDATA (csr_int_dbg_wdata), // Write Data for CSR_INT
    .CSR_INT_DBG_RDATA (csr_int_dbg_rdata), // Read  Data for CSR_INT
    .CSR_INT_CPU_REQ   (csr_int_cpu_req),   // Request for CSR_INT
    .CSR_INT_CPU_WRITE (csr_int_cpu_write), // Write   for CSR_INT
    .CSR_INT_CPU_ADDR  (csr_int_cpu_addr),  // Address for CSR_INT
    .CSR_INT_CPU_WDATA (csr_int_cpu_wdata), // Write Data for CSR_INT
    .CSR_INT_CPU_RDATA (csr_int_cpu_rdata), // Read  Data for CSR_INT
    //
    .CSR_DBG_DBG_REQ   (csr_dbg_dbg_req),   // Request for CSR_DBG
    .CSR_DBG_DBG_WRITE (csr_dbg_dbg_write), // Write   for CSR_DBG
    .CSR_DBG_DBG_ADDR  (csr_dbg_dbg_addr),  // Address for CSR_DBG
    .CSR_DBG_DBG_WDATA (csr_dbg_dbg_wdata), // Write Data for CSR_DBG
    .CSR_DBG_DBG_RDATA (csr_dbg_dbg_rdata), // Read  Data for CSR_DBG
    .CSR_DBG_CPU_REQ   (csr_dbg_cpu_req),   // Request for CSR_DBG
    .CSR_DBG_CPU_WRITE (csr_dbg_cpu_write), // Write   for CSR_DBG
    .CSR_DBG_CPU_ADDR  (csr_dbg_cpu_addr),  // Address for CSR_DBG
    .CSR_DBG_CPU_WDATA (csr_dbg_cpu_wdata), // Write Data for CSR_DBG
    .CSR_DBG_CPU_RDATA (csr_dbg_cpu_rdata), // Read  Data for CSR_DBG
    //
    .CSR_FPU_DBG_REQ   (csr_fpu_dbg_req),   // FPU CSR Access Request
    .CSR_FPU_DBG_WRITE (csr_fpu_dbg_write), // FPU CSR Access Write
    .CSR_FPU_DBG_ADDR  (csr_fpu_dbg_addr),  // FPU CSR Access Address
    .CSR_FPU_DBG_WDATA (csr_fpu_dbg_wdata), // FPU CSR Access Write Data
    .CSR_FPU_DBG_RDATA (csr_fpu_dbg_rdata), // FPU CSR Access Read Data
    .CSR_FPU_CPU_REQ   (csr_fpu_cpu_req),   // FPU CSR Access Request
    .CSR_FPU_CPU_WRITE (csr_fpu_cpu_write), // FPU CSR Access Write
    .CSR_FPU_CPU_ADDR  (csr_fpu_cpu_addr),  // FPU CSR Access Address
    .CSR_FPU_CPU_WDATA (csr_fpu_cpu_wdata), // FPU CSR Access Write Data
    .CSR_FPU_CPU_RDATA (csr_fpu_cpu_rdata), // FPU CSR Access Read Data
    //
    .IRQ_EXT   (IRQ_EXT),   // External Interrupt
    .IRQ_MSOFT (IRQ_MSOFT), // Machine Software Interrupt
    .IRQ_MTIME (IRQ_MTIME), // Machine Timer Interrupt
    //
    .INTCTRL_REQ (intctrl_req), // Interrupt Controller Request
    .INTCTRL_NUM (intctrl_num), // Interrupt Controller Request Number
    .INTCTRL_ACK (intctrl_ack), // Interrupt Controller Acknowledge
    //
    .MTVEC_INT (mtvec_int),    // Trap Vector for Interrupt
    .MTVEC_EXP (mtvec_exp),    // Trap Vector for Exception
    .MTVAL     (mtval),        // Trap Value
    .MEPC_SAVE (mepc_save),    // Exception PC to be saved
    .MEPC_LOAD (mepc_load),    // Exception PC to be loaded
    .MCAUSE    (mcause),       // Cause of Exception
    .EXP_ACK   (exp_ack),      // Exception Acknowledge
    .MRET_ACK  (mret_ack),     // MRET Acknowledge
    .INT_REQ   (int_req),      // Interrupt Request to CPU
    .INT_ACK   (int_ack),      // Interrupt Acknowledge from CPU
    //
    .WFI_WAITING  (wfi_waiting),  // WFI Waiting for Interrupt
    .WFI_THRU_REQ (wfi_thru_req), // WFI Through Request by Interrupt Edge duging MIE=0
    .WFI_THRU_ACK (wfi_thru_ack), // WFI Through Acknowledge
    //
    .INSTR_EXEC (instr_exec), // Instruction Retired
    //
    .MTIME  (MTIME),    // Timer Counter LSB
    .MTIMEH (MTIMEH),   // Timer Counter MSB
    //
    .DBG_STOP_COUNT (dbg_stop_count), // Stop Counter due to Debug Mode
    .DBG_MIE_STEP   (dbg_mie_step),   // Master Interrupt Enable during Step
    //
    .SET_MSTATUS_FS_DIRTY (set_mstatus_fs_dirty)  // Set MSTATUS FS Field as Dirty
);

//-----------------------
// CSR for Interrupt
//-----------------------
CPU_CSR_INT U_CPU_CSR_INT
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    .CSR_INT_DBG_REQ   (csr_int_dbg_req),   // Request for CSR_INT
    .CSR_INT_DBG_WRITE (csr_int_dbg_write), // Write   for CSR_INT
    .CSR_INT_DBG_ADDR  (csr_int_dbg_addr),  // Address for CSR_INT
    .CSR_INT_DBG_WDATA (csr_int_dbg_wdata), // Write Data for CSR_INT
    .CSR_INT_DBG_RDATA (csr_int_dbg_rdata), // Read  Data for CSR_INT
    .CSR_INT_CPU_REQ   (csr_int_cpu_req),   // Request for CSR_INT
    .CSR_INT_CPU_WRITE (csr_int_cpu_write), // Write   for CSR_INT
    .CSR_INT_CPU_ADDR  (csr_int_cpu_addr),  // Address for CSR_INT
    .CSR_INT_CPU_WDATA (csr_int_cpu_wdata), // Write Data for CSR_INT
    .CSR_INT_CPU_RDATA (csr_int_cpu_rdata), // Read  Data for CSR_INT
    //
    .IRQ         (IRQ),         // Interrupt Request Input
    .INTCTRL_REQ (intctrl_req), // Interrupt Controller Request
    .INTCTRL_NUM (intctrl_num), // Interrupt Controller Request Number
    .INTCTRL_ACK (intctrl_ack)  // Interrupt Controller Acknowledge
);

//--------------------
// CSR for Debugger
//--------------------
CPU_CSR_DBG U_CPU_CSR_DBG
(
    .RES_SYS  (RES_SYS),  // System Reset
    .RES_CPU  (res_cpu),  // CPU Reset
    .CLK      (CLK),      // System Clock
    .STBY_ACK (STBY_ACK), // System Stand-by Acknowledge
    //
    .HART_HALT_REQ      (HART_HALT_REQ),      // HART Halt Command
    .HART_STATUS        (HART_STATUS),        // HART Status (0:Run, 1:Halt) 
    .HART_RESET         (HART_RESET),         // HART Reset Signal
    .HART_HALT_ON_RESET (HART_HALT_ON_RESET), // HART Halt on Reset Request    
    .HART_RESUME_REQ    (HART_RESUME_REQ),    // HART Resume Request
    .HART_RESUME_ACK    (HART_RESUME_ACK),    // HART Resume Acknowledge
    .HART_AVAILABLE     (HART_AVAILABLE),     // HART_Available
    //
    .CSR_DBG_DBG_REQ   (csr_dbg_dbg_req),   // Request for CSR_DBG
    .CSR_DBG_DBG_WRITE (csr_dbg_dbg_write), // Write   for CSR_DBG
    .CSR_DBG_DBG_ADDR  (csr_dbg_dbg_addr),  // Address for CSR_DBG
    .CSR_DBG_DBG_WDATA (csr_dbg_dbg_wdata), // Write Data for CSR_DBG
    .CSR_DBG_DBG_RDATA (csr_dbg_dbg_rdata), // Read  Data for CSR_DBG
    .CSR_DBG_CPU_REQ   (csr_dbg_cpu_req),   // Request for CSR_DBG
    .CSR_DBG_CPU_WRITE (csr_dbg_cpu_write), // Write   for CSR_DBG
    .CSR_DBG_CPU_ADDR  (csr_dbg_cpu_addr),  // Address for CSR_DBG
    .CSR_DBG_CPU_WDATA (csr_dbg_cpu_wdata), // Write Data for CSR_DBG
    .CSR_DBG_CPU_RDATA (csr_dbg_cpu_rdata), // Read  Data for CSR_DBG
    //
    .DBG_STOP_COUNT (dbg_stop_count), // Stop Counter due to Debug Mode
    .DBG_STOP_TIMER (DBG_STOP_TIMER), // Stop Timer due to Debug Mode
    .DBG_MIE_STEP   (dbg_mie_step),   // Master Interrupt Enable during Step
    //
    .DBG_HALT_REQ   (dbg_halt_req),    // HALT Request
    .DBG_HALT_ACK   (dbg_halt_ack),    // HALT Acknowledge
    .DBG_HALT_RESET (dbg_halt_reset),  // HALT when Reset
    .DBG_HALT_EBREAK(dbg_halt_ebreak), // HALT when EBREAK
    .DBG_RESUME_REQ (dbg_resume_req),  // Resume Request 
    .DBG_RESUME_ACK (dbg_resume_ack),  // Resume Acknowledge 
    .DBG_DPC_SAVE   (dbg_dpc_save),    // Debug PC to be saved
    .DBG_DPC_LOAD   (dbg_dpc_load),    // Debug PC to be loaded
    .DBG_CAUSE      (dbg_cause),       // Debug Entry Cause
    //
    .CSR_DCSR_STEP  (csr_dcsr_step),   // Step bit in CSR_DCSR
    //
    .INSTR_EXEC (instr_exec), // Instruction Retired
    //
    .TRG_CND_BUS        (trg_cnd_bus),
    .TRG_CND_BUS_CHAIN  (trg_cnd_bus_chain),
    .TRG_CND_BUS_ACTION (trg_cnd_bus_action),
    .TRG_CND_BUS_MATCH  (trg_cnd_bus_match),
    .TRG_CND_BUS_MASK   (trg_cnd_bus_mask),
    .TRG_CND_BUS_HIT    (trg_cnd_bus_hit),
    .TRG_CND_TDATA2     (trg_cnd_tdata2),
    .TRG_CND_ICOUNT_HIT (trg_cnd_icount_hit),
    .TRG_CND_ICOUNT_ACT (trg_cnd_icount_act),
    .TRG_CND_ICOUNT_DEC (trg_cnd_icount_dec)
);

//----------------------
// Debug Function
//----------------------
CPU_DEBUG U_CPU_DEBUG
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    .DBGABS_REQ   (DBGABS_REQ),   // Debug Abstract Command Request
    .DBGABS_ACK   (DBGABS_ACK),   // Debug Abstract Command Aknowledge
    .DBGABS_TYPE  (DBGABS_TYPE),  // Debug Abstract Command Type
    .DBGABS_WRITE (DBGABS_WRITE), // Debug Abstract Command Write (if 0, read)
    .DBGABS_SIZE  (DBGABS_SIZE),  // Debug Abstract Command Size (0:byte, 1:HWord, 2:Word)
    .DBGABS_ADDR  (DBGABS_ADDR),  // Debug Abstract Command Address / Reg No.
    .DBGABS_WDATA (DBGABS_WDATA), // Debug Abstract Command Write Data
    .DBGABS_RDATA (DBGABS_RDATA), // Debug Abstract Command Read Data
    .DBGABS_DONE  (DBGABS_DONE),  // Debug Abstract Command Done ({BUSERR, EXCEPT, WRITE, ACK})
    //
    .DBGABS_CSR_REQ   (dbgabs_csr_req),   // Debug Abstract Command Request for CSR
    .DBGABS_CSR_WRITE (dbgabs_csr_write), // Debug Abstract Command Write   for CSR
    .DBGABS_CSR_ADDR  (dbgabs_csr_addr),  // Debug Abstract Command Address for CSR
    .DBGABS_CSR_WDATA (dbgabs_csr_wdata), // Debug Abstract Command Write Data for CSR
    .DBGABS_CSR_RDATA (dbgabs_csr_rdata), // Debug Abstract Command Read  Data for CSR
    //
    .DBGABS_GPR_REQ   (dbgabs_gpr_req),   // Debug Abstract Command Request for GPR
    .DBGABS_GPR_WRITE (dbgabs_gpr_write), // Debug Abstract Command Write   for GPR
    .DBGABS_GPR_ADDR  (dbgabs_gpr_addr),  // Debug Abstract Command Address for GPR
    .DBGABS_GPR_WDATA (dbgabs_gpr_wdata), // Debug Abstract Command Write Data for GPR
    .DBGABS_GPR_RDATA (dbgabs_gpr_rdata), // Debug Abstract Command Read  Data for GPR
    //
    .DBGABS_FPR_REQ   (dbgabs_fpr_req),   // Debug Abstract Command Request for FPR
    .DBGABS_FPR_WRITE (dbgabs_fpr_write), // Debug Abstract Command Write   for FPR
    .DBGABS_FPR_ADDR  (dbgabs_fpr_addr),  // Debug Abstract Command Address for FPR
    .DBGABS_FPR_WDATA (dbgabs_fpr_wdata), // Debug Abstract Command Write Data for FPR
    .DBGABS_FPR_RDATA (dbgabs_fpr_rdata), // Debug Abstract Command Read  Data for FPR
    //
    .BUSA_M_REQ       (busa_m_req),       // Abstract Command Memory Access
    .BUSA_M_ACK       (busa_m_ack),       // Abstract Command Memory Access
    .BUSA_M_SEQ       (busa_m_seq),       // Abstract Command Memory Access
    .BUSA_M_CONT      (busa_m_cont),      // Abstract Command Memory Access
    .BUSA_M_BURST     (busa_m_burst),     // Abstract Command Memory Access
    .BUSA_M_LOCK      (busa_m_lock),      // Abstract Command Memory Access
    .BUSA_M_PROT      (busa_m_prot),      // Abstract Command Memory Access
    .BUSA_M_WRITE     (busa_m_write),     // Abstract Command Memory Access
    .BUSA_M_SIZE      (busa_m_size),      // Abstract Command Memory Access
    .BUSA_M_ADDR      (busa_m_addr),      // Abstract Command Memory Access
    .BUSA_M_WDATA     (busa_m_wdata),     // Abstract Command Memory Access
    .BUSA_M_LAST      (busa_m_last),      // Abstract Command Memory Access
    .BUSA_M_RDATA     (busa_m_rdata),     // Abstract Command Memory Access
    .BUSA_M_DONE      (busa_m_done),      // Abstract Command Memory Access
    .BUSA_M_RDATA_RAW (busa_m_rdata_raw), // Abstract Command Memory Access
    .BUSA_M_DONE_RAW  (busa_m_done_raw),  // Abstract Command Memory Access
    //
    .TRG_CND_BUS        (trg_cnd_bus),
    .TRG_CND_BUS_CHAIN  (trg_cnd_bus_chain),
    .TRG_CND_BUS_ACTION (trg_cnd_bus_action),
    .TRG_CND_BUS_MATCH  (trg_cnd_bus_match),
    .TRG_CND_BUS_MASK   (trg_cnd_bus_mask),
    .TRG_CND_BUS_HIT    (trg_cnd_bus_hit),
    .TRG_CND_TDATA2     (trg_cnd_tdata2),
    .TRG_CND_ICOUNT_HIT (trg_cnd_icount_hit),
    .TRG_CND_ICOUNT_ACT (trg_cnd_icount_act),
    //
    .DEBUG_MODE  (DEBUG_MODE),    // Debug Mode
    .TRG_REQ_INST (trg_req_inst), // Trigger Request by Instruction (bit1:action, bit0:hit)
    .TRG_REQ_DATA (trg_req_data), // Trigger Request by Data Access (bit1:action, bit0:hit)
    .TRG_ACK_INST (trg_ack_inst), // Trigger Acknowledge for TRG_REQ_INST
    .TRG_ACK_DATA (trg_ack_data), // Trigger Acknowledge for TRG_REQ_DATA
    .TRG_REQ_INST_MASK (trg_req_inst_mask), // Mask Trigger Request by Instruction
    //
    .CSR_DCSR_STEP  (csr_dcsr_step),   // Step bit in CSR_DCSR
    //
    .INSTR_EXEC (instr_exec), // Instruction Retired
    .INSTR_ADDR (instr_addr), // Instruction Retired Address
    .INSTR_CODE (instr_code), // Instruction Retired Code
    //
    .BUSM_M_REQ       (busm_m_req),       // M Stage Memory Access
    .BUSM_M_ACK       (busm_m_ack),       // M Stage Memory Access
    .BUSM_M_WRITE     (busm_m_write),     // M Stage Memory Access
    .BUSM_M_SIZE      (busm_m_size),      // M Stage Memory Access
    .BUSM_M_ADDR      (busm_m_addr),      // M Stage Memory Access
    .BUSM_M_WDATA     (busm_m_wdata),     // M Stage Memory Access
    .BUSM_M_RDATA     (busm_m_rdata),     // M Stage Memory Access
    .BUSM_M_LAST      (busm_m_last),      // M Stage Memory Access
    .BUSM_M_DONE      (busm_m_done)       // M Stage Memory Access
);

//----------------------------------------------
// Arbitration b/w busa and busm (busa > busm)
//----------------------------------------------
wire busa_aphase;
wire busm_aphase;
reg  busa_dphase;
reg  busm_dphase;
reg  busa_after;
reg  busm_after;
//
assign busa_aphase = (busa_m_req              );
assign busm_aphase = (busm_m_req & ~busa_m_req);
//
assign busa_m_ack = busa_aphase & BUSD_M_ACK;
assign busm_m_ack = busm_aphase & BUSD_M_ACK;
//
always @(posedge CLK, posedge res_cpu)
begin
    if (res_cpu)
       busa_dphase <= 1'b0;
    else if (busa_m_ack)
       busa_dphase <= 1'b1;
    else if (busa_m_last)
       busa_dphase <= 1'b0;
end
//
always @(posedge CLK, posedge res_cpu)
begin
    if (res_cpu)
       busm_dphase <= 1'b0;
    else if (busm_m_ack)
       busm_dphase <= 1'b1;
    else if (busm_m_last)
       busm_dphase <= 1'b0;
end
//
assign BUSD_M_REQ = busa_aphase | busm_aphase;
//
assign BUSD_M_SEQ   = (busa_aphase)? busa_m_seq
                    : (busm_aphase)? busm_m_seq : 1'b0;
assign BUSD_M_CONT  = (busa_aphase)? busa_m_cont
                    : (busm_aphase)? busm_m_cont : 1'b0;
assign BUSD_M_BURST = (busa_aphase)? busa_m_burst
                    : (busm_aphase)? busm_m_burst : 3'b000;
assign BUSD_M_LOCK  = (busa_aphase)? busa_m_lock
                    : (busm_aphase)? busm_m_lock : 1'b0;
assign BUSD_M_PROT  = (busa_aphase)? busa_m_prot
                    : (busm_aphase)? busm_m_prot : 4'b0000;
assign BUSD_M_WRITE = (busa_aphase)? busa_m_write
                    : (busm_aphase)? busm_m_write : 1'b0;
assign BUSD_M_SIZE  = (busa_aphase)? busa_m_size
                    : (busm_aphase)? busm_m_size : 2'b00;
assign BUSD_M_ADDR  = (busa_aphase)? busa_m_addr
                    : (busm_aphase)? busm_m_addr : 32'h00000000;
assign BUSD_M_WDATA = (busa_aphase)? busa_m_wdata
                    : (busm_aphase)? busm_m_wdata : 32'h00000000;
assign busa_m_last  = (busa_dphase)? BUSD_M_LAST : 1'b0;
assign busm_m_last  = (busm_dphase)? BUSD_M_LAST : 1'b0;
assign busa_m_rdata_raw = (busa_dphase)? BUSD_M_RDATA_RAW : 32'h00000000;
assign busm_m_rdata_raw = (busm_dphase)? BUSD_M_RDATA_RAW : 32'h00000000;
assign busa_m_done_raw  = (busa_dphase)? BUSD_M_DONE_RAW : 4'b0000;
assign busm_m_done_raw  = (busm_dphase)? BUSD_M_DONE_RAW : 4'b0000;
//
always @(posedge CLK, posedge res_cpu)
begin
    if (res_cpu)
        busa_after <= 1'b0;
    else if (busa_m_last)
        busa_after <= 1'b1;
    else if (busa_after)
        busa_after <= 1'b0;
end
//
always @(posedge CLK, posedge res_cpu)
begin
    if (res_cpu)
        busm_after <= 1'b0;
    else if (busm_m_last)
        busm_after <= 1'b1;
    else if (busm_after)
        busm_after <= 1'b0;
end
//
assign busa_m_done  = (busa_after)? BUSD_M_DONE  : 4'b0000;
assign busm_m_done  = (busm_after)? BUSD_M_DONE  : 4'b0000;
assign busa_m_rdata = (busa_after)? BUSD_M_RDATA : 32'h00000000;
assign busm_m_rdata = (busm_after)? BUSD_M_RDATA : 32'h00000000;

//---------------------------------------
// 32bit Single Precision FPU
//---------------------------------------
CPU_FPU32 U_CPU_FPU32
(
    .RES_CPU (res_cpu), // CPU Reset
    .CLK     (CLK),     // System Clock
    //
    .CSR_FPU_DBG_REQ   (csr_fpu_dbg_req),   // FPU CSR Access Request
    .CSR_FPU_DBG_WRITE (csr_fpu_dbg_write), // FPU CSR Access Write
    .CSR_FPU_DBG_ADDR  (csr_fpu_dbg_addr),  // FPU CSR Access Address
    .CSR_FPU_DBG_WDATA (csr_fpu_dbg_wdata), // FPU CSR Access Write Data
    .CSR_FPU_DBG_RDATA (csr_fpu_dbg_rdata), // FPU CSR Access Read Data
    .CSR_FPU_CPU_REQ   (csr_fpu_cpu_req),   // FPU CSR Access Request
    .CSR_FPU_CPU_WRITE (csr_fpu_cpu_write), // FPU CSR Access Write
    .CSR_FPU_CPU_ADDR  (csr_fpu_cpu_addr),  // FPU CSR Access Address
    .CSR_FPU_CPU_WDATA (csr_fpu_cpu_wdata), // FPU CSR Access Write Data
    .CSR_FPU_CPU_RDATA (csr_fpu_cpu_rdata), // FPU CSR Access Read Data
    //
    .DBGABS_FPR_REQ   (dbgabs_fpr_req),   // Debug Abstract Command Request for FPR
    .DBGABS_FPR_WRITE (dbgabs_fpr_write), // Debug Abstract Command Write   for FPR
    .DBGABS_FPR_ADDR  (dbgabs_fpr_addr),  // Debug Abstract Command Address for FPR
    .DBGABS_FPR_WDATA (dbgabs_fpr_wdata), // Debug Abstract Command Write Data for FPR
    .DBGABS_FPR_RDATA (dbgabs_fpr_rdata), // Debug Abstract Command Read  Data for FPR
    //
    .ID_FPU_CMD     (id_fpu_cmd),      // FPU Command in ID Stage
    .ID_FPU_RMODE   (id_fpu_rmode),    // FPU Round Mode in ID Stage
    .ID_FPU_STALL   (id_fpu_stall),    // FPU Stall Request in ID Stage
    .ID_FPU_SRC1    (id_fpu_src1),     // FPU Source Register 1 in ID Stage
    .ID_FPU_SRC2    (id_fpu_src2),     // FPU Source Register 2 in ID Stage
    .ID_FPU_SRC3    (id_fpu_src3),     // FPU Source Register 3 in ID Stage
    .ID_FPU_DST1    (id_fpu_dst1),     // FPU Destinaton Register in ID Stage
    .EX_ALU_SRC1    (ex_alu_src1),     // FPU Source Register 1 in EX Stage
    .EX_ALU_SRC2    (ex_alu_src2),     // FPU Source Register 2 in EX Stage
    .EX_ALU_SRC3    (ex_alu_src3),     // FPU Source Register 3 in EX Stage (FPU)
    .EX_ALU_DST1    (ex_alu_dst1),     // FPU Destinaton Register in EX Stage
    .EX_STSRC       (ex_stsrc),        // FPU Memory Store Source in EX Stage
    .WB_LOAD_DST    (wb_load_dst),     // FPU Memory Load Destination in WB Stage
    //
    .EX_FPU_SRCDATA (ex_fpu_srcdata), // FPU Source Data in EX Stage
    .EX_FPU_DSTDATA (ex_fpu_dstdata), // FPU Destinaton Data in EX Stage
    .EX_FPU_ST_DATA (ex_fpu_st_data), // FPU Memory Store Data in EX Stage
    .WB_FPU_LD_DATA (wb_fpu_ld_data), // FPU Memory Load Data in WB Stage
    //
    .FPUCSR_DIRTY         (fpucsr_dirty),         // FPU CSR is Dirty
    .SET_MSTATUS_FS_DIRTY (set_mstatus_fs_dirty)  // Set MSTATUS FS Field as Dirty
);

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
