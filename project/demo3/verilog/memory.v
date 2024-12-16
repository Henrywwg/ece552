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
module memory (instruction_in, instruction_out, clk, rst, address, write_data, DUMP, 
   read_data_out, incrPC, incrPC_out, Binput, Binput_out, Xcomp, Xcomp_out, RegWrt_in, 
   RegWrt_out, xm_rd, wb_rd, wb_rd_data, rt_in, unaligned_error_in, unaligned_error_out,
   mem_stall_out);
   //Module Inputs
   input wire [15:0]instruction_in;
   input wire [15:0]incrPC;
   input wire [15:0]Binput;
   input wire [15:0]Xcomp; 

   input wire [15:0]rt_in;
   input wire RegWrt_in;
   input wire [2:0]wb_rd;
   input wire [15:0]wb_rd_data;

   input wire clk;
   input wire rst;
   input wire [15:0]address;
   input wire [15:0]write_data;
   input wire DUMP;
   input wire        unaligned_error_in;
   output wire        unaligned_error_out;
   output wire mem_stall_out;
   wire mem_stall_out_pre;
   
   //Module Outputs
   output wire [15:0]incrPC_out;
   output wire [15:0]instruction_out;
   output wire [15:0]read_data_out;
   output wire [15:0]Binput_out; 
   output wire [15:0]Xcomp_out; 

   output wire RegWrt_out;
   output wire [2:0]xm_rd;
   

   //Memory sigs
   wire MemWrt;
   wire en;
   wire [15:0]forward_M;
   wire memory_error;
   wire cache_done;
   wire d_cache_hit;
   wire TENT_write;
   wire actual_hit;

   wire [4:0]opcode;
   wire [15:0]instruction;
   wire [15:0]read_data;
   assign instruction = instruction_in;
   assign opcode = instruction[15:11];

   //assign cache_missed = (en | MemWrt) & ~cache_done

   assign TENT_write = mem_stall_out & MemWrt;

   /////////////////////////
   // MEM CONTROL SIGNALS //
   /////////////////////////
      // Check first 3 bits, and then check the lower 2 bits of the opcode
      // are the same using nots and xor.
      assign MemWrt = ((opcode[4:2] == 3'b100) & (~^opcode[1:0]));
      assign en = (opcode[4:0] == 5'b10001); //(opcode[4:0] == 5'b10000) | (opcode[4:0] == 5'b10011);
      //(opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10);

   //////////////////////
   // FORWARDING LOGIC //
   //////////////////////

	assign forward_M = rt_in; //write_data;

   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////
   
   mem_system_sc#(1) iIM(.DataOut(read_data), .Done(cache_done), .Stall(mem_stall_out_pre), .CacheHit(d_cache_hit), .err(memory_error), 
                   .Addr(address), .DataIn(forward_M), .Rd(en), .Wr(MemWrt), .createdump(DUMP), .clk(clk), .rst(rst));

   assign mem_stall_out = mem_stall_out_pre & ~cache_done;

   dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(mem_stall_out ? 16'h0800 : instruction), .q(instruction_out));
   dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(mem_stall_out ? incrPC_out : incrPC), .q(incrPC_out));
   dff B_input[15:0](.clk(clk), .rst(rst), .d(mem_stall_out ? 16'h0000 : Binput), .q(Binput_out));
   dff execute_comp[15:0](.clk(clk), .rst(rst), .d(mem_stall_out ? 16'h0000 : Xcomp), .q(Xcomp_out));
   dff read_data_pipe[15:0](.clk(clk), .rst(rst), .d(mem_stall_out ? 16'h0000 : read_data), .q(read_data_out));
   dff RegWrt_pipe(.clk(clk), .rst(rst), .d(mem_stall_out ? 1'b0 : RegWrt_in), .q(RegWrt_out));
   dff unaligned_error_dff(.clk(clk), .rst(rst), .d(mem_stall_out ? 1'b0 : (unaligned_error_in | memory_error)), .q(unaligned_error_out));

   dest_parser iParser(.instruction(instruction), .dest_reg(xm_rd));

endmodule
`default_nettype wire
