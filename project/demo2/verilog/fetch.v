/*
   CS/ECE 552 Spring '22
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.

*/
`default_nettype none
module fetch (clk, rst, jumpPC, incrPC, PCsrc, instruction_out, DUMP, 
   dst1, valid1);
   
   //////////////
   //    IO    //
   //////////////
      //Module Inputs
         input wire clk;
         input wire rst;
         input wire PCsrc;
         input wire [15:0]jumpPC;
         
         input wire [2:0]dst1;
         // input wire [2:0]dst2;
         // input wire [2:0]dst3;
         input wire valid1;
         // input wire valid2;
         // input wire valid3;


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
      wire RAW;

      //Silly signals
      wire halt_halt1, halt_halt2, halt_halt3, halt_halt4, HALT_ACTUAL;

      //Internal instruction signals
      wire [15:0]instruction;
      wire [15:0]instruction_to_pipe;
      wire [4:0]opcode;
      wire halt_fetch, raw_jmp_hlt, jmp_enroute, jmp_out, jmp_out_delayed, jmp_out_delayed_delayed, jmp_out_delayed_delayed_delayed;
      wire brstall[0:2];
      assign halt_fetch = HALT | raw_jmp_hlt; //_delayed;

      assign opcode = instruction[15:11];

      assign rs = instruction[10:8];
      assign rt = instruction[7:5];
   

   /////////////////////////////////
   // INSTANTIATE EXTERN. MODULES //
   /////////////////////////////////

      assign PC_new = PCsrc ? jumpPC : PC_p2;
      //DFFs hold value of PC
      dff iPC[15:0](.q(PC_q), .d(halt_fetch ? PC_q : PC_new), .clk(clk), .rst(rst));

      //memory2c is Instruction Memory and outputs instruction pointed to by PC
      memory2c iIM(.data_out(instruction), .data_in(16'h0000), .addr(PC_q), .enable(~HALT), .wr(1'b0), 
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
         case(opcode)
            5'b00000: 
               HALT = 1'b1;
            default: 
               HALT = 1'b0;
         endcase
      end

      assign DUMP = HALT_ACTUAL;

   //////////
   // PIPE //
   //////////
      dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction_to_pipe), .q(instruction_out));
      dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(PC_p2), .q(incrPC));

      dff jmp_imminent0(.clk(clk), .rst(rst), .d(jmp_enroute), .q(jmp_out));
      dff jmp_imminent2(.clk(clk), .rst(rst), .d(jmp_out), .q(jmp_out_delayed));
      
      dff br_stall1(.clk(clk), .rst(rst), .d(brstall[0]), .q(brstall[1]));
      dff br_stall2(.clk(clk), .rst(rst), .d(brstall[1]), .q(brstall[2]));


      dff HALT_halt1(.clk(clk), .rst(rst), .d(HALT), .q(halt_halt1));
      dff HALT_halt2(.clk(clk), .rst(rst), .d(halt_halt1), .q(halt_halt2));
      dff HALT_halt3(.clk(clk), .rst(rst), .d(halt_halt2), .q(halt_halt3));
      dff HALT_halt4(.clk(clk), .rst(rst), .d(halt_halt3), .q(halt_halt4));
      dff HALT_halt5(.clk(clk), .rst(rst), .d(halt_halt4), .q(HALT_ACTUAL));




   //////////////////
   // RAW DETECTOR //
   // (HOLMES, S)  //
   //////////////////
      //Parse source registers//
      assign rs_v = ((instruction[15:13] != 3'b000) & ({instruction[15:13], instruction[11]} != 4'b0010));             //indicates validity of register (is this actually a source)

      assign rt_v = (instruction[15:12] == 4'b1101) | (instruction[15:13] == 3'b111);

      //Let Sherlock find the hazards.
      RAW_detective iHolmes(.clk(clk), .rst(rst), .src1(rs), .src2(rt), .src_cnt({rt_v, rs_v}), 
                              .dst1(dst1), .valid1(valid1), .RAW(RAW));

      //Send bubble through pipe if there is a raw
      assign instruction_to_pipe = (RAW | jmp_out | jmp_out_delayed | brstall[1] | brstall[2]) ? 16'h0800 : instruction;


      //TODO: CORRECT SETTING OF PROGRAM IF STALLING PROCESSOR
      assign raw_jmp_hlt = (jmp_enroute | RAW | brstall[0]);
      assign jmp_enroute =  (opcode[4:2] == 3'b001) & ~RAW & ~jmp_out_delayed;
      assign brstall[0] =  (opcode[4:2] == 3'b011) & ~RAW & ~brstall[2];



endmodule
`default_nettype wire
