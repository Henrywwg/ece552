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


   ///////////////////
   // RAW DETECTION //
   ///////////////////
   dest_parser iParser(.instruction(), .dest_reg_val(), ..dest_valid());

endmodule
`default_nettype wire
