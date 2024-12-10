/*
   CS/ECE 552, Fall '22
   Homework #3, Problem #2
  
   This module creates a wrapper around the 8x16b register file, to do
   do the bypassing logic for RF bypassing.
*/
module regFile_bypass #(
						parameter width = 16
						)(
                       // Outputs
                       read1Data, read2Data, err,
                       // Inputs
                       clk, rst, read1RegSel, read2RegSel, writeRegSel, writeData, writeEn
                       );
	input        clk, rst;
	input [2:0]  read1RegSel;
	input [2:0]  read2RegSel;
	input [2:0]  writeRegSel;
	input [width-1:0] writeData;
	input        writeEn;

	output [width-1:0] read1Data;
	output [width-1:0] read2Data;
	output        err;

	wire [width-1:0] internalReadData1;
	wire [width-1:0] internalReadData2;

    // Instantiate the inner register file
	regFile #(.width(width)) inner_regFile (
		.read1Data(internalReadData1),
        .read2Data(internalReadData2),
        .err(err),
        .clk(clk),
        .rst(rst),
        .read1RegSel(read1RegSel),
        .read2RegSel(read2RegSel),
        .writeRegSel(writeRegSel),
        .writeData(writeData),
        .writeEn(writeEn)
    );

    // Bypass logic: If writing to the same register as being read, use writeData
	assign read1Data = (writeEn & (writeRegSel == read1RegSel)) ? writeData : internalReadData1;
    assign read2Data = (writeEn & (writeRegSel == read2RegSel)) ? writeData : internalReadData2;

endmodule
