/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (instruction, immSrc, ALUJmp, MemWrt InvA, InvB, Cin, sign, brType, SSrc , 0ext, ALUOpr, RegDst, RegSrc, RegWrt);

   //Inputs
   wire input [15:0]instruction;
   
   //Outputs (all control signals)
   wire output immSrc;
   wire output ALUJump;
   wire output MemWrt;
   
   wire output InvA;
   wire output InvB;
   wire output Cin;
   wire output sign;

   wire output brType;
   wire output BSrc;
   wire output 0ext;
   wire output ALUOpr;

   wire output RegDst;
   wire output RegSrc;
   wire output RegWrt;
   wire output [2:0] Oper;


   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
   wire [4:0]opcode = instruction[15:11];

   ///////////////////
   //CONTROL SIGNALS//
   ///////////////////

   //immSrc
   //Pick between 11bit sign extend (1) or 8bit extended (0)
   //Instructions using immSrc
   //8 bit ext: BEQ, BNEZ, BLTZ, BGEZ, LBI, SLBI, JR, JALR
   //11 bit ext: J, JAL
   //If opcode is 001x0, then we need to use sign extend 11 bit,
   //otherwise we can default to 8 bit extended
   assign immSrc = ({opcode[4:2], opcode[0]} == 4'b0111);

   //ALUJump
   // all branches and JR
   // all br share opcode[4:2] so check for that
   assign ALUJump = (opcode[4:2] == 3'b011) || (opcode[4:2] == 3'b001);

   //Check first 3 bits, and then check the lower 2 bits of the opcode
   // are the same using nots and xor.
   assign MemWrt = (opcode[4:2] == 3'b100) & ~(^opcode[1:0]);


   //Invert Rs
   assign invA = ({opcode, instruction[1:0]} == 7'b1101101) | (opcode == 5'b01001) || (opcode[4:1] == 4'b1110);

   //Regwrt when not doing branch, J or JR, mem writes or NOPs, HALT or siic
   assign RegWrt = (opcode[4:2] == 2'b011) | (opcode[4:1] == 4'b0001) | (opcode[4:1] == 4'b0000) | opcode[4:2] == 2'b001 |MemWrt;

   //Cin if we are invA or B. Since Cin not used for ands, is not a problem
   // if Cin asserted during ANDN insts
   assign Cin = invA || invB;

   //SLBI ANDNI XORI
   assign 0ext = (opcode[4:1] == 4'b0101) | (opcode[4:1] == 5'b10010);

   assign sign (opcode == 5'b01000) | (opcode == 5'b01001) 
   | (opcode == 5'b10000) | (opcode == 5'b10001) | (opcode == 5'b10011) | (opcode == 5'b11011 ); 

endmodule
`default_nettype wire
