# mmRISC-1 : RISC-V RV32IMAFC Core for MCU

“mmRISC_1” is a RISC-V compliant CPU core with RV32IM[A][F]C ISA for MCU.<br>
The “mmRISC” stands for “much more RISC”. <br>
For details, please refer PDF file under doc directory. <br>

## ISA
RV32IM[A][F]C (configurable)

## Harts
Multi Harts Supported, 1 to 2^20 (configurable)

## Pipeline
For Integer : 3 to 5 stages <br>
For Floating Point : 3 to 6 stages <br>

## Execution Cycles
Integer Multiplication MUL/MULH/MULHSU/MULHU : 1 cycle
Integer Division DIV/DIVU/REM/REMU : 33 cyles (Non-Restoring Method)
Floating Operations <br>
  FADD.S/FSUB.S/FMUL.S/FMADD.S/FMSUB.S/FNMADD.S/FNMSUB.S : 1 cycle <br>
  FDIV.S  : 11 cycles (Goldschmidt's Algorithm) <br>
  FSQRT.S : 19 cycles (Goldschmidt's Algorithm) <br>
  The convergence loop counts for FDIV.S and FSQRT.S can be configured by software. <br>

## Debug Support
External Debug Support Ver.0.13.2 with JTAG Interface <br)
Run / Stop / Step <br)
Abstract Command to access Register and Memory <br)
System Bus Access for Memory <br)
Hardware Break Points (Instruction / Data) x 4 (Configurable) <br)
Instruction Count Break Point x 1 <br)

## Privileged Mode
Machine-Mode (M-Mode) only <br)

## Interrupt
IRQ_EXT   : External Interrupt <br>
IRQ_MSOFT : Machine Software Interrupt <br>
IRQ_MTIME : Machine Timer Interrupt <br>
IRQ[63:0] : User IRQ, 64 inputs / Vectored Supported / 16 priority levels for each <br>

## Counters
64bits MCYCLE (Clock Cycle Counter) <br>
64bits MINSTRET (Instruction Retired Counter) <br>
64bits MTIME (Memory Mapped Interrupt Timer) <br>

## Bus Interface (AHB-Lite)
Instruction Fetch Bus <br>
Data Bus multiplexed with Debugger Abstract Command <br>
LR/SC Monitor Bus <br>
Debugger System Bus <br>

## RTL
Verilog-2001 / System Verilog <br>

## Verification
Vector Simluation <br>
RISC-V Compliance Test “riscv-arch-test” for I/C/M/Zifence/Privileged <br>
RISC-V Unit Test “riscv-tests” including Atomic and Floating Point ISA <br>

## FPGA Proven
DE10-Lite Board (Intel MAX 10 10M50DAF484C7G) <br>
JTAG Interface (FT2232D) <br>
Eclipse <br>

## Sample Programs
mmRISC_SampleCPU    Simple CPU Sample Program <br>
mmRISC_SampleCPU    Simple FPU Sample Program <br>
mmRISC_FreeRTOS     FreeRTOS Porting (Blinky) <br>
mmRISC_Dhrystone    Dhrystone Benchmark <br>
mmRISC_Coremark     Coremark Benchmark <br>
