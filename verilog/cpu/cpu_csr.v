//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : cpu_csr.v
// Description : CPU CSR (Control and Status Registers)
//-----------------------------------------------------------
// History :
// Rev.01 2021.04.01 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================
//
//===========================================================
// CSR Implemented
//---------------------------------------
// mvendorid : 0xf11 Machine Information Vendor ID
//   bit[31:0] R vendorid  fixed 0x00000000
//---------------------------------------
// marchid : 0xf12 Machine Information Achitecture ID
//   bit[31:0] R archid    fixed 0x6d6d3031 (mm01)
//---------------------------------------
// mimpid : 0xf13 Machine Information Implementation ID
//   bit[31:0] R impid     fixed 0x20210701
//---------------------------------------
// mhartid : 0xf14 Machine Information Hart ID
//   bit[31:0] R hardid    depends on HARTID signal
//---------------------------------------
// mstatus : 0x300 Machine Status
//   bit[31:15] R   reserved Zero
//   bit[14:13] R/W fs       Stete of Floating Point Unit
//   bit[12:11] R   mpp      Previous Privilede Mode, fixed to 11
//   bit[10: 8] R   reserved Zero
//   bit[    7] R/W mpie     Previous Global Interrupt Enable
//   bit[ 6: 4] R   reserved Zero
//   bit[    3] R/W mie      Global Interupt Enable
//   bit[ 2: 0] R   reserved Zero 
//---------------------------------------
// misa : 0x301 Machine Instruction Set Achitecture
//   bit[    0] R   A atmic      (fixed to 0) <--- configurable
//   bit[    1] R   B reserved   (fixed to 0) 
//   bit[    2] R   C compressed (fixed to 1) <--- configurable
//   bit[    3] R   D double fpu (fixed to 0)
//   bit[    4] R   E rv32e      (fixed to 0)
//   bit[    5] R   F single fpu (fixed to 0) <--- configurable
//   bit[    6] R   G reserved   (fixed to 0)
//   bit[    7] R   H hypervisor (fixed to 0)
//   bit[    8] R   I rv32i      (fixed to 1)
//   bit[    9] R   J reserved   (fixed to 0)
//   bit[   10] R   K reserved   (fixed to 0)
//   bit[   11] R   L reserved   (fixed to 0)
//   bit[   12] R   M mul/div    (fixed to 1)
//   bit[   13] R   N user intc  (fixed to 1)
//   bit[   14] R   O reserved   (fixed to 0)
//   bit[   15] R   P reserved   (fixed to 0)
//   bit[   16] R   Q quad fpu   (fixed to 0)
//   bit[   17] R   R reserved   (fixed to 0)
//   bit[   18] R   S s-mode     (fixed to 0)
//   bit[   19] R   T reserved   (fixed to 0)
//   bit[   20] R   U u-mode     (fixed to 0)
//   bit[   21] R   V reserved   (fixed to 0)
//   bit[   22] R   W reserved   (fixed to 0)
//   bit[   23] R   X reserved   (fixed to 0)
//   bit[   24] R   Y reserved   (fixed to 0)
//   bit[   25] R   Z reserved   (fixed to 0)
//   bit[29:26] R     reserved   (fixed to 0000)
//   bit[31:30] R   MXL (32bit)  (fixed to 01)
//---------------------------------------
// mie : 0x304 Machine Interrupt Enable
//   bit[31:12] R   reserved (fixed to 0)
//   bit[   11] R/W meie (machine external interrupt enable)
//   bit[10: 8] R   reserved (fixed to 0)
//   bit[    7] R/W mtie (machine timer interrupt enable)
//   bit[ 6: 4] R   reserved (fixed to 0)
//   bit[    3] R/W msie (machine software interrupt enable)
//   bit[ 2: 0] R   reserved (fixed to 0)
//---------------------------------------
// mtvec : 0x305 Machine Trap Vector Base Address Register
//   bit[31: 2] R/W Vector Base Address (Upper 30bits)
//   bit[ 1: 0] R/W Mode (00:Direct, 01:Vectored, others:reserved)
//     Direct Mode  : All traps including interrupts jump to Vector Base
//     Vectored Mode: Synchronous Traps (not interrupt) jump to  Vector Base
//                    Asynchronous Interrupt jump to (Vector Base) + (Exception Code) x 4
//---------------------------------------
// mscratch : 0x340 Machine Scratch
//   bit[31: 0] R/W Scratch
//---------------------------------------
// mepc : 0x341 Machine Exception Program Counter
//   bit[31: 0] R/W Exception PC (Return Address)
//---------------------------------------
// mcause : 0x342 Machine Cause
//   bit[   31] R/W Interrupt
//   bit[30: 0] R/W Exception Code
//     <Asynchronous> Interrupt = 1
//        mcause  Description (unstated are reserved)
//             3  Machine Software Interrupt (priority is controlled by software)
//             7  Machine Timer Interrupt    (priority is controlled by software)
//            11  Machine External Interrupt (priority is controlled by software)
//            16  Machine IRQ00 (priority is controlled by hardware)
//            17  Machine IRQ01 (priority is controlled by hardware)
//            ..  ....
//            79  Machine IRQ63 (priority is controlled by hardware)
//    <Synchronous> Interrupt = 0
//        mcause Description (unstated are reserved)
//             0  Instruction Address Misaligned
//             1  Instruction Access Fault
//             2  Illegal Instruction
//             3  Breakpoint
//             4  Load Address Misaligned
//             5  Load Access Fault
//             6  Store/AMO(Atomic Memory Operation) Address Misaligned
//             7  Store/AMO Access Fault
//            11  Environment Call from M-mode
//---------------------------------------
// mtval : 0x343 Machine Trap Value
//   bit[31: 0] R  Trap Value
//     Instruction Address Misaligned / Access Fault : Access Address
//     Load/Store Address Misaligned / Access Fault  : Access Address
//     BreakPoint          : Breakpoint Addess
//     Illegal Instruction : The Instruction Code
//     Environment Call    : 0x00000000
//     Interrupt           : 0x00000000
//---------------------------------------
// mip : 0x344 Machine Interrupt Pending
//   bit[31:12] R   reserved (fixed to 0)
//   bit[   11]     meip (machine external interrupt pending)
//   bit[10: 8] R   reserved (fixed to 0)
//   bit[    7] R    mtip (machine timer interrupt pending)
//   bit[ 6: 4] R   reserved (fixed to 0)
//   bit[    3] R   msip (machine software interrupt pending)
//   bit[ 2: 0] R   reserved (fixed to 0)
//---------------------------------------
// mcycle  : 0xb00  Machine Cycle Counter Lower Side
// mcycleh : 0xb80  Machine Cycle Counter Upper Side
//   bit[31: 0] R/W Cycle Counter (Lower/Upper)
//   [NOTE] Writing mcycle stores the value to a write buffer.
//          Writing mcycleh stores the value to mcycleh,
//          and stores the write buffer value to mcycle, simultaneously.
//   [NOTE] Reading mcycle captures {mcycleh:mcycle} into a 64bit
//          capture buffer and outputs lower 32bit of the buffer as read data.
//          Reading mcycleh outputs higher 32bit of the buffer as read data.
//---------------------------------------
// minstret  : 0xb02  Machine Instruction Retired Counter Lower Side
// minstreth : 0xb82  Machine Instruction Retired Counter Upper Side
//   bit[31 :0] R/W  Instruction Retired Counter (Lower/Upper)
//   [NOTE] Reading/Writing these registers follow same manner as mcycle/mcycleh.
//---------------------------------------
// mcountinhibit : 0x320  Machine Counter Inhibit
//   bit[31: 3] R   Reserved (Zero)
//   bit[    2] R/W IR  Inhibit Instruction Retired Counter
//   bit[    1] R   Resesrved (Zero)
//   bit[    0] R/W CY  Inhibit Cycle Counter
//---------------------------------------
// User Mode CSR
//   cycle    : 0xc00  Read-Only Mirror of mcycle
//   time     : 0xc01  Read-Only Mirror of mtime (Memory Mapped MTIME)
//   instret  : 0xc02  Read-Only Mirror of minstret
//   cycleh   : 0xc80  Read-Only Mirror of mcycleh
//   timeh    : 0xc81  Read-Only Mirror of mtimeh (Memory Mapped MTIME)
//   instreth : 0xc82  Read-Only Mirror of minstreth
//   [NOTE] Reading these registers follow same manner as mcycle/mcycleh.
//---------------------------------------

