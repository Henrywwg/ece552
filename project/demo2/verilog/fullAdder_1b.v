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

    // 3-input xor gate to compute sum
    xor3 iXOR(.in1(a),.in2(b),.in3(c_in),.out(s));

    // needed intermediate signals
    wire res1, res2, res3, res4, res5;

    // c_out is high if a*b + a*c_in + b*c_in
	// compute using only the provided NOT, NAND, NOR, and XOR gates
    nand2 iNAND(.in1(a),.in2(b),.out(res1));
    xor2 iXOR2(.in1(a),.in2(b),.out(res2));
    nand2 iNAND2(.in1(res2),.in2(c_in),.out(res3));
    not1 iNOT(.in1(res1),.out(res4));
    not1 iNOT2(.in1(res3),.out(res5));
    xor2 iXOR3(.in1(res4),.in2(res5),.out(c_out));
    
endmodule
