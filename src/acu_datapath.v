`timescale 1ns / 1ps

/* =========================================================================
   Datapath Components for the Crash Detector System
   Includes: Transmission Counter, Absolute Value Converter, Shift Register.
   ========================================================================= */

// --- Module 1: Transmission Counter (Counts up to 9 for 10-bit frame) ---
module cnt9(
    input wire ck, 
    input wire reset, 
    input wire clr, 
    input wire en,
    output wire hit
);
    reg [3:0] cnt, cnt_nxt;
    
    // Sequential block with asynchronous reset to clear X states
    always @(posedge ck or posedge reset) begin
        if (reset) cnt <= 4'd0;
        else       cnt <= cnt_nxt;
    end
    
    always @(*) begin
        if (clr)      cnt_nxt = 4'd0;
        else if (en)  cnt_nxt = cnt + 1;
        else          cnt_nxt = cnt;
    end
    
    // Assert hit when 10 bits (0 to 9) have been transmitted
    assign hit = (cnt == 4'd9) ? 1'b1 : 1'b0;
endmodule


// --- Module 2: 2's Complement to Sign-Magnitude Converter ---
module SignABS(
    input wire [7:0] num,
    output wire [8:0] sigabs
);
    wire [7:0] compl = ~num + 1'b1;
    
    // Bit 8 is the Sign flag (1 if negative). Bits [7:0] contain absolute value.
    assign sigabs = num[7] ? {1'b1, compl} : {1'b0, num};
endmodule


// --- Module 3: Shift Register for Serial Data Output ---
module ToBeTransm(
    input wire ck, 
    input wire reset, 
    input wire LOAD, 
    input wire SH, 
    input wire YnX,
    input wire [8:0] SABS,
    output wire Dbit,
    output reg [9:0] DATAtra
);
    reg [9:0] DATAtra_nxt;
    
    // Output the Most Significant Bit (MSB) continuously
    assign Dbit = DATAtra[9]; 
    
    // Added reset to prevent Unknown (X) states during initial comparison
    always @(posedge ck or posedge reset) begin
        if (reset) DATAtra <= 10'd0;
        else       DATAtra <= DATAtra_nxt;
    end
    
    always @(*) begin
        if (LOAD)     DATAtra_nxt = {YnX, SABS}; // Construct transmission packet
        else if (SH)  DATAtra_nxt = {DATAtra[8:0], 1'b0}; // Left Shift
        else          DATAtra_nxt = DATAtra;
    end
endmodule