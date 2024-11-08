/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (clk, rst, err, instruction_in, instruction_out, write_reg, write_data, immSrc_out, ALUjump_out, MemWrt_out, InvA_out, InvB_out, Cin_out, sign_out, 
   brType_out, BSrc_out, Oper_out, RegDst_out, RegSrc_out, RegWrt_out, five_extend_out, eight_extend_out, eleven_extend_out, R1_out, R2_out, opcode_out, SLBI_out,
   mem_en_out, PC_in, PC_out);

   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;

   //Inputs
   input wire clk;
   input wire rst;
   
   input wire [2:0]write_reg;
   input wire [15:0]write_data;

   //Outputs (all control signals)
   //PC sigs
   wire immSrc;
   output wire immSrc_out;
   wire ALUjump;
   output wire ALUjump_out;
   input wire [15:0]PC_in;
   output wire [15:0]PC_out;

   //ALU sigs
   wire InvA;
   output wire InvA_out;
   wire InvB_out;
   output wire InvB_out;
   wire Cin;
   output wire Cin_out;
   wire sign;
   output wire sign_out;
   wire [2:0]brType, Oper;
   output wire [2:0]brType_out, Oper_out;
   wire [1:0]BSrc;
   output wire [1:0]BSrc_out;

   //Reg sigs
   wire [1:0]RegDst, RegSrc;
   output wire [1:0]RegDst_out, RegSrc_out;
   wire RegWrt;
   output wire RegWrt_out;

   //Memory sigs
   wire MemWrt;
   output wire MemWrt_out;
   wire mem_en;
   output wire mem_en_out;

   //Sign extend outputs
   wire [15:0]five_extend, eight_extend, eleven_extend;
   output wire [15:0]five_extend_out, eight_extend_out, eleven_extend_out;

   //Register outputs
   wire [15:0]R1, R2; 
   output wire [15:0]R1_out, R2_out;

   //For execture stage
   wire [4:0]opcode;
   output wire [4:0]opcode_out;
   wire [15:0]SLBI;
   output wire [15:0]SLBI_out;

   //err flag
   wire err;
   output wire err_out;

   //For posterities state
   wire [15:0]instruction;
   assign instruction = instruction_in;

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
          ((opcode == 5'b11000) | ((opcode[4:2] == 3'b100) & (opcode[1:0] != 2'b01)) ? 2'b01 : 2'b00));
         
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
      assign SLBI = {R1[7:0], instruction[7:0]};

   ////////////////////////
   //INSTANTIATE REG FILE//
   ////////////////////////  
      regFile IregFile (.clk(clk), .rst(rst), .read1RegSel(instruction[10:8]), .read2RegSel(instruction[7:5]), 
                        .writeRegSel(write_reg), .writeData(write_data), .writeEn(RegWrt), .read1Data(R1), 
                        .read2Data(R2), .err(err));

   //////////
   // Pipe //
   //////////
   dff instruction_pipe[15:0](.clk(clk), .rst(rst), .d(instruction), .q(instruction_out));
   dff immSrc(.clk(clk), .rst(rst), .d(immSrc), .q(immSrc_out));
   dff ALUjump(.clk(clk), .rst(rst), .d(ALUjump), .q(ALUjump_out));
   dff InvertA(.clk(clk), .rst(rst), .d(InvA), .q(InvA_out));
   dff InvertB(.clk(clk), .rst(rst), .d(InvB), .q(InvB_out));
   dff Carry(.clk(clk), .rst(rst), .d(Cin), .q(Cin_out));
   dff Sign(.clk(clk), .rst(rst), .d(sign), .q(sign_out));
   dff branch[2:0](.clk(clk), .rst(rst), .d(brType), .q(brType_out));
   dff Operand[2:0](.clk(clk), .rst(rst), .d(Oper), .q(Oper_out));
   dff BSource[1:0](.clk(clk), .rst(rst), .d(BSrc), .q(BSrc_out));
   dff RD[1:0](.clk(clk), .rst(rst), .d(RegDst), .q(RegDst_out));
   dff RS[1:0](.clk(clk), .rst(rst), .d(RegSrc), .q(RegSrc_out));
   dff RW[1:0](.clk(clk), .rst(rst), .d(RegWrt), .q(RegWrt_out));
   dff Mem_write(.clk(clk), .rst(rst), .d(MemWrt), .q(MemWrt_out));
   dff mem_en(.clk(clk), .rst(rst), .d(mem_en), .q(mem_en_out));
   dff five[15:0](.clk(clk), .rst(rst), .d(five_extend), .q(five_extend_out));
   dff eight[15:0](.clk(clk), .rst(rst), .d(eight_extend), .q(eight_extend_out));
   dff eleven[15:0](.clk(clk), .rst(rst), .d(eleven_extend), .q(eleven_extend_out));
   dff reg1[15:0](.clk(clk), .rst(rst), .d(R1_extend), .q(R1_out));
   dff reg2[15:0](.clk(clk), .rst(rst), .d(R2_extend), .q(R2_out));
   dff op[4:0](.clk(clk), .rst(rst), .d(opcode), .q(opcode_out));
   dff slbi[15:0](.clk(clk), .rst(rst), .d(SLBI), .q(SLBI_out));
   dff error(.clk(clk), .rst(rst), .d(err), .q(err_out));
   dff PC_pipe[15:0](.clk(clk), .rst(rst), .d(PC_in), .q(PC_out));

endmodule
`default_nettype wire
