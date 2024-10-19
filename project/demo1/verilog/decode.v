/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (instruction, immSrc, ALUJmp, MemWrt InvA, InvB, 
   Cin, sign, brType, BSrc , 0ext, ALUOpr, RegDst, RegSrc, RegWrt);

   //Inputs
   wire input clk;
   wire input rst;
   wire input [15:0]instruction;
   

   //Outputs (all control signals)
   //PC sigs
   wire output immSrc;
   wire output ALUJump;
   //ALU sigs
   wire output InvA;
   wire output InvB;
   wire output Cin;
   wire output sign;
   wire output brType;
   wire output 0ext;
<<<<<<< HEAD

   wire output [2:0]Oper;
   wire output [1:0]RegDst;

=======
   wire output RegDst;
>>>>>>> 21f0afb760ea9c5ea9f50e88c78f17200bd46fd2
   wire output RegSrc;
   wire output RegWrt;
   wire output [1:0]BSrc;
   wire output [2:0]Oper;
   //Memory sigs
   wire output MemWrt;




   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
      wire [4:0]opcode = instruction[15:11];
      wire [2:0]ALUOpr;

   ///////////////////
   //CONTROL SIGNALS//
   ///////////////////
      
      /////////////////////////////////////
      // PROGRAM COUNTER CONTROL SIGNALS //
      /////////////////////////////////////
         //immSrc
         //pick between 11bit sign extend (1) or 8bit extended (0)
         //instructions using immSrc
         //8 bit ext: BEQ, BNEZ, BLTZ, BGEZ, LBI, SLBI, JR, JALR
         //11 bit ext: J, JAL
         //if opcode is 001x0, then we need to use sign extend 11 bit,
         //otherwise we can default to 8 bit extended
         assign immSrc = ({opcode[4:2], opcode[0]} == 4'b0010);

         //ALUJump
         //all branches and JR
         //all br share opcode[4:2] so check for that
         assign ALUJump = ({opcode[4:2], opcode[0]} == 4'b0011);

      ////////////////////////////
      // MEMORY CONTROL SIGNALS //
      ////////////////////////////
         //Check first 3 bits, and then check the lower 2 bits of the opcode
         //are the same using nots and xor.
         assign MemWrt = (opcode[4:2] == 3'b100) & ~(^opcode[1:0]);

      //Only for SLBI ANDNI XORI is 0ext needed, default sign extend
      assign 0ext = (opcode[4:1] == 4'b0101) | (opcode[4:1] == 5'b10010);

      //just pass the lower 2 bits of opcode
      assign brType = opcode[1:0];

      //////////////////////////////
      // REGISTER CONTROL SIGNALS //
      //////////////////////////////
         //Regwrt when not doing branch, J or JR, mem writes or NOPs, HALT or siic
         assign RegWrt = (opcode[4:2] == 2'b011) | (opcode[4:1] == 4'b0001) | 
                        (opcode[4:1] == 4'b0000) | (opcode[4:2] == 2'b001) | (opcode[4:2] == 5'b10000);

         // JAL and JALR have fixed $7 value - input 3
         // all comparison and Reg to Reg ALU math uses input 2
         // immediate instructions use input 1
         // default rest to use input 0
         assign regDst = opcode[4:1] == 4'b0011                   ? 2'b11 :
                        (((opcode[4:3] == 2'b11) & ^opcode[2:0])  ? 2'b10  :
                        ((opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101) | ({opcode[4:2], opcode[0]} == 4'b1001) 
                                                                  ? 2'b01 :
                                                                    2'b00));
         
         //LBI and BTR pull directly from B input (and SLBI)
         //JAL JALR, pull from PC adder logic
         //LD is only instruction grabbing from mem
         //Default rest to pulling from ALU
         assign regSrc = (opcode[5:1] == 4'b1100) | (opcode == 5'b10010)? 2'b11 : (
                        (opcode == 5'b10001)                           ? 2'b01 : (
                        (opcode[4:1 == 4'b0010])                       ? 2'b00 : 
                                                                        2'b10));

      /////////////////////////
      // ALU CONTROL SIGNALS //
      /////////////////////////
         assign ALUOpr = (opcode[4:1] == 4'b1101) ?  {opcode[0], instruction[1:0]} : 
                         (opcode[4:2] == 3'b101)  ?  {1'b0, instruction[1:0]} : 
                         (opcode[4:2] == 3'b010)  ?  {1'b1, instruction[1:0]} : 
                                                      3'b100;

      //just pass the lower 2 bits of opcode if the instruction is a branch instruction along with a third bit denoting that the inst was a branch.
      assign brType = (opcode[4:2] == 3'b011) ? {1'b1, opcode[1:0]} : {1'b0, opcode[1:0]};

      assign Oper = ALUOpr[2] ? ((ALUOpr[1] ? (ALUOpr[0] ? 3'b101 : 3'b111) : 3'b100)) : ((ALUOpr[1:0] == 2'b10) ? 3'b000 : ALUOpr);

         //Invert Rs
         assign InvA = ({opcode, instruction[1:0]} == 7'b1101101) | (opcode == 5'b01001) || (opcode[4:1] == 4'b1110);
         
         assign InvB = (opcode[3:0] == 4'b1011) ? (opcode[4] ? (&instruction[1:0] ? 1 : 0) : 1) : 0;
         
         // if we are invA or B. Since Cin not used for ands, is not a problem
         // if Cin asserted during ANDN insts
         assign Cin = invA | invB;

         //Rt (00) used when opcodes starts 1101 opcode or 111
         //TODO bsrc

   /////////////////////////
   //SIGN and ZERO EXTENDS//
   /////////////////////////

   ////////////////////////
   //INSTANTIATE REG FILE//
   ////////////////////////  
   //SLBI ANDNI XORI
   assign 0ext = (opcode[4:1] == 4'b0101) | (opcode[4:1] == 5'b10010);

   assign ALUOpr = (opcode[4:1] == 4'b1101) ? {opcode[0], instruction[1:0]} : 0;
   assign Oper = ALUOpr[2] ? ((ALUOpr[1] ? (ALUOpr[0] ? 3'b101 : 3'b111) : 3'b100)) : ((ALUOpr[1:0] == 2'b10) ? 3'b000 : ALUOpr);

   

endmodule
`default_nettype wire
