`timescale 1ns / 1ps

/* =========================================================================
   Module: acu_control_unit
   Description: Moore Finite State Machine (FSM) handling sensor handshaking
                and serial transmission scheduling.
   ========================================================================= */

module acu_control_unit(
    input wire ck, 
    input wire reset, 
    input wire INT, 
    input wire ready, 
    input wire hit,
    input wire [8:0] sabs,
    input wire [9:0] datatra,
    output reg start, 
    output reg sel, 
    output reg tck, 
    output reg load, 
    output reg sh, 
    output reg ynx, 
    output reg clr, 
    output reg en,
    output reg [7:0] regname
);

    // State definition using ASCII for clear waveform debugging
    reg [15:0] state, state_nxt;
    parameter [15:0] ID = "ID", RX = "RX", LX = "LX", RY = "RY", LY = "LY",
                     ZA = "ZA", ZB = "ZB", ZC = "ZC", UA = "UA", UB = "UB", UC = "UC";

    // Hardware condition: Is new Absolute Y greater than stored Absolute X?
    wire test;
    assign test = (sabs[7:0] > datatra[7:0]) ? 1'b1 : 1'b0;

    // 1. Sequential Logic (State Memory)
    always @(posedge ck or posedge reset) begin
        if (reset) 
            state <= ID;
        else 
            state <= state_nxt;
    end

    // 2. Combinational Logic (Next State routing)
    always @(*) begin
        case(state)
            ID: if(INT) state_nxt = RX; else state_nxt = ID;
            
            // X-Axis Acquisition
            RX: if(ready) state_nxt = LX; else state_nxt = RX;
            LX: state_nxt = RY;
            
            // Y-Axis Acquisition and Comparison
            RY: begin
                if (ready) begin
                    if (test) state_nxt = LY; // Y is greater, load Y
                    else      state_nxt = ZA; // X is greater, skip to transmission
                end
                else state_nxt = RY;
            end
            LY: state_nxt = ZA;
            
            // Serial Transmission Phases
            ZA: state_nxt = ZB;
            ZB: state_nxt = ZC;
            ZC: state_nxt = UA;
            UA: state_nxt = UB;
            UB: state_nxt = UC;
            UC: if(hit) state_nxt = ID; // Transmission complete
                else    state_nxt = ZA; // Transmit next bit
                
            default: state_nxt = ID; // Failsafe
        endcase
    end

    // 3. Output Logic (Moore Machine: depends ONLY on current state)
    always @(state) begin
        // Default assignments to prevent latches
        start = 0; sel = 0; tck = 0; load = 0; 
        sh = 0; ynx = 0; clr = 0; en = 0;
        regname = 8'h00;

        case(state)
            ID: clr = 1;
            RX: begin start = 1; regname = 8'h08; end // Request X-axis
            LX: load = 1;                             // Latch X-axis
            RY: begin start = 1; regname = 8'h09; end // Request Y-axis
            LY: begin load = 1; ynx = 1; end          // Latch Y-axis (since it's larger)
            
            // Clock and Data generation for Serial Protocol
            ZA, ZB, ZC: sel = 1;
            UA, UB:     begin tck = 1; sel = 1; end
            UC:         begin en = 1; sh = 1; sel = 1; tck = 0; end
            
            default:    clr = 1; // Failsafe
        endcase
    end
endmodule