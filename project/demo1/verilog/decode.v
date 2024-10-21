/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (clk, rst, err, instruction, write_reg, write_data, immSrc, ALUjump, MemWrt, InvA, InvB, Cin, sign, 
   brType, BSrc, Oper, RegDst, RegSrc, five_extend, eight_extend, eleven_extend, R1, R2, opcode, SLBI, mem_en);

   //Inputs
   input wire clk;
   input wire rst;
   input wire [15:0]instruction;
   input wire [2:0]write_reg;
   input wire [15:0]write_data;

   //Outputs (all control signals)
   //PC sigs
   output wire immSrc;
   output wire ALUjump;

   //ALU sigs
   output wire InvA;
   output wire InvB;
   output wire Cin;
   output wire sign;
   output wire [2:0]brType, Oper;
   output wire [1:0]BSrc;

   //Reg sigs
   output wire [1:0]RegDst, RegSrc;

   //Memory sigs
   output wire MemWrt;
   output wire mem_en;

   //Sign extend outputs
   output wire [15:0]five_extend, eight_extend, eleven_extend;

   //Register outputs
   output wire [15:0]R1, R2;

   //For execture stage
   output wire [4:0]opcode;
   output wire [15:0]SLBI;

   //err flag
   output wire err;


   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
      wire [2:0]ALUOpr;
      wire zero_ext;
      wire RegWrt;

      assign opcode = instruction[15:11];
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

         // ALUjump
         // all branches and JR
         // all br share opcode[4:2] so check for that
         assign ALUjump = ({opcode[4:2], opcode[0]} == 4'b0011);

      /////////////////////////
      // MEM CONTROL SIGNALS //
      /////////////////////////
         // Check first 3 bits, and then check the lower 2 bits of the opcode
         // are the same using nots and xor.
         assign MemWrt = ((opcode[4:2] == 3'b100) & (~^opcode[1:0]));
         assign mem_en = (opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10);


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
         assign RegDst = (opcode[4:1] == 4'b0011)                                ? 2'b11  : 
         ( ((opcode[4:3] == 2'b11) & |opcode[2:0] )                              ? 2'b10  :
          ((opcode == 5'b11000) | ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10)) ? 2'b01 : 2'b00));
         
         //LBI and BTR pull directly from B input (and SLBI)
         //JAL JALR, pull from PC adder logic
         //LD is only instruction grabbing from mem
         //Default rest to pulling from ALU
         assign RegSrc = (opcode == 5'b11000) |   (opcode == 5'b10010)        ? 2'b11 : 
                                                      ((opcode == 5'b10001)       ? 2'b01 : 
                          ((opcode [4:1] == 4'b0000) | (opcode[4:1] == 4'b0011)   ? 2'b00 : 2'b10));

      /////////////////////////
      // ALU CONTROL SIGNALS //
      /////////////////////////
         assign ALUOpr = (opcode[4:1] == 4'b1101) ?  {opcode[0], instruction[1:0]} : 
                         (opcode[4:2] == 3'b101)  ?  {1'b0, opcode[1:0]} : 
                         (opcode[4:2] == 3'b010)  ?  {1'b1, opcode[1:0]} : 3'b100;  // default is add

         assign Oper[2:0] = {3{(opcode[4:1] != 4'b0000)}} & (ALUOpr[2] ? ((ALUOpr[1] ? (ALUOpr[0] ? 3'b101 : 3'b111) : 3'b100)) : ALUOpr);

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

         //Rt (00) used when opcodes starts 1101 opcode or 111
         assign BSrc =  ((opcode[4:1] == 4'b1101) | (opcode[4:2] == 3'b111) 
                        | (opcode[4:1] == 4'b0000))                            ?  2'b00 : 
                        ((opcode[4:2] == 3'b010) | (opcode[4:2] == 3'b101)
                        | ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b10))   ?  2'b01 : 
                        ((opcode[4:0] == 5'b10010)                             ?  2'b11 : 2'b10));

         //just pass the lower 2 bits of opcode
         //Needs more bits
         assign brType = (opcode[4:2] == 3'b011) ? {1'b1, opcode[1:0]} : {3'b000};

         // sign is req for all operations where there is potential overflow
         // essentially all addition/subtraction operations except SCO
         // it's fine to assert at all time unless the instruction is SCO
         assign sign = (opcode != 5'b11111) & (opcode[4:1] != 4'b0000);

   /////////////////////////
   //SIGN and ZERO EXTENDS//
   /////////////////////////
      //Only for ANDNI XORI is zero_ext needed, default sign extend
      assign zero_ext = (opcode[4:1] == 4'b0101);

      //Assign extends based on value of zero_ext calculated above
      assign five_extend   = zero_ext ? {11'h000, instruction[4:0]}   : {{11{instruction[4]}}, instruction[4:0]};
      assign eight_extend  = zero_ext ? {8'h00, instruction[7:0]}     : {{8{instruction[7]}}, instruction[7:0]};
      
      //not dependent on value of zero_ext
      assign eleven_extend = {{5{instruction[10]}}, instruction[10:0]};

      //SLBI assignment
      assign SLBI = {R2[7:0], instruction[7:0]};

   ////////////////////////
   //INSTANTIATE REG FILE//
   ////////////////////////  
      regFile IregFile (.clk(clk), .rst(rst), .read1RegSel(instruction[10:8]), .read2RegSel(instruction[7:5]), 
                        .writeRegSel(write_reg), .writeData(write_data), .writeEn(RegWrt), .read1Data(R1), 
                        .read2Data(R2), .err(err));

endmodule
`default_nettype wire
