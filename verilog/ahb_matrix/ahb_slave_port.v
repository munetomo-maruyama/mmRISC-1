//===========================================================
// AHB Matrix
//-----------------------------------------------------------
// File Name   : ahb_slave_port.v
// Description : AHB Matrix Slave Port
//-----------------------------------------------------------
// History :
// Rev.01 2020.01.28 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//------------------------
// Top of AHB Slave Port
//------------------------
module AHB_SLAVE_PORT
    #(parameter
        SLAVES  = 8
     )
(
    // Global Signals
    input  wire HCLK,
    input  wire HRESETn,
    // Master Ports
    // Slave Ports
    output wire        S_HSEL      [0:SLAVES-1],
    output reg  [ 1:0] S_HTRANS    [0:SLAVES-1],
    output wire        S_HWRITE    [0:SLAVES-1],
    output wire        S_HMASTLOCK [0:SLAVES-1],
    output wire [ 2:0] S_HSIZE     [0:SLAVES-1],
    output wire [ 2:0] S_HBURST    [0:SLAVES-1],
    output wire [ 3:0] S_HPROT     [0:SLAVES-1],
    output wire [31:0] S_HADDR     [0:SLAVES-1],
    output wire [31:0] S_HWDATA    [0:SLAVES-1],
    output wire        S_HREADY    [0:SLAVES-1],
    input  wire        S_HREADYOUT [0:SLAVES-1],
    input  wire [31:0] S_HRDATA    [0:SLAVES-1],
    input  wire        S_HRESP     [0:SLAVES-1],
    // Internal Slave Connections
    input  wire        s_addr_req[0:SLAVES-1],    
    output wire        s_addr_ack[0:SLAVES-1],    
    output wire        s_data_ack[0:SLAVES-1],
    //
    input  wire        s_hsel      [0:SLAVES-1],
    input  wire [ 1:0] s_htrans    [0:SLAVES-1],
    input  wire        s_hwrite    [0:SLAVES-1],
    input  wire        s_hmastlock [0:SLAVES-1],
    input  wire [ 2:0] s_hsize     [0:SLAVES-1],
    input  wire [ 2:0] s_hburst    [0:SLAVES-1],
    input  wire [ 3:0] s_hprot     [0:SLAVES-1],
    input  wire [31:0] s_haddr     [0:SLAVES-1],
    input  wire [31:0] s_hwdata    [0:SLAVES-1],
    output wire [31:0] s_hrdata    [0:SLAVES-1],
    output wire        s_hresp     [0:SLAVES-1]
);

genvar slv;
//
wire s_phase_a[0:SLAVES-1];
reg  s_phase_d[0:SLAVES-1];
//
`ifdef NEED_HTRANS_SEQ_WHEN_BURST  // so far, undefined
wire [1:0] s_htrans_raw[0:SLAVES-1];
reg        s_sequence[0:SLAVES-1];
reg [31:0] s_addrincr1 [0:SLAVES-1];
reg [31:0] s_addrincr2 [0:SLAVES-1];
reg [31:0] s_addrincr4 [0:SLAVES-1];
reg [31:0] s_addrwrap04byte[0:SLAVES-1];
reg [31:0] s_addrwrap08byte[0:SLAVES-1];
reg [31:0] s_addrwrap16byte[0:SLAVES-1];
reg [31:0] s_addrwrap04half[0:SLAVES-1];
reg [31:0] s_addrwrap08half[0:SLAVES-1];
reg [31:0] s_addrwrap16half[0:SLAVES-1];
reg [31:0] s_addrwrap04word[0:SLAVES-1];
reg [31:0] s_addrwrap08word[0:SLAVES-1];
reg [31:0] s_addrwrap16word[0:SLAVES-1];
`endif
//
generate
    for (slv = 0; slv < SLAVES; slv = slv + 1)
    begin : SLAVE_PORT
        assign s_phase_a[slv]  = s_addr_req[slv] & S_HREADYOUT[slv] & S_HREADY[slv];
        assign s_addr_ack[slv] = s_addr_req[slv] & S_HREADYOUT[slv] & S_HREADY[slv];
        //
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
                s_phase_d[slv] <= 1'b0;
            else if (S_HREADYOUT[slv] & S_HREADY[slv])
                s_phase_d[slv] <= s_phase_a[slv];
        end
        //
        assign s_data_ack[slv] = s_phase_d[slv] & S_HREADYOUT[slv];
        assign S_HREADY[slv] = S_HREADYOUT[slv];    
        //
        assign S_HSEL[slv]   = (s_phase_a[slv])? s_hsel[slv] : 1'b0;
        //
        assign S_HWRITE[slv] = (s_phase_a[slv])? s_hwrite[slv] : 1'b0;
        assign S_HMASTLOCK[slv] = (s_phase_a[slv])? s_hmastlock[slv] : 1'b0;
        assign S_HSIZE[slv]  = (s_phase_a[slv])? s_hsize[slv] : 3'b000;
        assign S_HBURST[slv] = (s_phase_a[slv])? s_hburst[slv] : 3'b000;
        assign S_HPROT[slv]  = (s_phase_a[slv])? s_hprot[slv] : 4'b0000;
        assign S_HADDR[slv]  = (s_phase_a[slv])? s_haddr[slv] : 32'h0;
        //
        assign S_HWDATA[slv] = (s_phase_d[slv])? s_hwdata[slv] : 32'h0;
        assign s_hrdata[slv] = (s_phase_d[slv])? S_HRDATA[slv] : 32'h0;
        assign s_hresp[slv]  = (s_phase_d[slv])? S_HRESP[slv] : 1'b0;
        //
