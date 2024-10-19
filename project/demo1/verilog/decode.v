/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (instruction, immSrc, ALUJmp, MemWrt InvA, InvB, Cin, sign, brType, SSrc , 0ext, ALUOpr, RegDst, RegSrc, RegWrt);

   //Inputs
   wire input instruction;
   
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
   assign MemWrt = (opcode[4:2] == 3'b100) && ~(^opcode[1:0]);

   assign invA = ;

   assign RegWrt = ;

   

endmodule
`default_nettype wire
