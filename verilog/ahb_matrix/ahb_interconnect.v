//===========================================================
// AHB Matrix
//-----------------------------------------------------------
// File Name   : ahb_interconnect.v
// Description : AHB Interconnection among Masters and Slaves
//-----------------------------------------------------------
// History :
// Rev.01 2020.02.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//--------------------------------
// Top of AHB Interconnection
//--------------------------------
module AHB_INTERCONNECT
    #(parameter
        MASTERS     = 8,
        SLAVES      = 8,
        MASTERS_BIT = $clog2(MASTERS)
     )
(
    // Global Signals
    input  wire HCLK,
    input  wire HRESETn,
    // Master Connection
    input  wire        m_addr_req[0:MASTERS-1],    
    output reg         m_addr_ack[0:MASTERS-1],    
    output reg         m_data_ack[0:MASTERS-1],
    //
    input  wire        m_hsel      [0:MASTERS-1],
    input  wire [ 1:0] m_htrans    [0:MASTERS-1],
    input  wire        m_hwrite    [0:MASTERS-1],
    input  wire        m_hmastlock [0:MASTERS-1],
    input  wire [ 2:0] m_hsize     [0:MASTERS-1],
    input  wire [ 2:0] m_hburst    [0:MASTERS-1],
    input  wire [ 3:0] m_hprot     [0:MASTERS-1],
    input  wire [31:0] m_haddr     [0:MASTERS-1],
    input  wire [31:0] m_hwdata    [0:MASTERS-1],
    output reg  [31:0] m_hrdata    [0:MASTERS-1],
    output reg         m_hresp     [0:MASTERS-1],
    //
    input  wire [MASTERS_BIT-1:0] M_PRIORITY[0:MASTERS-1],
    // Slave Connection
    output reg         s_addr_req[0:SLAVES-1],    
    input  wire        s_addr_ack[0:SLAVES-1],    
    input  wire        s_data_ack[0:SLAVES-1],
    //
    output reg         s_hsel      [0:SLAVES-1],
    output reg  [ 1:0] s_htrans    [0:SLAVES-1],
    output reg         s_hwrite    [0:SLAVES-1],
    output reg         s_hmastlock [0:SLAVES-1],
    output reg  [ 2:0] s_hsize     [0:SLAVES-1],
    output reg  [ 2:0] s_hburst    [0:SLAVES-1],
    output reg  [ 3:0] s_hprot     [0:SLAVES-1],
    output reg  [31:0] s_haddr     [0:SLAVES-1],
    output reg  [31:0] s_hwdata    [0:SLAVES-1],
    input  wire [31:0] s_hrdata    [0:SLAVES-1],
    input  wire        s_hresp     [0:SLAVES-1],
    //
    input  wire [31:0] S_HADDR_BASE[0:SLAVES-1],
    input  wire [31:0] S_HADDR_MASK[0:SLAVES-1]
);

//integer mst, slv;
//genvar mst, slv;

reg  [MASTERS-1:0] phase_a_hit[0:SLAVES-1];
reg  [MASTERS-1:0] phase_a_req[0:SLAVES-1];
wire [MASTERS-1:0] phase_a_ack[0:SLAVES-1];
wire [MASTERS-1:0] phase_a_req_winner[0:SLAVES-1];
reg  [MASTERS-1:0] phase_a_ack_winner[0:SLAVES-1];
reg  [MASTERS-1:0] phase_d[0:SLAVES-1];
reg  [MASTERS-1:0] phase_a_lock[0:SLAVES-1];
//
reg  [MASTERS-1:0] phase_a_default;
reg  [MASTERS-1:0] phase_d_default;
//
reg  [MASTERS-1:0] lock[0:SLAVES-1];
reg  [MASTERS-1:0] lock_m;
reg  [SLAVES- 1:0] lock_s;

