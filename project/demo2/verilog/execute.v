/*
   CS/ECE 552 Spring '22
  
   Filename        : execute.v
   Description     : This is the overall module for the execute stage of the processor.
*/
`default_nettype none
module execute (PC, Oper, A, RegData, Inst4, Inst7, Inst10, SLBI, BSrc, InvA, InvB, Cin, sign, immSrc, 
   ALUjump, Xcomp, newPC, opcode, Binput, brType);
   
   input wire [4:0] opcode; // needed for certain logic
   input wire [15:0] PC; // Program counter already incrememnted used in branch related muxes.
   input wire [2:0] Oper; // Operand for ALU operation.
   input wire [15:0] A; // A input to ALU from Read Data 1.
   input wire [15:0] RegData; // B input 0 from Read Data 2.
   input wire [15:0] Inst4; // B input 1 from Instruction bits [4:0].
   input wire [15:0] Inst7; // B input 2 from Instruction bits [7:0].
   input wire [15:0] Inst10; // Muxed into PC adder for branches from Instruction bits [10:0].
   input wire [15:0] SLBI; // B input 3 from lower 8 bits of Read Data 2 and Instruction for SLBI.
   input wire [1:0] BSrc; // Mux signal to determine B input.
   input wire InvA; // Control signal to determine whether to invert the A input.
   input wire InvB; // Control signal to determine whether to invert the B input.
   input wire Cin;
   input wire sign; // Control signal for signed instructions.
   input wire immSrc; // Control signal to choose between Inst7 and Inst10 for branch immediate.
   input wire ALUjump; // Control signals to decide next PC value.
   input wire [2:0]brType; //Branch type. Determines which control signals need to be checked.

   output wire [15:0] Xcomp; // Result from EXECUTION stage.
   output wire [15:0] newPC; // PC for next instruction.
   output wire [15:0] Binput; // B input to ALU. Will be assigned via Mux.

   wire [15:0] ImmBrnch; // Mux output that feeds into PC and Imm adder for branch destination.
   wire [15:0] tempPC; // Result of PC + Imm for branches.
   wire [15:0] ALUrslt; // A placeholder for the result of the ALU operation
   wire SF, ZF, OF; // Signed, Zero, Overflow for Branch Conditions.
   wire TkBrch; // Signal determined by branching logic

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
   
endmodule
`default_nettype wire
