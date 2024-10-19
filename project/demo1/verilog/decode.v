/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (clk, rst, error, instruction, write_reg, write_data, immSrc, ALUJump, MemWrt InvA, InvB, Cin, sign, brType, BSrc, Oper, RegDst, RegSrc, five_extend, eight_extend, eleven_extend
               Rs, Rt);

   //Inputs
   wire input clk;
   wire input rst;
   wire input [15:0]instruction;
   wire input [2:0]write_reg;
   wire input [15:0]write_data;

   //Outputs (all control signals)
   //PC sigs
   wire output immSrc;
   wire output ALUJump;

   //ALU sigs
   wire output InvA;
   wire output InvB;
   wire output Cin;
   wire output sign;
   wire output [2:0]brType;
   wire output [1:0]BSrc;

   //Reg sigs
   wire output RegDst;
   wire output RegSrc;
   wire output [2:0] Oper;

   //Memory sig
   wire output MemWrt;

   //Sign extend outputs
   wire output [15:0]five_extend;
   wire output [15:0]eight_extend;
   wire output [15:0]eleven_extend;

   //Register outputs
   wire output [15:0]Rt;
   wire output [15:0]Rs;

   //Error flag
   wire output error;


   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
      wire [4:0]opcode = instruction[15:11];
      wire [2:0]ALUOpr;
      wire 0ext;
      wire [2:0]ALUOpr;
      wire RegWrt;

   ///////////////////
   //CONTROL SIGNALS//
   ///////////////////
      /////////////////////////////////////
      // PROGRAM COUNTER CONTROL SIGNALS //
      /////////////////////////////////////
         //immSrc
         //Pick between 11bit sign extend (1) or 8bit extended (0)
         //Instructions using immSrc
         //8 bit ext: BEQ, BNEZ, BLTZ, BGEZ, LBI, SLBI, JR, JALR
         //11 bit ext: J, JAL
         //If opcode is 001x0, then we need to use sign extend 11 bit,
         //otherwise we can default to 8 bit extended
         assign immSrc = ({opcode[4:2], opcode[0]} == 4'b0010);

   //ALUJump
   // all branches and JR
   // all br share opcode[4:2] so check for that
      assign ALUJump = ({opcode[4:2], opcode[0]} == 4'b0011);

      //Check first 3 bits, and then check the lower 2 bits of the opcode
      // are the same using nots and xor.
      assign MemWrt = (opcode[4:2] == 3'b100) & ~(^opcode[1:0]);

      //just pass the lower 2 bits of opcode
      //Needs more bits
      assign brType = opcode[4:2] == 3'b011 ? {1'b1, opcode[1:0]} : {1'b0, opcode[1:0]};

      //////////////////////////////
      // REGISTER CONTROL SIGNALS //
      //////////////////////////////
         //Regwrt when not doing branch, J or JR, mem writes or NOPs, HALT or siic
         assign RegWrt = ~((opcode[4:2] == 3'b011) | (opcode[4:1] == 4'b0001) | 
                        (opcode[4:1] == 4'b0000) | (opcode[4:1] == 4'b0010) | (opcode[4:0] == 5'b10000));

         // JAL and JALR have fixed $7 value - input 3
         // all comparison and Reg to Reg ALU math uses input 2
         // immediate instructions use input 1
         // default rest to use input 0
         assign regDst = opcode[4:1] == 4'b0011                    ? 2'b11 :
                           ( ((opcode[4:3] == 2'b11) & |opcode[2:0] ) | opcode == 5'b11100? 2'b10  :
                        ((opcode == 5'b11000) | (opcode == 5'b10010) | (opcode == 5'b10011) ? 2'b01 : 2'b00));
         
         //LBI and BTR pull directly from B input (and SLBI)
         //JAL JALR, pull from PC adder logic
         //LD is only instruction grabbing from mem
         //Default rest to pulling from ALU
         assign regSrc = (opcode[4:1] == 4'b1100) |   (opcode == 5'b10010)       ? 2'b11 : (
                                                      (opcode == 5'b10001)       ? 2'b01 : (
                                                      (opcode[4:1 == 4'b0011])   ? 2'b00 : 
                                                                                   2'b10));

      /////////////////////////
      // ALU CONTROL SIGNALS //
      /////////////////////////
         assign ALUOpr = (opcode[4:1] == 4'b1101) ?  {opcode[0], instruction[1:0]} : 
                         (opcode[4:2] == 3'b101)  ?  {1'b0, opcode[1:0]} : 
                         (opcode[4:2] == 3'b010)  ?  {1'b1, opcode[1:0]} : 
                                                      3'b100;

         assign Oper = ALUOpr[2] ? ((ALUOpr[1] ? (ALUOpr[0] ? 3'b101 : 3'b111) : 3'b100)) : ALUOpr;


         //Conditionally invert Rs
         assign InvA =  ({opcode, instruction[1:0]} == 7'b1101101) | (opcode == 5'b01001) | (opcode[4:1] == 4'b1110);
         
         //Conditionally invert Rt
         assign InvB =  ({opcode, instruction[1:0]} == 7'b1101111) | (opcode == 5'b01011) | (opcode == 5'b11110);
         

         // if we are invA or B. Since Cin not used for ands it is not a problem
         // if Cin is asserted during ANDN insts
         assign Cin = InvA | InvB;

         //Rt (00) used when opcodes starts 1101 opcode or 111
         assign BSrc =  ((opcode[4:1] == 4'b1101) | (opcode[4:2] == 3'b111))  ?  2'b00 : (
                        (opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101)|
                        ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10))      ?  2'b01 : (
                        (opcode[4:0] == 5'b10010)                             ?  2'b11 : 
                                                                                 2'b10));


         //Only for SLBI ANDNI XORI is 0ext needed, default sign extend
         assign 0ext = (opcode[4:1] == 4'b0101);

         assign sign (opcode[4:2] == 3'b011);



   /////////////////////////
   //SIGN and ZERO EXTENDS//
   /////////////////////////
      //Assign extends based on value of 0ext calculated above
      assign five_extend   = 0ext ? {11'h000, instruction[4:0]}   : {{11{instruction[4]}}, instruction[4:0]};
      assign eight_extend  = 0ext ? {8'h00, instruction[7:0]}     : {{8{instruction[7]}}, instruction[7:0]};
      
      //not dependent on value of 0ext
      assign eleven_extend = {{5{instruction[10]}}, instruction[10:0]};

   ////////////////////////
   //INSTANTIATE REG FILE//
   ////////////////////////  
      regFile IregFile( .clk(clk), .rst(rst), .read1RegSel(instruction[10:8]), .read2RegSel(instruction[7:5]), 
                        .writeRegSel(write_reg), .writeData(write_data), .writeEn(RegWrt), .read1Data(Rs), 
                        .read2Data(Rt), .err(error));

endmodule
`default_nettype wire
