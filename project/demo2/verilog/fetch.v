/*
   CS/ECE 552 Spring '22
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.

*/
`default_nettype none
module fetch (clk, rst, jumpPC, incrPC, PCsrc, instruction_out, DUMP, 
   dst1, valid1, valid2);
   
   //////////////
   //    IO    //
   //////////////
      //Module Inputs
         input wire clk;
         input wire rst;
         input wire PCsrc;
         input wire [15:0]jumpPC;
         
         input wire [2:0]dst1;   //Destination register from decode 
         input wire valid1;      //Is this a valid register
         input wire valid2;


      //Module Outputs
         output wire [15:0]incrPC;
         output wire [15:0]instruction_out;
         output wire DUMP;
         wire [2:0]rs;
         wire [2:0]rt;
         wire rs_v;
         wire rt_v;

   ///////////////////////
   // INTERNAL SIGNALS  //
   ///////////////////////
      //PC signals
      wire [15:0]PC_new;
      wire [15:0]PC_q;
      wire [15:0]PC_p2;
      reg HALT;

      //hazard detection signals
      wire [3:0]RAW, RAW_X;

      //Silly signals
      wire halt_halt1, halt_halt2, halt_halt3, halt_halt4, HALT_ACTUAL;

      //Internal instruction signals
      wire [15:0]instruction;
      wire [15:0]instruction_to_pipe, instruction_in_X;
      wire [4:0]opcode;
      wire halt_fetch, raw_jmp_hlt, jmp_enroute, jmp_out, jmp_out_delayed, jmp_out_delayed_delayed, jmp_out_delayed_delayed_delayed;
      
      wire [3:0]jumping; 
      wire [2:0]branching;
      wire [4:0]HALTing;
	   wire bubble;
      wire [2:0]dst2;

      assign opcode = instruction_to_pipe[15:11];

      assign rs = instruction[10:8];
      assign rt = instruction[7:5];
   

   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////

      assign PC_new = PCsrc ? jumpPC : PC_p2;         
      //DFFs hold value of PC
      dff iPC[15:0](.q(PC_q), .d(halt_fetch ? PC_q : PC_new), .clk(clk), .rst(rst));

      //memory2c is Instruction Memory and outputs instruction pointed to by PC
      memory2c iIM(.data_out(instruction), .data_in(16'h0000), .addr(PC_q), .enable(~(HALT & ~bubble)), .wr(1'b0), 
                  .createdump(1'b0), .clk(clk), .rst(rst));

   ///////////
   // LOGIC // 
   ///////////
      //Keep PC_p2 as PC_q + 2
      cla_16b #(16) PCadder(.sum(PC_p2), .a(PC_q), .b(16'h0002), .c_in(1'b0), .c_out());

   ///////////////////////////////////////////////////////////////
   // Create HALT Singal to stop processor and dump Data Memory //
   ///////////////////////////////////////////////////////////////
      always @(opcode) begin
         HALT = 1'b0;
         case(instruction_to_pipe[15:11])
            5'b00000: 
               HALT = 1'b1;
            default: 
               HALT = 1'b0;
         endcase
      end

      assign DUMP = HALTing[4];

   //////////
   // PIPE //
   //////////
      dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction_to_pipe), .q(instruction_out));
      dff instruction_pipe_inX[15:0](.clk(clk), .rst(rst), .d(instruction_out), .q(instruction_in_X));
      dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(PC_p2), .q(incrPC));


   //////////////////
   // RAW DETECTOR //
   // (HOLMES, S)  //
   //////////////////
      //Parse source registers//
      assign rs_v = ((instruction[15:13] != 3'b000) & ({instruction[15:13], instruction[11]} != 4'b0010));             //indicates validity of register (is this actually a source)

      assign rt_v = (instruction[15:12] == 4'b1101) | (instruction[15:13] == 3'b111) | (instruction[15:11] == 5'b10000) | (instruction[15:11] == 5'b10001);

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
      assign bubble = (|RAW) | (|RAW_X[2:0]) | (jumping[1]) | branching[1] | branching[2]  | jumping[2] | jumping[3];

      //Adjust instruction to process
      assign instruction_to_pipe = bubble ? 16'h0800 : instruction;
      
      //halt pc/fetching one clock after a HALT, or until we are done bubbling
      assign halt_fetch = (HALTing[1] | bubble)  & ~((jumping[2] | (branching[2] & PCsrc)));

      assign HALTing[0] = HALT;
      dff jump_cnt[2:0](.clk(clk), .rst(rst), .d(jumping[2:0]), .q(jumping[3:1]));
      dff br_cnt[1:0](.clk(clk), .rst(rst), .d(branching[1:0]), .q(branching[2:1]));
      dff RAW_cnt[2:0](.clk(clk), .rst(rst), .d(RAW[2:0]), .q(RAW[3:1]));
      dff RAWX_cnt[2:0](.clk(clk), .rst(rst), .d(RAW_X[2:0]), .q(RAW_X[3:1]));
      dff HALT_cnt[3:0](.clk(clk), .rst(rst), .d(HALTing[3:0]), .q(HALTing[4:1]));
     


endmodule
`default_nettype wire
