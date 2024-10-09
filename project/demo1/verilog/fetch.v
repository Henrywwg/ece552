/*
   CS/ECE 552 Spring '22
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.
   Author          : Henry Wysong-Grass
   Date            : 2024-10-09
   Tested?         : NO
*/
`default_nettype none
module fetch (clk, rst, PC_new, PC_p2, instruction);
   //Module Inputs
   input wire clk;
   input wire rst;
   input wire [15:0]PC_new;
   input wire DUMP;
   
   //Module Outputs
   output wire [15:0]PC_p2;
   output wire [15:0]instruction;


   ///////////////////////
   // INTERNAL SIGNALS  //
   ///////////////////////
   //PC_q stores current PC out and PC_p4 stores PC+4
   wire [15:0]PC_q;


   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////
   //DFFs hold value of PC
   dff iPC[15:0](.q(PC_q), .d(PC_new), .clk(clk), .rst(rst));

   //memory2c is Instruction Memory and outputs instruction pointed to by PC
   memory2c iIM(.data_out(instruction), .data_in(16'h0000), .addr(PC_q), .enable(1'b1), .wr(1'b0), .createdump(DUMP), .clk(clk), .rst(rst));



   ///////////
   // LOGIC //
   ///////////
   
   //Keep PC_p2 as PC_q + 2
   assign PC_p2 = PC_q + 16'h0002;



endmodule
`default_nettype wire
