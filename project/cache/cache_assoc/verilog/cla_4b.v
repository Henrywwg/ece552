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

	wire [3:0] G,P,C;
	
	// Compute generate and propagate bits
    assign G = a & b;             // Generate: G_i = a_i & b_i
    assign P = a ^ b;             // Propagate: P_i = a_i ^ b_i
    
    // Compute carry bits
    assign C[0] = G[0] | (P[0] & c_in);
    assign C[1] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & c_in);
    assign C[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & c_in);
	assign C[3] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & c_in);
    
    // Compute sum, leave c_out port unconnected
	fullAdder_1b iFULLADDER [3:0] (.a(a),.b(b),.c_in({C[2:0],c_in}),.s(sum),.c_out()); 
    
    // Compute c_out
    assign c_out = C[3];  // The carry-out of the 4-bit CLA
	
endmodule
