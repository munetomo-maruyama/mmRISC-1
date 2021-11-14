# mmRISC-1
RISC-V RV32IMAFC Core for MCU

“mmRISC_1” is a RISC-V compliant CPU core with RV32IM[A][F]C ISA for MCU. Overview of mmRISC-1 specifications are shown in Table 1.1. “mmRISC” stands for “much more RISC”.

1. ISA
RV32IM[A][F]C (configurable)

2. Harts
Multi Harts Supported, 1 to 2^20 (configurable)

3. Pipeline
For Integer : 3 to 5 stages
For Floating Point : 3 to 6 stages

4. Integer Multiplication
MUL/MULH/MULHSU/MULHU : 1 cycle

5. Integer Division
DIV/DIVU/REM/REMU : 33 cyles (Non-Restoring Method)

6. Floating Operations
FADD.S/FSUB.S/FMUL.S/FMADD.S/FMSUB.S/FNMADD.S/FNMSUB.S : 1 cycle
FDIV.S  : 11 cycles (Goldschmidt's Algorithm)
FSQRT.S : 19 cycles (Goldschmidt's Algorithm)
  The convergence loop counts for FDIV.S and FSQRT.S can be configured by software.

7. Debug Support
External Debug Support Ver.0.13.2 with JTAG Interface
Run / Stop / Step
Abstract Command to access Register and Memory
System Bus Access for Memory
Hardware Break Points (Instruction / Data) x 4 (Configurable)
Instruction Count Break Point x 1

8. Privileged Mode
Machine-Mode (M-Mode) only

9. Interrupt
IRQ_EXT   : External Interrupt
IRQ_MSOFT : Machine Software Interrupt
IRQ_MTIME : Machine Timer Interrupt  
IRQ[63:0] : User IRQ, 64 inputs / Vectored Supported / 16 priority levels for each

10. Counters
64bits MCYCLE (Clock Cycle Counter)
64bits MINSTRET (Instruction Retired Counter)
64bits MTIME (Memory Mapped Interrupt Timer)

11. Bus Interface (AHB-Lite)
Instruction Fetch Bus
Data Bus multiplexed with Debugger Abstract Command
LR/SC Monitor Bus
Debugger System Bus

12. RTL
Verilog-2001 / System Verilog

13. Verification
Vector Simluation
RISC-V Compliance Test “riscv-arch-test” for I/C/M/Zifence/Privileged
RISC-V Unit Test “riscv-tests” including Atomic and Floating Point ISA

13. FPGA Proven
DE10-Lite Board (Intel MAX 10 10M50DAF484C7G)
JTAG Interface (FT2232D)
Eclipse 

14. Sample Programs
mmRISC_SampleCPU    Simple CPU Sample Program
mmRISC_SampleCPU    Simple FPU Sample Program
mmRISC_FreeRTOS     FreeRTOS Porting (Blinky)
mmRISC_Dhrystone    Dhrystone Benchmark
mmRISC_Coremark     Coremark Benchmark

-------------------------------------
Copyright (C) 2021 Munetomo Maruyama





