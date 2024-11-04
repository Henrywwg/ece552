/*
    CS/ECE 552 FALL '22
    Homework #2, Problem 2
    
    A barrel shifter module.  It is designed to shift a number via rotate
    left, shift left, shift right arithmetic, or shift right logical based
    on the 'Oper' value that is passed in.  It uses these
    shifts to shift the value any number of bits.
 */
module shifter (In, ShAmt, Oper, Out);

    // declare constant for size of inputs, outputs, and # bits to shift
    parameter OPERAND_WIDTH = 16;
    parameter SHAMT_WIDTH   =  4;
    parameter NUM_OPERATIONS = 2;

    input  [OPERAND_WIDTH -1:0] In   ; // Input operand
    input  [SHAMT_WIDTH   -1:0] ShAmt; // Amount to shift/rotate
    input  [NUM_OPERATIONS-1:0] Oper ; // Operation type
    output [OPERAND_WIDTH -1:0] Out  ; // Result of shift/rotate

   /* YOUR CODE HERE */

   //////////////////////
   // Internal signals //
   //////////////////////
   wire [15:0]rotl_layer_0;
   wire [15:0]rotl_layer_1;
   wire [15:0]rotl_layer_2;
   wire [15:0]rotl_layer_3;

   wire [15:0]shiftl_layer_0;
   wire [15:0]shiftl_layer_1;
   wire [15:0]shiftl_layer_2;
   wire [15:0]shiftl_layer_3;

   wire [15:0]rotr_layer_0;
   wire [15:0]rotr_layer_1;
   wire [15:0]rotr_layer_2;
   wire [15:0]rotr_layer_3;

   wire [15:0]shiftrL_layer_0;
   wire [15:0]shiftrL_layer_1;
   wire [15:0]shiftrL_layer_2;
   wire [15:0]shiftrL_layer_3;
   
   /////////////////
   // Rotate Left //
   /////////////////
   assign rotl_layer_0 = ShAmt[0] ? {In[14:0], In[15]} : In;
   assign rotl_layer_1 = ShAmt[1] ? {rotl_layer_0[13:0], rotl_layer_0[15:14]} : rotl_layer_0;
   assign rotl_layer_2 = ShAmt[2] ? {rotl_layer_1[11:0], rotl_layer_1[15:12]} : rotl_layer_1;
   assign rotl_layer_3 = ShAmt[3] ? {rotl_layer_2[7:0], rotl_layer_2[15:8]} : rotl_layer_2;

   ////////////////
   // Shift Left //
   ////////////////
   assign shiftl_layer_0 = ShAmt[0] ? {In[14:0], 1'b0} : In;
   assign shiftl_layer_1 = ShAmt[1] ? {shiftl_layer_0[13:0], 2'b00} : shiftl_layer_0;
   assign shiftl_layer_2 = ShAmt[2] ? {shiftl_layer_1[11:0], 4'b0000} : shiftl_layer_1;
   assign shiftl_layer_3 = ShAmt[3] ? {shiftl_layer_2[7:0], 8'b00000000} : shiftl_layer_2;

   //////////////////
   // Rotate Right //
   //////////////////
   assign rotr_layer_0 = ShAmt[0] ? {In[0], In[15:1]} : In;
   assign rotr_layer_1 = ShAmt[1] ? {rotr_layer_0[1:0], rotr_layer_0[15:2]} : rotr_layer_0;
   assign rotr_layer_2 = ShAmt[2] ? {rotr_layer_1[3:0], rotr_layer_1[15:4]} : rotr_layer_1;
   assign rotr_layer_3 = ShAmt[3] ? {rotr_layer_2[7:0], rotr_layer_2[15:8]} : rotr_layer_2;

   /////////////////////////
   // Shift right Logical //
   /////////////////////////
   assign shiftrL_layer_0 = ShAmt[0] ? {1'b0, In[15:1]} : In;
   assign shiftrL_layer_1 = ShAmt[1] ? {2'b00, shiftrL_layer_0[15:2]} : shiftrL_layer_0;
   assign shiftrL_layer_2 = ShAmt[2] ? {4'b0000, shiftrL_layer_1[15:4]} : shiftrL_layer_1;
   assign shiftrL_layer_3 = ShAmt[3] ? {8'b00000000, shiftrL_layer_2[15:8]} : shiftrL_layer_2;

   ///////////////////////////////////
   // Choose between the operations //
   ///////////////////////////////////
   assign Out = Oper[1] ? (Oper[0] ? shiftrL_layer_3 : rotr_layer_3) : (Oper[0] ? shiftl_layer_3 : rotl_layer_3);
   
endmodule
