/*
    CS/ECE 552 FALL'22
    Homework #2, Problem 1
    
    a 4-bit CLA module
*/
module cla_4b(sum, c_out, a, b, c_in);

    // declare constant for size of inputs, outputs (N)
    parameter   N = 4;

    output [N-1:0] sum;
    output         c_out;
    input [N-1: 0] a, b;
    input          c_in;

    // YOUR CODE HERE

    ///////////////////////////////////////////////////
    // Internal signal for carries in between adders //
    /////////////////////////////////////////////////// 
    wire carry[2:0];
    wire [3:0]prop;
    wire [3:0]notg;
    wire notp0;
    wire notp1;
    wire notp2;
    wire notp3;
    

    fullAdder_1b add0(.a(a[0]), .b(b[0]), .c_in(c_in), .s(sum[0]));
    fullAdder_1b add1(.a(a[1]), .b(b[1]), .c_in(carry[0]), .s(sum[1]));
    fullAdder_1b add2(.a(a[2]), .b(b[2]), .c_in(carry[1]), .s(sum[2]));
    fullAdder_1b add3(.a(a[3]), .b(b[3]), .c_in(carry[2]), .s(sum[3]));

    //////////////////////
    // Look Ahead Logic //
    //////////////////////

    nand2 nand0[3:0](.in1(a), .in2(b), .out(notg));
    xor2 xor0[3:0](.in1(a), .in2(b), .out(prop));

    nand2 nand1(.in1(c_in), .in2(prop[0]), .out(notp0));
    nand2 nand2(.in1(notg[0]), .in2(notp0), .out(carry[0]));

    nand2 nand3(.in1(carry[0]), .in2(prop[1]), .out(notp1));
    nand2 nand4(.in1(notg[1]), .in2(notp1), .out(carry[1]));

    nand2 nand5(.in1(carry[1]), .in2(prop[2]), .out(notp2));
    nand2 nand6(.in1(notg[2]), .in2(notp2), .out(carry[2]));

    nand2 nand7(.in1(carry[2]), .in2(prop[3]), .out(notp3));
    nand2 nand8(.in1(notg[3]), .in2(notp3), .out(c_out));


endmodule