`include "defines.v"

//----------------------
// Define Module
//----------------------
module CPU_CSR
(
    input wire RES_CPU, // CPU Reset
    input wire CLK,     // System Clock
    //
    input wire [31:0] HART_ID, // Hart ID
    //
    input  wire        EX_CSR_REQ,
    input  wire        EX_CSR_WRITE,
    input  wire [11:0] EX_CSR_ADDR,
    input  wire [31:0] EX_CSR_WDATA,
    output wire [31:0] EX_CSR_RDATA,
    //
    input  wire        DBGABS_CSR_REQ,
    input  wire        DBGABS_CSR_WRITE,
    input  wire [11:0] DBGABS_CSR_ADDR,
    input  wire [31:0] DBGABS_CSR_WDATA,
    output reg  [31:0] DBGABS_CSR_RDATA,
    //
    output wire        CSR_INT_DBG_REQ,
    output wire        CSR_INT_DBG_WRITE,
    output wire [11:0] CSR_INT_DBG_ADDR,
    output wire [31:0] CSR_INT_DBG_WDATA,
    input  wire [31:0] CSR_INT_DBG_RDATA,
    output wire        CSR_INT_CPU_REQ,
    output wire        CSR_INT_CPU_WRITE,
    output wire [11:0] CSR_INT_CPU_ADDR,
    output wire [31:0] CSR_INT_CPU_WDATA,
    input  wire [31:0] CSR_INT_CPU_RDATA,
    //
    output wire        CSR_DBG_DBG_REQ,
    output wire        CSR_DBG_DBG_WRITE,
    output wire [11:0] CSR_DBG_DBG_ADDR,
    output wire [31:0] CSR_DBG_DBG_WDATA,
    input  wire [31:0] CSR_DBG_DBG_RDATA,
    output wire        CSR_DBG_CPU_REQ,
    output wire        CSR_DBG_CPU_WRITE,
    output wire [11:0] CSR_DBG_CPU_ADDR,
    output wire [31:0] CSR_DBG_CPU_WDATA,
    input  wire [31:0] CSR_DBG_CPU_RDATA,
    //
    output wire        CSR_FPU_DBG_REQ,   // FPU CSR Access Request
    output wire        CSR_FPU_DBG_WRITE, // FPU CSR Access Write
    output wire [11:0] CSR_FPU_DBG_ADDR,  // FPU CSR Access Address
    output wire [31:0] CSR_FPU_DBG_WDATA, // FPU CSR Access Write Data
    input  wire [31:0] CSR_FPU_DBG_RDATA, // FPU CSR Access Read Data
    output wire        CSR_FPU_CPU_REQ,   // FPU CSR Access Request
    output wire        CSR_FPU_CPU_WRITE, // FPU CSR Access Write
    output wire [11:0] CSR_FPU_CPU_ADDR,  // FPU CSR Access Address
    output wire [31:0] CSR_FPU_CPU_WDATA, // FPU CSR Access Write Data
    input  wire [31:0] CSR_FPU_CPU_RDATA, // FPU CSR Access Read Data
    //
    input  wire        IRQ_EXT,    // External Interrupt
    input  wire        IRQ_MTIME,  // Machine Timer Interrupt
    input  wire        IRQ_MSOFT,  // Machine SOftware Interrupt
    //
    input  reg         INTCTRL_REQ, // Interrupt Controller Request
    input  reg  [ 5:0] INTCTRL_NUM, // Interrupt Controller Request Number
    output wire        INTCTRL_ACK, // Interrupt Controller Acknowledge
    //
    output wire [31:0] MTVEC_INT,    // Trap Vector for Interrupt
    output wire [31:0] MTVEC_EXP,    // Trap Vector for Exception
    input  wire [31:0] MTVAL,        // Trap Value
    input  wire [31:0] MEPC_SAVE,    // Exception PC to be saved
    output wire [31:0] MEPC_LOAD,    // Exception PC to be loaded
    input  wire [31:0] MCAUSE,       // Cause of Exception
    input  wire        EXP_ACK,      // Exception Acknowledge
    input  wire        MRET_ACK,     // MRET Acknowledge
    output wire        INT_REQ,      // Interrupt Request to CPU
    input  wire        INT_ACK,      // Interrupt Acknowledge from CPU
    //
    input  wire        WFI_WAITING,  // WFI Waiting for Interrupt
    output reg         WFI_THRU_REQ, // WFI Through Request by Interrupt Edge duging MIE=0
    input  wire        WFI_THRU_ACK, // WFI Through Acknowledge
    //
    input  wire        INSTR_EXEC, // Instruction Retired
    //
    input  wire [31:0] MTIME,  // Timer Counter LSB
    input  wire [31:0] MTIMEH, // Timer Counter MSB 
    //
    input  wire        DBG_STOP_COUNT, // Stop Counter during Debug Mode
    input  wire        DBG_MIE_STEP,   // Master Interrupt Enable during Step
    //
    input  wire        SET_MSTATUS_FS_DIRTY // Set MSTATUS FS Field as Dirty
);

//----------------------------
// CSR Access
//----------------------------
wire        csr_core_cpu_req;
wire        csr_core_cpu_write;
wire [11:0] csr_core_cpu_addr;
wire [31:0] csr_core_cpu_wdata;
wire [31:0] csr_core_cpu_rdata;
wire        csr_core_dbg_req;
wire        csr_core_dbg_write;
wire [11:0] csr_core_dbg_addr;
wire [31:0] csr_core_dbg_wdata;
wire [31:0] csr_core_dbg_rdata;
//
assign CSR_INT_CPU_REQ   = EX_CSR_REQ 
    & ({EX_CSR_ADDR[11:4], 4'h0} == `CSR_MINTCURLVL); 