//------------------------
// HMASTLOCK Control
//------------------------
//always @(posedge HCLK, negedge HRESETn)
//begin
//    integer mst, slv;
//    for (slv = 0; slv < SLAVES; slv = slv + 1)
//    begin
//        for (mst = 0; mst < MASTERS; mst = mst + 1)
//        begin
//        if (~HRESETn)
//            lock[slv][mst] <= 1'b0;
//        else if (m_addr_ack[mst])
//            lock[slv][mst]
//            <= m_addr_req[mst] & m_hmastlock[mst]
//            & ((m_haddr[mst] & S_HADDR_MASK[slv]) == S_HADDR_BASE[slv]);
//        end
//    end
//end
//
always @(posedge HCLK, negedge HRESETn)
begin
    integer mst, slv;
    if (~HRESETn)
    begin
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            for (mst = 0; mst < MASTERS; mst = mst + 1)
            begin
                lock[slv][mst] <= 1'b0;
            end
        end
    end
    else
    begin
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            for (mst = 0; mst < MASTERS; mst = mst + 1)
            begin
            if (m_addr_ack[mst])
                lock[slv][mst]
                <= m_addr_req[mst] & m_hmastlock[mst]
                & ((m_haddr[mst] & S_HADDR_MASK[slv]) == S_HADDR_BASE[slv]);
            end
        end    
    end
end
//
always @*
begin
    integer mst, slv;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        lock_m[mst] = 1'b0;
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            lock_m[mst] = lock_m[mst] | lock[slv][mst];
        end
    end
end
//
always @*
begin
    integer mst, slv;
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        lock_s[slv] = 1'b0;
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            lock_s[slv] = lock_s[slv] | lock[slv][mst];
        end
    end
end

//------------------------
// Address Decoding
//------------------------
always @*
begin
    integer mst, slv;
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            phase_a_hit[slv][mst]
            = m_addr_req[mst]
            & ((m_haddr[mst] & S_HADDR_MASK[slv]) == S_HADDR_BASE[slv]);
        end
    end
end

//--------------------------
// Address Default Control
//--------------------------
always @*
begin
    integer mst, slv;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        phase_a_default[mst] = m_addr_req[mst];
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            if (phase_a_hit[slv][mst])
                phase_a_default[mst] = 1'b0;
        end
    end
end
//
//always @(posedge HCLK, negedge HRESETn)
//begin
//    integer mst;
//    for (mst = 0; mst < MASTERS; mst = mst + 1)
//    begin
//        if (~HRESETn)
//            phase_d_default[mst] <= 1'b0;
//        else if (phase_a_default[mst])
//            phase_d_default[mst] <= 1'b1;
//        else
//            phase_d_default[mst] <= 1'b0;
//    end
//end
//
always @(posedge HCLK, negedge HRESETn)
begin
    integer mst;
    if (~HRESETn)
    begin
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            phase_d_default[mst] <= 1'b0;
        end
    end
    else
    begin
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            if (phase_a_default[mst])
                phase_d_default[mst] <= 1'b1;
            else
                phase_d_default[mst] <= 1'b0;
        end
    end
end

//------------------------
// Address Phase Timing
//------------------------
always @*
begin
    integer mst, slv;
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            if (lock_s[slv] == 1'b0)
                phase_a_req[slv][mst] = phase_a_hit[slv][mst];
            // At least one locked master exists for the slave.
            // Last master should access the slave again.
            // Mastlock should lock the updates of arbitor's priority conditions.
            else
                phase_a_req[slv][mst] = phase_a_hit[slv][mst] & lock_m[mst];                
        end
    end
end
//
always @*
begin
    integer mst, slv;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        if (phase_a_default[mst]) // if Address Default
        begin
            m_addr_ack[mst] = 1'b1; // return ack soon
        end
        else // if Address Hit
        begin
            m_addr_ack[mst] = 0;
            for (slv = 0; slv < SLAVES; slv = slv + 1)
            begin
                m_addr_ack[mst] = (phase_a_req[slv][mst])? 
                    phase_a_ack[slv][mst] : m_addr_ack[mst];
            end
        end
    end
end

//------------------------------
// Priority Arbitration
//------------------------------
generate
    genvar slave;
    for (slave = 0; slave < SLAVES; slave = slave + 1)
    begin : AHB_ARB_SLAVE
        AHB_ARB
            #(
                .MASTERS (MASTERS)
             )
        U_AHB_ARB
        (
            // Global Signals
            .HCLK    (HCLK),
            .HRESETn (HRESETn),
            // Priority Configuration
            .ARB_PRIORITY (M_PRIORITY),
            // Bus Request
            .ARB_REQ     (phase_a_req[slave]),
            .ARB_REQ_ACK (phase_a_ack[slave]),
            // Bus Grant
            .ARB_GRANT     (phase_a_req_winner[slave]),
            .ARB_GRANT_ACK (phase_a_ack_winner[slave]),
            // Priority Lock (for HMASTLOCK)
            .ARB_PRIORITY_LOCK (s_hmastlock[slave])
        );
    end
endgenerate

