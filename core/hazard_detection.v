/**
 * Author: Andrei Thompson
 * Team: Janis and Alex
 * Written on 3/5/2014
 * Lab 3 
 */


`include "/projects/lab3/cse141l/core/definitions.v"

module hazard_detection #(parameter reg_width =  6)
(
	
	input [reg_width-1:0] dec_op_src1_i,
	input [reg_width-1:0] dec_op_src2_i,
	
	input [reg_width-1:0] ex_op_dest_i,
	input [reg_width-1:0] m_op_dest_i,
	input [reg_width-1:0] wb_op_dest_i,
	
	input net_reg_write_cmd_i,
	
	output logic pipeline_stall_o,
	output logic IF_ID_stall_o,
	output logic ID_EX_stall_o,
	output logic EX_M_stall_o,
	output logic M_WB_stall_o
);




always_comb begin
	pipeline_stall_o = 1'b0;
	
	/*
	if(net_reg_write_cmd_i == 1'b1)
		pipeline_stall_o = 1'b1;
		*/
	
	if(dec_op_src1_i != 1'b0 &&
			(
				dec_op_src1_i == ex_op_dest_i ||
				dec_op_src1_i == m_op_dest_i ||
				dec_op_src1_i == wb_op_dest_i
			)
		)
		pipeline_stall_o = 1'b1;
		
	if(dec_op_src1_i != 1'b0 &&
			(
				dec_op_src1_i == ex_op_dest_i ||
				dec_op_src1_i == m_op_dest_i ||
				dec_op_src1_i == wb_op_dest_i
			)
		)
		pipeline_stall_o = 1'b1;
		
	IF_ID_stall_o = 1'b0;
	ID_EX_stall_o = 1'b0;
	EX_M_stall_o = 1'b0;
	M_WB_stall_o = 1'b0;
		
	if(pipeline_stall_o) begin
		IF_ID_stall_o = 1'b1;
		ID_EX_stall_o = 1'b1;
		EX_M_stall_o = 1'b1;
		M_WB_stall_o = 1'b1;
		end

end

endmodule
