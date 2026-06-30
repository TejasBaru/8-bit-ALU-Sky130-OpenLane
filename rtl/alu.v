//==============================================================================
// Module      : alu
// Description : Parameterizable ALU with 16 operations, registered outputs
//               and status flags (carry, zero, overflow)
// Parameter   : DATA_WIDTH — 4, 8 (default), 16, 32
// Author      : Tejas Baru
//==============================================================================
`timescale 1ns/1ps
module alu #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,        // Active-low synchronous reset
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    input  wire [3:0]            opcode,
    output reg  [DATA_WIDTH-1:0] result,
    output reg                   carry_out,
    output reg                   zero,
    output reg                   overflow
);

    //--------------------------------------------------------------------------
    // Opcode Definitions
    //--------------------------------------------------------------------------
    localparam ADD      = 4'h0;
    localparam SUB      = 4'h1;
    localparam INC      = 4'h2;
    localparam DEC      = 4'h3;
    localparam AND      = 4'h4;
    localparam OR       = 4'h5;
    localparam XOR      = 4'h6;
    localparam XNOR     = 4'h7;
    localparam NAND     = 4'h8;
    localparam NOR      = 4'h9;
    localparam NOT      = 4'hA;
    localparam SHL      = 4'hB;
    localparam SHR      = 4'hC;
    localparam ROL      = 4'hD;
    localparam ROR      = 4'hE;
    localparam ARITH_SHR= 4'hF;

    //--------------------------------------------------------------------------
    // Internal Combinational Signals
    //--------------------------------------------------------------------------
    reg  [DATA_WIDTH:0]   result_ext;   // Extended by 1 bit for carry
    reg  [DATA_WIDTH-1:0] result_comb;
    reg                   carry_comb;
    reg                   overflow_comb;

    //--------------------------------------------------------------------------
    // Combinational Compute Block
    //--------------------------------------------------------------------------
    always @(*) begin
        result_ext    = {1'b0, {DATA_WIDTH{1'b0}}};
        result_comb   = {DATA_WIDTH{1'b0}};
        carry_comb    = 1'b0;
        overflow_comb = 1'b0;

        case (opcode)
            ADD: begin
                result_ext    = {1'b0, a} + {1'b0, b};
                result_comb   = result_ext[DATA_WIDTH-1:0];
                carry_comb    = result_ext[DATA_WIDTH];
                overflow_comb = (~a[DATA_WIDTH-1] & ~b[DATA_WIDTH-1] &  result_ext[DATA_WIDTH-1]) |
                                ( a[DATA_WIDTH-1] &  b[DATA_WIDTH-1] & ~result_ext[DATA_WIDTH-1]);
            end

            SUB: begin
                result_ext    = {1'b0, a} - {1'b0, b};
                result_comb   = result_ext[DATA_WIDTH-1:0];
                carry_comb    = result_ext[DATA_WIDTH];  // Borrow flag
                overflow_comb = ( a[DATA_WIDTH-1] & ~b[DATA_WIDTH-1] & ~result_ext[DATA_WIDTH-1]) |
                                (~a[DATA_WIDTH-1] &  b[DATA_WIDTH-1] &  result_ext[DATA_WIDTH-1]);
            end

            INC: begin
                result_ext  = {1'b0, a} + {{DATA_WIDTH{1'b0}}, 1'b1};
                result_comb = result_ext[DATA_WIDTH-1:0];
                carry_comb  = result_ext[DATA_WIDTH];
            end

            DEC: begin
                result_ext  = {1'b0, a} - {{DATA_WIDTH{1'b0}}, 1'b1};
                result_comb = result_ext[DATA_WIDTH-1:0];
                carry_comb  = result_ext[DATA_WIDTH];  // Borrow flag
            end

            AND:  result_comb = a & b;
            OR:   result_comb = a | b;
            XOR:  result_comb = a ^ b;
            XNOR: result_comb = ~(a ^ b);
            NAND: result_comb = ~(a & b);
            NOR:  result_comb = ~(a | b);
            NOT:  result_comb = ~a;

            SHL: begin
                result_comb = a << 1;
                carry_comb  = a[DATA_WIDTH-1];          // Shifted-out MSB
            end

            SHR: begin
                result_comb = a >> 1;
                carry_comb  = a[0];                     // Shifted-out LSB
            end

            ROL: begin
                result_comb = {a[DATA_WIDTH-2:0], a[DATA_WIDTH-1]};
                carry_comb  = a[DATA_WIDTH-1];
            end

            ROR: begin
                result_comb = {a[0], a[DATA_WIDTH-1:1]};
                carry_comb  = a[0];
            end

            ARITH_SHR: begin
                result_comb = {{1{a[DATA_WIDTH-1]}}, a[DATA_WIDTH-1:1]}; // Sign-extend
                carry_comb  = a[0];
            end

            default: begin
                result_comb   = {DATA_WIDTH{1'b0}};
                carry_comb    = 1'b0;
                overflow_comb = 1'b0;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Output Register Block — Synchronous Reset
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            result    <= {DATA_WIDTH{1'b0}};
            carry_out <= 1'b0;
            zero      <= 1'b0;
            overflow  <= 1'b0;
        end else begin
            result    <= result_comb;
            carry_out <= carry_comb;
            zero      <= (result_comb == {DATA_WIDTH{1'b0}});
            overflow  <= overflow_comb;
        end
    end

endmodule