assign CSR_INT_CPU_WRITE = EX_CSR_WRITE;
assign CSR_INT_CPU_ADDR  = EX_CSR_ADDR;
assign CSR_INT_CPU_WDATA = EX_CSR_WDATA;
//
assign CSR_INT_DBG_REQ   = DBGABS_CSR_REQ 
    & ({DBGABS_CSR_ADDR[11:4], 4'h0} == `CSR_MINTCURLVL); 
assign CSR_INT_DBG_WRITE = DBGABS_CSR_WRITE;
assign CSR_INT_DBG_ADDR  = DBGABS_CSR_ADDR;
assign CSR_INT_DBG_WDATA = DBGABS_CSR_WDATA;
//
assign CSR_DBG_CPU_REQ = EX_CSR_REQ 
    & ({EX_CSR_ADDR[11:5], 5'h0} == `CSR_TSELECT); 
assign CSR_DBG_CPU_WRITE = EX_CSR_WRITE;
assign CSR_DBG_CPU_ADDR  = EX_CSR_ADDR;
assign CSR_DBG_CPU_WDATA = EX_CSR_WDATA;
//
assign CSR_DBG_DBG_REQ = DBGABS_CSR_REQ 
    & ({DBGABS_CSR_ADDR[11:5], 5'h0} == `CSR_TSELECT); 
assign CSR_DBG_DBG_WRITE = DBGABS_CSR_WRITE;
assign CSR_DBG_DBG_ADDR  = DBGABS_CSR_ADDR;
assign CSR_DBG_DBG_WDATA = DBGABS_CSR_WDATA;
//
assign CSR_FPU_CPU_REQ = EX_CSR_REQ 
    & ((EX_CSR_ADDR[11:0] == `CSR_FFLAGS   )
     | (EX_CSR_ADDR[11:0] == `CSR_FRM      )
     | (EX_CSR_ADDR[11:0] == `CSR_FCSR     )
     | (EX_CSR_ADDR[11:0] == `CSR_FPU32CONV));
assign CSR_FPU_CPU_WRITE = EX_CSR_WRITE;
assign CSR_FPU_CPU_ADDR  = EX_CSR_ADDR;
assign CSR_FPU_CPU_WDATA = EX_CSR_WDATA;
//
assign CSR_FPU_DBG_REQ = DBGABS_CSR_REQ 
    & ((DBGABS_CSR_ADDR[11:0] == `CSR_FFLAGS   )
     | (DBGABS_CSR_ADDR[11:0] == `CSR_FRM      )
     | (DBGABS_CSR_ADDR[11:0] == `CSR_FCSR     )
     | (DBGABS_CSR_ADDR[11:0] == `CSR_FPU32CONV));
assign CSR_FPU_DBG_WRITE = DBGABS_CSR_WRITE;
assign CSR_FPU_DBG_ADDR  = DBGABS_CSR_ADDR;
assign CSR_FPU_DBG_WDATA = DBGABS_CSR_WDATA;
//
assign EX_CSR_RDATA = csr_core_cpu_rdata
                    | CSR_INT_CPU_RDATA 
                    | CSR_DBG_CPU_RDATA
                    | CSR_FPU_CPU_RDATA;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        DBGABS_CSR_RDATA <= 32'h00000000;
    else if (DBGABS_CSR_REQ & ~DBGABS_CSR_WRITE)
        DBGABS_CSR_RDATA <= csr_core_dbg_rdata
                          | CSR_INT_DBG_RDATA
                          | CSR_DBG_DBG_RDATA
                          | CSR_FPU_DBG_RDATA;
    else
        DBGABS_CSR_RDATA <= 32'h00000000;
end
//
assign csr_core_cpu_req   = EX_CSR_REQ;
assign csr_core_cpu_write = EX_CSR_WRITE;
assign csr_core_cpu_addr  = EX_CSR_ADDR;
assign csr_core_cpu_wdata = EX_CSR_WDATA;
assign csr_core_dbg_req   = DBGABS_CSR_REQ;
assign csr_core_dbg_write = DBGABS_CSR_WRITE;
assign csr_core_dbg_addr  = DBGABS_CSR_ADDR;
assign csr_core_dbg_wdata = DBGABS_CSR_WDATA;

//------------------------------------
// CSR_MVENDORID
//------------------------------------
wire [31:0] csr_mvendorid;
assign csr_mvendorid = `MVENDORID;

//------------------------------------
// CSR_MARCHID
//------------------------------------
wire [31:0] csr_marchid;
assign csr_marchid = `MARCHID;

//------------------------------------
// CSR_MIMPID
//------------------------------------
wire [31:0] csr_mimpid;
assign csr_mimpid = `MIMPID;

//------------------------------------
// CSR_MHARTID
//------------------------------------
wire [31:0] csr_mhartid;
`ifdef RISCV_TESTS
assign csr_mhartid = 32'h0;
`else
assign csr_mhartid = HART_ID;
`endif

//------------------------------------
// CSR_MSTATUS
//------------------------------------
reg  [31:0] csr_mstatus;
wire        mie;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        `ifdef RISCV_ISA_RV32F
        csr_mstatus <= {17'b0, 2'b01, 2'b11, 11'b0}; // fs=2'b01(initial), mpp=2'b11
        `else
        csr_mstatus <= {17'b0, 2'b00, 2'b11, 11'b0}; // fs=2'b00(off), mpp=2'b11
        `endif
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MSTATUS))
    begin
        `ifdef RISCV_ISA_RV32F
        csr_mstatus <= {17'b0, csr_core_dbg_wdata[14:13], 2'b11, 3'b0, csr_core_dbg_wdata[7], 3'b0, csr_core_dbg_wdata[3], 3'b0};
        `else
        csr_mstatus <= {17'b0, 2'b00, 2'b11, 3'b0, csr_core_dbg_wdata[7], 3'b0, csr_core_dbg_wdata[3], 3'b0};
        `endif
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MSTATUS))
    begin
        `ifdef RISCV_ISA_RV32F
        csr_mstatus <= {17'b0, csr_core_cpu_wdata[14:13], 2'b11, 3'b0, csr_core_cpu_wdata[7], 3'b0, csr_core_cpu_wdata[3], 3'b0};
        `else
        csr_mstatus <= {17'b0, 2'b00, 2'b11, 3'b0, csr_core_cpu_wdata[7], 3'b0, csr_core_cpu_wdata[3], 3'b0};
        `endif
    end
    else if (EXP_ACK | INT_ACK)
    begin
        if (SET_MSTATUS_FS_DIRTY) // set FS as Dirty
            csr_mstatus <= {17'b0, 2'b11, 2'b11, 3'b0, csr_mstatus[3], 3'b0, 1'b0, 3'b0}; // clear mie
        else
            csr_mstatus <= {17'b0, csr_mstatus[14:13], 2'b11, 3'b0, csr_mstatus[3], 3'b0, 1'b0, 3'b0}; // clear mie
    end
    else if (MRET_ACK)
    begin
        if (SET_MSTATUS_FS_DIRTY) // set FS as Dirty
            csr_mstatus <= {17'b0, 2'b11, 2'b11, 3'b0, csr_mstatus[7], 3'b0, csr_mstatus[7], 3'b0}; // restore mie
        else
            csr_mstatus <= {17'b0, csr_mstatus[14:13], 2'b11, 3'b0, csr_mstatus[7], 3'b0, csr_mstatus[7], 3'b0}; // restore mie
    end
    else if (SET_MSTATUS_FS_DIRTY) // set FS as Dirty
    begin
            csr_mstatus <= {17'b0, 2'b11, csr_mstatus[12:0]};
    end
end
//
assign mie = csr_mstatus[3] & DBG_MIE_STEP;

//------------------------------------
// CSR_MISA
//------------------------------------
wire [31:0] csr_misa;
assign csr_misa = `MISA_N
                | `MISA_M
                | `MISA_I
                `ifdef RISCV_ISA_RV32F
                | `MISA_F
                `endif
                | `MISA_C
                `ifdef RISCV_ISA_RV32A
                | `MISA_A
                `endif
                | `MISA_32;
                
//------------------------------------
// CSR_MIE
//------------------------------------
reg  [31:0] csr_mie;
wire        meie;
wire        mtie;
wire        msie;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mie <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MIE))
    begin
        csr_mie <= {20'b0, csr_core_dbg_wdata[11], 3'b0, csr_core_dbg_wdata[7], 3'b0, csr_core_dbg_wdata[3], 3'b0};
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MIE))
    begin
        csr_mie <= {20'b0, csr_core_cpu_wdata[11], 3'b0, csr_core_cpu_wdata[7], 3'b0, csr_core_cpu_wdata[3], 3'b0};
    end
end
//
assign meie = csr_mie[11];
assign mtie = csr_mie[ 7];
assign msie = csr_mie[ 3];

//---------------------------
// CSR_MTVEC
//---------------------------
reg [31:0] csr_mtvec;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mtvec  <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MTVEC))
    begin
        csr_mtvec  <= csr_core_dbg_wdata;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MTVEC))
    begin
        csr_mtvec  <= csr_core_cpu_wdata;
    end
