//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tb_top.v
// Description : Testbench for Top Level
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
//-----------------------------------------------------------
// Copyright (C) 2017-2020 M.Maruyama
//===========================================================

`include "defines_core.v"
`include "defines_chip.v"

`timescale 1ns/100ps
//`define JTAG_FAST
//
`ifdef JTAG_FAST
    `define TB_TCYC_CLK   100 //ns (10MHz)
    `define TB_TCYC_CLK_2  50 //ns (10MHz)
    `define TB_TCYC_TCK    20 //ns (50MHz)
`else
    `define TB_TCYC_CLK    20 //ns (50MHz)
    `define TB_TCYC_CLK_2  10 //ns (50MHz)
    `define TB_TCYC_TCK   100 //ns (10MHz)
`endif
//
`define TB_TCYC_TCKC (`TB_TCYC_TCK / 5) // cJTAG TCKC
//
`define TB_STOP 1000000000 //cyc
`define TB_RESET_WIDTH 50  //ns
//
`define DUMP_ID_STAGE
//
//`define JTAG_OPERATION
//`define JTAG_SBACCESS
`define HARDWARE_BREAK

//------------------------
// Top of Testbench
//------------------------
module tb_TOP;

//--------------------
// JTAG or cJTAG
//--------------------
reg tb_enable_cjtag; // selection whether using JTAG or cJTAG

//--------
// Global
//--------
reg [ 4:0] IR_OUT; // global
reg [63:0] DR_OUT; // global
reg        TDO;    // global

//-------------------------------
// Generate Clock
//-------------------------------
reg tb_clk;
reg tb_clk_speed;
//
initial tb_clk = 1'b0;
always #(`TB_TCYC_CLK_2) tb_clk = ~tb_clk;

//--------------------------
// Generate Reset
//--------------------------
reg tb_res;
//
initial
begin
    tb_res = 1'b1;
        # (`TB_RESET_WIDTH)
    tb_res = 1'b0;       
end
//
// Initialize Internal Power on Reset
initial
begin
    U_CHIP_TOP_WRAP.U_CHIP_TOP.por_count = 0;
    U_CHIP_TOP_WRAP.U_CHIP_TOP.por_n = 0;
end

//----------------------------
// Simulation Cycle Counter
//----------------------------
reg [31:0] tb_cyc;
//
always @(posedge tb_clk, posedge tb_res)
begin
    if (tb_res)
    
        tb_cyc <= 32'h0;
    else
        tb_cyc <= tb_cyc + 32'h1;
