# mmRISC-1 : RISC-V RV32IMAFC Core for MCU

“mmRISC_1” is a RISC-V compliant CPU core with RV32IM[A][F]C ISA for MCU.<br>
The “mmRISC” stands for “much more RISC”. <br>
For details, please refer PDF file under doc directory. <br>

## Technical Notes

### 2021.12.26 Notes on Questa Sim
If you use Questa Sim to simulate mmRISC-1, please add an option -voptargs="+acc" in vsim command.<br>

### 2021.12.31 Some modifications except for mmRISC Core
Followings are updated. Main RTL Body of mmRISC is not modified due to no bugs found yet.<br>
  (1) Added MRET and WFI descriptions in Technical Reference Manual Rev.02. <br>
  (2) Supported Questa as logic simulator. To do so, add an option -voptargs="+acc" in vsim command. <br>
  (3) Supported Initialization of Instruction RAM in FPGA using .mif file. A conversion tool hex2mif is added in tools directory. <br>
  (4) Updated JTAG interface schematic. <br>
  (5) Changed operation of application mmRISC_SampleCPU. <br>
  (6) Add a retro text video game StarTrek as an application. <br>
  
### 2022.02.12 Fixed a bug in HALT/RESUME operations of mmRISC Core
  BUG: Sometimes ignored HALT/RESUME Requests from Debugger during ID Stage is being stalled due to memory wait cycles. <br>
  WHY: DBG_HALT_ACK  and DBG_RESUME_ACK are asserted in one cycle even during ID stallings. If these ACK signals are asserted, corresponding DBG_HALT_REQ and DBG_RESUME_REQ are immediately negated, then the pipeline control may ignore DBG_HALT_REQ and DBG_RESUME_REQ. <br>
  FIX: DBG_HALT_ACK and DBG_RESUME_ACK are asserted only at last of ID stages after its stalls in cpu_pipeline.v. <br>
  
### 2022.03.20 Fixed following bugs in Floating Point Instructions in mmRISC Core
  BUG1: FMV W.X and FMV X.W sometimes could not transfer correct data according to pipeline stall or wait-cycle timing. <br>
  WHY1: EX_FPU_DSTDATA was active only when EX_ALU_DST1 was asserted.  <br>
  FIX1: EX_FPU_DSTDATA is connected from ex_busZ directly in cpu_datapath.v. EX_FPU_SRCDATA is stretched until next updating in cpu_fpu32.v. <br>
  <br>
  BUG2: In FLW (load) followed by FMADD.S/FMSUB.S/FNMSUB.S/FNMADD.S, FMADDs did not use latest loaded data in src3. <br>
  WHY2: The register contention check between FLW's destination and FMADD's source 3 (src3) was not implemented. <br>
  FIX2: Contention check between FLW's destination and FMADD's source 3 (src3) is implemented in cpu_pipeline.v. <br>

### 2022.03.20 (2) Added Simple I2C and SDRAM Interface in FPGA
 Followings are updated. <br> 
 (1) common/defines.v is divided into defines_core.v for mmRISC Core and defines_chip.v for Chip System. (defines.v is not used any more.)<br>
 (2) Simple I2C Core is added in FPGA. Related modifications are applied in RTL and Verification resources. Simple CPU Sample Program supports I2C which comunicates with Accelerometer Sensor on MAX10-Lite board. <br>
 (3) Simple SDRAM Interface logic is added in FPGA which accesses 64MB SDRAM on MAX10-Lite board. <br>
 0x80000000-( 64GB) SDRAM <br>
 0x88000000-( 48KB) Internal Data RAM <br>
 0x90000000-(128KB) Internal Instruction RAM <br>
 * The Technical Reference Manual has not been updated along with above updates. Please wait for a while. <br>

### 2022.05.01 Fixed Operation of RV32F Instruction in which source registers are FRn and destination register is XRn. 
 BUG : When RV32F Instruction in which destination register is XRn, such as FMV.X.W, FCLASS.S, FCMP,FCVT.W(U).S and FCMP.S, is followed by an instruction in which above XRn is used as source register, sometimes the source value is old one that has not been updated by the RV32F instruction.<br>
 WHY : Incorrect instruction stallings.<br>
 FIX : Make the RV32F instruction in which its destination is XRn be multicycle instruction in each. Updated cpu_pipeline.v and cpu_fpu32.v.<br>

### 2022.05.01 Added Simple SPI, one more I2C in FPGA. Added an application mmRISC_TouchLCD
(1) Added SPI, one more I2C.<br>
(2) Wrote know-hows in Technical Reference Manual to use Raspberry Pi as a Development Environment including OpenOCD interface. Added an example of openocd script for Raspberry Pi in directory "openocd".<br>
(3) In application mmRISC_SampleCPU, added access of Acceleration Sensor on MAX10-Lite board through I2C interface.<br>
(4) Added new application mmRISC_TouchLCD which handles Adafruit-2-8-tft-touch-shield-v2 with Resistive Touch Panel or Capacitive Touch Panel for Arduino.<br>
(5) In each sample program, baud rate of UART is unified to 115200bps.<br>

### 2022.05.03 Corrected Test Banch Codes
(1) In simulation/modelsim/mmRISC_Simulation, simulation/modelsim/riscv-tests and simulation/modelsim/riscv-arch-test, corrected test banch top RTL (tb_TOP.v) and simulation script (sim_TOP.do) in each directory.<br>
(2) Correct minor typo in comment of uart.v.<br>
(3) Body RTL codes of mmRISC and its SOC(FPGA) do not have any bugs.<br> 
 
### 2022.05.04 Repaired directory contentes in riscv-arch-test and riscv-tests
Some files and directories were lacked in riscv-arch-test and riscv-tests. Repaired them.<br>

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
External Debug Support Ver.0.13.2 with JTAG Interface <br>
Run / Stop / Step <br)
Abstract Command to access Register and Memory <br>
System Bus Access for Memory <br>
Hardware Break Points (Instruction / Data) x 4 (Configurable) <br>
Instruction Count Break Point x 1 <br>

## Privileged Mode
Machine-Mode (M-Mode) only <br>

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
Simple CPU Sample Program <br>
Simple FPU Sample Program <br>
FreeRTOS Porting (Blinky) <br>
Dhrystone Benchmark <br>
Coremark Benchmark <br>
Retro StarTrek Game <br>
Touch LCD Panal Demo <br>
