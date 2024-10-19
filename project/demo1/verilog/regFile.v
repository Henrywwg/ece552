/*
   CS/ECE 552, Fall '22
   Homework #3, Problem #1
  
   This module creates a 16-bit register.  It has 1 write port, 2 read
   ports, 3 register select inputs, a write enable, a reset, and a clock
   input.  All register state changes occur on the rising edge of the
   clock. 
*/
module regFile #(
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
	output [width-1:0] read2Data;	// I'm told it's fine to change the arugments for variable width
	output        err;
   
	// Declare an array to hold the data from registers
	wire [width-1:0] readData_arr [7:0];
    
	// Create the enable signals: only one register will be enabled at a time
    wire [7:0] enables = {
    (writeRegSel == 3'b111) & writeEn,
    (writeRegSel == 3'b110) & writeEn,
    (writeRegSel == 3'b101) & writeEn,
    (writeRegSel == 3'b100) & writeEn,
    (writeRegSel == 3'b011) & writeEn,
    (writeRegSel == 3'b010) & writeEn,
    (writeRegSel == 3'b001) & writeEn,
    (writeRegSel == 3'b000) & writeEn
	};

	// Instantiate the registers with variable width
    register #(.width(width)) registers [7:0] (
        .clk(clk),
        .rst(rst),
        .we(enables),
        .wdata(writeData),
        .rdata({readData_arr[7], readData_arr[6], readData_arr[5], readData_arr[4],
                 readData_arr[3], readData_arr[2], readData_arr[1], readData_arr[0]})
    );

    // Read logic for the specified register
    assign read1Data = readData_arr[read1RegSel];
    assign read2Data = readData_arr[read2RegSel];

    // Error handling
    wire writeData_error = (writeData == {width{1'bx}});	 // Check if writeData is unknown
    wire writeEn_error = (writeEn == 1'bx);               // Check if writeEn is unknown
    wire rst_error = (rst == 1'bx);                        // Check if rst is unknown

    // Combine all error signals
    assign err = writeData_error | writeEn_error | rst_error;

endmodule
