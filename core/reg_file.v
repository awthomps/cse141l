// A register file with asynchronous read and synchronous write
module reg_file #(parameter addr_width_p = 6)
                (input clk
                ,input [addr_width_p-1:0] rs_addr_i
                ,input [addr_width_p-1:0] rd_addr_i
                ,input wen_i
                ,input [31:0] write_data_i
                ,output logic [31:0] rs_val_o
                ,output logic [31:0] rd_val_o
                );

logic [31:0] RF [2**addr_width_p-1:0];

assign rs_val_o = RF [rs_addr_i];
assign rd_val_o = RF [rd_addr_i];

always_ff @ (posedge clk)
  begin
    if (wen_i)
      RF [rd_addr_i] <= write_data_i;
  end

endmodule

