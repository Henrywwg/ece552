/*
   CS/ECE 552 Spring '22
  
   Filename        : execute.v
   Description     : This is the overall module for the execute stage of the processor.
*/
`default_nettype none
module execute (clk, rst, instruction_in, instruction_out, incrPC, incrPC_out, A_reg, 
   RegData_reg, RegData_out, Xcomp_out, newPC, Binput_out, PCsrc, RegWrt_in, RegWrt_out, 
   WData, forward_A, forward_B, rs, rt, rs_v, rt_v, rt_out);

   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;

   input wire RegWrt_in;
   output wire RegWrt_out;
   input wire [15:0]WData;
   input wire [1:0]forward_A;
   input wire [1:0]forward_B;

   input wire clk;
   input wire rst;
   input wire [15:0] incrPC;
   input wire [15:0] A_reg;             // A input to ALU from Read Data 1.
   input wire [15:0] RegData_reg;       // B input 0 from Read Data 2.

   output wire PCsrc;               // IF branch or jump instruction set high
   output wire [15:0] Xcomp_out;    // Result from EXECUTION stage.
   output wire [15:0] newPC;        // PC for next instruction.
   output wire [15:0] incrPC_out;   // PC for next instruction.
   output wire [15:0] Binput_out;   // B input to ALU. Will be assigned via Mux.
   output wire [15:0] RegData_out;
   output wire [15:0] rt_out;
   
   //Forwarding signals
   output wire [2:0]rs;
   output wire [2:0]rt;

   output wire rs_v;
   output wire rt_v;

   //Signals for RAW and forwarding units
   //output wire rd;

   ////////////////////////////////////
   ///////// INTERNAL WIRES ///////////
   ////////////////////////////////////
      wire [15:0] ImmBrnch; // Mux output that feeds into PC and Imm adder for branch destination.
      wire [15:0] tempPC; // Result of PC + Imm for branches.
      wire [15:0] ALUrslt; // A placeholder for the result of the ALU operation
      wire [15:0] Xcomp; // Result from EXECUTION stage.
      wire [15:0] Binput; // B input to ALU. Will be assigned via Mux.
      wire SF, ZF, OF; // Signed, Zero, Overflow for Branch Conditions.
      wire TkBrch; // Signal determined by branching logic
      wire Cin, InvA, InvB, sign;
      wire zero_ext;
      wire immSrc;
      wire ALUjump;
      wire [1:0] BSrc;
      wire [2:0] ALUOpr;
      wire [2:0] brType;
      wire [2:0] Oper;
      wire [4:0] opcode;
      wire [15:0] instruction;
      wire [15:0] SLBI;
      wire [15:0] ext_5, ext_8, ext_11;

      wire [15:0] A, RegData;

   assign A =  (forward_A == 2'b01) ? WData : 
               ((forward_A == 2'b10) ? Xcomp_out : A_reg );

   assign RegData =  (forward_B == 2'b01) ? WData : 
                    ((forward_B == 2'b10) ? Xcomp_out : RegData_reg );

   //assign RegData = RegData_reg;

   assign instruction = instruction_in;
   assign opcode = instruction[15:11];



   /////////////////////////////////////
   // PROGRAM COUNTER CONTROL SIGNALS //
   /////////////////////////////////////

      // NEW SIGNAL
      assign PCsrc = TkBrch | ALUjump;

      // ALUjump
      // all branches and JR
      // all br share opcode[4:2] so check for that
      assign ALUjump = ({opcode[4:2], opcode[0]} == 4'b0011);
   
      //immSrc
      //If opcode is 001x0, then we need to use sign extend 11 bit,
      //otherwise we can default to 8 bit extended
      assign immSrc = ({opcode[4:2], opcode[0]} == 4'b0010);



   /////////////////////
   // CONTROL SIGNALS //
   /////////////////////
      /////////////////////////
      // ALU CONTROL SIGNALS //
      /////////////////////////
      assign ALUOpr = (opcode[4:1] == 4'b1101) ?  {opcode[0], instruction[1:0]} : 
      (opcode[4:2] == 3'b101)  ?  {1'b0, opcode[1:0]} : 
      (opcode[4:2] == 3'b010)  ?  {1'b1, opcode[1:0]} : 3'b100;  // default is add

      //Conditionally invert R1 
      // all instructions where "Rs" R1 must be negative
      // SUB & SUBI
      assign InvA =  ({opcode, instruction[1:0]} == 7'b1101101) | (opcode == 5'b01001);
            
      //Conditionally invert R2
      // all instructions where B inputs req bitwise NOT ~
      // ANDNI & ANDN
      // all conditional instructions that aren't branch or SCO (Rs - Rt)
      assign InvB =  ({opcode, instruction[1:0]} == 7'b1101111) | (opcode == 5'b01011)
                     | ((opcode[4:2] == 3'b111) & (~&opcode[1:0]));
      
      // We only need Cin when A is inverted for subtraction, InvB is for AND operations only
      assign Cin = InvA | InvB;

      assign Oper[2:0] = {3{(opcode[4:1] != 4'b0000)}} & (ALUOpr[2] ? ((ALUOpr[1] ? (ALUOpr[0] ? 3'b101 : 3'b111) : 3'b100)) : ALUOpr);

      //just pass the lower 2 bits of opcode
      assign brType = (opcode[4:2] == 3'b011) ? {1'b1, opcode[1:0]} : {3'b000};

      // sign is req for all operations where there is potential overflow
      // essentially all addition/subtraction operations except SCO
      // it's fine to assert at all time unless the instruction is SCO
      assign sign = (opcode != 5'b11111) & (opcode[4:1] != 4'b0000);

      ///////////////////////////
      // SIGN and ZERO EXTENDS //
      ///////////////////////////
      //Only for ANDNI XORI is zero_ext needed, default sign extend
      assign zero_ext = (opcode[4:1] == 4'b0101);

      //Assign extends based on value of zero_ext calculated above
      assign ext_5   = zero_ext ? {11'h000, instruction[4:0]}   : {{11{instruction[4]}}, instruction[4:0]};
      assign ext_8  = zero_ext ? {8'h00, instruction[7:0]}     : {{8{instruction[7]}}, instruction[7:0]};

      //Unconditionally sign extend this one
      assign ext_11 = {{5{instruction[10]}}, instruction[10:0]};

      //SLBI assignment
      assign SLBI = {A[7:0], instruction[7:0]};

      //Rt (00) used when opcodes starts 1101 opcode or 111
      assign BSrc =  ((opcode[4:1] == 4'b1101) | (opcode[4:2] == 3'b111) | (opcode[4:1] == 4'b0000))                          ?  2'b00 : 
                     ((opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101) | ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10))  ?  2'b01 : 
                     ((opcode[4:0] == 5'b10010)                                                                               ?  2'b11 : 2'b10));

      //////////////////
      // B select Mux //
      //////////////////
      assign Binput = (brType[2] | (opcode == 5'b11001)) ? 16'h0000 : (BSrc[1] ? (BSrc[0] ? SLBI : ext_8) : (BSrc[0] ? ext_5 : RegData));

   ///////////////////////
   // ALU instantiation //
   ///////////////////////
   alu ExecuteALU(.InA(A), .InB(Binput), .Cin(Cin), .Oper(Oper), .invA(InvA), .invB(InvB), 
                  .sign(sign), .Out(ALUrslt), .Zero(ZF), .Ofl(OF));
   assign SF = ALUrslt[15];

   /////////////////////////////////////////////////
   // Logic for Instructions that write to Rd 
   // based off the conditional result of the ALU
   /////////////////////////////////////////////////
   reg [15:0] result;
   always @(*) begin
		// Default to avoid latches
		result = 16'h0000;

        case(opcode)
            5'b11100: result = {{15{1'b0}}, ZF};
            5'b11101: result = OF ? (~SF ? 16'b1 : 16'b0) : {15'b0, SF};
            5'b11110: result = OF ? (~SF ? 16'b1 : 16'b0) : {15'b0, (SF | ZF)};
            5'b11111: result = {15'b0, OF};
            5'b11001: result = {ALUrslt[0], ALUrslt[1], ALUrslt[2], ALUrslt[3], ALUrslt[4], ALUrslt[5], 
               ALUrslt[6], ALUrslt[7], ALUrslt[8], ALUrslt[9], ALUrslt[10], ALUrslt[11], ALUrslt[12], ALUrslt[13], 
               ALUrslt[14], ALUrslt[15]};
            default: result = ALUrslt;
        endcase
        
   end

   /////////////////////////////////
   // Branch Condition Evaluation //
   /////////////////////////////////
   assign TkBrch = ({opcode[4:2], opcode[0]} == 4'b0010) | (brType[2] ? (brType[1] ? (brType[0] ? (~SF | ZF) : SF) : (brType[0] ? ~ZF : ZF)) : 1'b0);

   ////////////////////////////////////
   // Branch destination calculation //
   ////////////////////////////////////
   assign ImmBrnch = immSrc ? ext_11 : ext_8;
   cla_16b #(16) PCadder(.sum(tempPC), .a(incrPC), .b(ImmBrnch), .c_in(1'b0), .c_out());

   ////////////////////
   // Assign Outputs //
   ////////////////////
   assign newPC = ALUjump ? ALUrslt : (TkBrch ? tempPC : incrPC);
   assign Xcomp = result;

   //////////
   // Pipe //
   //////////
   dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction), .q(instruction_out));
   dff execute_comp[15:0](.clk(clk), .rst(rst), .d(Xcomp), .q(Xcomp_out));
   dff incrPC_pipe[15:0](.clk(clk), .rst(rst), .d(incrPC), .q(incrPC_out));
   dff B_input_pipe[15:0](.clk(clk), .rst(rst), .d((opcode == 5'b10011) ? RegData :  Binput), .q(Binput_out));
   dff write_data_pipe[15:0](.clk(clk), .rst(rst), .d(A), .q(RegData_out));
   dff RegWrt_pipe(.clk(clk), .rst(rst), .d(RegWrt_in), .q(RegWrt_out));
   
   dff rt_pipe[15:0](.clk(clk), .rst(rst), .d(RegData), .q(rt_out));


   ///////////////////
   // RAW DETECTION //
   ///////////////////
   //dest_parser iParser(.instruction(instruction), .dest_reg_val(rd));

   assign rs_v = ((instruction[15:13] != 3'b000) & ({instruction[15:13], instruction[11]} != 4'b0010));             //indicates validity of register (is this actually a source)

   assign rt_v = (instruction[15:12] == 4'b1101) | (instruction[15:13] == 3'b111);

   assign rs = instruction[10:8];
   assign rt = instruction[7:5];

endmodule
`default_nettype wire
