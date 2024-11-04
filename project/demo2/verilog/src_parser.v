`default_nettype none

/*
   CS/ECE 552 Spring '22
  
   Filename        : src_parser.v
   Description     : This module parses registers that may cause data dependencies.
   Author          : Henry Wysong-Grass
   Date            : 2024-11-04
   Tested?         : NO
*/
module src_parser(instruction, src_reg_val, src_valid);

    //The instruction to be parsed
    input [15:0]instruction;

    //The parsed register number
    output wire [2:0]src_reg;
    //Inst may not cause data depencies
    output wire src_valid;



    wire [2:0]src_1_mux_intermediate_1;
    wire [4:0]opcode;

    //Grab opcode for simplicity in comparisons
    assign opcode = instruction[15:11];

    assign src_valid = !((opcode[4:1] == 4'b0010) | (opcode[4:2] == 3'b000) | (opcode[4:2] == 3'b011));

    //Register sources (or equivalent dependency producer) can be found in instruction[7:5], [10:8] [4:2]
    //Default to 10:8 cause i'm lazy ;3
    assign src_1_mux_intermediate_1 =   (opcode[4:3] == 2'b11) &  (opcode != 5'b11000)      ? instruction[4:2] :
                                        (opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101)   ? instruction[7:5] : instruction[10:8];


    

endmodule

`default_nettype wire
