`timescale 1ns/ 1ps
/* CSE141L Lab 1: Tools of the Trade
 * File Name: register_file.v
 * Written by: Andrei Thompson
 * ID: A09597901
 * 1/14/2014
 */

//changed things in file to correspond to lab2 core.v so that core.v deos not
//have to be changed such as: variables and one parameter parameter to correspond
module reg_file#(parameter addr_width_p = 6, parameter W1 = 32)
//parameter W0 = 64, parameter W1 = 32)
(
	input clk,
	input wen_i,
	input [W1-1:0] write_data_i,
	input [addr_width_p-1:0] rs_addr_i,
	input [addr_width_p-1:0] rd_addr_i,
	
	output [W1-1:0] rs_val_o,
	output [W1-1:0] rd_val_o
);

	logic [W1-1:0] RF[2**addr_width_p-1:0];
	
	assign rs_val_o = RF[rs_addr_i];
	assign rd_val_o = RF[rd_addr_i];
	
	always_ff @(posedge clk)
		begin

			if(wen_i) RF[rd_addr_i] <= write_data_i;
		end
		
endmodule