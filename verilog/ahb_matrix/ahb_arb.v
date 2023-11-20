//===========================================================
// AHB Matrix
//-----------------------------------------------------------
// File Name   : ahb_arb.v
// Description : AHB Matrix Arbiter
//-----------------------------------------------------------
// History :
// Rev.01 2020.01.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020 M.Maruyama
//===========================================================

//------------------------
// AHB Arbitor
//------------------------
module AHB_ARB
    #(parameter
        MASTERS = 8,
        LEVELS = MASTERS,
        MASTERS_BIT =$clog2(MASTERS)
     )
(
    // Global Signals
    input  wire HCLK,
    input  wire HRESETn,
    // Priority Configuration
    input  wire [MASTERS_BIT-1:0] ARB_PRIORITY [0:MASTERS-1],    
    // Bus Request
    input  wire [MASTERS-1:0] ARB_REQ,
    output reg  [MASTERS-1:0] ARB_REQ_ACK,
    // Bus Grant
    output reg  [MASTERS-1:0] ARB_GRANT,
    input  wire [MASTERS-1:0] ARB_GRANT_ACK,
    // Priority Lock (for HMASTLOCK)
    input  wire ARB_PRIORITY_LOCK
);

//---------------------------
// Level Group Request
//---------------------------
reg  [MASTERS-1:0] level_group_req[0:LEVELS-1];
//
always @*
begin
    integer mst, lvl;
    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
        for (mst = 0; mst < MASTERS; mst = mst + 1)
            level_group_req[lvl][mst] = (lvl == ARB_PRIORITY[mst])? ARB_REQ[mst] : 1'b0;
end

//-----------------------------------
// Level Group Grant Acknowledge
//-----------------------------------
reg                     level_grant_ack[0:LEVELS-1];
reg  [MASTERS_BIT -1:0] level_grant_mst[0:LEVELS-1];
//
always @*
begin
    integer lvl, mst;
    reg  grant;
    reg  [MASTERS_BIT -1:0] master;
    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
    begin
        grant = 1'b0;
        master = 0;
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            if ((lvl == ARB_PRIORITY[mst]) && (ARB_GRANT[mst] & ARB_GRANT_ACK[mst]))
            begin
                grant = 1'b1;
                master = (MASTERS_BIT)'(mst);
            end
        end
        level_grant_ack[lvl] = grant;
        level_grant_mst[lvl] = master;
    end
end