end
//
assign MTVEC_EXP = {csr_mtvec[31:2], 2'b00};

//---------------------------
// CSR_MSCRATCH
//---------------------------
reg [31:0] csr_mscratch;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mscratch  <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MSCRATCH))
    begin
        csr_mscratch  <= csr_core_dbg_wdata;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MSCRATCH))
    begin
        csr_mscratch  <= csr_core_cpu_wdata;
    end
end

//---------------------
// CSR_MEPC
//---------------------
reg [31:0] csr_mepc;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mepc  <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MEPC))
    begin
        csr_mepc  <= csr_core_dbg_wdata;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MEPC))
    begin
        csr_mepc  <= csr_core_cpu_wdata;
    end
    else if (EXP_ACK | INT_ACK)
    begin
        csr_mepc <= MEPC_SAVE;
    end
end
//
assign MEPC_LOAD = csr_mepc;

//---------------------
// CSR_MCAUSE
//---------------------
reg  [31:0] csr_mcause;
wire        mei_req;
wire        msi_req;
wire        mti_req;
wire        irq_req;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcause  <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MCAUSE))
    begin
        csr_mcause  <= csr_core_dbg_wdata;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MCAUSE))
    begin
        csr_mcause  <= csr_core_cpu_wdata;
    end
    else if (EXP_ACK)
    begin
        csr_mcause <= MCAUSE;
    end
    else if (INT_ACK)
    begin
        csr_mcause <=
              (mei_req)? `MCAUSE_INTERRUPT_MEI
            : (msi_req)? `MCAUSE_INTERRUPT_MSI
            : (mti_req)? `MCAUSE_INTERRUPT_MTI
            : (irq_req)? `MCAUSE_INTERRUPT_IRQ_BASE + {26'h0, INTCTRL_NUM}
            : 32'h00000000;
    end
end

//---------------------------
// CSR_MTVAL
//---------------------------
reg [31:0] csr_mtval;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mtval  <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MTVAL))
    begin
        csr_mtval  <= csr_core_dbg_wdata;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MTVAL))
    begin
        csr_mtval  <= csr_core_cpu_wdata;
    end
    else if (EXP_ACK | INT_ACK)
    begin
        csr_mtval  <= MTVAL;
    end
