/*
   CS/ECE 552 Spring '22
  
   Filename        : memory.v
   Description     : This module contains all components in the Memory stage of the 
                     processor.
   Author          : Henry Wysong-Grass
   Date            : 2024-10-09
   Tested?         : NO
*/
`default_nettype none
module memory (instruction_in, instruction_out, clk, rst, address, write_data, DUMP, read_data);
   //Module Inputs
   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;

   input wire clk;
   input wire rst;
   input wire [15:0]address;
   input wire [15:0]write_data;
   input wire DUMP;
   
   //Module Outputs
   output wire [15:0]read_data;

   //Memory sigs
   wire MemWrt;
   wire en;

   /////////////////////////
   // MEM CONTROL SIGNALS //
   /////////////////////////
      // Check first 3 bits, and then check the lower 2 bits of the opcode
      // are the same using nots and xor.
      assign MemWrt = ((opcode[4:2] == 3'b100) & (~^opcode[1:0]));
      assign en = (opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10);
   
   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////

   //memory2c is Memory and outputs values pointed to be address
   memory2c iIM(.data_out(read_data), .data_in(write_data), .addr(address), .enable(en), 
                .wr(MemWrt), .createdump(DUMP), .clk(clk), .rst(rst));


endmodule
`default_nettype wire
