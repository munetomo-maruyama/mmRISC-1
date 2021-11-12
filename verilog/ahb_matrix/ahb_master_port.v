//===========================================================
// AHB Matrix
//-----------------------------------------------------------
// File Name   : ahb_master_port.v
// Description : AHB Matrix Master Port
//-----------------------------------------------------------
// History :
// Rev.01 2020.01.15 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//------------------------
// Top of AHB Master Port
//------------------------
module AHB_MASTER_PORT
    #(parameter
        MASTERS = 8
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
    // Internal Master Connections
    output wire        m_addr_req[0:MASTERS-1],    
    input  wire        m_addr_ack[0:MASTERS-1],    
    input  wire        m_data_ack[0:MASTERS-1],
    //
    output wire        m_hsel      [0:MASTERS-1],
    output wire [ 1:0] m_htrans    [0:MASTERS-1],
    output wire        m_hwrite    [0:MASTERS-1],
    output wire        m_hmastlock [0:MASTERS-1],
    output wire [ 2:0] m_hsize     [0:MASTERS-1],
    output wire [ 2:0] m_hburst    [0:MASTERS-1],
    output wire [ 3:0] m_hprot     [0:MASTERS-1],
    output wire [31:0] m_haddr     [0:MASTERS-1],
    output wire [31:0] m_hwdata    [0:MASTERS-1],
    input  wire [31:0] m_hrdata    [0:MASTERS-1],
    input  wire        m_hresp     [0:MASTERS-1]
);

genvar mst;

//-----------------------------
// Master-Slave Interface
//-----------------------------
wire m_phase_a_0[0:MASTERS-1];
reg  m_phase_a_1[0:MASTERS-1];
reg  m_phase_d  [0:MASTERS-1];
reg  m_hreadyout_0[0:MASTERS-1];

generate
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin : MASTER_PORT
        assign m_phase_a_0[mst] = M_HSEL[mst] & M_HTRANS[mst][1] & M_HREADYOUT[mst] & M_HREADY[mst];
        //
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
                m_phase_a_1[mst] <= 1'b0;
          //else if (M_HREADYOUT[mst] & M_HREADY[mst] & m_addr_ack[mst])
            else if (m_addr_ack[mst])
                m_phase_a_1[mst] <= 1'b0;
            else if (M_HREADYOUT[mst] & M_HREADY[mst])
                m_phase_a_1[mst] <= m_phase_a_0[mst];
        end
        //
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
                m_phase_d[mst] <= 1'b0;
            else if (M_HREADYOUT[mst] & M_HREADY[mst] & m_phase_a_0[mst])
                m_phase_d[mst] <= 1'b1;
            else if (M_HREADYOUT[mst] & M_HREADY[mst])
                m_phase_d[mst] <= 1'b0;
        end
        //
        assign m_addr_req[mst] = m_phase_a_0[mst] | m_phase_a_1[mst];
        //
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
                m_hreadyout_0[mst] <= 1'b1;
            else if (m_phase_a_0[mst])
                m_hreadyout_0[mst] <= 1'b0;
            else if (m_data_ack[mst])
                m_hreadyout_0[mst] <= 1'b1;
        end
        //
        assign M_HREADYOUT[mst] = m_hreadyout_0[mst] | m_data_ack[mst];
    end
endgenerate

//---------------------
// Command Signals
//---------------------
reg         m_hsel_1[0:MASTERS-1];
reg  [ 1:0] m_htrans_1[0:MASTERS-1];
reg         m_hwrite_1[0:MASTERS-1];
reg         m_hmastlock_1[0:MASTERS-1];
reg  [ 2:0] m_hsize_1[0:MASTERS-1];
reg  [ 2:0] m_hburst_1[0:MASTERS-1];
reg  [ 3:0] m_hprot_1[0:MASTERS-1];
reg  [31:0] m_haddr_1[0:MASTERS-1];
//
generate
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin : COMMAND_SIGNALS
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
            begin
                m_hsel_1     [mst] <= 1'b0;
                m_htrans_1   [mst] <= 2'b00;
                m_hwrite_1   [mst] <= 1'b0;
                m_hmastlock_1[mst] <= 1'b0;
                m_hsize_1    [mst] <= 3'b000;
                m_hburst_1   [mst] <= 3'b000;
                m_hprot_1    [mst] <= 4'b0000;
                m_haddr_1    [mst] <= 32'h00000000;
            end
            else if (M_HREADYOUT[mst] & M_HREADY[mst])
            begin
                m_hsel_1     [mst] <= M_HSEL     [mst];
                m_htrans_1   [mst] <= M_HTRANS   [mst];
                m_hwrite_1   [mst] <= M_HWRITE   [mst];
                m_hmastlock_1[mst] <= M_HMASTLOCK[mst];
                m_hsize_1    [mst] <= M_HSIZE    [mst];
                m_hburst_1   [mst] <= M_HBURST   [mst];
                m_hprot_1    [mst] <= M_HPROT    [mst];
                m_haddr_1    [mst] <= M_HADDR    [mst];
            end
        end
        //
        assign m_hsel     [mst] = (m_phase_a_0[mst])? M_HSEL  [mst]
                                : (m_phase_a_1[mst])? m_hsel_1[mst]
                                : 1'b0;
        assign m_htrans   [mst] = (m_phase_a_0[mst])? M_HTRANS  [mst]
                                : (m_phase_a_1[mst])? m_htrans_1[mst]
                                : 2'b00;
        assign m_hwrite   [mst] = (m_phase_a_0[mst])? M_HWRITE  [mst]
                                : (m_phase_a_1[mst])? m_hwrite_1[mst]
                                : 1'b0;
        assign m_hmastlock[mst] = (m_phase_a_0[mst])? M_HMASTLOCK  [mst]
                                : (m_phase_a_1[mst])? m_hmastlock_1[mst]
                                : 1'b0;
        assign m_hsize    [mst] = (m_phase_a_0[mst])? M_HSIZE  [mst]
                                : (m_phase_a_1[mst])? m_hsize_1[mst]
                                : 3'b000;
        assign m_hburst   [mst] = (m_phase_a_0[mst])? M_HBURST  [mst]
                                : (m_phase_a_1[mst])? m_hburst_1[mst]
                                : 3'b000;
        assign m_hprot    [mst] = (m_phase_a_0[mst])? M_HPROT  [mst]
                                : (m_phase_a_1[mst])? m_hprot_1[mst]
                                : 4'b0000;
        assign m_haddr    [mst] = (m_phase_a_0[mst])? M_HADDR  [mst]
                                : (m_phase_a_1[mst])? m_haddr_1[mst]
                                : 32'h00000000;                        
    end
endgenerate

//---------------------
// Data Signals
//---------------------
generate
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin : DATA_SIGNALS
        assign m_hwdata[mst] = (m_phase_d[mst])? M_HWDATA[mst]
                             : 32'h00000000;
        assign M_HRDATA[mst] = (m_phase_d[mst])? m_hrdata[mst]
                             : 32'h00000000;
        assign M_HRESP [mst] = (m_phase_d[mst])? m_hresp [mst]
                             : 1'b0;
    end
endgenerate

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
