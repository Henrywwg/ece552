/*
   CS/ECE 552 Spring '22
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.

*/
`default_nettype none
module fetch (clk, rst, jumpPC, incrPC, PCsrc, instruction_out, DUMP, 
   dst1, valid1, valid2, instruction_in_X, squash, unaligned_error_in, 
   unaligned_error_out, mem_stall);
   
   //////////////
   //    IO    //
   //////////////
      //Module Inputs
         input wire        clk;
         input wire        rst;
         input wire        PCsrc;
         input wire [15:0] jumpPC;
         input wire mem_stall;
         
         input wire [2:0]  dst1;   //Destination register from decode Jjjj
         input wire        valid1;      //Is this a valid register
         input wire        valid2;
         input wire [15:0] instruction_in_X;
         input wire        squash;
         input wire        unaligned_error_in;
         output wire        unaligned_error_out;


      //Module Outputs
         output wire [15:0]incrPC;
         output wire [15:0]instruction_out;
         output wire       DUMP;
         
         wire [2:0]  rs;
         wire [2:0]  rt;
         wire        rs_v;
         wire        rt_v;

   ///////////////////////
   // INTERNAL SIGNALS  //
   ///////////////////////
      //PC signals
      wire [15:0] PC_new;
      wire [15:0] PC_q;
      wire [15:0] PC_p2;
      reg         HALT;

      //hazard detection signals
      wire [3:0]  RAW, RAW_X;

      //Internal instruction signals
      wire [15:0]instruction;
      wire [15:0]instruction_to_pipe;
      wire [4:0]opcode;
      wire halt_fetch;
      
      wire [3:0]jumping; 
      wire [2:0]branching;
      wire [4:0]HALTing;
	   wire bubble;
      wire [2:0]dst2;
      wire memory_error;
      wire actual_halt;
      wire i_cache_hit;
      wire cache_done;

      assign opcode = instruction_to_pipe[15:11];

      assign rs = instruction[10:8];
      assign rt = instruction[7:5];
   

   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////

      assign PC_new = PCsrc ? jumpPC : PC_p2;         
      //DFFs hold value of PC
      dff iPC[15:0](.q(PC_q), .d(halt_fetch & ~squash ? PC_q : PC_new), .clk(clk), .rst(rst));

      //memory2c is Instruction Memory and outputs instruction pointed to by PC
      //stallmem iIM(.data_out(instruction), .data_in(16'h0000), .addr(PC_q), .enable(~(HALT & ~bubble)), .wr(1'b0), 
      //            .createdump(1'b0), .clk(clk), .rst(rst), .err(memory_error));

      stallmem iIM(.DataOut(instruction), .Done(cache_done), .Stall(), .CacheHit(i_cache_hit), .err(memory_error), 
                   .Addr(PC_q), .DataIn(16'h0000), .Rd(1'b1), .Wr(1'b0), .createdump(1'b0), .clk(clk), .rst(rst));

   ///////////
   // LOGIC // 
   ///////////
      //Keep PC_p2 as PC_q + 2
      cla_16b #(16) PCadder(.sum(PC_p2), .a(PC_q), .b(16'h0002), .c_in(1'b0), .c_out());

   ///////////////////////////////////////////////////////////////
   // Create HALT Singal to stop processor and dump Data Memory //
   ///////////////////////////////////////////////////////////////
      always @(opcode, squash, unaligned_error_in) begin
         HALT = 1'b0;
         case({instruction_to_pipe[15:11], squash})
            7'b0000000: 
               HALT = 1'b1;

            default: 
               HALT = 1'b0;
         endcase
      end

      assign DUMP = HALTing[4];
//(instruction_out[15:13] != 3'b011) & (instruction_in_X[15:13] != 3'b011)
   //////////
   // PIPE //
   //////////
      dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(mem_stall ? instruction_out : (squash ? 16'h0800 : instruction_to_pipe)), .q(instruction_out));
      dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(mem_stall ? incrPC : PC_p2), .q(incrPC));


   //////////////////
   // RAW DETECTOR //
   // (HOLMES, S)  //
   //////////////////
      //Parse source registers//
      assign rs_v = ((instruction[15:13] != 3'b000) & ({instruction[15:13], instruction[11]} != 4'b0010));             //indicates validity of register (is this actually a source)

      assign rt_v = (instruction[15:12] == 4'b1101) | (instruction[15:13] == 3'b111) | (instruction[15:11] == 5'b10000) | (instruction[15:11] == 5'b10011);

      //Let Sherlock find the hazards.
      RAW_detective iHolmes(.clk(clk), .rst(rst), .src1(rs), .src2(rt), .src_cnt({rt_v, rs_v}), 
                              .dst1(dst1), .valid1(valid1), .RAW(RAW[0]));

      RAW_detective iSherlock(.clk(clk), .rst(rst), .src1(rs), .src2(rt), .src_cnt({rt_v, rs_v}), 
                              .dst1(dst2), .valid1(valid2), .RAW(RAW_X[0]));

	   dest_parser iPawrseX(.instruction(instruction_in_X), .dest_reg(dst2));
      
      //If a br/raw/jmp is in progress, then opcode will default to 0x0800
      //making these both evaluate to 0. When br/raw/jmp has cleared the
      //pipe, then opcode is reassigned to the actual instruction.
      assign jumping[0] = (opcode[4:2] == 3'b001);
      assign branching[0] = (opcode[4:2] == 3'b011);

      //Do we need to output NOPs?
      assign bubble = (|RAW[0]) | (|RAW_X[0]) | (jumping[1])  | jumping[2] | jumping[3] | ~cache_done;

      //Adjust instruction to process
      assign instruction_to_pipe = (bubble | squash)? 16'h0800 : instruction;
      
      //halt pc/fetching one clock after a HALT, or until we are done bubbling
      assign halt_fetch = ((HALTing[1] | bubble)  & ~jumping[2]) | mem_stall;

      assign HALTing[0] = HALT | unaligned_error_in;
      dff jump_cnt[2:0](.clk(clk), .rst(rst), .d(mem_stall ? jumping[3:1] : jumping[2:0]), .q(jumping[3:1]));
      dff br_cnt[1:0](.clk(clk), .rst(rst), .d(mem_stall ? branching[2:1] : branching[1:0]), .q(branching[2:1]));
      dff HALT_cnt[3:0](.clk(clk), .rst(rst), .d(mem_stall ? HALTing[4:1] : ((HALTing[3:0] & {4{~squash}}))), .q(HALTing[4:1]));
      dff unaligned_error_dff(.clk(clk), .rst(rst), .d(mem_stall ? unaligned_error_out : memory_error), .q(unaligned_error_out));
     
      assign actual_halt = HALTing[4] | unaligned_error_in;

endmodule
`default_nettype wire
