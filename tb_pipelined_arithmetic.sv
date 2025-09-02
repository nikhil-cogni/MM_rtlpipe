// Testbench for pipelined arithmetic modules

module tb_pipelined_arithmetic #(
    parameter MODULE_ID = 1,    // Which arithmetic_opX module to test
    parameter WIDTH = 16,       // Data width (between 8 and 32)
    parameter PIPE_STAGES = 3   // Number of pipeline stages
);
    // Clock and reset
    logic clk = 0;
    logic reset;
    
    // Inputs and outputs
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [WIDTH-1:0] c_logic_then_pipe;
    logic [WIDTH-1:0] c_pipe_then_logic;
    
    // Test configuration
    localparam CYCLES = 100;  // Number of test cycles
    
    // Counters and flags
    int cycle_count = 0;
    int error_count = 0;
    bit test_done = 0;
    
    // DUT instantiations
    // Version 1: Combinational logic followed by N pipeline stages
    logic_then_pipe #(
        .MODULE_ID(MODULE_ID),
        .WIDTH(WIDTH),
        .PIPE_STAGES(PIPE_STAGES)
    ) dut1 (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .c(c_logic_then_pipe)
    );
    
    // Version 2: N pipeline stages followed by combinational logic
    pipe_then_logic #(
        .MODULE_ID(MODULE_ID),
        .WIDTH(WIDTH),
        .PIPE_STAGES(PIPE_STAGES)
    ) dut2 (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .c(c_pipe_then_logic)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Stimulus generation
    initial begin
        $display("TEST START");
        $display("Testing MODULE_ID = %0d, WIDTH = %0d, PIPE_STAGES = %0d", MODULE_ID, WIDTH, PIPE_STAGES);
        
        // Apply reset
        reset = 1;
        a = 0;
        b = 0;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Initial comparison delay to allow pipelines to fill
        repeat (PIPE_STAGES+1) @(posedge clk);
        
        // Apply stimulus for test cycles
        for (int i = 0; i < CYCLES; i++) begin
            // Generate pseudo-random inputs using cycle count as seed
            a = $urandom() % (2**WIDTH);
            b = $urandom() % (2**WIDTH);
            
            @(posedge clk);
            cycle_count++;
            
            // Compare outputs after pipelines have been filled
            if (cycle_count > PIPE_STAGES*2) begin
                if (c_logic_then_pipe !== c_pipe_then_logic) begin
                    error_count++;
                    $display("LOG: %0t : ERROR : tb_pipelined_arithmetic : outputs : expected_value: %h actual_value: %h", 
                             $time, c_logic_then_pipe, c_pipe_then_logic);
                end else begin
                    $display("LOG: %0t : INFO : tb_pipelined_arithmetic : outputs match : value: %h", 
                             $time, c_logic_then_pipe);
                end
            end
        end
        
        // Final check after pipelines drain
        repeat (PIPE_STAGES) @(posedge clk);
        
        // Report results
        if (error_count == 0) begin
            $display("TEST PASSED: All %0d comparisons matched!", CYCLES - PIPE_STAGES*2);
        end else begin
            $display("ERROR: Found %0d mismatches out of %0d comparisons!", 
                     error_count, CYCLES - PIPE_STAGES*2);
            $display("TEST FAILED");
        end
        
        test_done = 1;
        #100 $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CYCLES*20*10);
        if (!test_done) begin
            $display("ERROR: Test timeout!");
            $display("TEST FAILED");
            $finish;
        end
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule
