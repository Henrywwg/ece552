/*
    CS/ECE 552 FALL '22
    Homework #2, Problem 3

    A multi-bit ALU module (defaults to 16-bit). It is designed to choose
    the correct operation to perform on 2 multi-bit numbers from rotate
    left, shift left, shift right arithmetic, shift right logical, add,
    or, xor, & and.  Upon doing this, it should output the multi-bit result
    of the operation, as well as drive the output signals Zero and Overflow
    (OFL).
*/
module alu (InA, InB, Cin, Oper, invA, invB, sign, Out, Zero, Ofl, Cout);

    parameter OPERAND_WIDTH = 16;    
    parameter NUM_OPERATIONS = 3;
       
    input  [OPERAND_WIDTH -1:0] InA ; // Input operand A
    input  [OPERAND_WIDTH -1:0] InB ; // Input operand B
    input                       Cin ; // Carry in
    input  [NUM_OPERATIONS-1:0] Oper; // Operation type
    input                       invA; // Signal to invert A
    input                       invB; // Signal to invert B
    input                       sign; // Signal for signed operation
    output [OPERAND_WIDTH -1:0] Out ; // Result of computation
    output                      Ofl ; // Signal if overflow occured
    output                      Zero; // Signal if Out is 0
    output                      Cout; // Carry out bit (added for Execute stage of processor).

    /* YOUR CODE HERE */

    //////////////////////
    // Internal Signals //
    //////////////////////
    wire [OPERAND_WIDTH -1:0]A;
    wire [OPERAND_WIDTH -1:0]B;
    wire [15:0]shift_result;
    wire [15:0]add_result;
    wire [OPERAND_WIDTH -1:0]temp_out;
    wire temp_sign;
    wire sign_neg;
    wire sign_pos;
    wire temp_ofl;

    assign A = invA ? ~InA : InA;
    assign B = invB ? ~InB : InB;

    /////////////
    // Shifter //
    /////////////
    shifter shift0(.In(A), .ShAmt(B[3:0]), .Oper(Oper[1:0]), .Out(shift_result));

    ///////////
    // Adder //
    ///////////
    cla_16b adder(.a(A), .b(B), .c_in(Cin), .sum(add_result), .c_out(Cout));
    nand2 nand0(.in1(A[OPERAND_WIDTH -1]), .in2(B[OPERAND_WIDTH -1]), .out(temp_sign));
    not1 not0(.in1(temp_sign), .out(sign_neg));
    nor2 nor0(.in1(A[OPERAND_WIDTH -1]), .in2(B[OPERAND_WIDTH -1]), .out(sign_pos));
    assign temp_ofl = sign_neg ? (add_result[OPERAND_WIDTH -1] ? 0 : 1) : (sign_pos ? add_result[OPERAND_WIDTH -1] : 0);

    ///////////////////
    // Determine Out //
    ///////////////////
    assign temp_out = Oper[1] ? (Oper[0] ? (A^B) : (A|B)) : (Oper[0] ? (A&B) : (add_result));
    assign Out = Oper[2] ? temp_out : shift_result;

    ///////////////////
    // Determine Ofl //
    ///////////////////
    assign Ofl = sign ? temp_ofl : Cout;

    ///////////////
    // Zero flag //
    ///////////////
    assign Zero = (|Out) ? 0 : 1;

    
endmodule
