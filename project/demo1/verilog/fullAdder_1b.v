/*
    CS/ECE 552 FALL '22
    Homework #2, Problem 1
    
    a 1-bit full adder
*/
module fullAdder_1b(s, c_out, a, b, c_in);
    output s;
    output c_out;
	input  a, b;
    input  c_in;

    //////////////////////
    // Internal Signals //
    //////////////////////
    wire xorAB, andAB, andCxorAB;

    ///////////////////////////
    // Gates for computing S //
    ///////////////////////////
    xor2 xor0(.in1(a), .in2(b), .out(xorAB));
    xor2 xor1(.in1(xorAB), .in2(c_in), .out(s));

    //////////////////////////////
    // Gates for computing Cout //
    //////////////////////////////
    nand2 nand0(.in1(xorAB), .in2(c_in), .out(andCxorAB));
    nand2 nand1(.in1(a), .in2(b), .out(andAB));

    ///////////////////////////////////////////////////////////////////////////////////////
    // We can exploit the fact that implementing AND requires a NOT after the NAND       //
    // and OR requires a NOT before each operand to eliminate both gates as back to back //
    // NOT operations result in the original signal.                                     //
    ///////////////////////////////////////////////////////////////////////////////////////
    nand2 nand3(.in1(andCxorAB), .in2(andAB), .out(c_out));

endmodule