//--------------------------
// Round Robin Pointer
//--------------------------
reg [MASTERS_BIT-1:0] rb_pointer[0:LEVELS-1];
reg [MASTERS_BIT-1:0] rb_pointer_min[0:LEVELS-1];
reg [MASTERS_BIT-1:0] rb_pointer_max[0:LEVELS-1];
//
always @*
begin
    integer lvl, mst;
    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
    begin
        rb_pointer_min[lvl] = ~((MASTERS_BIT)'(0));
        rb_pointer_max[lvl] =  ((MASTERS_BIT)'(0));
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            if ((ARB_PRIORITY[mst] == lvl) && (rb_pointer_min[lvl] > mst))
            begin
                rb_pointer_min[lvl] = (MASTERS_BIT)'(mst);
            end
            else if ((ARB_PRIORITY[mst] == lvl) && (rb_pointer_max[lvl] < mst))
            begin
                rb_pointer_max[lvl] = (MASTERS_BIT)'(mst);
            end            
        end        
    end
end
//
//always @(posedge HCLK, negedge HRESETn)
//begin
//    integer lvl;
//    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
//    begin
//        if (~HRESETn)
//            rb_pointer[lvl] <= rb_pointer_min[lvl];
//        else if (ARB_PRIORITY_LOCK)
//            rb_pointer[lvl] <= rb_pointer[lvl]; // Lock
//        else if ((level_grant_ack[lvl]) && (rb_pointer[lvl] >= rb_pointer_max[lvl]))
//            rb_pointer[lvl] <= rb_pointer_min[lvl];            
//        else if (level_grant_ack[lvl])
//            rb_pointer[lvl] <= level_grant_mst[lvl] + (MASTERS_BIT)'(1); //rb_pointer[lvl] + 1;            
//    end
//end 
//
always @(posedge HCLK, negedge HRESETn)
begin
    integer lvl;
    if (~HRESETn)
    begin
        for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
        begin
            rb_pointer[lvl] <= rb_pointer_min[lvl];        
        end
    end
    else
    begin
        for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
        begin
            if (ARB_PRIORITY_LOCK)
                rb_pointer[lvl] <= rb_pointer[lvl]; // Lock
            else if ((level_grant_ack[lvl]) && (rb_pointer[lvl] >= rb_pointer_max[lvl]))
                rb_pointer[lvl] <= rb_pointer_min[lvl];            
            else if (level_grant_ack[lvl])
                rb_pointer[lvl] <= level_grant_mst[lvl] + (MASTERS_BIT)'(1); //rb_pointer[lvl] + 1;            
        end
    end
end 

//------------------------
// Round Robin Arbiter
//------------------------
wire [MASTERS-1:0] rb_grant[0:LEVELS-1];
generate
    genvar lvl;
    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
    begin : U_AHB_ARB_RB
        AHB_ARB_RB
            #(
                 .MASTERS  (MASTERS)
             )
        U_AHB_ARB_RB
        (
            .RB_REQ     (level_group_req[lvl]),
            .RB_POINTER (rb_pointer[lvl]),
            .RB_GRANT   (rb_grant[lvl])
        );
    end
endgenerate

//------------------------
// Final Granted Winner
//------------------------
always @*
begin
    integer lvl, mst;
    reg found;
    found = 1'b0;
    for (mst = 0; mst < MASTERS; mst = mst + 1) ARB_GRANT[mst] = 1'b0;
    for (lvl = 0; lvl < LEVELS; lvl = lvl + 1)
    begin
        if (!found)
        for (mst = 0; mst < MASTERS; mst = mst + 1)
        begin
            ARB_GRANT[mst] = rb_grant[lvl][mst];
            found = found | ARB_GRANT[mst];
        end
    end
end

//------------------------
// Request Acknowledge
//------------------------
always @*
begin
    integer mst;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        ARB_REQ_ACK[mst] = ARB_REQ[mst] & ARB_GRANT[mst] & ARB_GRANT_ACK[mst];
    end
end

//------------------------
// End of Module
//------------------------
endmodule

//=======================================
// Module Round Robin Arbiter
//=======================================
module AHB_ARB_RB
    #(parameter
        MASTERS = 8,
        MASTERS_BIT = $clog2(MASTERS)
     )
(
    input  wire [MASTERS-1:0] RB_REQ,
    input  wire [MASTERS_BIT-1:0] RB_POINTER,
    output reg  [MASTERS-1:0] RB_GRANT
);

//----------------
// Request Mask
//----------------
wire [MASTERS-1:0] rb_mask;
wire [MASTERS-1:0] rb_req_masked;
wire               rb_req_masked_none;
//
assign rb_mask = {MASTERS{1'b1}} << RB_POINTER;
assign rb_req_masked = RB_REQ & rb_mask;
assign rb_req_masked_none = ~(|rb_req_masked);

//----------------------------------------
// Simple Prioiry for Unmasked rb_req
//----------------------------------------
reg  [MASTERS-1:0] rb_grant_unmasked;
//
always @*
begin
    integer mst;
    reg found;
    found = 1'b0;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        rb_grant_unmasked[mst] = RB_REQ[mst] & (~found);
        found = found | rb_grant_unmasked[mst];
    end
end

//----------------------------------------
// Simple Prioiry for Masked rb_req_masked
//----------------------------------------
reg  [MASTERS-1:0] rb_grant_masked;
//
always @*
begin
    integer mst;
    reg found;
    found = 1'b0;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        rb_grant_masked[mst] = rb_req_masked[mst] & (~found);
        found = found | rb_grant_masked[mst];
    end
end

//-----------------------
// Final Granted Signal
//-----------------------
always @*
begin
    integer mst;
    for (mst = 0; mst < MASTERS; mst = mst + 1)
    begin
        RB_GRANT[mst] = (rb_req_masked_none)? rb_grant_unmasked[mst] :
                                              rb_grant_masked[mst];
    end
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
