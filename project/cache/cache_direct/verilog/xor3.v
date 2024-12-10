/*
    CS/ECE 552 FALL '22
    Homework #2, Problem 1

    3 input XOR
*/
module xor3 (out,in1,in2,in3);
   output out;
   input in1,in2,in3;
   assign out = in1 ^ in2 ^ in3;
endmodule
