module register #(parameter width = 16)(
	input clk, rst, we,
	input [width-1:0] wdata,
	output [width-1:0] rdata
);
	// Instantiate width number of flip flops
	dff iDFF [width-1:0] (.clk(clk),.rst(rst),.d(we ? wdata : rdata),.q(rdata));

endmodule