end

//---------------------------
// CSR_MIP
//---------------------------
wire [31:0] csr_mip;
wire        meip;
wire        mtip;
wire        msip;
//
assign csr_mip = {20'b0, meip, 3'b0, mtip, 3'b0, msip, 3'b0};

//--------------------------
// Interrupt Control
//--------------------------
// Priority : MEI > MSI > MTI > IRQn
assign meip = IRQ_EXT;
assign msip = IRQ_MSOFT; 
assign mtip = IRQ_MTIME;
assign mei_req = meip & meie;
assign msi_req = msip & msie;
assign mti_req = mtip & mtie;
assign irq_req = INTCTRL_REQ;

assign INT_REQ = mie & (mei_req | msi_req | mti_req | irq_req);
assign MTVEC_INT = (csr_mtvec[1:0] != 2'b01)? {csr_mtvec[31:2], 2'b00}
       : (mei_req)? {csr_mtvec[31:2], 2'b00} + 32'h0000002c
       : (msi_req)? {csr_mtvec[31:2], 2'b00} + 32'h0000000c
       : (mti_req)? {csr_mtvec[31:2], 2'b00} + 32'h0000001c
       : (irq_req)? {csr_mtvec[31:2], 2'b00} + 32'h00000040
                    + {24'h0, INTCTRL_NUM, 2'b00}
       : 32'h00000000;
assign INTCTRL_ACK = ~(mei_req | msi_req | mti_req) & INT_ACK;

//----------------------------
// WFI Through during MIE=0
//----------------------------
wire wfi_thru_req = ~mie & (mei_req | msi_req | mti_req | irq_req);
reg  wfi_thru_req_delay;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        wfi_thru_req_delay <= 1'b0;
    else
        wfi_thru_req_delay <= wfi_thru_req;
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
        WFI_THRU_REQ <= 1'b0;
    else if (~WFI_WAITING)
        WFI_THRU_REQ <= 1'b0;
    else if (wfi_thru_req & ~wfi_thru_req_delay) // rising edge
        WFI_THRU_REQ <= 1'b1;
    else if (WFI_THRU_ACK)
        WFI_THRU_REQ <= 1'b0;
end

//------------------------------------
// CSR_MCYCLE, CSR_MCYCLEH
//------------------------------------
reg  [31:0] csr_mcycle;
reg  [31:0] csr_mcycle_wbuf_cpu;
reg  [31:0] csr_mcycle_wbuf_dbg;
reg  [31:0] csr_mcycleh;
reg  [31:0] csr_mcycleh_rbuf_cpu;
reg  [31:0] csr_mcycleh_rbuf_dbg;
wire        inhibit_cycle;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcycle_wbuf_dbg <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MCYCLE))   
    begin
        csr_mcycle_wbuf_dbg <= csr_core_dbg_wdata;
    end
end
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcycle_wbuf_cpu <= 32'h00000000;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MCYCLE))   
    begin
        csr_mcycle_wbuf_cpu <= csr_core_cpu_wdata;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcycle  <= 32'h00000000;
        csr_mcycleh <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MCYCLEH))
    begin
        csr_mcycle  <= csr_mcycle_wbuf_dbg;
        csr_mcycleh <= csr_core_dbg_wdata;    
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MCYCLEH))
    begin
        csr_mcycle  <= csr_mcycle_wbuf_cpu;
        csr_mcycleh <= csr_core_cpu_wdata;    
    end
    else if (~inhibit_cycle)
    begin
        csr_mcycle  <= csr_mcycle + 32'h00000001;
        csr_mcycleh <= (csr_mcycle == 32'hffffffff)? csr_mcycleh + 32'h00000001 : csr_mcycleh;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcycleh_rbuf_dbg <= 32'h00000000;
    end
    else if (csr_core_dbg_req & ~csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MCYCLE))
    begin
        csr_mcycleh_rbuf_dbg <= csr_mcycleh;
    end
