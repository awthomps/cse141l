/**
 * Author: Andrei Thompson
 * Team: Janis and Alex
 * Written on 3/4/2014
 * Lab 3 
 */
`include "/projects/lab3/cse141l/core/definitions.v"


//TODO: add a reset capability to this module

/*
typedef struct packed {
	controls_s if_id;
	controls_s id_ex;
	controls_s ex_m;
	controls_s m_wb;
} controls_buddle_s;
*/
module signal_controller( input clk,
input controls_s newControl,

output controls_s if_id_o,
output controls_s id_ex_o,
output controls_s ex_m_o,
output controls_s m_wb_o
);

controls_buddle_s array;
//for now, don't use if_id


always_comb
begin
	//if_id_o = array.if_id;
	id_ex_o = array.id_ex;
	ex_m_o = array.ex_m;
	m_wb_o = array.m_wb;
end



always_ff @ (posedge clk)
begin
	//pass down the pipeline
	//array.if_id <= newControl;
	//array.id_ex <= array.if_id;
	array.id_ex <= newControl;
	array.ex_m <= array.id_ex;
	array.m_wb <= array.ex_m;
end

endmodule