//------------------------
// Data Phase Timing
//------------------------
//always @(posedge HCLK, negedge HRESETn)
//begin
//    integer mst, slv;
//    for (slv = 0; slv < SLAVES; slv = slv + 1)
//    begin
//        for (mst = 0; mst < MASTERS; mst = mst + 1)
//        begin
//            if (~HRESETn)
//                phase_d[slv][mst] <= 1'b0;
//            else if (s_addr_ack[slv])
//                phase_d[slv][mst] <= phase_a_req_winner[slv][mst];
//            else if (s_data_ack[slv])
//                phase_d[slv][mst] <= 1'b0;                    
//        end
//    end
//end
//
always @(posedge HCLK, negedge HRESETn)
begin
    integer mst, slv;
    if (~HRESETn)
    begin
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            for (mst = 0; mst < MASTERS; mst = mst + 1)
            begin
                phase_d[slv][mst] <= 1'b0;
            end
        end
    end
    else    
    begin
        for (slv = 0; slv < SLAVES; slv = slv + 1)
        begin
            for (mst = 0; mst < MASTERS; mst = mst + 1)
            begin
                if (s_addr_ack[slv])
                    phase_d[slv][mst] <= phase_a_req_winner[slv][mst];
                else if (s_data_ack[slv])
                    phase_d[slv][mst] <= 1'b0;                    
            end
        end
    end
end

//-----------------------------
// Address Phase Signals
//-----------------------------
always @*
begin
    integer mst, slv;
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        s_addr_req[slv] = 0;
        s_hsel  [slv] = 0;
        s_htrans[slv] = 0;
        s_hwrite[slv] = 0;
        s_hmastlock[slv] = 0;
        s_hsize [slv] = 0;
        s_hburst[slv] = 0;
        s_hprot [slv] = 0;
        s_haddr [slv] = 0;
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            s_addr_req[slv]  = (phase_a_req_winner[slv][mst])? m_addr_req[mst] : s_addr_req[slv];
            s_hsel  [slv]    = (phase_a_req_winner[slv][mst])? m_hsel  [mst] : s_hsel  [slv];
            s_htrans[slv]    = (phase_a_req_winner[slv][mst])? m_htrans[mst] : s_htrans[slv];
            s_hwrite[slv]    = (phase_a_req_winner[slv][mst])? m_hwrite[mst] : s_hwrite[slv];
            s_hmastlock[slv] = (phase_a_req_winner[slv][mst])? m_hmastlock[mst] : s_hmastlock[slv];
            s_hsize [slv]    = (phase_a_req_winner[slv][mst])? m_hsize [mst] : s_hsize [slv];
            s_hburst[slv]    = (phase_a_req_winner[slv][mst])? m_hburst[mst] : s_hburst[slv];
            s_hprot [slv]    = (phase_a_req_winner[slv][mst])? m_hprot [mst] : s_hprot [slv];
            s_haddr [slv]    = (phase_a_req_winner[slv][mst])? m_haddr [mst] : s_haddr [slv];
        end
    end
end
//
always @*
begin
    integer mst, slv;
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            phase_a_ack_winner[slv][mst]
            = phase_a_req_winner[slv][mst] & s_addr_ack[slv];
        end
    end
end

//--------------------------
// Data Phase Signals
//--------------------------
always @*
begin
    integer mst, slv;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        m_data_ack[mst] = 0;
        m_hrdata[mst] = 0;
        m_hresp [mst] = 0;
        //
        if (phase_d_default[mst]) // if Address Default
        begin
            m_data_ack[mst] = 1'b1;
            m_hrdata  [mst] = 32'hdeaddead;
          //m_hresp   [mst] = 1'b1; // Error If address does not hit.        
            m_hresp   [mst] = 1'b0; // No error even if address does not hit.        
        end
        else // if Address Hit
        begin
            for (slv = 0; slv < SLAVES; slv = slv + 1)
            begin
                m_data_ack[mst] = (phase_d[slv][mst])? s_data_ack[slv] : m_data_ack[mst];
                m_hrdata  [mst] = (phase_d[slv][mst])? s_hrdata  [slv] : m_hrdata  [mst];
                m_hresp   [mst] = (phase_d[slv][mst])? s_hresp   [slv] : m_hresp   [mst];
            end
        end
    end
    //
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin
        s_hwdata[slv] = 0;
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            s_hwdata[slv] = (phase_d[slv][mst])? m_hwdata[mst] : s_hwdata[slv];
        end
    end
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
