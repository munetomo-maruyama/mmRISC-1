//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : spi.v
// Description : Top of SPI
//-----------------------------------------------------------
// S_S_History :
// Rev.01 2022.02.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2022 M.Maruyama
//===========================================================

//===========================================================
// Register Definitions
//===========================================================
// SPCR   ADDR 0x00 R/W SPI Control Register
//    bit7    : SPIE   SPI Interrupt Enable
//    bit6    : SPE    SPI Core Enable
//    bit5    : Reserved
//    bit4    : MSTR   Master Mode Select (always should be 1)
//    bit3    : CPOL   Clock Polarity
//    bit2    : CPHA   Clock Phase
//    bit1:0  : SPR    SPI Clock Rate Select
//      EPSR SPR  Rate    EPSR SPR Rate     EPSR SPR Rate
//       00   00  CLK/2    01   00 CLK/8     10   00 CLK/512
//       00   01  CLK/4    01   01 CLK/64    10   01 CLK/1024
//       00   10  CLK/16   01   10 CLK/128   10   10 CLK/2048
//       00   11  CLK/32   01   11 CLK/256   10   11 CLK/4096
//-----------------------------------------------------------
// SPSR   ADDR 0x04 R/W SPI Status Register
//    bit7    : SPIF    SPI Interrupt Flag (Write 1 to Clear)
//    bit6    : WCOL    Write Collision (Write 1 to Clear)
//    bit5:4  : Reserved
//    bit3    : WFFULL  Write FIFO Full
//    bit2    : WFEMPTY Write FIFO Empty
//    bit1    : RFFULL  Read FIFO Full
//    bit0    : RFEMPTY Read FIFO Empty
//-----------------------------------------------------------
// SPDR   ADDR 0x08 R/W SPI Data Register
//    bit7:0  : Write Buffer when Write
//    bit7:0  : Read Buffer when Read
//-----------------------------------------------------------
// SPER   ADDR 0x0C R/W SPI Extension Register
//    bit7:6  : ICNT    Interrupt Count
//       00 : SPIF is set after every completed transfer
//       01 : SPIF is set after every two completed transfers
//       10 : SPIF is set after every three completed transfers
//       11 : SPIF is set after every four completed transfers
//    bit5:2  : Reserved
//    bit1:0  : ESPR     Extended SPI Clock Rate Select
//-----------------------------------------------------------
// SPCS   ADDR 0x10 R/W SPI Chip Select Pin
//    bit7:0  : SPI Chip Select Pin Level (Initial is 0xFF)
//              Lower 4bits of SPCS are used.
//===========================================================

//*************************************************
// Module Definition
//*************************************************
module SPI
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
    // SPI Port
    output wire [3:0] SPI_CSN,  // SPI Chip Select
    output wire       SPI_SCK,  // SPI Clock
    output wire       SPI_MOSI, // SPI MOSI
    input  wire       SPI_MISO, // SPI MISO
    //
    // Interrupt Request
    output wire IRQ_SPI
);

//-----------------
// Internal Signals
//-----------------
reg        wb_stb_o;     // stobe/core select signal
reg        wb_cyc_o;     // valid bus cycle input
reg        wb_we_o;      // write enable input
reg  [2:0] wb_adr_o;     // lower address bits
wire [7:0] wb_dat_o;     // databus input
//
wire       core_wb_stb_o;
wire       core_wb_cyc_o;
wire       core_wb_we_o;
wire [2:0] core_wb_adr_o;
wire [7:0] core_wb_dat_o;
wire [7:0] core_wb_dat_i;
wire       core_wb_ack_i;
//
wire       spcs_wb_stb_o;
wire       spcs_wb_cyc_o;
wire       spcs_wb_we_o;
wire [2:0] spcs_wb_adr_o;
wire [7:0] spcs_wb_dat_o;
wire [7:0] spcs_wb_dat_i;
wire       spcs_wb_ack_i;