end
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcycleh_rbuf_cpu <= 32'h00000000;
    end
    else if (csr_core_cpu_req & ~csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MCYCLE))
    begin
        csr_mcycleh_rbuf_cpu <= csr_mcycleh;
    end
end

//------------------------------------
// CSR_MINSTRET, CSR_MINSTRETH
//------------------------------------
reg  [31:0] csr_minstret;
reg  [31:0] csr_minstret_wbuf_cpu;
reg  [31:0] csr_minstret_wbuf_dbg;
reg  [31:0] csr_minstreth;
reg  [31:0] csr_minstreth_rbuf_cpu;
reg  [31:0] csr_minstreth_rbuf_dbg;
wire        inhibit_instret;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_minstret_wbuf_dbg <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MINSTRET))   
    begin
        csr_minstret_wbuf_dbg <= csr_core_dbg_wdata;
    end
end
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_minstret_wbuf_cpu <= 32'h00000000;
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MINSTRET))
    begin
        csr_minstret_wbuf_cpu <= csr_core_cpu_wdata;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_minstret  <= 32'h00000000;
        csr_minstreth <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MINSTRETH))
    begin
        csr_minstret  <= csr_minstret_wbuf_dbg;
        csr_minstreth <= csr_core_dbg_wdata;    
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MINSTRETH))
    begin
        csr_minstret  <= csr_minstret_wbuf_cpu;
        csr_minstreth <= csr_core_cpu_wdata;    
    end
    else if (INSTR_EXEC & ~inhibit_instret)
    begin
        csr_minstret  <= csr_minstret + 32'h00000001;
        csr_minstreth <= (csr_minstret == 32'hffffffff)? csr_minstreth + 32'h00000001 : csr_minstreth;
    end
end
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_minstreth_rbuf_dbg <= 32'h00000000;
    end
    else if (csr_core_dbg_req & ~csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MINSTRET))
    begin
        csr_minstreth_rbuf_dbg <= csr_minstreth;
    end
