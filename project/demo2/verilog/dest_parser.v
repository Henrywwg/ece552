`default_nettype none

/*
   CS/ECE 552 Spring '22
  
   Filename        : dest_parser.v
   Description     : This module parses registers that may cause data dependencies.
   Author          : Henry Wysong-Grass
   Date            : 2024-11-04
   Tested?         : NO
*/
module dest_parser(instruction, dest_reg_val);

   //The instruction to be parsed
   input wire [15:0]instruction;
   input wire RegWrt;

   //The parsed register number
   output wire [2:0]dest_reg;
   //Inst may not cause data depencies
   output wire dest_valid;



   wire [2:0]dest_1_mux_intermediate_1;
   wire [4:0]opcode;

   //Grab opcode for simplicity in comparisons
   assign opcode = instruction[15:11];

   //assign dest_valid = !((opcode[4:1] == 4'b0010) | (opcode[4:2] == 3'b000) | (opcode[4:2] == 3'b011));
   //This logic was already written smh

   //Register sources (or equivalent dependency producer) can be found in instruction[7:5], [10:8] [4:2]
   //Default to 10:8 cause i'm lazy ;3
   assign dest_reg =   (opcode[4:3] == 2'b11) &  (opcode != 5'b11000)      ? instruction[4:2] :
                                       (opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101)   ? instruction[7:5] : instruction[10:8];


   

endmodule

`default_nettype wire
