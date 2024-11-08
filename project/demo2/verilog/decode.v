/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (clk, rst, err_out, incrPC, incrPC_out, instruction_in, instruction_out, 
   write_reg, write_data, R1_out, R2_out, RegWrt);

   input wire [15:0]incrPC;
   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;
   output wire [15:0]incrPC_out

   input wire clk;
   input wire rst;
   input wire RegWrt;
   input wire [2:0]write_reg;
   input wire [15:0]write_data;

   output wire [15:0]R1_out, R2_out; 
   output wire err_out;

   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
   wire err;
   wire [15:0]R1, R2;
   wire [4:0]opcode;
   wire [15:0]instruction;
   assign instruction = instruction_in;
   assign opcode = instruction[15:11];

   ////////////////////////
   //INSTANTIATE REG FILE//
   ////////////////////////  
   regFile IregFile (.clk(clk), .rst(rst), .read1RegSel(instruction[10:8]), 
      .read2RegSel(instruction[7:5]), .writeRegSel(write_reg), .writeData(write_data), 
      .writeEn(RegWrt), .read1Data(R1), .read2Data(R2), .err(err));

   ////////////////////////
   // Pipeline Registers //
   ////////////////////////
   dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction), .q(instruction_out));
   dff reg1[15:0](.clk(clk), .rst(rst), .d(R1), .q(R1_out));
   dff reg2[15:0](.clk(clk), .rst(rst), .d(R2), .q(R2_out));
   dff error(.clk(clk), .rst(rst), .d(err), .q(err_out));
   dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(incrPC), .q(incrPC_out));

   ///////////////////
   // RAW DETECTION //
   ///////////////////
   dest_parser iParser(.instruction(), .dest_reg_val(), .dest_valid());

endmodule
`default_nettype wire
