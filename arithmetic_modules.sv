// Collection of 25 arithmetic modules with parameterizable widths
// Each module implements various combinations of arithmetic, bitwise, and shift operations

// Module 1: Adds a to lower bits of b with shifting
module arithmetic_op1 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Add a to b[WIDTH/2-1:0] shifted left by 1
    assign c = a + (b[WIDTH/2-1:0] << 1);
endmodule

// Module 2: XOR with shifted value
module arithmetic_op2 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: XOR of a with b right-shifted by 2
    assign c = a ^ (b >> 2);
endmodule

// Module 3: Upper bits addition with lower bits
module arithmetic_op3 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Upper half of a plus lower half of b
    assign c = a[WIDTH-1:WIDTH/2] + b[WIDTH/2-1:0];
endmodule

// Module 4: Bitwise AND with addition
module arithmetic_op4 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Bitwise AND of a with b plus a
    assign c = (a & b) + a;
endmodule

// Module 5: Subtraction with shifted value
module arithmetic_op5 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: a minus b shifted left by 3
    assign c = a - (b << 3);
endmodule

// Module 6: OR operation with addition
module arithmetic_op6 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: a OR'd with b, then add WIDTH/4
    assign c = (a | b) + WIDTH/4;
endmodule

// Module 7: Mixed bit operations
module arithmetic_op7 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: XOR upper half of a with lower half of b
    assign c = {a[WIDTH-1:WIDTH/2] ^ b[WIDTH/2-1:0], a[WIDTH/2-1:0]};
endmodule

// Module 8: Arithmetic with concatenation
module arithmetic_op8 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Add a to concatenated nibbles of b
    assign c = a + {b[WIDTH/4-1:0], b[WIDTH-1:WIDTH-WIDTH/4]};
endmodule

// Module 9: Conditional selection
module arithmetic_op9 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Select a or b based on MSB of a
    assign c = a[WIDTH-1] ? a + b : a - b;
endmodule

// Module 10: Nested bit operations
module arithmetic_op10 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: ((a & b) ^ (a | b)) + a[WIDTH/2-1:0]
    assign c = ((a & b) ^ (a | b)) + {{(WIDTH/2){1'b0}}, a[WIDTH/2-1:0]};
endmodule

// Module 11: Rotate and add
module arithmetic_op11 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Add a to rotated b (rotate left by WIDTH/4)
    assign c = a + {b[WIDTH-WIDTH/4-1:0], b[WIDTH-1:WIDTH-WIDTH/4]};
endmodule

// Module 12: Bit reversal addition
module arithmetic_op12 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: a plus bit-reversed b (simplistic reversal)
    logic [WIDTH-1:0] b_reversed;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : reverse_bits
            assign b_reversed[i] = b[WIDTH-1-i];
        end
    endgenerate
    
    assign c = a + b_reversed;
endmodule

// Module 13: Modulo arithmetic with bit masks
module arithmetic_op13 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: a modulo (b masked to power of 2 - 1)
    // This creates a mask like 000011111
    logic [WIDTH-1:0] mask;
    assign mask = (1 << (b % WIDTH)) - 1;
    
    assign c = a & mask;
endmodule

// Module 14: Bit interleaving
module arithmetic_op14 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Interleave bits from upper half of a and b
    // Takes every other bit from a and b to form result
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : interleave_bits
            assign c[i*2] = a[i+WIDTH/2];
            assign c[i*2+1] = b[i+WIDTH/2];
        end
    endgenerate
endmodule

// Module 15: Conditional addition or subtraction with shifts
module arithmetic_op15 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: If a > b then a+b<<1 else a-b>>1
    assign c = (a > b) ? (a + (b << 1)) : (a - (b >> 1));
endmodule

// Module 16: Bitwise operations on upper/lower halves
module arithmetic_op16 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Upper half: a&b, Lower half: a^b
    assign c = {{(a[WIDTH-1:WIDTH/2] & b[WIDTH-1:WIDTH/2])}, {(a[WIDTH/2-1:0] ^ b[WIDTH/2-1:0])}};
endmodule

// Module 17: Masked addition
module arithmetic_op17 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Add a to b with every other bit masked
    logic [WIDTH-1:0] mask;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : create_mask
            assign mask[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
        end
    endgenerate
    
    assign c = a + (b & mask);
endmodule

// Module 18: Selective negation
module arithmetic_op18 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Negate bits of a where b has 1, then add to original a
    assign c = a + (~a & b);
endmodule

// Module 19: Partial sum and difference
module arithmetic_op19 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Upper half: a+b, Lower half: a-b
    assign c = {{(a[WIDTH-1:WIDTH/2] + b[WIDTH-1:WIDTH/2])}, {(a[WIDTH/2-1:0] - b[WIDTH/2-1:0])}};
endmodule

// Module 20: Arithmetic with XOR mask
module arithmetic_op20 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: (a + b) XOR (a - b)
    assign c = (a + b) ^ (a - b);
endmodule

// Module 21: Shifted part-select operations
module arithmetic_op21 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Lower quarter of a shifted left by WIDTH/2, plus upper quarter of b
    assign c = (a[WIDTH/4-1:0] << (WIDTH/2)) + {{(3*WIDTH/4){1'b0}}, b[WIDTH-1:3*WIDTH/4]};
endmodule

// Module 22: Cross-section addition
module arithmetic_op22 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Add middle section of a to middle section of b, place in middle of result
    logic [WIDTH/2-1:0] middle;
    assign middle = a[3*WIDTH/4-1:WIDTH/4] + b[3*WIDTH/4-1:WIDTH/4];
    
    assign c = {a[WIDTH-1:3*WIDTH/4], middle, b[WIDTH/4-1:0]};
endmodule

// Module 23: Complex conditional operation
module arithmetic_op23 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: If a[0] then (a&b)+(a|b) else (a^b)-(a&b)
    assign c = a[0] ? ((a & b) + (a | b)) : ((a ^ b) - (a & b));
endmodule

// Module 24: Alternating bit operations
module arithmetic_op24 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: Even bits: a&b, Odd bits: a|b
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : alternate_ops
            assign c[i] = (i % 2 == 0) ? (a[i] & b[i]) : (a[i] | b[i]);
        end
    endgenerate
endmodule

// Module 25: Weighted sum with shifts
module arithmetic_op25 #(parameter WIDTH = 8) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] c
);
    // Operation: a + (b>>1) + (b>>2) + (b>>3) (weighted sum)
    assign c = a + (b >> 1) + (b >> 2) + (b >> 3);
endmodule
