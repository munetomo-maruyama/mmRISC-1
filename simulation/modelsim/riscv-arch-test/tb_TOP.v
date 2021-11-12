//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tb_top.v
// Description : Testbench for Top Level
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.02 2021.03.14 M.Maruyama riscv_arch_test
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

`include "defines.v"
`timescale 1ns/100ps
//`define JTAG_FAST
//
`ifdef JTAG_FAST
    `define TB_TCYC_CLK  100 //ns (10MHz)
    `define TB_TCYC_TCLK 20  //ns (50MHz)
`else
    `define TB_TCYC_CLK  20  //ns (50MHz)
    `define TB_TCYC_TCLK 100 //ns (10MHz)
`endif
//
`define TB_STOP 400000 //cyc
`define TB_RESET_WIDTH 50 //ns

//------------------------
// Top of Testbench
//------------------------
module tb_TOP;

integer i;
reg [63:0] DR_OUT; // global

//-------------------------------
// Generate Clock
//-------------------------------
reg tb_clk;
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
    U_CHIP_TOP.por_count = 0;
    U_CHIP_TOP.por_n = 0;
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
//
assign watch_res    = U_CHIP_TOP.U_MMRISC.RES_ORG;
assign watch_clk    = U_CHIP_TOP.U_MMRISC.CLK;
assign watch_hsel   = U_CHIP_TOP.U_MMRISC.CPUD_M_HSEL[0];
assign watch_htrans = U_CHIP_TOP.U_MMRISC.CPUD_M_HTRANS[0];
assign watch_hsize  = U_CHIP_TOP.U_MMRISC.CPUD_M_HSIZE[0];
assign watch_hwrite = U_CHIP_TOP.U_MMRISC.CPUD_M_HWRITE[0];
assign watch_haddr  = U_CHIP_TOP.U_MMRISC.CPUD_M_HADDR[0];
assign watch_hwdata = U_CHIP_TOP.U_MMRISC.CPUD_M_HWDATA[0];
assign watch_hready    = U_CHIP_TOP.U_MMRISC.CPUD_M_HREADY[0];
assign watch_hreadyout = U_CHIP_TOP.U_MMRISC.CPUD_M_HREADYOUT[0];
//
reg watch_match;
//
always @(posedge watch_clk, posedge watch_res)
begin
    if (watch_res)
    begin
        watch_match <= 1'b0;
    end
    else if (watch_hready & watch_hreadyout)
    begin
        watch_match <= (watch_hsel      == 1'b1)
                     & (watch_htrans[1] == 1'b1)
                     & (watch_hsize     == 3'b010)
                     & (watch_hwrite    == 1'b1)
                     & (watch_haddr     == `TOHOST);
    end
