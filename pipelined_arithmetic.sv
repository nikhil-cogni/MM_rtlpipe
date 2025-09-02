// Pipelined versions of the arithmetic modules

// Version 1: Combinational logic followed by N pipeline stages
module logic_then_pipe #(
    parameter MODULE_ID = 1,  // Which arithmetic_opX module to use
    parameter WIDTH = 8,       // Data width
    parameter PIPE_STAGES = 2  // Number of pipeline stages
) (
    input logic clk,
    input logic reset,
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Output from the combinational logic
    logic [WIDTH-1:0] combo_out;
    
    // Pipeline registers
    logic [WIDTH-1:0] pipe_regs [PIPE_STAGES:0];
    
    // Instantiate the selected combinational logic module
    generate
        case (MODULE_ID)
            1: arithmetic_op1 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            2: arithmetic_op2 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            3: arithmetic_op3 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            4: arithmetic_op4 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            5: arithmetic_op5 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            6: arithmetic_op6 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            7: arithmetic_op7 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            8: arithmetic_op8 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            9: arithmetic_op9 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            10: arithmetic_op10 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            11: arithmetic_op11 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            12: arithmetic_op12 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            13: arithmetic_op13 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            14: arithmetic_op14 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            15: arithmetic_op15 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            16: arithmetic_op16 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            17: arithmetic_op17 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            18: arithmetic_op18 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            19: arithmetic_op19 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            20: arithmetic_op20 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            21: arithmetic_op21 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            22: arithmetic_op22 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            23: arithmetic_op23 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            24: arithmetic_op24 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            25: arithmetic_op25 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
            default: arithmetic_op1 #(WIDTH) combo_logic (.a(a), .b(b), .c(combo_out));
        endcase
    endgenerate
    
    // Connect the combinational output to the first pipeline register
    assign pipe_regs[0] = combo_out;
    
    // Create the pipeline stages
    genvar i;
    generate
        for (i = 1; i <= PIPE_STAGES; i = i + 1) begin : pipe_stage
            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    pipe_regs[i] <= '0;
                end else begin
                    pipe_regs[i] <= pipe_regs[i-1];
                end
            end
        end
    endgenerate
    
    // Connect the last pipeline register to the output
    assign c = pipe_regs[PIPE_STAGES];
    
endmodule

// Version 2: N pipeline stages followed by combinational logic
module pipe_then_logic #(
    parameter MODULE_ID = 1,  // Which arithmetic_opX module to use
    parameter WIDTH = 8,       // Data width
    parameter PIPE_STAGES = 2  // Number of pipeline stages
) (
    input logic clk,
    input logic reset,
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Pipeline registers for inputs
    logic [WIDTH-1:0] a_pipe [PIPE_STAGES:0];
    logic [WIDTH-1:0] b_pipe [PIPE_STAGES:0];
    
    // Connect the inputs to the first pipeline stage
    assign a_pipe[0] = a;
    assign b_pipe[0] = b;
    
    // Create the pipeline stages for inputs
    genvar i;
    generate
        for (i = 1; i <= PIPE_STAGES; i = i + 1) begin : pipe_stage
            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    a_pipe[i] <= '0;
                    b_pipe[i] <= '0;
                end else begin
                    a_pipe[i] <= a_pipe[i-1];
                    b_pipe[i] <= b_pipe[i-1];
                end
            end
        end
    endgenerate
    
    // Instantiate the selected combinational logic module with pipelined inputs
    generate
        case (MODULE_ID)
            1: arithmetic_op1 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            2: arithmetic_op2 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            3: arithmetic_op3 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            4: arithmetic_op4 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            5: arithmetic_op5 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            6: arithmetic_op6 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            7: arithmetic_op7 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            8: arithmetic_op8 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            9: arithmetic_op9 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            10: arithmetic_op10 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            11: arithmetic_op11 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            12: arithmetic_op12 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            13: arithmetic_op13 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            14: arithmetic_op14 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            15: arithmetic_op15 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            16: arithmetic_op16 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            17: arithmetic_op17 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            18: arithmetic_op18 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            19: arithmetic_op19 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            20: arithmetic_op20 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            21: arithmetic_op21 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            22: arithmetic_op22 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            23: arithmetic_op23 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            24: arithmetic_op24 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            25: arithmetic_op25 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
            default: arithmetic_op1 #(WIDTH) combo_logic (.a(a_pipe[PIPE_STAGES]), .b(b_pipe[PIPE_STAGES]), .c(c));
        endcase
    endgenerate
    
endmodule
