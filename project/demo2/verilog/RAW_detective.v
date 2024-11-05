`default_nettype none

/*
 * Module works in conjuction with src_parser to find RAWs in the pipe
 * 
 * Henry Wysong-Grass
 */

module RAW_detective(clk, rst, src1, src2, src_cnt, dst1, valid1, dst2, valid2, dst3, valid3, RAW);

    input wire clk;
    input wire rst;

    input wire [2:0]src1;
    input wire [2:0]src2;
    input wire [1:0]src_cnt;


    input wire [2:0]dst1;
    input wire [2:0]dst2;
    input wire [2:0]dst3;
    input wire valid1;
    input wire valid2;
    input wire valid3;

    output wire RAW;

    //////////////////////
    // INTERNAL SIGNALS //
    //////////////////////
    wire RAW_int_1, RAW_int_2;

    assign RAW_int_1 = ((src1 == dst1) & valid1) | ((src1 == dst2) & valid2) | ((src1 == dst3) & valid3);
    assign RAW_int_2 = ((src2 == dst1) & valid1) | ((src2 == dst2) & valid2) | ((src2 == dst3) & valid3);

    assign RAW =    (src_cnt == 2'b01) ? RAW_int_1 :
                    (src_cnt == 2'b10) ? RAW_int_1 | RAW_int_2 : 1'b0;

endmodule

`default_nettype wire