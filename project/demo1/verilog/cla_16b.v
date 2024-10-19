/*
    CS/ECE 552 FALL '22
    Homework #2, Problem 1
    
    a 16-bit CLA module
*/
module cla_16b(sum, c_out, a, b, c_in);

    // declare constant for size of inputs, outputs (N)
    parameter   N = 16;

    output [N-1:0] sum;
    output         c_out;
    input [N-1: 0] a, b;
    input          c_in;

    // YOUR CODE HERE

    //////////////////////
    // Internal Signals //
    //////////////////////
    wire carry[2:0];
    wire [15:0]xorAB;
    wire notand[7:0];
    wire prop[3:0];
    wire notprop[3:0];
    wire gen[3:0];
    wire notgen[3:0];
    
    cla_4b look_ahead0(.a(a[3:0]), .b(b[3:0]), .c_in(c_in), .sum(sum[3:0]), .c_out(gen[0]));
    cla_4b look_ahead1(.a(a[7:4]), .b(b[7:4]), .c_in(carry[0]), .sum(sum[7:4]), .c_out(gen[1]));
    cla_4b look_ahead2(.a(a[11:8]), .b(b[11:8]), .c_in(carry[1]), .sum(sum[11:8]), .c_out(gen[2]));
    cla_4b look_ahead3(.a(a[15:12]), .b(b[15:12]), .c_in(carry[2]), .sum(sum[15:12]), .c_out(gen[3]));


    //////////////////////
    // Look Ahead logic //
    //////////////////////
    xor2 xor0[15:0](.in1(a), .in2(b), .out(xorAB));


    nand2 nand0(.in1(xorAB[0]), .in2(xorAB[1]), .out(notand[0]));
    nand2 nand1(.in1(xorAB[2]), .in2(xorAB[3]), .out(notand[1]));
    nor2 nor0(.in1(notand[0]), .in2(notand[1]), .out(prop[0]));
    nand2 nand12(.in1(prop[0]), .in2(c_in), .out(notprop[0]));
    not1 not0(.in1(gen[0]), .out(notgen[0]));
    nand2 nand2(.in1(notprop[0]), .in2(notgen[0]), .out(carry[0]));

    nand2 nand3(.in1(xorAB[4]), .in2(xorAB[5]), .out(notand[2]));
    nand2 nand4(.in1(xorAB[6]), .in2(xorAB[7]), .out(notand[3]));
    nor2 nor2(.in1(notand[2]), .in2(notand[3]), .out(prop[1]));
    nand2 nand13(.in1(prop[1]), .in2(carry[0]), .out(notprop[1]));
    not1 not1(.in1(gen[1]), .out(notgen[1]));
    nand2 nand5(.in1(notprop[1]), .in2(notgen[1]), .out(carry[1]));

    nand2 nand6(.in1(xorAB[8]), .in2(xorAB[9]), .out(notand[4]));
    nand2 nand7(.in1(xorAB[10]), .in2(xorAB[11]), .out(notand[5]));
    nor2 nor4(.in1(notand[4]), .in2(notand[5]), .out(prop[2]));
    nand2 nand14(.in1(prop[2]), .in2(carry[1]), .out(notprop[2]));
    not1 not2(.in1(gen[2]), .out(notgen[2]));
    nand2 nand8(.in1(notprop[2]), .in2(notgen[2]), .out(carry[2]));

    nand2 nand9(.in1(xorAB[12]), .in2(xorAB[13]), .out(notand[6]));
    nand2 nand10(.in1(xorAB[14]), .in2(xorAB[15]), .out(notand[7]));
    nor2 nor6(.in1(notand[6]), .in2(notand[7]), .out(prop[3]));
    nand2 nand15(.in1(prop[3]), .in2(carry[2]), .out(notprop[3]));
    not1 not3(.in1(gen[3]), .out(notgen[3]));
    nand2 nand11(.in1(notprop[3]), .in2(notgen[3]), .out(c_out));

endmodule
