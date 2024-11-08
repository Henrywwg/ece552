/*
   CS/ECE 552 Spring '22
  
   Filename        : execute.v
   Description     : This is the overall module for the execute stage of the processor.
*/
`default_nettype none
module execute (instruction_in, instruction_out, PC, A, RegData, Inst4, Inst7, Inst10, SLBI, 
   Xcomp, newPC, opcode, Binput);

   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;

   input wire clk;
   input wire rst;
   input wire [4:0] opcode; // needed for certain logic
   input wire [15:0] PC; // Program counter already incrememnted used in branch related muxes.
   input wire [15:0] A; // A input to ALU from Read Data 1.
   input wire [15:0] RegData; // B input 0 from Read Data 2.
   input wire [15:0] Inst4; // B input 1 from Instruction bits [4:0].
   input wire [15:0] Inst7; // B input 2 from Instruction bits [7:0].
   input wire [15:0] Inst10; // Muxed into PC adder for branches from Instruction bits [10:0].
   input wire [15:0] SLBI; // B input 3 from lower 8 bits of Read Data 2 and Instruction for SLBI.

   output wire [15:0] Xcomp; // Result from EXECUTION stage.
   output wire [15:0] newPC; // PC for next instruction.
   output wire [15:0] Binput; // B input to ALU. Will be assigned via Mux.

   wire [15:0] ImmBrnch; // Mux output that feeds into PC and Imm adder for branch destination.
   wire [15:0] tempPC; // Result of PC + Imm for branches.
   wire [15:0] ALUrslt; // A placeholder for the result of the ALU operation
   wire SF, ZF, OF; // Signed, Zero, Overflow for Branch Conditions.
   wire TkBrch; // Signal determined by branching logic

   ////////////////////////////////////
   // Logic Brought Over From Decode //
   ////////////////////////////////////
   wire [1:0]BSrc;
   wire Cin;
   //ALU sigs
   wire InvA;
   wire InvB;
   wire sign;
   wire [2:0]brType, Oper;
   //Outputs (all control signals)
   //PC sigs
   wire immSrc;
   wire ALUjump;

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

   /////////////////////////////////////
   // PROGRAM COUNTER CONTROL SIGNALS //
   /////////////////////////////////////

      // ALUjump
      // all branches and JR
      // all br share opcode[4:2] so check for that
      assign ALUjump = ({opcode[4:2], opcode[0]} == 4'b0011);
   
      //immSrc
      //Pick between 11bit sign extend (1) or 8bit extended (0)
      //Instructions using immSrc
      //8 bit ext: BEQ, BNEZ, BLTZ, BGEZ, LBI, SLBI, JR, JALR
      //11 bit ext: J, JAL
      //If opcode is 001x0, then we need to use sign extend 11 bit,
      //otherwise we can default to 8 bit extended
      assign immSrc = ({opcode[4:2], opcode[0]} == 4'b0010);

   //Rt (00) used when opcodes starts 1101 opcode or 111
   assign BSrc =  ((opcode[4:1] == 4'b1101) | (opcode[4:2] == 3'b111) 
   | (opcode[4:1] == 4'b0000))                            ?  2'b00 : 
   ((opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101)
   | ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10))   ?  2'b01 : 
   ((opcode[4:0] == 5'b10010)                             ?  2'b11 : 2'b10));

   //////////////////
   // B select Mux //
   //////////////////
   assign Binput = (brType[2] | (opcode == 5'b11001)) ? 16'h0000 : (BSrc[1] ? (BSrc[0] ? SLBI : Inst7) : (BSrc[0] ? Inst4 : RegData));

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
   assign ImmBrnch = immSrc ? Inst10 : Inst7;
   cla_16b #(16) PCadder(.sum(tempPC), .a(PC), .b(ImmBrnch), .c_in(1'b0), .c_out());

   ////////////////////
   // Assign Outputs //
   ////////////////////
   assign newPC = ALUjump ? ALUrslt : (TkBrch ? tempPC : PC);
   assign Xcomp = result;

   //////////
   // Pipe //
   //////////
   dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction), .q(instruction_out));
   dff execute_comp[15:0](.clk(clk), .rst(rst), .d(Xcomp), .q(Xcomp_out));
   dff new_pc[15:0](.clk(clk), .rst(rst), .d(newPC), .q(newPC_out));
   dff B_input[15:0](.clk(clk), .rst(rst), .d(Binput), .q(Binput_out));
   


   ///////////////////
   // RAW DETECTION //
   ///////////////////
   dest_parser iParser(.instruction(), .dest_reg_val(), ..dest_valid());

endmodule
`default_nettype wire
