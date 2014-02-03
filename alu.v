//This is the ALU module of the core, op_code_e is defined in definitions.v file
`include "definitions.v"

module alu (input  [31:0] rd_i 
           ,input  [31:0] rs_i 
           ,input  instruction_s op_i
           ,output logic [31:0] result_o
           ,output logic jump_now_o);
			  
			  logic[4:0] n;
			  logic[31:0] lreg, rreg;
			  
always_comb
  begin
    jump_now_o = 1'bx;
    result_o   = 32'dx;
	 
	 n = rs_i[4:0];

    unique casez (op_i)
      `kADDU:  result_o   = rd_i +  rs_i;
      `kSUBU:  result_o   = rd_i -  rs_i;
      `kSLLV:  result_o   = rd_i << rs_i[4:0];
      `kSRAV:  result_o   = $signed (rd_i)   >>> rs_i[4:0];
      `kSRLV:  result_o   = $unsigned (rd_i) >>  rs_i[4:0]; 
      `kAND:   result_o   = rd_i & rs_i;
      `kOR:    result_o   = rd_i | rs_i;
      `kNOR:   result_o   = ~ (rd_i|rs_i);
      `kSLT:   result_o   = ($signed(rd_i)<$signed(rs_i))     ? 32'd1 : 32'd0;
      `kSLTU:  result_o   = ($unsigned(rd_i)<$unsigned(rs_i)) ? 32'd1 : 32'd0;
		`kBRLU:  result_o   = (lreg << n) | (rreg >> (32 - n));
      `kBEQZ:  jump_now_o = (rd_i==32'd0)                     ? 1'b1  : 1'b0;
      `kBNEQZ: jump_now_o = (rd_i!=32'd0)                     ? 1'b1  : 1'b0;
      `kBGTZ:  jump_now_o = ($signed(rd_i)>$signed(32'd0))    ? 1'b1  : 1'b0;
      `kBLTZ:  jump_now_o = ($signed(rd_i)<$signed(32'd0))    ? 1'b1  : 1'b0;
      
      `kMOV, `kLW, `kLBU, `kJALR, `kBAR:   
               result_o   = rs_i;
      `kSW, `kSB:    
               result_o   = rd_i;
      //`kDONE:
      
      default: 
        begin 
          result_o   = 32'dX; 
          jump_now_o = 1'bX; 
        end
    endcase
  end

endmodule 
