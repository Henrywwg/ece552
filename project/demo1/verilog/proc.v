/* $Author: sinclair $ */
/* $LastChangedDate: 2020-02-09 17:03:45 -0600 (Sun, 09 Feb 2020) $ */
/* $Rev: 46 $ */
`default_nettype none
module proc (/*AUTOARG*/
   // Outputs
   err, 
   // Inputs
   clk, rst
   );

   input wire clk;
   input wire rst;

   output reg err;

   // None of the above lines can be modified

   /// wires ///
   wire [15:0] instruction, write_data, R1, R2, five_extend, eight_extend, eleven_extend, 
               newPC, incrPC, SLBI, Binput, Xcomp, read_data;
   wire [4:0] opcode;
   wire [2:0] write_reg, brType, Oper, RegDst, RegSrc;
   wire [1:0] BSrc;
   wire immSrc, ALUjump, MemWrt, InvA, InvB, Cin, sign, error_decode, createDump;

   // As desribed in the homeworks, use the err signal to trap corner
   // cases that you think are illegal in your statemachines
   // OR all the err ouputs for every sub-module and assign it as this
   // err output
   always @(*) begin
        err = error_decode;
   end
   
   /* your code here -- should include instantiations of fetch, decode, execute, mem and wb modules */
   fetch iIF (.clk(clk), .rst(rst), .PC_new(newPC), .DUMP(createDump), .PC_p2(incrPC), .instruction(instruction));

   decode iD (.clk(clk), .rst(rst), .err(error_decode), .instruction(instruction), 
   .write_reg(write_reg), .write_data(write_data), .immSrc(immSrc), .ALUJump(ALUjump), .MemWrt(MemWrt),
   .InvA(InvA), .InvB(InvB), .Cin(Cin), .sign(sign), .brType(brType), .BSrc(BSrc), .Oper(Oper), 
   .RegDst(RegDst), .RegSrc(RegSrc), .five_extend(five_extend), .eight_extend(eight_extend), 
   .eleven_extend(eleven_extend), .R1(R1), .R2(R2), .opcode(opcode), .SLBI(SLBI));

   execute iX (.PC(incrPC), .Oper(Oper), .A(R1), .RegData(R2), .Inst4(five_extend), .Inst7(eight_extend), 
               .Inst10(eleven_extend), .SLBI(SLBI), .BSrc(BSrc), .InvA(InvA), .InvB(InvB), .Cin(Cin), 
               .sign(sign), .immSrc(immSrc), .ALUjump(ALUjump), .Xcomp(Xcomp), .newPC(newPC), 
               .opcode(opcode), .Binput(Binput));

   memory iM (.clk(clk), .rst(rst), .we(MemWrt), .address(Xcomp), .write_data(R2), 
              .DUMP(createDump), .readData(read_data));

   wb iWB (.RegSrc(RegSrc), .PC(incrPC), .MemData(read_data), .ALUData(Xcomp), .RegData(Binput),
           .WData(write_data), .RegDst(RegDst), .Inst(instruction), .WRegister(write_reg));
   
   
endmodule // proc
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :0:
