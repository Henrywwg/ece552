/*
   CS/ECE 552 Spring '22
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.
   Author          : Henry Wysong-Grass
   Date            : 2024-10-09
   Tested?         : NO
*/
`default_nettype none
module fetch (clk, rst, PC_new, DUMP, PC_p2, instruction);
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
   //PC_q stores current PC out and PC_p2 stores PC+2
   wire [15:0]PC_q;
   wire [4:0]opcode = instruction[15:11];

   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////
   //DFFs hold value of PC
   dff iPC[15:0](.q(PC_q), .d(HALT ? PC_q : PC_new), .clk(clk), .rst(rst));

   //memory2c is Instruction Memory and outputs instruction pointed to by PC
   memory2c iIM(.data_out(instruction), .data_in(16'h0000), .addr(PC_q), .enable(~HALT), .wr(1'b0), 
                .createdump(DUMP), .clk(clk), .rst(rst));

   ///////////
   // LOGIC //
   ///////////
   //Keep PC_p2 as PC_q + 2
   cla_16b #(16) PCadder(.sum(PC_p2), .a(PC_q), .b(16'h0002), .c_in(1'b0));

   reg HALT;
   always @(opcode) begin
      HALT = 1'b0;
      case(opcode)
         5'b00000: 
            HALT = 1'b1;
         default: 
            HALT = 1'b0;
      endcase
   end



endmodule
`default_nettype wire
