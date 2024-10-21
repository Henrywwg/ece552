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
	
	wire [15:0] G,P;
	wire [3:0] C;
	
	// Compute generate and propagate bits
    assign G = a & b;             // Generate: G_i = a_i & b_i
    assign P = a ^ b;             // Propagate: P_i = a_i ^ b_i
    
    // Compute carry bits independently 
	assign C[0] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & c_in);
	assign C[1] = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | (P[7] & P[6] & P[5] & G[4]) | (P[7] & P[6] & P[5] & P[4] & C[0]);
	assign C[2] = G[11] | (P[11] & G[10]) | (P[11] & P[10] & G[9]) | (P[11] & P[10] & P[9] & G[8]) | (P[11] & P[10] & P[9] & P[8] & C[1]);
	assign C[3] = G[15] | (P[15] & G[14]) | (P[15] & P[14] & G[13]) | (P[15] & P[14] & P[13] & G[12]) | (P[15] & P[14] & P[13] & P[12] & C[2]);

	// use four 4-bit CLAs without utilizing c_out
    cla_4b iCLA4 [3:0] (.a({a[15:12],a[11:8],a[7:4],a[3:0]}),
						.b({b[15:12],b[11:8],b[7:4],b[3:0]}),
						.c_in({C[2:0],c_in}),
						.sum({sum[15:12],sum[11:8],sum[7:4],sum[3:0]}),
						.c_out());

	assign c_out = C[3];
	
endmodule
