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
   wire [15:0] write_data_reg, R1, jumpPC, read_data;
   wire [15:0] incrPC_F2D, incrPC_D2X, incrPC_X2M, incrPC_M2W;
   wire [15:0] inst_F2D, inst_D2X, inst_X2M, inst_M2W;
   wire [15:0] forward_A, forward_b;
   wire [15:0] R2_D2X, R2_X2M;
   wire [15:0] Xcomp_X2M, Xcomp_M2W;
   wire [15:0] Binput_X2M, Binput_M2W;
   wire [2:0] write_reg, rd, xm_rd, mwb_rd;
   wire createDump, PCsrc, regFileErr;
   wire RegWrt_D2X, RegWrt_X2M, RegWrt_mem;

   // As desribed in the homeworks, use the err signal to trap corner
   // cases that you think are illegal in your statemachines
   // OR all the err ouputs for every sub-module and assign it as this
   // err output
   always @(*) begin
	err = 1'b0;
		case(regFileErr)
			1'b1: err = 1'b1;
			default: err = 1'b0;
		endcase
	end
   
   /* your code here -- should include instantiations of fetch, decode, execute, mem and wb modules */
   fetch iIF (.clk(clk), .rst(rst), .jumpPC(jumpPC), .DUMP(createDump), .incrPC(incrPC_F2D), 
   .PCsrc(PCsrc), .instruction_out(inst_F2D), .dst1(rd), .valid1(RegWrt_D2X));

   decode iD (.clk(clk), .rst(rst), .err_out(regFileErr), .instruction_in(inst_F2D), 
   .instruction_out(inst_D2X), .incrPC(incrPC_F2D), .incrPC_out(incrPC_D2X), 
   .write_reg(write_reg), .write_data(write_data_reg), .RegWrt_in(RegWrt_mem), 
   .RegWrt_out(RegWrt_D2X), .RegWrt_pipeline(RegWrt_D2X),
   .R1_out(R1), .R2_out(R2_D2X), .rd(rd));

   execute iX (.clk(clk), .rst(rst), .instruction_in(inst_D2X), .instruction_out(inst_X2M), 
   .incrPC(incrPC_D2X), .incrPC_out(incrPC_X2M), .newPC(jumpPC), .A_reg(R1), 
   .RegData_reg(R2_D2X), .Xcomp_out(Xcomp_X2M), 
   .Binput_out(Binput_X2M), .RegData_out(R2_X2M), .PCsrc(PCsrc),
   .RegWrt_in(RegWrt_D2X), .RegWrt_out(RegWrt_X2M), .WData(write_data_reg), 
   .Forward_A(forward_A), .Forward_B(forward_B)
   .rs(rs), .rt(rt), .rs_v(rs_v), .rt_v(rt_v));

   memory iM (.clk(clk), .rst(rst), .instruction_in(inst_X2M), .instruction_out(inst_M2W), 
   .address(Xcomp_X2M), .write_data(R2_X2M), .DUMP(createDump),
   .incrPC(incrPC_X2M), .incrPC_out(incrPC_M2W), .Binput(Binput_X2M), .Binput_out(Binput_M2W), 
   .Xcomp(Xcomp_X2M), .Xcomp_out(Xcomp_M2W), .read_data_out(read_data)
   .RegWrt_in(RegWrt_X2M), .RegWrt_out(RegWrt_mem), .xm_rd(xm_rd));

   wb iWB (.incrPC(incrPC_M2W), .MemData(read_data), .ALUData(Xcomp_M2W), .RegData(Binput_M2W),
   .WData(write_data_reg), .instruction_in(inst_M2W), .WRegister(write_reg), .mwb_rd(mwb_rd));
   
   forward iFORWARD (.rs(rs), .rt(rt), .rs_v(rs_v), .rt_v(rt_v), 
   .xm_wr(RegWrt_X2M), .xm_rd(xm_rd), .mwb_wr(RegWrt_mem), .mwb_rd(mwb_rd),
   .forward_A(forward_A), .forward_b(forward_B));
   
endmodule // proc
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :0:
