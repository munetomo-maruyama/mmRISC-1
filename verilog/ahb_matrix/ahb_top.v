//===========================================================
// AHB Matrix
//-----------------------------------------------------------
// File Name   : ahb_top.v
// Description : AHB Matrix Top Level
//-----------------------------------------------------------
// History :
// Rev.01 2020.01.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//------------------------
// Top of AHB Matrix
//------------------------
module AHB_MATRIX
    #(parameter
        MASTERS = 8,
        SLAVES  = 8,
        MASTERS_BIT = $clog2(MASTERS)
     )
(
    // Global Signals
    input  wire HCLK,
    input  wire HRESETn,
    // Master Ports
    input  wire        M_HSEL      [0:MASTERS-1],
    input  wire [ 1:0] M_HTRANS    [0:MASTERS-1],
    input  wire        M_HWRITE    [0:MASTERS-1],
    input  wire        M_HMASTLOCK [0:MASTERS-1],
    input  wire [ 2:0] M_HSIZE     [0:MASTERS-1],
    input  wire [ 2:0] M_HBURST    [0:MASTERS-1],
    input  wire [ 3:0] M_HPROT     [0:MASTERS-1],
    input  wire [31:0] M_HADDR     [0:MASTERS-1],
    input  wire [31:0] M_HWDATA    [0:MASTERS-1],
    input  wire        M_HREADY    [0:MASTERS-1],
    output wire        M_HREADYOUT [0:MASTERS-1],
    output wire [31:0] M_HRDATA    [0:MASTERS-1],
    output wire        M_HRESP     [0:MASTERS-1],
    input  wire [MASTERS_BIT-1:0] M_PRIORITY[0:MASTERS-1],
        // (ex) MASTERS=8
        //      M_PRIORITY[0]=0 : Level0 Single Group Highest
        //      M_PRIORITY[1]=1 : Level1 Round-Robin Group among [1][2][3]
        //      M_PRIORITY[2]=1 : Level1 Round-Robin Group among [1][2][3]
        //      M_PRIORITY[3]=1 : Level1 Round-Robin Group among [1][2][3]
        //      M_PRIORITY[4]=2 : Level2 Round-Robin Group among [4][5]
        //      M_PRIORITY[5]=2 : Level2 Round-Robin Group among [4][5]
        //      M_PRIORITY[6]=3 : Level3 Single Group
        //      M_PRIORITY[7]=4 : Level4 Single Group Lowest    
    // Slave Ports
    output wire        S_HSEL       [0:SLAVES-1],
    output wire [ 1:0] S_HTRANS     [0:SLAVES-1],
    output wire        S_HWRITE     [0:SLAVES-1],
    output wire        S_HMASTLOCK  [0:SLAVES-1],
    output wire [ 2:0] S_HSIZE      [0:SLAVES-1],
    output wire [ 2:0] S_HBURST     [0:SLAVES-1],
    output wire [ 3:0] S_HPROT      [0:SLAVES-1],
    output wire [31:0] S_HADDR      [0:SLAVES-1],
    output wire [31:0] S_HWDATA     [0:SLAVES-1],
    output wire        S_HREADY     [0:SLAVES-1],
    input  wire        S_HREADYOUT  [0:SLAVES-1],
    input  wire [31:0] S_HRDATA     [0:SLAVES-1],
    input  wire        S_HRESP      [0:SLAVES-1],
    input  wire [31:0] S_HADDR_BASE [0:SLAVES-1],
    input  wire [31:0] S_HADDR_MASK [0:SLAVES-1]
        // (ex) S_HADDR_BASE[]=0x01000000, S_HADDR_BASE[]=0xfff00000
        //      Slave Address Range=0x01000000-0x010fffff
);

//
// HREADYOUT   1110001
// H_command   001xxx2
// m_phase_a_0 00100010
// m_phase_a_1   000001
// m_phase_d     011111
// m_addr_req    1   1
// m_addr_ack    1   1
// m_data_ack    000010

//
// HREADYOUT   111000000100000011
// H_command   001xxxxxx2xxxxxx00
// m_phase_a_0   1      1
// m_phase_a_1   0111100011110000
// m_phase_d     0000011100001110
// m_addr_req    1111100111110000
// m_addr_ack    0000100000010000
// m_data_ack    0000000100000010

wire m_addr_req[0:MASTERS-1];
wire m_addr_ack[0:MASTERS-1];
wire m_data_ack[0:MASTERS-1];
wire s_addr_req[0:SLAVES-1];
wire s_addr_ack[0:SLAVES-1];
wire s_data_ack[0:SLAVES-1];
//
wire        m_hsel      [0:MASTERS-1];
wire [ 1:0] m_htrans    [0:MASTERS-1];
wire        m_hwrite    [0:MASTERS-1];
wire        m_hmastlock [0:MASTERS-1];
wire [ 2:0] m_hsize     [0:MASTERS-1];
wire [ 2:0] m_hburst    [0:MASTERS-1];
wire [ 3:0] m_hprot     [0:MASTERS-1];
wire [31:0] m_haddr     [0:MASTERS-1];
wire [31:0] m_hwdata    [0:MASTERS-1];
wire [31:0] m_hrdata    [0:MASTERS-1];
wire        m_hresp     [0:MASTERS-1];
//
wire        s_hsel      [0:SLAVES-1];
wire [ 1:0] s_htrans    [0:SLAVES-1];
wire        s_hwrite    [0:SLAVES-1];
wire        s_hmastlock [0:SLAVES-1];
wire [ 2:0] s_hsize     [0:SLAVES-1];
wire [ 2:0] s_hburst    [0:SLAVES-1];
wire [ 3:0] s_hprot     [0:SLAVES-1];
wire [31:0] s_haddr     [0:SLAVES-1];
wire [31:0] s_hwdata    [0:SLAVES-1];
wire [31:0] s_hrdata    [0:SLAVES-1];
wire        s_hresp     [0:SLAVES-1];

//-----------------------------------
// AHB Master Port
//-----------------------------------
AHB_MASTER_PORT
   #(
        .MASTERS (MASTERS)
    )
U_AHB_MASTER_PORT 
(
    // Global Signals
    .HCLK    (HCLK),
    .HRESETn (HRESETn),
    // Master Ports
    .M_HSEL      (M_HSEL),
    .M_HTRANS    (M_HTRANS),
    .M_HWRITE    (M_HWRITE),
    .M_HMASTLOCK (M_HMASTLOCK),
    .M_HSIZE     (M_HSIZE),
    .M_HBURST    (M_HBURST),
    .M_HPROT     (M_HPROT),
    .M_HADDR     (M_HADDR),
    .M_HWDATA    (M_HWDATA),
    .M_HREADY    (M_HREADY),
    .M_HREADYOUT (M_HREADYOUT),
    .M_HRDATA    (M_HRDATA),
    .M_HRESP     (M_HRESP),
    // Internal Master Connections
    .m_addr_req  (m_addr_req),    
    .m_addr_ack  (m_addr_ack),    
    .m_data_ack  (m_data_ack),
    //
    .m_hsel      (m_hsel),
    .m_htrans    (m_htrans),
    .m_hwrite    (m_hwrite),
    .m_hmastlock (m_hmastlock),
    .m_hsize     (m_hsize),
    .m_hburst    (m_hburst),
    .m_hprot     (m_hprot),
    .m_haddr     (m_haddr),
    .m_hwdata    (m_hwdata),
    .m_hrdata    (m_hrdata),
    .m_hresp     (m_hresp)
);

//-------------------------------
// AHB Interconnction
//-------------------------------
AHB_INTERCONNECT
    #(
        .MASTERS (MASTERS),
        .SLAVES  (SLAVES)
     )
U_AHB_INTERCONNECT
(
    // Global Signals
    .HCLK    (HCLK),
    .HRESETn (HRESETn),
    // Internal Master Connection
    .m_addr_req  (m_addr_req),    
    .m_addr_ack  (m_addr_ack),    
    .m_data_ack  (m_data_ack),
    //
    .m_hsel      (m_hsel),
    .m_htrans    (m_htrans),
    .m_hwrite    (m_hwrite),
    .m_hmastlock (m_hmastlock),
    .m_hsize     (m_hsize),
    .m_hburst    (m_hburst),
    .m_hprot     (m_hprot),
    .m_haddr     (m_haddr),
    .m_hwdata    (m_hwdata),
    .m_hrdata    (m_hrdata),
    .m_hresp     (m_hresp),
    //
    .M_PRIORITY  (M_PRIORITY),
    // Internal Slave Connection
    .s_addr_req  (s_addr_req),
    .s_addr_ack  (s_addr_ack),
    .s_data_ack  (s_data_ack),
    //
    .s_hsel      (s_hsel),
    .s_htrans    (s_htrans),
    .s_hwrite    (s_hwrite),
    .s_hmastlock (s_hmastlock),
    .s_hsize     (s_hsize),
    .s_hburst    (s_hburst),
    .s_hprot     (s_hprot),
    .s_haddr     (s_haddr),
    .s_hwdata    (s_hwdata),
    .s_hrdata    (s_hrdata),
    .s_hresp     (s_hresp),
    //
    .S_HADDR_BASE(S_HADDR_BASE),
    .S_HADDR_MASK(S_HADDR_MASK)
);

//-----------------------------------
// AHB Slave Port
//-----------------------------------
AHB_SLAVE_PORT
   #(
        .SLAVES (SLAVES)
    )
U_AHB_SLAVE_PORT 
(
    // Global Signals
    .HCLK    (HCLK),
    .HRESETn (HRESETn),
    // Slave Ports
    .S_HSEL      (S_HSEL),
    .S_HTRANS    (S_HTRANS),
    .S_HWRITE    (S_HWRITE),
    .S_HMASTLOCK (S_HMASTLOCK),
    .S_HSIZE     (S_HSIZE),
    .S_HBURST    (S_HBURST),
    .S_HPROT     (S_HPROT),
    .S_HADDR     (S_HADDR),
    .S_HWDATA    (S_HWDATA),
    .S_HREADY    (S_HREADY),
    .S_HREADYOUT (S_HREADYOUT),
    .S_HRDATA    (S_HRDATA),
    .S_HRESP     (S_HRESP),
    // Internal Slave Connections
    .s_addr_req  (s_addr_req),    
    .s_addr_ack  (s_addr_ack),    
    .s_data_ack  (s_data_ack),
    //
    .s_hsel      (s_hsel),
    .s_htrans    (s_htrans),
    .s_hwrite    (s_hwrite),
    .s_hmastlock (s_hmastlock),
    .s_hsize     (s_hsize),
    .s_hburst    (s_hburst),
    .s_hprot     (s_hprot),
    .s_haddr     (s_haddr),
    .s_hwdata    (s_hwdata),
    .s_hrdata    (s_hrdata),
    .s_hresp     (s_hresp)
);

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
