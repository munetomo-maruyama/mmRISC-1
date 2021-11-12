//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : uart.v
// Description : Top of UART
//-----------------------------------------------------------
// S_S_History :
// Rev.01 2021.02.22 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================

//======================================================
// UART : Asynchronous Serial Interface
//
// [UART_REG] 32bit Register
//
// 2'h3 : UART_BG1 Baud Rate Generator Div1 (read/write)
//  23    22    21    20    19    18    17    16
//   7     6     5     4     3     2     1     0
// -----------------------------------------------
//| B17 | B16 | B15 | B14 | B13 | B12 | B11 | B10 |
// -----------------------------------------------
//
// 2'h2 : UART_BG0 Baud Rate Generator Div0 (read/write)
//  31    30    29    28    27    26    25    24
//   7     6     5     4     3     2     1     0
// -----------------------------------------------
//| B07 | B06 | B05 | B04 | B03 | B02 | B01 | B00 |
// -----------------------------------------------
//
// Baud Rate = (fCLK/4) / ((BG0+2)*(BG1))
//
//
// 2'h1 : UART_CSR (TXRDY=~full_o, RXRDY=~empty_o) (read/write)
//  15     14     13    12    11    10      9       8
//   7      6      5     4     3     2      1       0
// ---------------------------------------------------
//| IETX | IERX |     |     |     |     | TXRDY | RXRDY |
// ---------------------------------------------------
// Interrput = IETX & TXRDY | IERX & RXRDY
//
// 2'h0 : UART_TXD(Write)/UART_RXD(Read)
//   7     6     5     4     3     2     1     0
//   7     6     5     4     3     2     1     0
// -----------------------------------------------
//| TR7 | TR6 | TR5 | TR4 | TR3 | TR2 | TR1 | TR0 |
// -----------------------------------------------

//*************************************************
// Module Definition
//*************************************************
module UART
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
    // UART
    input  wire RXD, // receive data
    output wire TXD, // transmit data
    input  wire CTS, // clear to send
    output wire RTS, // request to send
    //
    // Interrupt Request
    output wire IRQ_UART
);

//-----------------
// Internal Signals
//-----------------
//reg         wrtxd,  rdrxd;
//reg         wrtxd1, rdrxd1;
//							
wire       sio_ce, sio_ce_x4;		   
wire [7:0] din_i;  // TX_DATA
wire [7:0] dout_o; // RX_DATA
wire       re_i, we_i;
wire       full_o, empty_o;
reg  [7:0] div0;
reg  [7:0] div1;
//
reg        ietx;
reg        ierx;
wire       txrdy;
wire       rxrdy; 
//
assign txrdy = ~full_o;
assign rxrdy = ~empty_o;
assign IRQ_UART = ietx & txrdy | ierx & rxrdy;

//--------------------
// AS_HB to Wishbone
//--------------------
reg         CE, WE;
reg  [ 3:0] SEL;
wire [31:0] DATI;
reg  [31:0] DATO;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        CE  <= 1'b0;
        WE  <= 1'b0;
        SEL <= 4'b0000;
    end
    else if (S_HSEL & S_HTRANS[1] & S_HREADY)
    begin
        CE <= 1'b1;
        WE <= S_HWRITE;
        SEL[0] <= (S_HSIZE == 3'b011) 
                | (S_HSIZE == 3'b001) & (S_HADDR[1]   == 1'b0)
                | (S_HSIZE == 3'b000) & (S_HADDR[1:0] == 2'b00);
        SEL[1] <= (S_HSIZE == 3'b011) 
                | (S_HSIZE == 3'b001) & (S_HADDR[1]   == 1'b0)
                | (S_HSIZE == 3'b000) & (S_HADDR[1:0] == 2'b01);
        SEL[2] <= (S_HSIZE == 3'b011) 
                | (S_HSIZE == 3'b001) & (S_HADDR[1]   == 1'b1)
                | (S_HSIZE == 3'b000) & (S_HADDR[1:0] == 2'b10);
        SEL[3] <= (S_HSIZE == 3'b011) 
                | (S_HSIZE == 3'b001) & (S_HADDR[1]   == 1'b1)
                | (S_HSIZE == 3'b000) & (S_HADDR[1:0] == 2'b11);
    end
    else
    begin
        CE  <= 1'b0;
        WE  <= 1'b0;
        SEL <= 4'b0000;
    end
end
//
assign DATI = S_HWDATA;
assign S_HRDATA = DATO;
assign S_HREADYOUT = 1'b1;
assign S_HRESP = 1'b0;

//----------------------
// Register R/W Operation
//----------------------
always @(posedge CLK, posedge RES)
begin
    if (RES)
        div1[7:0] <= 8'h00;
    else if (CE & WE & SEL[3])
        div1[7:0] <= DATI[31:24];
end
always @(posedge CLK or posedge RES)
begin
    if (RES)
        div0[7:0] <= 8'h00;
    else if (CE & WE & SEL[2])
        div0[7:0] <= DATI[23:16];
end
always @(posedge CLK or posedge RES)
begin
    if (RES)
    begin
        ietx <= 1'b0;
        ierx <= 1'b0;
    end
    else if (CE & WE & SEL[1])
    begin
        ietx <= DATI[15];
        ierx <= DATI[14];
    end
end
//
assign din_i[7:0] = DATI[7:0];
//
always @*
begin
    if (CE)
    begin
        DATO[31:24] <= div1[7:0];
        DATO[23:16] <= div0[7:0];
        DATO[15: 8] <= {ietx, ierx, 4'b0000, txrdy, rxrdy};
        DATO[ 7: 0] <= dout_o;
    end
    else
    begin
        DATO[31:0] <= 32'h00000000;
    end
end
//
//always @*
//begin
//    if (CE & WE & SEL[0])
//        wrtxd <= 1'b1;
//    else
//        wrtxd <= 1'b0;
//end	
//always @(posedge CLK, posedge RES)
//begin
//    if (RES)
//        wrtxd1 <= 1'b0;
//    else
//        wrtxd1 <= wrtxd;
//end
//
//always @*
//begin
//    if (CE & WE & SEL[0])
//       rdrxd <= 1'b1;
//    else
//       rdrxd <= 1'b0;
//end				
//always @(posedge CLK, posedge RES)
//begin
//    if (RES)
//        rdrxd1 <= 1'b0;
//    else
//        rdrxd1 <= rdrxd;
//end

//assign we_i = ~wrtxd & wrtxd1; // negate edge of wrtxd
//assign re_i = ~rdrxd & rdrxd1; // negate edge of rdrxd
assign we_i = CE &  WE & SEL[0];
assign re_i = CE & ~WE & SEL[0];

//---------------------
// UART Internal Blocks
//---------------------
sasc_top TOP
(
    .clk       (CLK),
    .rst       (~RES),
    .rxd_i     (RXD),
    .txd_o     (TXD),
    .cts_i     (CTS),
    .rts_o     (RTS),
    .sio_ce    (sio_ce),
    .sio_ce_x4 (sio_ce_x4),
    .din_i     (din_i),
    .dout_o    (dout_o),
    .re_i      (re_i),
    .we_i      (we_i),
	.full_o    (full_o),
    .empty_o   (empty_o)
);
//
sasc_brg BRG
(
    .clk       (CLK),
    .rst       (~RES),
    .div0      (div0),
    .div1      (div1),  
	.sio_ce    (sio_ce),
    .sio_ce_x4 (sio_ce_x4)
);

//======================================================
  endmodule
//======================================================
