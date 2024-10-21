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
module memory (clk, rst, we, address, write_data, DUMP, read_data, en);
   //Module Inputs
   input wire clk;
   input wire rst;
   input wire we;
   input wire en;
   input wire [15:0]address;
   input wire [15:0]write_data;
   input wire DUMP;
   
   //Module Outputs
   output wire [15:0]read_data;


   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////

   //memory2c is Memory and outputs values pointed to be address
   memory2c iIM(.data_out(read_data), .data_in(write_data), .addr(address), .enable(en), 
                .wr(we), .createdump(DUMP), .clk(clk), .rst(rst));


endmodule
`default_nettype wire
