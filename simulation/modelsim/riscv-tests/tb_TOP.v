//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tb_top.v
// Description : Testbench for Top Level
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2021.03.14 M.Maruyama riscv_tests
// Rev.04 2023.08.26 M.Maruyama for latest mmRISC-1
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

`include "defines_core.v"
`include "defines_chip.v"

`timescale 1ns/100ps
//`define JTAG_FAST
//
`ifdef JTAG_FAST
    `define TB_TCYC_CLK 100 //ns (10MHz)
    `define TB_TCYC_TCK  20 //ns (50MHz)
`else
    `define TB_TCYC_CLK  20 //ns (50MHz)
    `define TB_TCYC_TCK 100 //ns (10MHz)
`endif
//
`define TB_STOP 400000 //cyc
`define TB_RESET_WIDTH 50 //ns

//------------------------
// Top of Testbench
//------------------------
module tb_TOP;

//--------------------
// JTAG or cJTAG
//--------------------
reg tb_enable_cjtag; // selection whether using JTAG or cJTAG


//-------------------------------
// Generate Clock
//-------------------------------
reg tb_clk;
wire tb_clk_speed;
assign tb_clk_speed = 1'b0;
//
initial tb_clk = 1'b0;
always #(`TB_TCYC_CLK / 2) tb_clk = ~tb_clk;

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
        $finish; //$stop;
    end
end

//--------------------------
// Terminate Simulation
//--------------------------
wire        watch_res      [0 : `HART_COUNT - 1];
wire        watch_clk      [0 : `HART_COUNT - 1];
wire        watch_hsel     [0 : `HART_COUNT - 1];
wire [ 1:0] watch_htrans   [0 : `HART_COUNT - 1];
wire        watch_hwrite   [0 : `HART_COUNT - 1];
wire [ 2:0] watch_hsize    [0 : `HART_COUNT - 1];
wire [31:0] watch_haddr    [0 : `HART_COUNT - 1];
wire [31:0] watch_hwdata   [0 : `HART_COUNT - 1];
wire        watch_hready   [0 : `HART_COUNT - 1];
wire        watch_hreadyout[0 : `HART_COUNT - 1];
reg         watch_match    [0 : `HART_COUNT - 1];
reg  [ 1:0] detect_tohost  [0 : `HART_COUNT - 1];
reg  [ 1:0] detect_finish;
//
generate
    genvar n;
    for (n = 0; n <  `HART_COUNT ; n = n + 1)
    begin
        assign watch_res[n]    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.RES_ORG;
        assign watch_clk[n]    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CLK;
        assign watch_hsel[n]   = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HSEL[n];
        assign watch_htrans[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HTRANS[n];
        assign watch_hsize[n]  = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HSIZE[n];
        assign watch_hwrite[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HWRITE[n];
        assign watch_haddr[n]  = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HADDR[n];
        assign watch_hwdata[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HWDATA[n];
        assign watch_hready[n]    = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HREADY[n];
        assign watch_hreadyout[n] = U_CHIP_TOP_WRAP.U_CHIP_TOP.U_MMRISC.CPUD_M_HREADYOUT[n];
        //
        always @(posedge watch_clk[n], posedge watch_res[n])
        begin
            if (watch_res[n])
            begin
                watch_match[n] <= 1'b0;
            end
            else if (watch_hready[n] & watch_hreadyout[n])
            begin
                watch_match[n] <= (watch_hsel[n]      == 1'b1)
                                & (watch_htrans[n][1] == 1'b1)
                                & (watch_hsize[n]     == 3'b010)
                                & (watch_hwrite[n]    == 1'b1)
                                & (watch_haddr[n]     == (`TOHOST + (n << 24)));
            end
        end
        //
        always @(posedge watch_clk[n], posedge watch_res[n])
        begin
            if (watch_res[n])
            begin
                detect_tohost[n] <= 2'b00;
            end
            else if (watch_match[n] & watch_hready[n] & watch_hreadyout[n] & (watch_hwdata[n] == 32'h00000001))
            begin
                detect_tohost[n] <= 2'b10; // PASS
            end
            else if (watch_match[n] & watch_hready[n] & watch_hreadyout[n])
            begin
                detect_tohost[n] <= 2'b11; // FAIL
            end
        end
    end
endgenerate
//
always @*
begin
    integer i;
    detect_finish = 2'b10;
    for (i = 0;  i < `HART_COUNT; i = i + 1)
    begin
        detect_finish[1] = detect_finish[1] & detect_tohost[i][1];
        detect_finish[0] = detect_finish[0] | detect_tohost[i][0];
    end
end
//
integer fdump;
reg [31:0] addr, data;
always @(posedge watch_clk[0])
begin
    if (detect_finish[1])
    begin
        $display("***** DETECT TOHOST ***** at %08x", `TOHOST);
        fdump = $fopen("result.txt", "w");
        //
        if (detect_finish == 2'b10)
            $fdisplay(fdump, "PASS");
        else
            $fdisplay(fdump, "FAIL");
        //
        $fclose(fdump);
        $finish; //$stop;
    end
end


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
assign srst_n = tb_srst_n;
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
//  .STBY_REQ   (tb_stby),
    .STBY_ACK_N (),
    //
    .RESOUT_N (),
    //
`ifdef SIMULATION
    .SRSTn (srst_n),
`endif
    //
    .TRSTn (tb_trst_n),
    .TCK (tb_tck),
    .TMS (tb_tms),
    .TDI (tb_tdi),
    .TDO (tb_tdo),
`ifdef SIMULATION
    .RTCK (tb_rtck),
`endif
    //
`ifdef ENABLE_CJTAG
    .TCKC_pri (tb_tckc),
    .TCKC_rep (tb_tckc),
    .TMSC_pri (tb_tmsc),
    .TMSC_rep (tb_tmsc),
    //
    .TMSC_PUP_rep (tb_tmsc_pup),
    .TMSC_PDN_rep (tb_tmsc_pdn),
`endif
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

//------------------------
// Stimulus
//------------------------
initial
begin
    tb_stby         = 1'b0;
    tb_enable_cjtag = 1'b0;
    Task_JTAG_INIT_PIN();
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
