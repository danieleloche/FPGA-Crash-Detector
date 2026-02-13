`timescale 1ns / 1ps

/* =========================================================================
   Module: acu_top_module
   Description: Top level entity connecting the Control Unit (FSM) 
                and the Datapath modules for the Crash Detection System.
   ========================================================================= */

module acu_top_module(
    input wire ck, 
    input wire reset, 
    input wire INT, 
    input wire ready,
    input wire [7:0] DATAout,
    output wire Dbit, 
    output wire start,
    output wire [7:0] regname,
    output wire sel, 
    output wire tck
);

    // Internal wires connecting Control Unit and Datapath
    wire [8:0] SABS;
    wire [9:0] DATAtra;
    wire hit, LOAD, SH, YnX, clr, en;

    // 1. Control Unit Instantiation (Explicit mapping to avoid Z states)
    acu_control_unit u_control (
        .ck(ck), 
        .reset(reset), 
        .INT(INT), 
        .ready(ready), 
        .hit(hit), 
        .sabs(SABS), 
        .datatra(DATAtra), 
        .start(start), 
        .sel(sel), 
        .tck(tck), 
        .load(LOAD), 
        .sh(SH), 
        .ynx(YnX), 
        .clr(clr), 
        .en(en), 
        .regname(regname)
    );
    
    // 2. Datapath: 10-bit Transmission Counter
    cnt9 u_counter (
        .ck(ck), 
        .reset(reset), // Added reset for initialization safety
        .clr(clr), 
        .en(en), 
        .hit(hit)
    );
    
    // 3. Datapath: 2's Complement to Sign-Magnitude Converter
    SignABS u_converter (
        .num(DATAout), 
        .sigabs(SABS)
    );
    
    // 4. Datapath: Shift Register for Serial Transmission
    ToBeTransm u_shift_reg (
        .ck(ck), 
        .reset(reset), // Added reset to avoid X states in comparison
        .LOAD(LOAD), 
        .SH(SH), 
        .YnX(YnX), 
        .SABS(SABS), 
        .Dbit(Dbit), 
        .DATAtra(DATAtra)
    );

endmodule