end
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_minstreth_rbuf_cpu <= 32'h00000000;
    end
    else if (csr_core_cpu_req & ~csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MINSTRET))
    begin
        csr_minstreth_rbuf_cpu <= csr_minstreth;
    end
end

//------------------------------------
// CSR_MCOUNTINHIBIT
//------------------------------------
reg [31:0] csr_mcountinhibit;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_mcountinhibit <= 32'h00000000;
    end
    else if (csr_core_dbg_req & csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_MCOUNTINHIBIT))
    begin
        csr_mcountinhibit <= {29'b0, csr_core_dbg_wdata[2], 1'b0, csr_core_dbg_wdata[0]};
    end
    else if (csr_core_cpu_req & csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_MCOUNTINHIBIT))
    begin
        csr_mcountinhibit <= {29'b0, csr_core_cpu_wdata[2], 1'b0, csr_core_cpu_wdata[0]};
    end
end
//
assign inhibit_instret = csr_mcountinhibit[2] | DBG_STOP_COUNT;
assign inhibit_cycle   = csr_mcountinhibit[0] | DBG_STOP_COUNT;

//------------------------------------
// CSR_CYCLE  , CSR_CYCLEH
// CSR_TIME   , CSR_TIMEH
// CSR_INSTRET, CSR_INSTRETH
//------------------------------------
reg  [31:0] csr_cycleh_rbuf_cpu;
reg  [31:0] csr_cycleh_rbuf_dbg;
reg  [31:0] csr_timeh_rbuf_cpu;
reg  [31:0] csr_timeh_rbuf_dbg;
reg  [31:0] csr_instreth_rbuf_cpu;
reg  [31:0] csr_instreth_rbuf_dbg;
//
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_cycleh_rbuf_dbg   <= 32'h00000000;
        csr_timeh_rbuf_dbg    <= 32'h00000000;
        csr_instreth_rbuf_dbg <= 32'h00000000;
    end
    else if (csr_core_dbg_req & ~csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_CYCLE))
    begin
        csr_cycleh_rbuf_dbg <= csr_mcycleh;
    end
    else if (csr_core_dbg_req & ~csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_TIME))
    begin
        csr_timeh_rbuf_dbg <= MTIMEH;
    end
    else if (csr_core_dbg_req & ~csr_core_dbg_write & (csr_core_dbg_addr[11:0] == `CSR_INSTRET))
    begin
        csr_instreth_rbuf_dbg <= csr_minstreth;
    end        
end
always @(posedge CLK, posedge RES_CPU)
begin
    if (RES_CPU)
    begin
        csr_cycleh_rbuf_cpu   <= 32'h00000000;
        csr_timeh_rbuf_cpu    <= 32'h00000000;
        csr_instreth_rbuf_cpu <= 32'h00000000;
    end
    else if (csr_core_cpu_req & ~csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_CYCLE))
    begin
        csr_cycleh_rbuf_cpu <= csr_mcycleh;
    end
    else if (csr_core_cpu_req & ~csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_TIME))
    begin
        csr_timeh_rbuf_cpu <= MTIMEH;
    end
    else if (csr_core_cpu_req & ~csr_core_cpu_write & (csr_core_cpu_addr[11:0] == `CSR_INSTRET))
    begin
        csr_instreth_rbuf_cpu <= csr_minstreth;
    end        
end

