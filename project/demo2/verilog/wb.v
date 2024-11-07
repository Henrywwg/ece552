/*
   CS/ECE 552 Spring '22
  
   Filename        : wb.v
   Description     : This is the module for the overall Write Back stage of the processor.
*/
`default_nettype none
module wb (instruction_in, RegSrc, PC, MemData, ALUData, RegData, WData, RegDst, Inst, WRegister);

   input wire [15:0]instruction_in;

   input wire [1:0] RegDst, RegSrc; // Control Signals for data and register selection.
   input wire [15:0] PC, MemData, ALUData, RegData; // 4 possible strings of data can get written to a register.
   input wire [15:0] Inst; // Take in full instruction and choose bits to select register destination depending on the instruction.

   output wire [15:0] WData; // Output data that gets written to a register.
   output wire [2:0] WRegister; // The register data gets written to.

   //////////////////////////////////////////////////
   // Mux logic to determine destination register. //
   //////////////////////////////////////////////////
   assign WRegister = RegDst[1] ? (RegDst[0] ? 3'b111 : Inst[4:2]) : (RegDst[0] ? Inst[10:8] : Inst[7:5]);

   //////////////////////////////////
   // Mux logic to determine data. //
   //////////////////////////////////
   assign WData = RegSrc[1] ? (RegSrc[0] ? RegData : ALUData) : (RegSrc[0] ? MemData : PC);

endmodule
`default_nettype wire