`ifdef NEED_HTRANS_SEQ_WHEN_BURST
        assign s_htrans_raw[slv] = (s_phase_a[slv])? s_htrans[slv] : 2'b00;
        always @(posedge HCLK, negedge HRESETn)
        begin
            if (~HRESETn)
            begin
                s_sequence [slv] <= 1'b0;
                s_addrincr1[slv] <= 32'h00000000;
                s_addrincr2[slv] <= 32'h00000000;
                s_addrincr4[slv] <= 32'h00000000;
                s_addrwrap04byte[slv] <= 32'h00000000;
                s_addrwrap08byte[slv] <= 32'h00000000;
                s_addrwrap16byte[slv] <= 32'h00000000;
                s_addrwrap04half[slv] <= 32'h00000000;
                s_addrwrap08half[slv] <= 32'h00000000;
                s_addrwrap16half[slv] <= 32'h00000000;
                s_addrwrap04word[slv] <= 32'h00000000;
                s_addrwrap08word[slv] <= 32'h00000000;
                s_addrwrap16word[slv] <= 32'h00000000;
            end
            else if (s_htrans_raw[1] & S_HREADYOUT[slv] & S_HREADY[slv])
            begin
                s_sequence [slv] <= 1'b1;
                s_addrincr1[slv] <= S_HADDR[slv] + 32'h00000001;      
                s_addrincr2[slv] <= S_HADDR[slv] + 32'h00000002;      
                s_addrincr4[slv] <= S_HADDR[slv] + 32'h00000004;      
                s_addrwrap04byte[slv] <= {S_HADDR[slv][31:2], S_HADDR[slv][1:0] + 2'h1}; 
                s_addrwrap08byte[slv] <= {S_HADDR[slv][31:3], S_HADDR[slv][2:0] + 3'h1};
                s_addrwrap16byte[slv] <= {S_HADDR[slv][31:4], S_HADDR[slv][3:0] + 4'h1};
                s_addrwrap04half[slv] <= {S_HADDR[slv][31:3], S_HADDR[slv][2:0] + 3'h2}; 
                s_addrwrap08half[slv] <= {S_HADDR[slv][31:4], S_HADDR[slv][3:0] + 4'h2}; 
                s_addrwrap16half[slv] <= {S_HADDR[slv][31:5], S_HADDR[slv][4:0] + 5'h2}; 
                s_addrwrap04word[slv] <= {S_HADDR[slv][31:4], S_HADDR[slv][3:0] + 4'h4}; 
                s_addrwrap08word[slv] <= {S_HADDR[slv][31:5], S_HADDR[slv][4:0] + 5'h4};
                s_addrwrap16word[slv] <= {S_HADDR[slv][31:6], S_HADDR[slv][5:0] + 6'h4};
            end
        end
        //
        always @*
        begin
            if (s_sequence [slv] == 1'b0)
                S_HTRANS[slv] = s_htrans_raw[slv];
            else if (s_htrans_raw[slv] == 2'b00) // idle
                S_HTRANS[slv] = 2'b00;
            else if (s_htrans_raw[slv] == 2'b01) // busy
                S_HTRANS[slv] = 2'b01;
            else if (s_htrans_raw[slv] == 2'b10) // noseq
                S_HTRANS[slv] = 2'b10;
            else if (S_HBURST[slv] == 3'b000) // single
                S_HTRANS[slv] = s_htrans_raw[slv];
            else if (S_HBURST[slv][0] == 1'b1) // incr/incr4/incr8/incr16
            begin
                casez (S_HSIZE[slv])
                    3'b000 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrincr1[slv])? 2'b11 : 2'b10;
                    3'b001 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrincr2[slv])? 2'b11 : 2'b10;
                    3'b010 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrincr4[slv])? 2'b11 : 2'b10;
                    default: S_HTRANS[slv] = 2'b10;
                endcase
            end
            else if (S_HBURST[slv] == 3'b010) // wrap4
            begin
                casez (S_HSIZE[slv])
                    3'b000 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap04byte[slv])? 2'b11 : 2'b10;
                    3'b001 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap04half[slv])? 2'b11 : 2'b10;
                    3'b010 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap04word[slv])? 2'b11 : 2'b10;
                    default: S_HTRANS[slv] = 2'b10;
                endcase
            end            
            else if (S_HBURST[slv] == 3'b100) // wrap8
            begin
                casez (S_HSIZE[slv])
                    3'b000 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap08byte[slv])? 2'b11 : 2'b10;
                    3'b001 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap08half[slv])? 2'b11 : 2'b10;
                    3'b010 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap08word[slv])? 2'b11 : 2'b10;
                    default: S_HTRANS[slv] = 2'b10;
                endcase
            end            
            else if (S_HBURST[slv] == 3'b110) // wrap16
            begin
                casez (S_HSIZE[slv])
                    3'b000 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap16byte[slv])? 2'b11 : 2'b10;
                    3'b001 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap16half[slv])? 2'b11 : 2'b10;
                    3'b010 : S_HTRANS[slv] = (S_HADDR[slv] == s_addrwrap16word[slv])? 2'b11 : 2'b10;
                    default: S_HTRANS[slv] = 2'b10;
                endcase
            end
            else
            begin
                S_HTRANS[slv] = s_htrans_raw[slv];                        
            end
        end
`else // NEED_HTRANS_SEQ_WHEN_BURST
        assign S_HTRANS[slv] = (s_phase_a[slv])? s_htrans[slv] : 2'b00;
`endif
    end
endgenerate

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