end
//
always @*
begin
    if (tb_cyc == `TB_STOP)
    begin
        $display("***** SIMULATION TIMEOUT ***** at %d", tb_cyc);
        $stop;
    end
end

//-------------------------
// Dump File
//-------------------------
integer fdump;
initial fdump = $fopen("dump.txt", "w");

//----------------------------
// Simulation Stop Condition
//----------------------------
reg stop_by_stimulus;
reg stop_by_program;
initial
begin
    stop_by_stimulus = 1'b0;
    stop_by_program  = 1'b0;
end
//
always @*
begin
    if (stop_by_stimulus & stop_by_program)
    begin
        $fclose(fdump);
        $stop;
    end
end

//-------------------------------------
// Bus Watcher
//-------------------------------------
wire        watch_res;
wire        watch_clk;
wire        watch_hsel;
wire [ 1:0] watch_htrans;
wire        watch_hwrite;
wire [ 2:0] watch_hsize;
wire [31:0] watch_haddr;
wire [31:0] watch_hwdata;
wire        watch_hready;
wire        watch_hreadyout;
wire [ 3:0] watch_state_id_ope;
//
assign watch_res    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.RES_ORG;
assign watch_clk    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CLK;
assign watch_hsel   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HSEL[0];
assign watch_htrans = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HTRANS[0];
assign watch_hsize  = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HSIZE[0];
assign watch_hwrite = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HWRITE[0];
assign watch_haddr  = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HADDR[0];
assign watch_hwdata = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HWDATA[0];
assign watch_hready    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HREADY[0];
assign watch_hreadyout = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HREADYOUT[0];
assign watch_state_id_ope = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.state_id_ope;
//
//-------------------------------------
// Terminate Simulation by watching Bus
//-------------------------------------
reg watch_terminate;
//
always @(posedge watch_clk, posedge watch_res)
begin
    if (watch_res)
    begin
        watch_terminate <= 1'b0;
    end
    else if (watch_hready & watch_hreadyout)
    begin
        watch_terminate <= (watch_hsel      == 1'b1)
                         & (watch_htrans[1] == 1'b1)
                         & (watch_hsize     == 3'b010)
                         & (watch_hwrite    == 1'b1)
                         & (watch_haddr     == 32'hfffffffc);
        
    end
end
//
wire detect_tohost;
assign detect_tohost = watch_terminate & watch_hready & watch_hreadyout
                     & (watch_hwdata == 32'hdeaddead);
//
reg [31:0] addr, data;
always @(posedge watch_clk)
begin
    if (detect_tohost)
    begin
        $display("***** DETECT FINAL INSTRUCTION *****");
        stop_by_program = 1'b1;
    end
end

//-------------------------------------------
// Dump Operation Results (Verify Floating)
//-------------------------------------------
reg        watch_dump;
reg [31:0] watch_dump_addr;
//
always @(posedge watch_clk, posedge watch_res)
begin
    if (watch_res)
    begin
        watch_dump <= 1'b0;
    end
    else if (watch_hready & watch_hreadyout)
    begin
        watch_dump_addr <= watch_haddr;
        watch_dump <= (watch_hsel      == 1'b1)
                    & (watch_htrans[1] == 1'b1)
                    & (watch_hsize     == 3'b010)
                    & (watch_hwrite    == 1'b1)
                    & (watch_haddr[31:4] == 28'hffffffe);
    end
end
//
always @(posedge watch_clk)
begin
    if (watch_dump & watch_hready & watch_hreadyout)
    begin
      //$fdisplay(fdump, "%08x %08x", watch_dump_addr, watch_hwdata);
    end
end

//--------------------------------------
// Dump ID Stage
//--------------------------------------
`ifdef DUMP_ID_STAGE
wire watch_instr_exec;
wire [31:0] watch_pipe_id_pc;
wire [31:0] watch_pipe_id_code;
wire [31:0] watch_regxr[0:31];
wire [31:0] watch_regfr[0:31];
//
assign watch_instr_exec = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.INSTR_EXEC;
assign watch_pipe_id_pc = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.pipe_id_pc;
assign watch_pipe_id_code = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.pipe_id_code;
generate
    genvar n;
    for (n = 0; n < 32; n = n + 1)
    begin
        assign watch_regxr[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_DATAPATH.regXR[n];
        `ifdef RISCV_ISA_RV32F
        assign watch_regfr[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_FPU32.regFR[n];
        `else
        assign watch_regfr[n] = 32'hxxxxxxxx;
        `endif
    end
endgenerate
//
always @(posedge watch_clk, posedge watch_res)
begin
    if (watch_instr_exec)
    begin
        integer i;
        $fwrite(fdump, "ID PC=%08x CODE=%08x ", watch_pipe_id_pc, watch_pipe_id_code);
        for (i = 0; i < 32; i = i + 1)
        begin
            $fwrite(fdump, "XR%0d=%08x ", i, watch_regxr[i]);
        end
        for (i = 0; i < 32; i = i + 1)
        begin
            $fwrite(fdump, "FR%0d=%08x ", i, watch_regfr[i]);
        end
        $fdisplay(fdump, "");
    end
end
`endif

//--------------------------
// Device Under Test
//--------------------------
reg  tb_srst_n; // reset except for debug logic
wire srst_n;
assign srst_n = tb_srst_n;
pullup (srst_n);
//
reg  tb_trst_n;
reg  tb_tck;
reg  tb_tms;
reg  tb_tdi;
wire tb_tdo;
wire tb_rtck;
pullup(tb_tdo);
//
wire tb_tckc;
wire tb_tmsc;
wire tb_tmsc_pup;
wire tb_tmsc_pdn;
pullup(tb_tckc);
//pullup(tb_tmsc);
assign (weak1, weak0) #1 tb_tmsc = (tb_tmsc_pup === 1'b1)? 1'b1 : 1'bz;
assign (weak1, weak0) #1 tb_tmsc = (tb_tmsc_pdn === 1'b0)? 1'b0 : 1'bz;
//
wire [31:0] gpio0;
wire [31:0] gpio1;
wire [31:0] gpio2;
wire rxd;
wire txd;
wire i2c0_scl;  // I2C0 SCL
wire i2c0_sda;  // I2C0 SDA
wire i2c0_ena;  // I2C0 Enable (Fixed to 1)
wire i2c0_adr;  // I2C0 ALTADDR (Fixed to 0)
wire i2c0_int1; // I2C0 Device Interrupt Request 1
wire i2c0_int2; // I2C0 Device Interrupt Request 2
wire i2c1_scl;  // I2C1 SCL
wire i2c1_sda;  // I2C1 SDA
wire [ 3:0] spi_csn;  // SPI Chip Select
wire        spi_sck;  // SPI Clock
wire        spi_mosi; // SPI MOSI
wire        spi_miso; // SPI MISO
//
wire        sdram_clk;  // SDRAM Clock
wire        sdram_cke;  // SDRAM Clock Enable
wire        sdram_csn;  // SDRAM Chip Select
wire [ 1:0] sdram_dqm;  // SDRAM Byte Data Mask
wire        sdram_rasn; // SDRAM Row Address Strobe
wire        sdram_casn; // SDRAM Column Address Strobe
wire        sdram_wen;  // SDRAM Write Enable
wire [ 1:0] sdram_ba;   // SDRAM Bank Address
wire [12:0] sdram_addr; // SDRAM Addess
wire [15:0] sdram_dq;   // SDRAM Data
//
pullup(txd);
pullup(i2c0_scl);
pullup(i2c0_sda);
pullup(i2c1_scl);
pullup(i2c1_sda);
assign i2c0_int1 = 1'b0;
assign i2c0_int2 = 1'b0;
assign spi_miso = ~spi_mosi; // reversed loop back
//
generate
    genvar i;
    for (i = 0; i < 32; i = i + 1)
    begin
        pullup(gpio0[i]);
        pullup(gpio1[i]);
        pullup(gpio2[i]);
    end
endgenerate
//
reg  tb_stby;
reg  tb_debug_secure;
reg  tb_reset_halt_n;
assign gpio2[10] = tb_reset_halt_n;
assign gpio2[ 9] = tb_debug_secure;
assign gpio2[ 8] = tb_stby;
assign gpio2[ 7] = tb_clk_speed;
assign gpio2[ 6] = tb_enable_cjtag;
//
CHIP_TOP_WRAP U_CHIP_TOP_WRAP
(
    .RES_N (~tb_res),
    .CLK50 (tb_clk),
    //
  //.STBY_REQ   (tb_stby),
    .STBY_ACK_N (),
    //
    .RESOUT_N (),
    //
`ifdef SIMULATION
    .SRSTn (srst_n),
    .RTCK (tb_rtck),
`endif
    //
    .TRSTn (tb_trst_n),
    .TCK (tb_tck),
    .TMS (tb_tms),
    .TDI (tb_tdi),
    .TDO (tb_tdo),
    //
    .TCKC_pri (tb_tckc),
    .TCKC_rep (tb_tckc),
    .TMSC_pri (tb_tmsc),
    .TMSC_rep (tb_tmsc),
    //
    .TMSC_PUP_rep (tb_tmsc_pup),
    .TMSC_PDN_rep (tb_tmsc_pdn),
    //
    .GPIO0 (gpio0),
    .GPIO1 (gpio1),
    .GPIO2 (gpio2),
    //
    .RXD (txd),
    .TXD (rxd),
    //
    .I2C0_SCL  (i2c0_scl),  // I2C0 SCL
    .I2C0_SDA  (i2c0_sda),  // I2C0 SDA
    .I2C0_ENA  (i2c0_ena),  // I2C0 Enable (Fixed to 1)
    .I2C0_ADR  (i2c0_adr),  // I2C0 ALTADDR (Fixed to 0)
    .I2C0_INT1 (i2c0_int1), // I2C0 Device Interrupt Request 1
    .I2C0_INT2 (i2c0_int2), // I2C0 Device Interrupt Request 2
    //
    .I2C1_SCL  (i2c1_scl),  // I2C1 SCL
    .I2C1_SDA  (i2c1_sda),  // I2C1 SDA
    //
    .SPI_CSN  (spi_csn),  // SPI Chip Select
    .SPI_SCK  (spi_sck),  // SPI Clock
    .SPI_MOSI (spi_mosi), // SPI MOSI
    .SPI_MISO (spi_miso), // SPI MISO
    //
    .SDRAM_CLK  (sdram_clk),  // SDRAM Clock
    .SDRAM_CKE  (sdram_cke),  // SDRAM Clock Enable
    .SDRAM_CSn  (sdram_csn),  // SDRAM Chip Select
    .SDRAM_DQM  (sdram_dqm),  // SDRAM Byte Data Mask
    .SDRAM_RASn (sdram_rasn), // SDRAM Row Address Strobe
    .SDRAM_CASn (sdram_casn), // SDRAM Column Address Strobe
    .SDRAM_WEn  (sdram_wen),  // SDRAM Write Enable
    .SDRAM_BA   (sdram_ba),   // SDRAM Bank Address
    .SDRAM_ADDR (sdram_addr), // SDRAM Addess
    .SDRAM_DQ   (sdram_dq)    // SDRAM Data
);

//--------------------
// I2C Model
//--------------------
i2c_slave_model U_I2C_SLAVE0
(
    .scl (i2c_scl0),
    .sda (i2c_sda0)
);
i2c_slave_model U_I2C_SLAVE1
(
    .scl (i2c_scl1),
    .sda (i2c_sda1)
);

//--------------------
// SDRAM Model
//--------------------
sdr U_SDRAM
(
    .Dq    (sdram_dq),
    .Addr  (sdram_addr),
    .Ba    (sdram_ba),
    .Clk   (sdram_clk),
    .Cke   (sdram_cke),
    .Cs_n  (sdram_csn),
    .Ras_n (sdram_rasn),
    .Cas_n (sdram_casn),
    .We_n  (sdram_wen),
    .Dqm   (sdram_dqm)
);

//------------------------
// Task : RESET_SYS
// (except for degug logic)
//------------------------
task Task_RESET_SYS();
    tb_srst_n = 1'bz;
    #(`TB_TCYC_TCK * 1);
    tb_srst_n = 1'b0;
    #(`TB_TCYC_TCK * 1);
    tb_srst_n = 1'bz;
    #(`TB_TCYC_TCK * 1);
    $display("----RESET_SYS");
endtask

//--------------------------
// Task ; JTAG_INIT_PIN
//--------------------------
task Task_JTAG_INIT_PIN();
    if (tb_enable_cjtag)
    begin
        // Compact JTAG
        tb_tck = 1'b0;
        tb_tms = 1'b0;
        tb_tdi = 1'b1;
        tb_trst_n = 1'b1;
        tb_srst_n = 1'bz;
        #(`TB_TCYC_TCK);
      //tb_reset_halt_n = 1'b1;
        tb_tms = 1'b1;
    end
    else
    begin
        // Normal JTAG
        tb_tck = 1'b0;
        tb_tms = 1'b0;
        tb_tdi = 1'bx;
        tb_trst_n = 1'b1;
        tb_srst_n = 1'bz;
        #(`TB_TCYC_TCK);
      //tb_reset_halt_n = 1'b1;
    end
    #(`TB_TCYC_TCK * 1);
    $display("----JTAG_INIT_PIN");
endtask

//--------------------------
// Task ; Reset Run
//--------------------------
task Task_RESET_RUN();
    tb_reset_halt_n = 1'b1;
    $display("----RESET RUN");
endtask

//--------------------------
// Task ; Reset Halt
//--------------------------
task Task_RESET_HALT();
    tb_reset_halt_n = 1'b0;
    $display("----RESET HALT");
endtask

//------------------------
// Task : JTAG_RESET_TAP
//------------------------
task Task_JTAG_RESET_TAP();
    tb_trst_n = 1'b1;
    #(`TB_TCYC_TCK * 1);
    tb_trst_n = 1'b0;
    #(`TB_TCYC_TCK * 1);
    tb_trst_n = 1'b1;
    #(`TB_TCYC_TCK * 1);
    $display("----JTAG_RESET_TAP");
endtask

//-------------------------
// Task : JTAG_BIT
//-------------------------
task Task_JTAG_BIT(input TMS, input TDI);
    if (tb_enable_cjtag)
    begin
        // Compact JTAG
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = ~TDI; // nTDI
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = ~TDI; // nTDI
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = TMS; // TMS
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = TMS; // TMS
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b0; tb_tdi = 1'b1; // HIZ
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b0; tb_tdi = 1'b0; // TDO
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b0; tb_tdi = 1'b0; // TDO
        TDO = tb_tdo;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b0; tb_tdi = 1'b0; 
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; 
    end
    else
    begin
        // Normal JTAG
        tb_tck = 1'b0;
        tb_tms = TMS;
        tb_tdi = TDI;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; // rise
        TDO = tb_tdo;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; // fall
    end
endtask

//--------------------------
// Task ; CJTAG_ONLINE
//--------------------------
task Task_CJTAG_ONLINE(integer count);
    if (tb_enable_cjtag)
    begin
        integer i;
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        for (i = 0; i < count; i = i + 1)
        begin
            #(`TB_TCYC_TCK / 2);
            tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
            #(`TB_TCYC_TCK / 2);
            tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1;
        end
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        $display("----CJTAG_ONLINE");
    end
endtask
//
task Task_CJTAG_ONLINE_NAGATIVE(integer count);
    if (tb_enable_cjtag)
    begin
        integer i;
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b1;
        for (i = 0; i < count; i = i + 1)
        begin
            #(`TB_TCYC_TCK / 2);
            tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1;
            #(`TB_TCYC_TCK / 2);
            tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
        end
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b1;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        $display("----CJTAG_ONLINE_NAGATIVE");
    end
endtask

//--------------------------------
// Task ; CJTAG_ACTIVATION_ILGL
//--------------------------------
task Task_CJTAG_ACTIVATION_ILGL();
    if (tb_enable_cjtag)
    begin
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0;
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        $display("----CJTAG_ACTIVATION_ILGL");
    end
endtask

//--------------------------------
// Task ; CJTAG_ACTIVATION_CODE
//--------------------------------
task Task_CJTAG_ACTIVATION_CODE(input [3:0] code);
    if (tb_enable_cjtag)
    begin
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = code[0];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = code[0];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = code[1];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = code[1];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = code[2];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = code[2];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = code[3];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = code[3];
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0;
        $display("----CJTAG_ACTIVATION_CODE(0x%01x)", code);
    end
endtask

//-------------------------
// Task : CJTAG_OPENOCD
//-------------------------
task Task_CJTAG_OPENOCD();
    if (tb_enable_cjtag)
    begin
        // Drive cJTAG escape sequence for TAP reset - 8 TMSC edges
        //          /* TCK=0, TMS=1, TDI=0 (drive TMSC to 0 baseline) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge of TCK with TMSC still 0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK with TMSC still 0) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //
        // 3 TCK pulses for padding
        //          /* TCK=1, TMS=1, TDI=0 (drive rising TCK edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (drive falling TCK edge) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive rising TCK edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (drive falling TCK edge) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive rising TCK edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (drive falling TCK edge) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //
        // Drive cJTAG escape sequence for SELECT
        //          /* TCK=1, TMS=1, TDI=0 (rising edge of TCK with TMSC still 0, TAP reset that was >
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (drive rising TMSC edge) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (drive falling TMSC edge) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK with TMSC still 0) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //
        // Drive cJTAG escape sequence for OScan1 activation -- OAC = 1100 -> 2 wires -- >
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK with TMSC still 0... online mode activate>
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... OAC bit1==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=1 (falling edge TCK) */
        //          {'0', '1', '1'},
        #(`TB_TCYC_TCK / 2);
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2); // BUG CAUSE
        #(`TB_TCYC_TCK / 2);
        #(`TB_TCYC_TCK / 2);
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (rising edge TCK... OAC bit2==1) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=1 (falling edge TCK, TMSC stays high) */
        //          {'0', '1', '1'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (rising edge TCK... OAC bit3==1) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //         /* TCK=1, TMS=1, TDI=0 (rising edge TCK... EC bit0==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... EC bit1==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... EC bit2==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=1 (falling edge TCK) */
        //          {'0', '1', '1'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=1 (rising edge TCK... EC bit3==1) */
        //          {'1', '1', '1'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b1; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... CP bit0==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... CP bit1==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... CP bit2==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=1, TMS=1, TDI=0 (rising edge TCK... CP bit3==0) */
        //          {'1', '1', '0'},
        tb_tck = 1'b1; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        //          /* TCK=0, TMS=1, TDI=0 (falling edge TCK) */
        //          {'0', '1', '0'},
        tb_tck = 1'b0; tb_tms = 1'b1; tb_tdi = 1'b0; #(`TB_TCYC_TCK / 2);
        end
