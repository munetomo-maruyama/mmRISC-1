//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : i2c.v
// Description : Top of I2C
//-----------------------------------------------------------
// S_S_History :
// Rev.01 2022.02.12 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

//===========================================================
// Register Definitions
//===========================================================
// PRERL  ADDR 0x00 R/W Clock Prescale Low
// PRERH  ADDR 0x04 R/W Clock Prescale High
//     CLK=16.666MHz, SCL=100KHz
//     PRER=20MHz/(5*100KHz)-1=39=0x0027
//-----------------------------------------------------------
// CTL    ADDR 0x08 R/W Control Register
//     bit7   : EN     I2C Core Enable
//     bit6   : IEN    I2C Interrupt Enable
//     bit5:0 : Reserved
//-----------------------------------------------------------
// TXR    ADDR 0x0C W   Transmit Data
//     bit7:1 : TXD[7:1]  Transmit Data
//     bit0   : TXD[0]/RW Transmit Data or RW bit (0:W, 1:R)
//-----------------------------------------------------------
// RXR    ADDR 0x0C R   Receive Data
//     bit7:0 : RXD       Receive Data
//-----------------------------------------------------------
// CR     ADDR 0x10 W   Command Register
//     bit7*  : STA  Generate Start Condition (repeated, too)
//     bit6*  : STO  Generate Stop  Condition
//     bit5*  : RD   Read from Slave
//     bit4*  : WR   Write to Slave
//     bit3   : ACK  For Reciever, sent ACK if cleared or NACK when set
//     bit2:1 : Reserved
//     bit0*  : IACK Clear Pending Interrupt
//     (* : cleated automatically)
//-----------------------------------------------------------
// SR     ADDR 0x10 R   Status Register
//     bit7   : RXACK  0:Received Acknowledge, 1:Not Received
//     bit6   : BUSY   0:After STOP, 1:After START
//     bit5   : AL     Arbitraton Lost
//     bit4:2 : Reserved
//     bit1   : TIP    0:Trasfer Complete, 1:Transferring
//     bit0   : IF     Interrupt Flag
//===========================================================

//*************************************************
// Module Definition
//*************************************************
module I2C
(
    // System
    input  wire CLK, // clock
    input  wire RES, // reset
    //
    // AHB Lite Slave port
    input  wire        S_HSEL,
    input  wire [ 1:0] S_HTRANS,
    input  wire        S_HWRITE,
    input  wire        S_HMASTLOCK,
    input  wire [ 2:0] S_HSIZE,
    input  wire [ 2:0] S_HBURST,
    input  wire [ 3:0] S_HPROT,
    input  wire [31:0] S_HADDR,
    input  wire [31:0] S_HWDATA,
    input  wire        S_HREADY,
    output wire        S_HREADYOUT,
    output wire [31:0] S_HRDATA,
    output wire        S_HRESP,
    //
    // I2C Port
    input  wire I2C_SCL_I,   // SCL Input
    output wire I2C_SCL_O,   // SCL Output
    output wire I2C_SCL_OEN, // SCL Output Enable (neg)
    input  wire I2C_SDA_I,   // SDA Input
    output wire I2C_SDA_O,   // SDA Output
    output wire I2C_SDA_OEN, // SDA Output Enable (neg)
    //
    // Interrupt Request
    output wire IRQ_I2C
);

//-----------------
// Internal Signals
//-----------------
reg        wb_stb_o;     // stobe/core select signal
reg        wb_cyc_o;     // valid bus cycle input
reg        wb_we_o;      // write enable input
reg  [2:0] wb_adr_o;     // lower address bits
wire [7:0] wb_dat_o;     // databus input
wire [7:0] wb_dat_i;     // databus output
wire       wb_ack_i;     // bus cycle acknowledge output

//-----------------
// Bus Interface
//-----------------
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        wb_cyc_o <= 1'b0;
        wb_stb_o <= 1'b0;
        wb_we_o  <= 1'b0;
        wb_adr_o <= 3'b000;
    end
    else if (S_HSEL & S_HTRANS[1] & S_HREADY & S_HREADYOUT)
    begin
        wb_cyc_o <= 1'b1;
        wb_stb_o <= 1'b1;
        wb_we_o  <= S_HWRITE;
        wb_adr_o <= S_HADDR[4:2];
    end
    else if (S_HREADY & S_HREADYOUT)
    begin
        wb_cyc_o <= 1'b0;
        wb_stb_o <= 1'b0;
        wb_we_o  <= 1'b0;
        wb_adr_o <= 3'b000;
    end
end
//
assign wb_dat_o = S_HWDATA[7:0];
assign S_HRDATA = (wb_ack_i)? wb_dat_i : 8'h00;
assign S_HRESP  = 1'b0;
assign S_HREADYOUT = (wb_cyc_o)? wb_ack_i : 1'b1;

//-----------------
// I2C Core
//-----------------
i2c_master_top U_I2C_CORE
(
    .wb_clk_i  (CLK),      // master clock input
    .wb_rst_i  ( RES),     // synchronous active high reset
    .arst_i    (~RES),     // asynchronous reset
    .wb_adr_i  (wb_adr_o), // lower address bits
    .wb_dat_i  (wb_dat_o), // databus input
    .wb_dat_o  (wb_dat_i), // databus output
    .wb_we_i   (wb_we_o),  // write enable input
    .wb_stb_i  (wb_stb_o), // stobe/core select signal
    .wb_cyc_i  (wb_cyc_o), // valid bus cycle input
    .wb_ack_o  (wb_ack_i), // bus cycle acknowledge output
    .wb_inta_o (IRQ_I2C),  // interrupt request signal output
    //
    .scl_pad_i    (I2C_SCL_I),   // SCL-line input
    .scl_pad_o    (I2C_SCL_O),   // SCL-line output (always 1'b0)
    .scl_padoen_o (I2C_SCL_OEN), // SCL-line output enable (active low)
    .sda_pad_i    (I2C_SDA_I),   // SDA-line input
    .sda_pad_o    (I2C_SDA_O),   // SDA-line output (always 1'b0)
    .sda_padoen_o (I2C_SDA_OEN)  // SDA-line output enable (active low)
);

//======================================================
  endmodule
//======================================================