end
//
wire detect_tohost;
assign detect_tohost = watch_match & watch_hready & watch_hreadyout
                     & (watch_hwdata == 32'h00000001);
//
integer fdump;
reg [31:0] addr, data;
always @(posedge watch_clk)
begin
    if (detect_tohost)
    begin
        $display("***** DETECT TOHOST ***** at %08x", `TOHOST);
        fdump = $fopen("dump.signature", "w");
        //
        for (addr = `DUMP_BGN; addr < `DUMP_END; addr = addr + 4)
        begin
            data =               U_CHIP_TOP.U_RAM1.s_mem_3[addr[23:2]];
            data = (data << 8) + U_CHIP_TOP.U_RAM1.s_mem_2[addr[23:2]];
            data = (data << 8) + U_CHIP_TOP.U_RAM1.s_mem_1[addr[23:2]];
            data = (data << 8) + U_CHIP_TOP.U_RAM1.s_mem_0[addr[23:2]];
            $fdisplay(fdump, "%08x", data);
        end
        //
        $fclose(fdump);
        $finish; //$stop;
    end
end


//--------------------------
// Device Under Test
//--------------------------
reg  tb_trst_n;
reg  tb_srst_n; // reset except for debug logic
wire srst_n;
reg  tb_tck;
reg  tb_tms;
reg  tb_tdi;
wire tb_tdo;
wire tb_rtck;
wire [31:0] gpio0;
wire [31:0] gpio1;
wire [31:0] gpio2;
wire rxd;
wire txd;
//
assign srst_n = tb_srst_n;
assign rxd = 1'b1;
//
CHIP_TOP U_CHIP_TOP
(
    .RES_N (~tb_res),
    .CLK50 (tb_clk),
    //
    .SDRAM_CLK(),
    .SDRAM_CKE(),
    .SDRAM_CSn(),
    //
    .TRSTn (tb_trst_n),
    .SRSTn (srst_n),
    //
    .TCK (tb_tck),
    .TMS (tb_tms),
    .TDI (tb_tdi),
    .TDO (tb_tdo),
    .RTCK (tb_rtck),
    //
    .GPIO0 (gpio0),
    .GPIO1 (gpio1),
    .GPIO2 (gpio2),
    //
    .RXD (rxd),
    .TXD (txd)
);

//--------------------------
// Task ; JTAG_INIT_PIN
//--------------------------
task Task_JTAG_INIT_PIN();
    tb_tck = 1'b1;
    tb_tms = 1'b1;
    tb_tdi = 1'bx;
    tb_trst_n = 1'b1;
    tb_srst_n = 1'bz;    
endtask

//------------------------
// Task : JTAG_RESET_TAP
//------------------------
task Task_JTAG_RESET_TAP();
    tb_trst_n = 1'b1;
    #(`TB_TCYC_TCLK * 1);
    tb_trst_n = 1'b0;
    #(`TB_TCYC_TCLK * 1);
    tb_trst_n = 1'b1;
    #(`TB_TCYC_TCLK * 1);
    $display("----JTAG_RESET_TAP");
endtask

//------------------------
// Task : JTAG_RESET_SYS
// (except for degug logic)
//------------------------
task Task_JTAG_RESET_SYS();
    tb_srst_n = 1'bz;
    #(`TB_TCYC_TCLK * 1);
    tb_srst_n = 1'b0;
    #(`TB_TCYC_TCLK * 1);
    tb_srst_n = 1'bz;
    #(`TB_TCYC_TCLK * 1);
    $display("----JTAG_RESET_SYS");
endtask

//-------------------------
// Task : JTAG_INIT_STATE
//-------------------------
task Task_JTAG_INIT_STATE();
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Any State
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Test Logic Reset    
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Run Test Idle
        tb_tms = 1'b1;
        tb_tck = 1'b1;
    #(`TB_TCYC_TCLK * 1);
    $display("----JTAG_INIT_STATE");
endtask;

//----------------------
// Task : JTAG_Shift_IR
//----------------------
task Task_JTAG_Shift_IR(input [4:0] IR, integer verbose);
    reg [4:0] IR_OUT;
    //---- Run Test Idle
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Select DR Scan
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //----Select IR Scan
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Capture IR
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Shift IR (bit0-bit3)
    for (i = 0; i < 4; i = i + 1)
    begin
            tb_tms = 1'b0;
            tb_tdi = IR[i];
            tb_tck = 1'b0;
        #(`TB_TCYC_TCLK / 2);
            IR_OUT[i] = tb_tdo;
            tb_tck = 1'b1; // rise
        #(`TB_TCYC_TCLK / 2);
    end
    //---- Shift IR (bit4)
        tb_tms = 1'b1;
        tb_tdi = IR[4];
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        IR_OUT[4] = tb_tdo;
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Exit1-IR
        tb_tms = 1'b1;
        tb_tdi = 1'bx;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Update IR
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Run Test Idle
        tb_tms = 1'b1;
        tb_tck = 1'b1;
    #(`TB_TCYC_TCLK * 1);
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
        tb_tms = 1'b1;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Select DR Scan
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Capture DR
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Shift DR (bit0-)
    for (i = 0; i < (length - 1); i = i + 1)
    begin
            tb_tms = 1'b0;
            tb_tdi = DR[i];
            tb_tck = 1'b0;
        #(`TB_TCYC_TCLK / 2);
            DR_OUT[i] = tb_tdo;
            tb_tck = 1'b1; // rise
        #(`TB_TCYC_TCLK / 2);
    end
    //---- Shift DR (bit length-1)
        tb_tms = 1'b1;
        tb_tdi = DR[length - 1];
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        DR_OUT[length - 1] = tb_tdo;
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Exit1-DR
        tb_tms = 1'b1;
        tb_tdi = 1'bx;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Update DR
        tb_tms = 1'b0;
        tb_tck = 1'b0;
    #(`TB_TCYC_TCLK / 2);
        tb_tck = 1'b1; // rise
    #(`TB_TCYC_TCLK / 2);
    //---- Run Test Idle
        tb_tms = 1'b1;
        tb_tck = 1'b1;
    #(`TB_TCYC_TCLK * 1);
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

//--------------------------------
// Display TAP Controller State
//--------------------------------
initial U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_tck = `JTAG_TAP_CAPTURE_IR;
//
`ifdef DEBUG_TAP_CONTROLLER_STATE
wire tck;
wire [3:0] state_tap;
wire [3:0] state_tap_next;
assign tck = U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.TCK;
assign state_tap = U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_tck;
assign state_tap_next = U_CHIP_TOP.U_MMRISC.U_DEBUG_TOP.U_DEBUG_DTM_JTAG.state_tap_next_tck;
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
initial
begin
    Task_JTAG_INIT_PIN();
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