endtask

//-------------------------
// Task : JTAG_INIT_STATE
//-------------------------
task Task_JTAG_INIT_STATE();
    //---- Any State
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //---- Test Logic Reset    
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Run Test Idle
    #(`TB_TCYC_TCK * 1);
    $display("----JTAG_INIT_STATE");
endtask;

//----------------------
// Task : JTAG_Shift_IR
//----------------------
task Task_JTAG_Shift_IR(input [4:0] IR, integer verbose);
    integer i;
    IR_OUT = 5'b0;
    //---- Run Test Idle
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //---- Select DR Scan
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //----Select IR Scan
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Capture IR
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Shift IR (bit0-bit3)
    for (i = 0; i < 4; i = i + 1)
    begin
        Task_JTAG_BIT(.TMS(1'b0), .TDI(IR[i]));    
        IR_OUT[i] = TDO;
    end
    //---- Shift IR (bit4)
    Task_JTAG_BIT(.TMS(1'b1), .TDI(IR[4]));    
    IR_OUT[4] = TDO;
    //---- Exit1-IR
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //---- Update IR
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Run Test Idle
    #(`TB_TCYC_TCK * 1);
    // Message
    if (verbose) $display("----JTAG IR SFT_IN(0x%01x) SFT_OUT(0x%01x)", IR, IR_OUT);
endtask

//------------------------
// Task : JTAG_Shift_DR
//------------------------
task Task_JTAG_Shift_DR(input [63:0] DR, integer length, integer verbose);
    // output [63:0] DR_OUT is declared as Global.
    integer i;
    DR_OUT = 64'h0;
    //---- Run Test Idle
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //---- Select DR Scan
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Capture DR
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Shift DR (bit0-)
    for (i = 0; i < (length - 1); i = i + 1)
    begin
        Task_JTAG_BIT(.TMS(1'b0), .TDI(DR[i]));    
        DR_OUT[i] = TDO;
    end
    //---- Shift DR (bit length-1)
    Task_JTAG_BIT(.TMS(1'b1), .TDI(DR[length - 1]));    
    DR_OUT[length - 1] = TDO;
    //---- Exit1-DR
    Task_JTAG_BIT(.TMS(1'b1), .TDI(1'bx));    
    //---- Update DR
    Task_JTAG_BIT(.TMS(1'b0), .TDI(1'bx));    
    //---- Run Test Idle
    #(`TB_TCYC_TCK * 1);
    // Message
    if (verbose) $display("----JTAG DR SFT_IN(0x%16x) SFT_OUT(0x%16x)", DR, DR_OUT);
endtask

//-----------------------------
// Task : JTAG_DMI_WRTE
//-----------------------------
task Task_JTAG_DMI_WRTE(input [6:0] DMI_ADDR, input [31:0] DMI_DATA, integer verbose);
    integer i;
    reg [63:0] DR;
    // Invoke a Command
    i = 0;
    Task_JTAG_Shift_IR(`JTAG_IR_DMI, verbose);  
    DR = {23'h0, DMI_ADDR, DMI_DATA, `DMI_COMMAND_WR};
    Task_JTAG_Shift_DR(DR, 41, verbose);
    $display("----JTAG_DMI_WRTE (TRY%02d) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)", 
        i, DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);          
    if (DR_OUT[1:0])  // unexpected op code
    begin
        $display("!!!!Unexpeced op code (0x%01x)", DR_OUT[1:0]);
        $stop;
    end
    // Repeat until Not Busy
    begin : Task_JTAG_DMI_WRTE_LOOP
        for (i = 1; i < 10; i = i + 1)
        begin
            Task_JTAG_Shift_IR(`JTAG_IR_DMI, verbose);  
            DR = {23'h0, DMI_ADDR, 32'hxxxxxxxx, `DMI_COMMAND_NOP};
            Task_JTAG_Shift_DR(DR, 41, verbose);
            $display("    JTAG_DMI_NOP  (TRY%2d) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)", 
                i, DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);          
            if (DR_OUT[1:0] == `DMI_RESPONSE_OK   ) disable Task_JTAG_DMI_WRTE_LOOP;
            if (DR_OUT[1:0] == `DMI_RESPONSE_ERROR) disable Task_JTAG_DMI_WRTE_LOOP;
            // Retry because of BUSY
          //$display("    Retry %2d because of BUSY.", i);
            Task_JTAG_Shift_IR(`JTAG_IR_DTMCS, verbose);
            Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b0, 1'b1, 16'h0}, 32, verbose);
            Task_JTAG_Shift_DR(64'h0, 32, verbose);
        end
    end
    // Still not OK?
    if (DR_OUT[1:0] == `DMI_RESPONSE_ERROR)
    begin
        $display("!!!!DMI Error (0x%1x)", DR_OUT[1:0]);
        $stop;
    end
    if (DR_OUT[1:0] == `DMI_RESPONSE_BUSY)
    begin
        $display("!!!!DMI Busy Timeout (0x%1x)", DR_OUT[1:0]);
        $stop;
    end
endtask

//-----------------------------
// Task : JTAG_DMI_READ
//-----------------------------
task Task_JTAG_DMI_READ(input [6:0] DMI_ADDR, input [31:0] DMI_DATA, integer verbose);
    integer i;
    reg [63:0] DR;
    // Invoke a Command
    i = 0;
    Task_JTAG_Shift_IR(`JTAG_IR_DMI, verbose);  
    DR = {23'h0, DMI_ADDR, DMI_DATA, `DMI_COMMAND_RD};
    Task_JTAG_Shift_DR(DR, 41, verbose);
    $display("----JTAG_DMI_READ (TRY%02d) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)", 
        i, DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);          
    if (DR_OUT[1:0])  // unexpected op code
    begin
        $display("!!!!Unexpeced op code (0x%01x)", DR_OUT[1:0]);
        $stop;
    end
    // Repeat until Not Busy
    begin : Task_JTAG_DMI_READ_LOOP
        for (i = 1; i < 10; i = i + 1)
        begin
            Task_JTAG_Shift_IR(`JTAG_IR_DMI, verbose);  
            DR = {23'h0, DMI_ADDR, 32'hxxxxxxxx, `DMI_COMMAND_NOP};
            Task_JTAG_Shift_DR(DR, 41, verbose);
            $display("    JTAG_DMI_NOP  (TRY%2d) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)", 
                i, DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);          
            if (DR_OUT[1:0] == `DMI_RESPONSE_OK   ) disable Task_JTAG_DMI_READ_LOOP;
            if (DR_OUT[1:0] == `DMI_RESPONSE_ERROR) disable Task_JTAG_DMI_READ_LOOP;
            // Retry because of BUSY
          //$display("    Retry %2d because of BUSY.", i);
            Task_JTAG_Shift_IR(`JTAG_IR_DTMCS, verbose);
            Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b0, 1'b1, 16'h0}, 32, verbose);
            Task_JTAG_Shift_DR(64'h0, 32, verbose);
        end
    end
    // Still not OK?
    if (DR_OUT[1:0] == `DMI_RESPONSE_ERROR)
    begin
        $display("!!!!DMI Error (0x%1x)", DR_OUT[1:0]);
        $stop;
    end
    if (DR_OUT[1:0] == `DMI_RESPONSE_BUSY)
    begin
        $display("!!!!DMI Busy Timeout (0x%1x)", DR_OUT[1:0]);
        $stop;
    end
    // Verify
    if (DMI_DATA !== 32'hxxxxxxxx)
    begin
        if (DMI_DATA == DR_OUT[33:2])
            $write(" ---> Verify OK:0x%08x", DMI_DATA);
        else
        begin
            $display(" ---> Verify NG:0x%08x", DMI_DATA);
            $stop;
        end
    end
    $display("");
endtask

//-----------------------------
// Task : JTAG_DMI_WRTE FAST
//-----------------------------
task Task_JTAG_DMI_WRTE_FAST(input [6:0] DMI_ADDR, input [31:0] DMI_DATA, integer verbose);
    reg [63:0] DR;
    DR = {23'h0, DMI_ADDR, DMI_DATA, `DMI_COMMAND_WR};
    Task_JTAG_Shift_DR(DR, 41, verbose);
    $display("----JTAG_DMI_WRTE (FAST) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)",
        DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);         
endtask

//-----------------------------
// Task : JTAG_DMI_READ FAST
//-----------------------------
task Task_JTAG_DMI_READ_FAST(input [6:0] DMI_ADDR, input [31:0] DMI_DATA, integer verbose);
    reg [63:0] DR;
    DR = {23'h0, DMI_ADDR, DMI_DATA, `DMI_COMMAND_RD};
    Task_JTAG_Shift_DR(DR, 41, verbose);
    $display("----JTAG_DMI_READ (FAST) SFT_IN(0x%02x 0x%08x 0x%01x) SFT_OUT(0x%02x 0x%08x 0x%01x)",
        DR[40:34], DR[33:2], DR[1:0], DR_OUT[40:34], DR_OUT[33:2], DR_OUT[1:0]);         
    // Verify
    if (DMI_DATA !== 32'hxxxxxxxx)
    begin
        if (DMI_DATA == DR_OUT[33:2])
            $write(" ---> Verify OK:0x%08x", DMI_DATA);
        else
        begin
            $display(" ---> Verify NG:0x%08x", DMI_DATA);
            $stop;
        end
    end
    $display("");
endtask

//-----------------------------------
// Task : Write by ABSCMD
//-----------------------------------
// CMDTYPE : 8'h00=Register, 8'h02=Memory
// ADDR    : Register...0x00000000-0x00000fff : CSR
//                      0x00001000-0x0000101f : XRn
//                      0x00001020-0x0000103f : FRn
//                      0x0000c000-0x0000ffff : reserved
task TASK_JTAG_ABSCMD_WR(input [7:0] CMDTYPE, input [31:0] ADDR, input [31:0] WDATA);
    // Register
    if (CMDTYPE == 8'h00)
    begin
        Task_JTAG_DMI_WRTE(`DM_DATA_0, WDATA, `VERBOSE_OFF);
        Task_JTAG_DMI_WRTE(`DM_COMMAND, {CMDTYPE, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, ADDR[15:0]}, `VERBOSE_OFF); // WR
        Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
        $display("----JTAG_ABSCMD_WR(REG) RNUM=0x%04x WDATA=0x%08x", ADDR, WDATA);

    end
    // Memory (32bit)
    else
    begin
        Task_JTAG_DMI_WRTE(`DM_DATA_0, WDATA, `VERBOSE_OFF);
        Task_JTAG_DMI_WRTE(`DM_DATA_1, ADDR , `VERBOSE_OFF);
        Task_JTAG_DMI_WRTE(`DM_COMMAND, {CMDTYPE, 1'b0, 3'h2, 1'b0, 2'b0, 1'b1, 2'b0, 14'b0}, `VERBOSE_OFF); // WR
        Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);    
        $display("----JTAG_ABSCMD_WR(MEM) ADDR=0x%04x WDATA=0x%08x", ADDR, WDATA);
    end
endtask

//-----------------------------------
// Task : Read by ABSCMD
//-----------------------------------
// CMDTYPE : 8'h00=Register, 8'h02=Memory
// ADDR    : Register...0x00000000-0x00000fff : CSR
//                      0x00001000-0x0000101f : XRn
//                      0x00001020-0x0000103f : FRn
//                      0x0000c000-0x0000ffff : reserved
task TASK_JTAG_ABSCMD_RD(input [7:0] CMDTYPE, input [31:0] ADDR, output [31:0] RDATA);
    // Register
    if (CMDTYPE == 8'h00)
    begin
        Task_JTAG_DMI_WRTE(`DM_COMMAND, {CMDTYPE, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b0, ADDR[15:0]}, `VERBOSE_OFF); // RD
        Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
        Task_JTAG_DMI_READ(`DM_DATA_0, 32'hxxxxxxxx, `VERBOSE_OFF);
        RDATA = DR_OUT[33:2];
        $display("----JTAG_ABSCMD_RD(REG) RNUM=0x%04x RDATA=0x%08x", ADDR, RDATA);
    end
    // Memory (32bit)
    else
    begin
        Task_JTAG_DMI_WRTE(`DM_DATA_1, ADDR , `VERBOSE_OFF);
        Task_JTAG_DMI_WRTE(`DM_COMMAND, {CMDTYPE, 1'b0, 3'h2, 1'b0, 2'b0, 1'b0, 2'b0, 14'b0}, `VERBOSE_OFF); // WR
        Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);    
        Task_JTAG_DMI_READ(`DM_DATA_0, 32'hxxxxxxxx, `VERBOSE_OFF);
        RDATA = DR_OUT[33:2];
        $display("----JTAG_ABSCMD_RD(MEM) ADDR=0x%04x RDATA=0x%08x", ADDR, RDATA);
    end
endtask

//--------------------------------
// Display TAP Controller State
//--------------------------------
initial U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_tck = `JTAG_TAP_CAPTURE_IR;
//
`ifdef DEBUG_TAP_CONTROLLER_STATE
wire tck;
wire [3:0] state_tap;
wire [3:0] state_tap_next;
assign tck = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.TCK;
assign state_tap = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_tck;
assign state_tap_next = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_next_tck;
//
always @(posedge tck)
begin
    if (state_tap != state_tap_next)
    begin
        if (state_tap_next == `JTAG_TAP_TEST_LOGIC_RESET) $display("JTAG_TAP_TEST_LOGIC_RESET");
        if (state_tap_next == `JTAG_TAP_RUN_TEST_IDLE   ) $display("JTAG_TAP_RUN_TEST_IDLE");
        if (state_tap_next == `JTAG_TAP_SELECT_DR_SCAN  ) $display("JTAG_TAP_SELECT_DR_SCAN");
        if (state_tap_next == `JTAG_TAP_CAPTURE_DR      ) $display("JTAG_TAP_CAPTURE_DR");
        if (state_tap_next == `JTAG_TAP_SHIFT_DR        ) $display("JTAG_TAP_SHIFT_DR");
        if (state_tap_next == `JTAG_TAP_EXIT1_DR        ) $display("JTAG_TAP_EXIT1_DR");
        if (state_tap_next == `JTAG_TAP_PAUSE_DR        ) $display("JTAG_TAP_PAUSE_DR");
        if (state_tap_next == `JTAG_TAP_EXIT2_DR        ) $display("JTAG_TAP_EXIT2_DR");
        if (state_tap_next == `JTAG_TAP_UPDATE_DR       ) $display("JTAG_TAP_UPDATE_DR");
        if (state_tap_next == `JTAG_TAP_SELECT_IR_SCAN  ) $display("JTAG_TAP_SELECT_IR_SCAN");
        if (state_tap_next == `JTAG_TAP_CAPTURE_IR      ) $display("JTAG_TAP_CAPTURE_IR");
        if (state_tap_next == `JTAG_TAP_SHIFT_IR        ) $display("JTAG_TAP_SHIFT_IR");
        if (state_tap_next == `JTAG_TAP_EXIT1_IR        ) $display("JTAG_TAP_EXIT1_IR");
        if (state_tap_next == `JTAG_TAP_PAUSE_IR        ) $display("JTAG_TAP_PAUSE_IR");
        if (state_tap_next == `JTAG_TAP_EXIT2_IR        ) $display("JTAG_TAP_EXIT2_IR");
        if (state_tap_next == `JTAG_TAP_UPDATE_IR       ) $display("JTAG_TAP_UPDATE_IR");
    end
end
`endif

//------------------------
// Stimulus
//------------------------
reg [31:0] jtag_data;
reg        detect_break;
reg [31:0] rdata;
reg [31:0] opcode;
//
initial
begin
    tb_enable_cjtag = 1'b1;
    //
    tb_stby         = 1'b0;
    tb_debug_secure = 1'b1;
    tb_clk_speed    = 1'b0; // High Speed
    tb_srst_n       = 1'bz; // pullup
    //
    Task_RESET_RUN();
//  Task_RESET_HALT();
    Task_JTAG_INIT_PIN();
    #(`TB_TCYC_CLK);
    @(negedge watch_res);
    #(`TB_TCYC_TCK * 10);
    tb_reset_halt_n = 1'b1;
    
    /*
    if (tb_enable_cjtag)
    begin
        Task_CJTAG_ONLINE(2);
        #(`TB_TCYC_TCK * 10);
        //
        Task_CJTAG_ONLINE(3);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1001); // EC(NG)
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(3);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // CP(NG)
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(3);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(5);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        //
        Task_JTAG_INIT_STATE();
        #(`TB_TCYC_TCK * 10);
        $display("Read JTAG ID");
        Task_JTAG_Shift_IR(`JTAG_IR_IDCODE, `VERBOSE_ON);
        Task_JTAG_Shift_DR(32'h0, 32, `VERBOSE_ON);
        #(`TB_TCYC_TCK * 10);
        //
        Task_CJTAG_ONLINE(5);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        $stop;
    end
    */
    //
//------------------------------------------------------------------------
`ifdef JTAG_OPERATION
    //------------------------------------
    if (tb_enable_cjtag)
    begin
        Task_CJTAG_ONLINE_NAGATIVE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        Task_CJTAG_ONLINE_NAGATIVE(2);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE_NAGATIVE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        //
        Task_CJTAG_ONLINE(2);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(5);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE_NAGATIVE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(3);
        #(`TB_TCYC_TCK * 10);
        //
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(2);
        Task_CJTAG_ONLINE(3);
        Task_CJTAG_ONLINE(4);
        Task_CJTAG_ACTIVATION_CODE(4'b0100); // Illegal
        Task_CJTAG_ONLINE(3);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        Task_CJTAG_OPENOCD();
        #(`TB_TCYC_TCK * 10);
        Task_JTAG_INIT_STATE();
        #(`TB_TCYC_TCK * 10);
        #(`TB_TCYC_TCK * 10);
        #(`TB_TCYC_TCK * 10);
        //------------------------------------
        Task_CJTAG_ONLINE_NAGATIVE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
        //
        Task_CJTAG_OPENOCD();
    end
    //------------------------------------
  //Task_RESET_SYS();
    #(`TB_TCYC_TCK * 10);
    #(`TB_TCYC_CLK * 10);
    Task_JTAG_INIT_STATE();
    #(`TB_TCYC_TCK * 10);
    //
    $display("Shift in Long Data when IR=5'h1f");
    Task_JTAG_Shift_IR(5'h1f, `VERBOSE_ON);
    Task_JTAG_Shift_DR(64'h0123456789abcdef, 64, `VERBOSE_ON);
    //
    $display("Read/Write USER");
    Task_JTAG_Shift_IR(`JTAG_IR_USER, `VERBOSE_ON);
    Task_JTAG_Shift_DR(64'h000000001234abcd, 32, `VERBOSE_ON);
    Task_JTAG_Shift_DR(64'h00000000aa556699, 32, `VERBOSE_ON);
    //
    $display("Read IDCODE");
    Task_JTAG_Shift_IR(`JTAG_IR_IDCODE, `VERBOSE_ON);
    Task_JTAG_Shift_DR(64'h0, 32, `VERBOSE_ON);
    //
    $display("RD DM_Default");
    Task_JTAG_DMI_READ(7'h7f, 32'hdead007f, `VERBOSE_ON);
    //
    $display("WR&RD DM_CONTROL to set dmactive");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    //
    $display("Security Pass Code");
    Task_JTAG_DMI_WRTE(`DM_AUTHDATA, 32'h12345678, `VERBOSE_ON);
    //
    $display("Write DTMCS to Assert dmihardreset and Check dmactive cleared");
    Task_JTAG_Shift_IR(`JTAG_IR_DTMCS, `VERBOSE_ON);
    Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b1, 1'b0, 16'h0}, 32, `VERBOSE_ON);
    Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b0, 1'b0, 16'h0}, 32, `VERBOSE_ON);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000000, `VERBOSE_OFF);
    //
    $display("Reset Rest of the System by ndmreset and set dmactive");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000003, `VERBOSE_ON);
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    //
    $display("Select Hart 0");
    Task_JTAG_DMI_WRTE(`DM_HAWINDOWSEL, 32'h00000000, `VERBOSE_ON);
    Task_JTAG_DMI_WRTE(`DM_HAWINDOW   , 32'h00000001, `VERBOSE_ON);
    //
    $display("Halt Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h80000001, `VERBOSE_ON);
    //
    `ifdef RISCV_ISA_RV32F
    $display("ABSCMD WR/RD FPR 00");
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h456789ab, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h456789ab, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h1020}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    tb_clk_speed = 1'b1; // Low Speed
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b0, 16'h1020}, `VERBOSE_OFF); // RD
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h456789ab, `VERBOSE_OFF);
    //
    $display("ABSCMD WR/RD FPR 31");
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h56789abc, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h56789abc, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h103f}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b0, 16'h103f}, `VERBOSE_OFF); // RD
    tb_clk_speed    = 1'b0; // High Speed
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h56789abc, `VERBOSE_OFF);
    `endif
    //
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    $display("Halt Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h80000001, `VERBOSE_OFF);
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    //
    $display("HART_STEP_OPERATION");
    jtag_data = (1 << 31) | (0 << 26) | (0 << 16) | (1 << 0); // haltreq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    //
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000004, `VERBOSE_OFF); // step=1
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h07b0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    //
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    //
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    //
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF); // step=0
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h07b0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    //
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); //resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    //
    $display("HALT for STBY and Step Execution");
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 20);
    //
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 20);
    jtag_data = (1 << 31) | (0 << 26) | (0 << 16) | (1 << 0); // haltreq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 20);
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 20);
    //
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 20);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 20);
    //
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 50);
    jtag_data = (1 << 31) | (0 << 26) | (0 << 16) | (1 << 0); // haltreq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 50);
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 50);
    //
    jtag_data = (1 << 31) | (0 << 26) | (0 << 16) | (1 << 0); // haltreq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 10);
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000004, `VERBOSE_OFF); // step=1
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h07b0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 10);
    //
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); // resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    //
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00000000, `VERBOSE_OFF); // step=0
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h0, 1'b0, 3'h2, 1'b0, 1'b0, 1'b1, 1'b1, 16'h07b0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_READ(`DM_ABSTRACTCS, 32'h00000002, `VERBOSE_OFF);
    //
    jtag_data = (1 << 30) | (0 << 26) | (0 << 16) | (1 << 0); //resumereq
    Task_JTAG_DMI_WRTE(`DM_CONTROL, jtag_data, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //
    $display("***** Repeat STBY & RESUME *****");
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b1;
    tb_clk_speed = 1'b1; // Low Speed
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 50);
    tb_stby = 1'b1;
    #(`TB_TCYC_TCK * 50);
    tb_clk_speed    = 1'b0; // High Speed
    tb_stby = 1'b0;
    #(`TB_TCYC_TCK * 50);
    //    
    #(`TB_TCYC_TCK * 10000);
    tb_clk_speed = 1'b1; // Low Speed
    #(`TB_TCYC_TCK * 10000);
    tb_clk_speed    = 1'b0; // High Speed
    #(`TB_TCYC_TCK * 50);
`endif // JTAG_OPERATION
//------------------------------------------------------------------------
`ifdef JTAG_SBACCESS
    //------------------------------------
    if (tb_enable_cjtag)
    begin
        Task_CJTAG_ONLINE(2);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(5);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ONLINE(3);
        #(`TB_TCYC_TCK * 10);
        //
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
    end
    //------------------------------------
    Task_JTAG_INIT_STATE();
    #(`TB_TCYC_TCK * 10);
    //
    $display("WR&RD DM_CONTROL to set dmactive");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    //
    $display("Security Pass Code");
    Task_JTAG_DMI_WRTE(`DM_AUTHDATA, 32'h12345678, `VERBOSE_OFF);
    //
    $display("Write DTMCS to Assert dmihardreset and Check dmactive cleared");
    Task_JTAG_Shift_IR(`JTAG_IR_DTMCS, `VERBOSE_ON);
    Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b1, 1'b0, 16'h0}, 32, `VERBOSE_ON);
    Task_JTAG_Shift_DR({32'h0, 14'h0, 1'b0, 1'b0, 16'h0}, 32, `VERBOSE_ON);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000000, `VERBOSE_OFF);
    //
    $display("Reset Rest of the System by ndmreset and set dmactive");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000003, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    //
    $display("Select Hart 0");
    Task_JTAG_DMI_WRTE(`DM_HAWINDOWSEL, 32'h00000000, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_HAWINDOW   , 32'h00000001, `VERBOSE_OFF);
    //
    $display("ABSCMD WR/RD RAM");
    Task_JTAG_DMI_WRTE(`DM_DATA_1, 32'h88000000, `VERBOSE_OFF); // addr
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h00112233, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b1, 16'h0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h44556677, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b1, 16'h0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'h8899aabb, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b1, 16'h0}, `VERBOSE_OFF); // WR
    Task_JTAG_DMI_WRTE(`DM_DATA_0, 32'hccddeeff, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b1, 16'h0}, `VERBOSE_OFF); // WR
    //
    Task_JTAG_DMI_WRTE(`DM_DATA_1, 32'h88000000, `VERBOSE_OFF); // addr
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b0, 16'h0}, `VERBOSE_OFF); // RD
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h00112233, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b0, 16'h0}, `VERBOSE_OFF); // RD
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h44556677, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b0, 16'h0}, `VERBOSE_OFF); // RD
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'h8899aabb, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_WRTE(`DM_COMMAND, {8'h2, 1'b0, 3'h2, 1'b1, 2'b0, 1'b0, 16'h0}, `VERBOSE_OFF); // RD
    Task_JTAG_DMI_READ(`DM_DATA_0, 32'hccddeeff, `VERBOSE_OFF); // rdata
    //
    $display("SBACCESS WR/RD RAM");
    Task_JTAG_DMI_WRTE(`DM_SBCS, {3'h1, 6'b0, 1'b0, 1'b0, 1'b0, 3'h2, 1'b1, 1'b0, 3'b0, 7'd32, 5'b00111}, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_SBADDRESS_0, 32'h88000100, `VERBOSE_OFF); // addr
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'h00112233, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'h44556677, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'h8899aabb, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'hccddeeff, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'h01234567, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'h89abcdef, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'hbeefface, `VERBOSE_OFF); // wdata
    Task_JTAG_DMI_WRTE_FAST(`DM_SBDATA_0, 32'hdeadface, `VERBOSE_OFF); // wdata
    //
    Task_JTAG_DMI_WRTE(`DM_SBCS, {3'h1, 6'b0, 1'b0, 1'b0, 1'b1, 3'h2, 1'b1, 1'b1, 3'b0, 7'd32, 5'b00111}, `VERBOSE_OFF);
    Task_JTAG_DMI_WRTE(`DM_SBADDRESS_0, 32'h88000100, `VERBOSE_OFF); // addr
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h00000000, `VERBOSE_OFF); // dummy rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h00112233, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h44556677, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h8899aabb, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'hccddeeff, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h01234567, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'h89abcdef, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'hbeefface, `VERBOSE_OFF); // rdata
    Task_JTAG_DMI_READ_FAST(`DM_SBDATA_0, 32'hdeadface, `VERBOSE_OFF); // rdata
    //
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    //
    #(`TB_TCYC_TCK * 100);
    $stop;
`endif // JTAG_SBACCESS
//------------------------------------------------------------------------
`ifdef HARDWARE_BREAK
    //------------------------------------
    if (tb_enable_cjtag)
    begin
        Task_CJTAG_ONLINE(3);
        #(`TB_TCYC_TCK * 10);
        Task_CJTAG_ACTIVATION_CODE(4'b1100); // OAC
        Task_CJTAG_ACTIVATION_CODE(4'b1000); // EC
        Task_CJTAG_ACTIVATION_CODE(4'b0000); // CP
        #(`TB_TCYC_TCK * 10);
    end
    //------------------------------------
    Task_JTAG_INIT_STATE();
    #(`TB_TCYC_TCK * 10);
    //
    $display("WR&RD DM_CONTROL to set dmactive");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_OFF);
    //
    $display("Security Pass Code");
    Task_JTAG_DMI_WRTE(`DM_AUTHDATA, 32'h12345678, `VERBOSE_ON);
    //
    $display("Select Hart 0");
    Task_JTAG_DMI_WRTE(`DM_HAWINDOWSEL, 32'h00000000, `VERBOSE_ON);
    Task_JTAG_DMI_WRTE(`DM_HAWINDOW   , 32'h00000001, `VERBOSE_ON);
    //
    $display("Reset Rest of the System by ndmreset with ResetHalt");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h0000000b, `VERBOSE_ON);
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    Task_JTAG_DMI_READ(`DM_CONTROL, 32'h00000001, `VERBOSE_ON);
    //
    // Set Software Break
    $display("Read Opcode at 0x90000808");
    TASK_JTAG_ABSCMD_RD(8'h02, 32'h90000808, opcode);
    $display("Write EBREAK at 0x90000808");
    TASK_JTAG_ABSCMD_WR(8'h02, 32'h90000808, 32'h00100073);
    $display("Let EBREAK enter Debug Mode ");
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c3);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Set Hardware Breakpoint 0");
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TSELECT,  32'h00000000);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TDATA2 ,  32'h9000080c);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_MCONTROL,
        (4'b0010   << 28) + // type
        (1'b1      << 27) + // dmode
        (6'b000000 << 21) + // maskmax (ro)
        (1'b0      << 20) + // hit
        (1'b0      << 19) + // select
        (1'b0      << 18) + // timing
        (2'b00     << 16) + // sizelo
        (4'b0001   << 12) + // action
        (1'b0      << 11) + // chain
        (4'b0000   <<  7) + // match
        (1'b1      <<  6) + // m
        (1'b0      <<  5) + // reseerved
        (1'b0      <<  4) + // s
        (1'b0      <<  3) + // u
        (1'b1      <<  2) + // execute
        (1'b0      <<  1) + // store
        (1'b0      <<  0)   // load
    );
    /*
    //
    $display("Set Hardware Breakpoint 1");
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TSELECT,  32'h00000001);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TDATA2 ,  32'h90000806);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_MCONTROL,
        (4'b0010   << 28) + // type
        (1'b1      << 27) + // dmode
        (6'b000000 << 21) + // maskmax (ro)
        (1'b0      << 20) + // hit
        (1'b0      << 19) + // select
        (1'b0      << 18) + // timing
        (2'b00     << 16) + // sizelo
        (4'b0001   << 12) + // action
        (1'b0      << 11) + // chain
        (4'b0000   <<  7) + // match
        (1'b1      <<  6) + // m
        (1'b0      <<  5) + // reseerved
        (1'b0      <<  4) + // s
        (1'b0      <<  3) + // u
        (1'b1      <<  2) + // execute
        (1'b0      <<  1) + // store
        (1'b0      <<  0)   // load
    );
    //
    $display("Set Hardware Breakpoint 2");
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TSELECT,  32'h00000001);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TDATA2 ,  32'h90000808);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_MCONTROL,
        (4'b0010   << 28) + // type
        (1'b1      << 27) + // dmode
        (6'b000000 << 21) + // maskmax (ro)
        (1'b0      << 20) + // hit
        (1'b0      << 19) + // select
        (1'b0      << 18) + // timing
        (2'b00     << 16) + // sizelo
        (4'b0001   << 12) + // action
        (1'b0      << 11) + // chain
        (4'b0000   <<  7) + // match
        (1'b1      <<  6) + // m
        (1'b0      <<  5) + // reseerved
        (1'b0      <<  4) + // s
        (1'b0      <<  3) + // u
        (1'b1      <<  2) + // execute
        (1'b0      <<  1) + // store
        (1'b0      <<  0)   // load
    );
    #(`TB_TCYC_TCK * 10);
    //
    $display("Set Hardware Breakpoint 3");
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TSELECT,  32'h00000001);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_TDATA2 ,  32'h9000080c);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_MCONTROL,
        (4'b0010   << 28) + // type
        (1'b1      << 27) + // dmode
        (6'b000000 << 21) + // maskmax (ro)
        (1'b0      << 20) + // hit
        (1'b0      << 19) + // select
        (1'b0      << 18) + // timing
        (2'b00     << 16) + // sizelo
        (4'b0001   << 12) + // action
        (1'b0      << 11) + // chain
        (4'b0000   <<  7) + // match
        (1'b1      <<  6) + // m
        (1'b0      <<  5) + // reseerved
        (1'b0      <<  4) + // s
        (1'b0      <<  3) + // u
        (1'b1      <<  2) + // execute
        (1'b0      <<  1) + // store
        (1'b0      <<  0)   // load
    );
    #(`TB_TCYC_TCK * 10);
    */
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //-------------------------------------------------------------
    $display("Wait for Software Break");
    while(1)
    begin
        @(posedge watch_clk)
        Task_JTAG_DMI_READ(`DM_STATUS, 32'hxxxxxxxx, `VERBOSE_OFF);
        if (DR_OUT[9+2]) break;
    end
    $display("Revert Opcode at 0x90000808");
    TASK_JTAG_ABSCMD_WR(8'h02, 32'h90000808, opcode);
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //-------------------------------------------------------------
    $display("Wait for Hardware Break");
    while(1)
    begin
        @(posedge watch_clk)
        if (detect_break) break;
    end
    #(`TB_TCYC_TCK * 10);
    $display("Clear Detect Break");
    detect_break = 1'b0;
    #(`TB_TCYC_TCK * 10);
    //
    $display("Enable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c7);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0 Again");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Disable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c3);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //-------------------------------------------------------------
    /*
    $display("Wait for Hardware Break");
    while(1)
    begin
        @(posedge watch_clk)
        if (detect_break) break;
    end
    #(`TB_TCYC_TCK * 10);
    //
    $display("Enable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c7);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0 Again");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Disable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c3);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0 Again");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //-------------------------------------------------------------
    $display("Wait for Hardware Break");
    while(1)
    begin
        @(posedge watch_clk)
        if (detect_break) break;
    end
    #(`TB_TCYC_TCK * 10);
    //
    $display("Enable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c7);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0 Again");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Disable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c3);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //-------------------------------------------------------------
    $display("Wait for Hardware Break");
    while(1)
    begin
        @(posedge watch_clk)
        if (detect_break) break;
    end
    #(`TB_TCYC_TCK * 10);
    //
    $display("Enable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c7);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0 Again");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Disable Step in DCSR");
    TASK_JTAG_ABSCMD_RD(8'h00, `CSR_DCSR, rdata);
    TASK_JTAG_ABSCMD_WR(8'h00, `CSR_DCSR, 32'h400080c3);
    #(`TB_TCYC_TCK * 10);
    //
    $display("Resume Hart 0");
    Task_JTAG_DMI_WRTE(`DM_CONTROL, 32'h40000001, `VERBOSE_OFF);
    #(`TB_TCYC_TCK * 10);
    */
`endif // HARDWARE_BREAK
//------------------------------------------------------------------------
    #(`TB_TCYC_TCK * 10);
    $display("***** DETECT FINAL STIMULUS *****");
    stop_by_stimulus = 1'b1;
end

//-----------------------------------------------
// Detect Break
//-----------------------------------------------
always @(posedge watch_clk, posedge watch_res)
begin
    if (watch_res)
        detect_break <= 1'b0;
    else if (watch_state_id_ope == `STATE_ID_DEBUG_MODE)
        detect_break <= 1'b1;
    else
        detect_break <= 1'b0;
end

//--------------------------------------
// Counter for Bcc Taken and Not Taken
//--------------------------------------
reg  [31:0] count_bcc;
reg  [31:0] count_bcc_stall;
reg  [31:0] count_bcc_taken;
reg  [31:0] count_bcc_not_taken;
//
wire cpu_res, cpu_clk;
wire cpu_stall, cpu_bcc, cpu_cmp;
assign cpu_res   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.RES_CPU;
assign cpu_clk   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.CLK;
assign cpu_stall = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.stall;
assign cpu_bcc   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.fetch_start_by_cond;
assign cpu_cmp   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.U_CPU_TOP[0].U_CPU_TOP.U_CPU_PIPELINE.ID_CMP_RSLT;
//
always @(posedge cpu_clk, posedge cpu_res)
begin
    if (cpu_res)
    begin
        count_bcc           <= 32'h0;
        count_bcc_stall     <= 32'h0;
        count_bcc_taken     <= 32'h0;
        count_bcc_not_taken <= 32'h0;
    end
    else
    begin
        if (cpu_bcc & ~cpu_stall) count_bcc <= count_bcc + 32'h1;
        if (cpu_bcc &  cpu_stall) count_bcc_stall <= count_bcc_stall + 32'h1;
        if (cpu_bcc & ~cpu_stall &  cpu_cmp) count_bcc_taken <= count_bcc_taken + 32'h1;
        if (cpu_bcc & ~cpu_stall & ~cpu_cmp) count_bcc_not_taken <= count_bcc_not_taken + 32'h1;
    end
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
