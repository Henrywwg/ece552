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

   // Decode wires //
   wire [15:0] instruction, write_data, R1, R2, five_extend, eight_extend, eleven_extend;
   wire [2:0] write_reg, brType, Oper, RegDst, RegSrc;
   wire [1:0] BSrc;
   wire immSrc, ALUJump, MemWrt InvA, InvB, Cin, sign, error_decode;

   // OR all the err ouputs for every sub-module and assign it as this
   // err output
   
   // As desribed in the homeworks, use the err signal to trap corner
   // cases that you think are illegal in your statemachines
   
   
   /* your code here -- should include instantiations of fetch, decode, execute, mem and wb modules */
   fetch

   decode iD (.clk(clk), .rst(rst), .error(error_decode), .instruction(instruction), 
   .write_reg(write_reg), .write_data(write_data), .immSrc(immSrc), .ALUJump(ALUJump), .MemWrt(MemWrt),
   .InvA(InvA), .InvB(InvB), .Cin(Cin), .sign(sign), .brType(brType), .BSrc(BSrc), .Oper(Oper), 
   .RegDst(RegDst), .RegSrc(RegSrc), .five_extend(five_extend), .eight_extend(eight_extend), 
   .eleven_extend(eleven_extend), .R1(R1), .R2(R2));
   
   
endmodule // proc
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :0:
