`include "definitions.v"

//---- Controller ----//
module cl_decode (input instruction_s instruction_i

                 ,output logic is_load_op_o
                 ,output logic op_writes_rf_o
                 ,output logic is_store_op_o
                 ,output logic is_mem_op_o
                 ,output logic is_byte_op_o
                 );

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
    `kMOV,  `kJALR, `kLW,   `kLBU:
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