//-------------------
// Read Data
//-------------------
assign csr_core_dbg_rdata = (~csr_core_dbg_req)? 32'h00000000 // do not include csr_core_write
    :  (csr_core_dbg_addr == `CSR_MVENDORID    )? csr_mvendorid
    :  (csr_core_dbg_addr == `CSR_MARCHID      )? csr_marchid
    :  (csr_core_dbg_addr == `CSR_MIMPID       )? csr_mimpid
    :  (csr_core_dbg_addr == `CSR_MHARTID      )? csr_mhartid
    :  (csr_core_dbg_addr == `CSR_MSTATUS      )? csr_mstatus
    :  (csr_core_dbg_addr == `CSR_MISA         )? csr_misa
    :  (csr_core_dbg_addr == `CSR_MIE          )? csr_mie
    :  (csr_core_dbg_addr == `CSR_MTVEC        )? csr_mtvec
    :  (csr_core_dbg_addr == `CSR_MSCRATCH     )? csr_mscratch
    :  (csr_core_dbg_addr == `CSR_MEPC         )? csr_mepc
    :  (csr_core_dbg_addr == `CSR_MCAUSE       )? csr_mcause
    :  (csr_core_dbg_addr == `CSR_MTVAL        )? csr_mtval
    :  (csr_core_dbg_addr == `CSR_MIP          )? csr_mip
    :  (csr_core_dbg_addr == `CSR_MCYCLE       )? csr_mcycle
    :  (csr_core_dbg_addr == `CSR_MCYCLEH      )? csr_mcycleh_rbuf_dbg
    :  (csr_core_dbg_addr == `CSR_MINSTRET     )? csr_minstret
    :  (csr_core_dbg_addr == `CSR_MINSTRETH    )? csr_minstreth_rbuf_dbg
    :  (csr_core_dbg_addr == `CSR_MCOUNTINHIBIT)? csr_mcountinhibit
    :  (csr_core_dbg_addr == `CSR_CYCLE        )? csr_mcycle
    :  (csr_core_dbg_addr == `CSR_CYCLEH       )? csr_cycleh_rbuf_dbg
    :  (csr_core_dbg_addr == `CSR_TIME         )? MTIME
    :  (csr_core_dbg_addr == `CSR_TIMEH        )? csr_timeh_rbuf_dbg
    :  (csr_core_dbg_addr == `CSR_INSTRET      )? csr_minstret
    :  (csr_core_dbg_addr == `CSR_INSTRETH     )? csr_instreth_rbuf_dbg
    : 32'h00000000;
assign csr_core_cpu_rdata = (~csr_core_cpu_req)? 32'h00000000 // do not include csr_core_write
    :  (csr_core_cpu_addr == `CSR_MVENDORID    )? csr_mvendorid
    :  (csr_core_cpu_addr == `CSR_MARCHID      )? csr_marchid
    :  (csr_core_cpu_addr == `CSR_MIMPID       )? csr_mimpid
    :  (csr_core_cpu_addr == `CSR_MHARTID      )? csr_mhartid
    :  (csr_core_cpu_addr == `CSR_MSTATUS      )? csr_mstatus
    :  (csr_core_cpu_addr == `CSR_MISA         )? csr_misa
    :  (csr_core_cpu_addr == `CSR_MIE          )? csr_mie
    :  (csr_core_cpu_addr == `CSR_MTVEC        )? csr_mtvec
    :  (csr_core_cpu_addr == `CSR_MSCRATCH     )? csr_mscratch
    :  (csr_core_cpu_addr == `CSR_MEPC         )? csr_mepc
    :  (csr_core_cpu_addr == `CSR_MCAUSE       )? csr_mcause
    :  (csr_core_cpu_addr == `CSR_MTVAL        )? csr_mtval
    :  (csr_core_cpu_addr == `CSR_MIP          )? csr_mip
    :  (csr_core_cpu_addr == `CSR_MCYCLE       )? csr_mcycle
    :  (csr_core_cpu_addr == `CSR_MCYCLEH      )? csr_mcycleh_rbuf_cpu
    :  (csr_core_cpu_addr == `CSR_MINSTRET     )? csr_minstret
    :  (csr_core_cpu_addr == `CSR_MINSTRETH    )? csr_minstreth_rbuf_cpu
    :  (csr_core_cpu_addr == `CSR_MCOUNTINHIBIT)? csr_mcountinhibit
    :  (csr_core_cpu_addr == `CSR_CYCLE        )? csr_mcycle
    :  (csr_core_cpu_addr == `CSR_CYCLEH       )? csr_cycleh_rbuf_cpu
    :  (csr_core_cpu_addr == `CSR_TIME         )? MTIME
    :  (csr_core_cpu_addr == `CSR_TIMEH        )? csr_timeh_rbuf_cpu
    :  (csr_core_cpu_addr == `CSR_INSTRET      )? csr_minstret
    :  (csr_core_cpu_addr == `CSR_INSTRETH     )? csr_instreth_rbuf_cpu
    : 32'h00000000;

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
