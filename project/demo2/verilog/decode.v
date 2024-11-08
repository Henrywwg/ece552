/*
   CS/ECE 552 Spring '22
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (clk, rst, err, instruction_in, instruction_out, write_reg, write_data,
   five_extend, eight_extend, eleven_extend, R1, R2, opcode, SLBI, RegWrt);

   input wire [15:0]instruction_in;
   output wire [15:0]instruction_out;

   //Inputs
   input wire clk;
   input wire rst;
   input wire RegWrt;
   input wire [2:0]write_reg;
   input wire [15:0]write_data;

   //Sign extend outputs
   output wire [15:0]five_extend, eight_extend, eleven_extend;

   //Register outputs
   output wire [15:0]R1, R2;

   //For execture stage
   output wire [4:0]opcode;
   output wire [15:0]SLBI;

   //err flag
   output wire err;

   //For posterities state
   wire [15:0]instruction;
   assign instruction = instruction_in;

   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
      wire [2:0]ALUOpr;
      wire zero_ext;

      assign opcode = instruction[15:11];
   ///////////////////
   //CONTROL SIGNALS//
   ///////////////////

      /////////////////////////
      // ALU CONTROL SIGNALS //
      /////////////////////////
         assign ALUOpr = (opcode[4:1] == 4'b1101) ?  {opcode[0], instruction[1:0]} : 
                         (opcode[4:2] == 3'b101)  ?  {1'b0, opcode[1:0]} : 
                         (opcode[4:2] == 3'b010)  ?  {1'b1, opcode[1:0]} : 3'b100;  // default is add

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

endmodule
`default_nettype wire
