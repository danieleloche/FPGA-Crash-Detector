`timescale 1ns / 1ps

/* =========================================================================
   Module: tb_crash_detector (Testbench)
   Description: Simulates the handshaking protocol and tests 3 crash scenarios.
   ========================================================================= */

module tb_crash_detector;

    // Testbench signals
    reg [7:0] DATAout;
    reg ck, reset, INT, ready;
    wire [7:0] regname;
    wire Dbit, start, sel, tck;

    // Unit Under Test (UUT) Instantiation
    acu_top_module dut (
        .ck(ck), 
        .reset(reset), 
        .INT(INT), 
        .ready(ready), 
        .DATAout(DATAout), 
        .Dbit(Dbit), 
        .start(start), 
        .regname(regname), 
        .sel(sel), 
        .tck(tck)
    );

    // Clock Generation (Period = 10ns -> 100MHz)
    always #5 ck = ~ck;

    initial begin
        // 1. Initial State (Reset sequence)
        ck = 0; reset = 0; ready = 0; INT = 0; DATAout = 8'h00;
        
        #10 reset = 1;
        #10 reset = 0;
        
        $display("--- SIMULATION STARTED ---");

        // =======================================================
        // SCENARIO 1: Severe X-Axis Impact (Negative G-Force)
        // =======================================================
        $display("Testing Scenario 1: X-Axis impact dominant");
        #20 INT = 1; // Trigger interrupt from sensor
        #10 INT = 0;
        
        #100 DATAout = 8'hE7; // X value: -25 (Absolute = 25)
        #10 ready = 1;
        #10 ready = 0;
        
        #100 DATAout = 8'h43; // Y value: +67 (Absolute = 67)
        #10 ready = 1;
        #10 ready = 0;
        
        #700; // Wait for full serial transmission
        
        // =======================================================
        // SCENARIO 2: Severe X-Axis Impact (Positive G-Force)
        // =======================================================
        $display("Testing Scenario 2: X-Axis positive dominant");
        #20 INT = 1;
        #10 INT = 0;
        
        #100 DATAout = 8'h43; // X value: +67 (Larger absolute value)
        #10 ready = 1;
        #10 ready = 0;
        
        #100 DATAout = 8'hE7; // Y value: -25
        #10 ready = 1;
        #10 ready = 0;
        
        #700; // Wait for full serial transmission
        
        // =======================================================
        // SCENARIO 3: Severe Y-Axis Impact (Negative G-Force)
        // =======================================================
        $display("Testing Scenario 3: Y-Axis impact dominant");
        #20 INT = 1;
        #10 INT = 0;
        
        #100 DATAout = 8'h15; // X value: +21
        #10 ready = 1;
        #10 ready = 0;
        
        #100 DATAout = 8'h85; // Y value: -123 (Larger absolute value)
        #10 ready = 1;
        #10 ready = 0;
        
        #700; 
        $display("--- SIMULATION FINISHED ---");
        $stop;
    end
endmodule