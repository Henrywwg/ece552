/*
   CS/ECE 552 Spring '22
  
   Filename        : execute.v
   Description     : This is the overall module for the execute stage of the processor.
*/
`default_nettype none
module execute (PC, Oper, A, RegData, Inst4, Inst7, Inst10, SLBI, BSrc, InvA, InvB, Cin, Sign, ImmSrc, TkBrch, ALUJmp, SF, ZF, OF, CF, ALUrslt, newPC);

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
   input wire Sign; // Control signal for signed instructions.
   input wire ImmSrc; // Control signal to choose between Inst7 and Inst10 for branch immediate.
   input wire TkBrch, ALUJmp; // Control signals to decide next PC value.
   output wire SF, ZF, OF, CF; // Signed, Zero, Overflow, and Carry Flags for Branch Conditions.
   output wire [15:0] ALUrslt; // Result from ALU operation.
   output wire [15:0] newPC; // PC for next instruction.

   wire [15:0] B; // B input to ALU. Will be assigned via Mux.
   wire [15:0] ImmBrnch; // Mux output that feeds into PC and Imm adder for branch destination.
   wire [15:0] tempPC; // Result of PC + Imm for branches.

   //////////////////
   // B select Mux //
   //////////////////
   assign B = BSrc[1] ? (BSrc[0] ? SLBI : Inst7) : (BSrc[0] ? Inst4 : RegData);

   ///////////////////////
   // ALU instantiation //
   ///////////////////////
   alu ExecuteALU(.InA(A), .InB(B), .Cin(Cin), .Oper(ALUOper), .invA(InvA), .invB(InvB), .sign(Sign), .Out(ALUrslt), .Zero(ZF), .Ofl(OF), .Cout(CF));

   /////////////////////////////////
   // Branch Condition Evaluation //
   /////////////////////////////////


   ////////////////////////////////////
   // Branch destination calculation //
   ////////////////////////////////////
   assign ImmBrnch = ImmSrc ? Inst10 : Inst7;
   cla_16b #(16) PCadder(.sum(tempPC), .a(PC), .b(ImmBrnch), .c_in(1'b0));

   /////////////////////
   // Branching Muxes //
   /////////////////////
   assign newPC = ALUJmp ? ALUrslt : (TkBrch ? tempPC : PC);
   




   
endmodule
`default_nettype wire
