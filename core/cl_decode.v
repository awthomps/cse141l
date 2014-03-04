//`include "definitions.v"
`include "/projects/lab3/cse141l/core/definitions.v"

//---- Controller ----//
module cl_decode (input instruction_s instruction_i
                 ,input logic clk

                 ,output logic is_load_op_o
                 ,output logic op_writes_rf_o
                 ,output logic is_store_op_o
                 ,output logic is_mem_op_o
                 ,output logic is_byte_op_o
					  ,output controls_s controls_o
                 );

//controls_s register
controls_s controls_r;

//we may have to have this controlled by something else as well
//(in case there is a stall or something)
always_ff @ (posedge clk)
begin
  controls_o <= controls_r;
end
  
always_comb
  //always done (already assigned in other always_comb blocks):
  begin
    controls_r.is_load_op_c = is_load_op_o;
    controls_r.op_writes_rf_c = op_writes_rf_o;
    controls_r.is_store_op_c = is_store_op_o;
    controls_r.is_mem_op_c = is_mem_op_o;
    controls_r.is_byte_op_c = is_byte_op_o;
    controls_r.instruction = instruction_i;
  end
  
always_comb
  //TODO: FILL IN YOUR CASES HERE
  unique casez (instruction_i)
    `kADDU, `kSUBU, `kSLLV, `kSRLV, `kSRAV,
    `kAND, `kOR, `kNOR, `kSLT, `kSLTU,
    `kMOV, `kBRLU, `kROR:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b1;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	end
//I am not so sure about this one (signal to
//indicate an end of program):
    `kBAR:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	 end
    `kWAIT:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = IDLE;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'b1;//not so sure about this anymore
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0; //assign PC_wen = (net_PC_write_cmd_IDLE || ~stall);
	 end
    `kBEQZ, `kBNEQZ, `kBGTZ:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b1; //this depends on values from register memory
		 controls_r.PC_wen_r = 1'b0;
	 end
	 // BLTZ to SMS1
	 `kBLTZ:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b1;
		 controls_r.PC_wen_r = 1'b0;
	 end
	 
	`kXOR:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b1;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	end
	
	`kJALR:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b1;
		 controls_r.PC_wen_r = 1'b0;
	end
	 
	`kLW:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	end
	
	`kLBU:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b1;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	end
	
	`kSW:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	end
	 
	 `kSB:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	 end
	 
	 `kSMS0:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b1;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	 end
	 
	 `kSMS1:
	 begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b1;
		 controls_r.state_r = 2'bXX;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'bX;
		 controls_r.jump_now = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
	 end
	 
	 
	 // end of controls for BLTZ to SMS1
	default:
	begin
		 controls_r.imem_wen = 1'b0;
		 controls_r.PC_wen_r = 1'b0;
		 controls_r.net_reg_write_cmd = 1'b0;
	    controls_r.rf_wen = 1'b0;
		 controls_r.state_r = 2'b00;
		 controls_r.exception_o = 1'b0;
		 controls_r.stall = 1'b0;
		 controls_r.net_PC_write_cmd_IDLE = 1'b0;
		 controls_r.jump_now = 1'b0;
	end
  //NOTE: im not sure what we will do for our default case
  endcase

// mem_to_reg signal, to determine whether instr 
// xfers data from dmem to rf 
always_comb
  unique casez (instruction_i)
    `kLW,`kLBU:
      is_load_op_o = 1'b1;
        
    default:
      is_load_op_o = 1'b0;
  endcase

// reg_write signal, to determine whether a register file write 
// is needed or not
always_comb
  unique casez (instruction_i)
    `kADDU, `kSUBU, `kSLLV, `kSRAV, `kSRLV,
    `kAND,  `kOR,   `kNOR,  `kSLT,  `kSLTU, 
    `kMOV,  `kJALR, `kLW,   `kLBU, `kBRLU, `kXOR, `kROR, //BRLU, XOR, ROR added
    `kSMS0, `kSMS1: //SMS0, SMS1 added
      op_writes_rf_o = 1'b1; 
    
    default:
      op_writes_rf_o = 1'b0;
  endcase
  
// is_mem_op_o signal, which indicates if the instruction is a memory operation 
always_comb       
  unique casez (instruction_i)
    `kLW, `kLBU, `kSW, `kSB:
      is_mem_op_o = 1'b1;
    
    default:
      is_mem_op_o = 1'b0;
  endcase

// is_store_op_o signal, which indicates if the instruction is a store
always_comb       
  unique casez (instruction_i)
    `kSW, `kSB:
      is_store_op_o = 1'b1;
    
    default:
      is_store_op_o = 1'b0;
  endcase

// byte_not_word_c, which indicates the data memory related instruction 
// is byte or word oriented
always_comb
  unique casez (instruction_i)
    `kLBU,`kSB:
      is_byte_op_o = 1'b1;
       
    default: 
      is_byte_op_o = 1'b0;
  endcase

endmodule