//-----------------
// Bus Interface
//-----------------
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        wb_stb_o <= 1'b0;
        wb_cyc_o <= 1'b0;
        wb_we_o  <= 1'b0;
        wb_adr_o <= 3'b000; //[4:2]
    end
    else if (S_HSEL & S_HTRANS[1] & S_HREADY & S_HREADYOUT)
    begin
        wb_stb_o <= 1'b1;
        wb_cyc_o <= 1'b1;
        wb_we_o  <= S_HWRITE;
        wb_adr_o <= S_HADDR[4:2];
    end
    else if (S_HREADY & S_HREADYOUT)
    begin
        wb_stb_o <= 1'b0;
        wb_cyc_o <= 1'b0;
        wb_we_o  <= 1'b0;
        wb_adr_o <= 3'b000; //[4:2]-->[2:0]
    end
end
//
assign wb_dat_o = S_HWDATA[7:0];
//
assign core_wb_stb_o = (wb_adr_o[2])? 1'b0 : wb_stb_o;
assign core_wb_cyc_o = (wb_adr_o[2])? 1'b0 : wb_cyc_o;
assign core_wb_we_o  = (wb_adr_o[2])? 1'b0 : wb_we_o;
assign core_wb_adr_o = (wb_adr_o[2])? 3'b0 : wb_adr_o;
assign core_wb_dat_o = (wb_adr_o[2])? 8'b0 : wb_dat_o;
//
assign spcs_wb_stb_o = (wb_adr_o[2])? wb_stb_o : 1'b0;
assign spcs_wb_cyc_o = (wb_adr_o[2])? wb_cyc_o : 1'b0;
assign spcs_wb_we_o  = (wb_adr_o[2])? wb_we_o  : 1'b0;
assign spcs_wb_adr_o = (wb_adr_o[2])? wb_adr_o : 3'b0;
assign spcs_wb_dat_o = (wb_adr_o[2])? wb_dat_o : 8'b0;
//
assign S_HRDATA    = (core_wb_ack_i)? {24'h0, core_wb_dat_i}
                   : (spcs_wb_ack_i)? {24'h0, spcs_wb_dat_i} : 32'h0;
assign S_HREADYOUT = (core_wb_cyc_o)? core_wb_ack_i
                   : (spcs_wb_cyc_o)? spcs_wb_ack_i : 1'b1;
assign S_HRESP     = 1'b0;

//-----------------
// SPI Core
//-----------------
simple_spi_top U_SPI_CORE
(
    // 8bit WISHBONE bus slave interface
    .clk_i  (CLK),      // clock
    .rst_i  (~RES),     // reset (asynchronous active low)
    .cyc_i  (core_wb_cyc_o), // cycle
    .stb_i  (core_wb_stb_o), // strobe
    .adr_i  (core_wb_adr_o[1:0]), // address
    .we_i   (core_wb_we_o),  // write enable
    .dat_i  (core_wb_dat_o), // data input
    .dat_o  (core_wb_dat_i), // data output
    .ack_o  (core_wb_ack_i), // normal bus termination
    .inta_o (IRQ_SPI),  // interrupt output

    // SPI port
    .sck_o  (SPI_SCK),  // serial clock output
    .mosi_o (SPI_MOSI), // MasterOut SlaveIN
    .miso_i (SPI_MISO)  // MasterIn SlaveOut
);

//-----------------
// SPCS Register
//-----------------
reg [7:0] spcs;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
        spcs <= 8'hff;
    else if (spcs_wb_cyc_o & spcs_wb_stb_o & spcs_wb_we_o & spcs_wb_adr_o[2])
        spcs <= spcs_wb_dat_o;
end
//
assign spcs_wb_dat_i = spcs;
assign spcs_wb_ack_i = spcs_wb_cyc_o & spcs_wb_stb_o;
//
// Chip Select Output
assign SPI_CSN = spcs[3:0];

//======================================================
  endmodule
//======================================================
