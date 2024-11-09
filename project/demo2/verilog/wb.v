/*
   CS/ECE 552 Spring '22
  
   Filename        : wb.v
   Description     : This is the module for the overall Write Back stage of the processor.
*/
`default_nettype none
module wb (instruction_in, incrPC, MemData, ALUData, RegData, WData, WRegister);

   input wire [15:0] instruction_in;
   input wire [15:0] incrPC, MemData, ALUData, RegData; // 4 possible strings of data can get written to a register.

   output wire [15:0] WData; // Output data that gets written to a register.
   output wire [2:0] WRegister; // The register data gets written to.

   //Reg sigs
   wire [1:0]RegDst, RegSrc;

   wire [4:0]opcode;
   wire [15:0]instruction;
   assign instruction = instruction_in;
   assign opcode = instruction[15:11];

   //////////////////////////////
   // REGISTER CONTROL SIGNALS //
   //////////////////////////////
      //NOTE:  RegWrt is created in decode, passed through the pipe (for use with forwarding), 
      //       and passed from the MEM/WB pipe back into decode, hence it does not appear in this module.

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
                  
   //////////////////////////////////////////////////
   // Mux logic to determine destination register. //
   //////////////////////////////////////////////////
      assign WRegister = RegDst[1] ? (RegDst[0] ? 3'b111 : instruction[4:2]) : 
                                  (RegDst[0] ? instruction[10:8] : instruction[7:5]);

   //////////////////////////////////
   // Mux logic to determine data. //
   //////////////////////////////////
      assign WData = RegSrc[1] ? (RegSrc[0] ? RegData : ALUData) : (RegSrc[0] ? MemData : incrPC);

endmodule
`default_nettype wire
