// =============================================================================
// Module      : alu_tb
// Description : Self-checking directed testbench for parameterizable ALU
//               Covers all 16 opcodes with PASS/FAIL terminal output
//               VCD dump for GTKWave
// Standard    : Verilog-2001
// =============================================================================

`timescale 1ns/1ps

module alu_tb;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;

    // -------------------------------------------------------------------------
    // DUT Ports
    // -------------------------------------------------------------------------
    reg                   clk;
    reg                   rst_n;
    reg  [DATA_WIDTH-1:0] a;
    reg  [DATA_WIDTH-1:0] b;
    reg  [3:0]            opcode;
    wire [DATA_WIDTH-1:0] result;
    wire                  carry_out;
    wire                  zero;
    wire                  overflow;

    // -------------------------------------------------------------------------
    // Opcode Definitions
    // -------------------------------------------------------------------------
    localparam ADD       = 4'h0;
    localparam SUB       = 4'h1;
    localparam INC       = 4'h2;
    localparam DEC       = 4'h3;
    localparam AND       = 4'h4;
    localparam OR        = 4'h5;
    localparam XOR       = 4'h6;
    localparam XNOR      = 4'h7;
    localparam NAND      = 4'h8;
    localparam NOR       = 4'h9;
    localparam NOT       = 4'hA;
    localparam SHL       = 4'hB;
    localparam SHR       = 4'hC;
    localparam ROL       = 4'hD;
    localparam ROR       = 4'hE;
    localparam ARITH_SHR = 4'hF;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    alu #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .a         (a),
        .b         (b),
        .opcode    (opcode),
        .result    (result),
        .carry_out (carry_out),
        .zero      (zero),
        .overflow  (overflow)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // VCD Dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);
    end

    // -------------------------------------------------------------------------
    // Task: apply_and_check
    //   Applies inputs, waits one clock, checks result and flags
    //   exp_carry / exp_overflow / exp_zero: 2 = don't care
    // -------------------------------------------------------------------------
    task apply_and_check;
        input [DATA_WIDTH-1:0] in_a;
        input [DATA_WIDTH-1:0] in_b;
        input [3:0]            op;
        input [DATA_WIDTH-1:0] exp_result;
        input integer          exp_carry;
        input integer          exp_overflow;
        input integer          exp_zero;
        input [127:0]          test_name;

        reg pass;
    begin
        a      = in_a;
        b      = in_b;
        opcode = op;
        @(posedge clk); #1;  // Sample just after clock edge

        pass = 1;

        if (result !== exp_result) begin
            $display("FAIL [%0s] | result: got %0d, exp %0d", test_name, result, exp_result);
            pass = 0;
        end
        if (exp_carry !== 2 && carry_out !== exp_carry[0]) begin
            $display("FAIL [%0s] | carry_out: got %0b, exp %0b", test_name, carry_out, exp_carry[0]);
            pass = 0;
        end
        if (exp_overflow !== 2 && overflow !== exp_overflow[0]) begin
            $display("FAIL [%0s] | overflow: got %0b, exp %0b", test_name, overflow, exp_overflow[0]);
            pass = 0;
        end
        if (exp_zero !== 2 && zero !== exp_zero[0]) begin
            $display("FAIL [%0s] | zero: got %0b, exp %0b", test_name, zero, exp_zero[0]);
            pass = 0;
        end

        if (pass) begin
            $display("PASS [%0s] | a=%0d b=%0d op=%0h -> result=%0d carry=%0b ovf=%0b zero=%0b",
                     test_name, in_a, in_b, op, result, carry_out, overflow, zero);
            pass_count = pass_count + 1;
        end else begin
            fail_count = fail_count + 1;
        end
    end
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        // Reset
        rst_n  = 0;
        a      = 0;
        b      = 0;
        opcode = 0;
        repeat(3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("\n===== ALU Testbench Start =====\n");

        // ----- ADD -----
        $display("--- ADD ---");
        apply_and_check(8'd10,  8'd20,  ADD, 8'd30,  0, 0, 0, "ADD_basic");
        apply_and_check(8'd0,   8'd0,   ADD, 8'd0,   0, 0, 1, "ADD_zero");
        apply_and_check(8'd255, 8'd1,   ADD, 8'd0,   1, 0, 1, "ADD_carry");
        apply_and_check(8'd127, 8'd1,   ADD, 8'd128, 0, 1, 0, "ADD_overflow_pos");
        apply_and_check(8'd128, 8'd255, ADD, 8'd127, 1, 1, 0, "ADD_overflow_neg");

        // ----- SUB -----
        $display("--- SUB ---");
        apply_and_check(8'd30,  8'd10,  SUB, 8'd20,  0, 0, 0, "SUB_basic");
        apply_and_check(8'd10,  8'd10,  SUB, 8'd0,   0, 0, 1, "SUB_zero");
        apply_and_check(8'd0,   8'd1,   SUB, 8'd255, 1, 0, 0, "SUB_borrow");
        apply_and_check(8'd128, 8'd1,   SUB, 8'd127, 0, 1, 0, "SUB_overflow_neg");
        apply_and_check(8'd127, 8'd255, SUB, 8'd128, 1, 1, 0, "SUB_overflow_pos");

        // ----- INC -----
        $display("--- INC ---");
        apply_and_check(8'd5,   8'd0,   INC, 8'd6,   0, 2, 0, "INC_basic");
        apply_and_check(8'd255, 8'd0,   INC, 8'd0,   1, 2, 1, "INC_wrap");

        // ----- DEC -----
        $display("--- DEC ---");
        apply_and_check(8'd5,   8'd0,   DEC, 8'd4,   0, 2, 0, "DEC_basic");
        apply_and_check(8'd0,   8'd0,   DEC, 8'd255, 1, 2, 0, "DEC_wrap");

        // ----- AND -----
        $display("--- AND ---");
        apply_and_check(8'hF0, 8'h0F, AND, 8'h00, 0, 0, 1, "AND_no_overlap");
        apply_and_check(8'hFF, 8'hAA, AND, 8'hAA, 0, 0, 0, "AND_mask");

        // ----- OR -----
        $display("--- OR ---");
        apply_and_check(8'hF0, 8'h0F, OR, 8'hFF, 0, 0, 0, "OR_complement");
        apply_and_check(8'h00, 8'h00, OR, 8'h00, 0, 0, 1, "OR_zero");

        // ----- XOR -----
        $display("--- XOR ---");
        apply_and_check(8'hFF, 8'hFF, XOR, 8'h00, 0, 0, 1, "XOR_same");
        apply_and_check(8'hF0, 8'h0F, XOR, 8'hFF, 0, 0, 0, "XOR_complement");

        // ----- XNOR -----
        $display("--- XNOR ---");
        apply_and_check(8'hFF, 8'hFF, XNOR, 8'hFF, 0, 0, 0, "XNOR_same");
        apply_and_check(8'hF0, 8'h0F, XNOR, 8'h00, 0, 0, 1, "XNOR_complement");

        // ----- NAND -----
        $display("--- NAND ---");
        apply_and_check(8'hFF, 8'hFF, NAND, 8'h00, 0, 0, 1, "NAND_all_ones");
        apply_and_check(8'hF0, 8'h0F, NAND, 8'hFF, 0, 0, 0, "NAND_no_overlap");

        // ----- NOR -----
        $display("--- NOR ---");
        apply_and_check(8'h00, 8'h00, NOR, 8'hFF, 0, 0, 0, "NOR_all_zero");
        apply_and_check(8'hFF, 8'h00, NOR, 8'h00, 0, 0, 1, "NOR_one_full");

        // ----- NOT -----
        $display("--- NOT ---");
        apply_and_check(8'hFF, 8'h00, NOT, 8'h00, 0, 0, 1, "NOT_all_ones");
        apply_and_check(8'hA5, 8'h00, NOT, 8'h5A, 0, 0, 0, "NOT_pattern");

        // ----- SHL -----
        $display("--- SHL ---");
        apply_and_check(8'b00000001, 8'd0, SHL, 8'b00000010, 0, 2, 0, "SHL_basic");
        apply_and_check(8'b10000001, 8'd0, SHL, 8'b00000010, 1, 2, 0, "SHL_carry");
        apply_and_check(8'b10000000, 8'd0, SHL, 8'b00000000, 1, 2, 1, "SHL_carry_zero");

        // ----- SHR -----
        $display("--- SHR ---");
        apply_and_check(8'b10000000, 8'd0, SHR, 8'b01000000, 0, 2, 0, "SHR_basic");
        apply_and_check(8'b00000001, 8'd0, SHR, 8'b00000000, 1, 2, 1, "SHR_carry");

        // ----- ROL -----
        $display("--- ROL ---");
        apply_and_check(8'b10110001, 8'd0, ROL, 8'b01100011, 1, 2, 0, "ROL_basic");
        apply_and_check(8'b00000001, 8'd0, ROL, 8'b00000010, 0, 2, 0, "ROL_no_wrap");

        // ----- ROR -----
        $display("--- ROR ---");
        apply_and_check(8'b10110001, 8'd0, ROR, 8'b11011000, 1, 2, 0, "ROR_basic");
        apply_and_check(8'b10000000, 8'd0, ROR, 8'b01000000, 0, 2, 0, "ROR_no_wrap");

        // ----- ARITH_SHR -----
        $display("--- ARITH_SHR ---");
        apply_and_check(8'b10000000, 8'd0, ARITH_SHR, 8'b11000000, 0, 2, 0, "ASHR_neg");
        apply_and_check(8'b01000000, 8'd0, ARITH_SHR, 8'b00100000, 0, 2, 0, "ASHR_pos");
        apply_and_check(8'b11111110, 8'd0, ARITH_SHR, 8'b11111111, 0, 2, 0, "ASHR_neg_one");

        // ----- Reset check -----
        $display("--- RESET ---");
        rst_n = 0;
        @(posedge clk); #1;
        if (result === 8'd0 && carry_out === 1'b0 && zero === 1'b0 && overflow === 1'b0) begin
            $display("PASS [RESET] | All outputs cleared");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL [RESET] | result=%0d carry=%0b zero=%0b ovf=%0b", result, carry_out, zero, overflow);
            fail_count = fail_count + 1;
        end
        rst_n = 1;

        // ----- Summary -----
        $display("\n===== Testbench Complete =====");
        $display("PASSED: %0d", pass_count);
        $display("FAILED: %0d", fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED — review above");
        $display("==============================\n");

        $finish;
    end

endmodule
