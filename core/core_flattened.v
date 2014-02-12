`include "definitions.v"

// Flatten and unflatten structs
module core_flattened #(parameter imem_addr_width_p=-1 
                       ,net_ID_p = 10'b0000000001)
                       (input  clk
                       ,input  reset

                       ,input  [$bits(net_packet_s)-1:0] net_packet_flat_i
                       ,output [$bits(net_packet_s)-1:0] net_packet_flat_o
                  
                       ,input  [$bits(mem_out_s)-1:0] from_mem_flat_i
                       ,output [$bits(mem_in_s)-1:0]  to_mem_flat_o

                       ,output logic [mask_length_gp-1:0] barrier_o
                       ,output logic                      exception_o
                       ,output [$bits(debug_s)-1:0]       debug_flat_o
                       ,output logic [31:0]               data_mem_addr
                       );

core #(.imem_addr_width_p(imem_addr_width_p),.net_ID_p(net_ID_p)) core1
             (.clk(clk)
             ,.reset(reset)

             ,.net_packet_i(net_packet_flat_i)
             ,.net_packet_o(net_packet_flat_o)
                  
             ,.from_mem_i(from_mem_flat_i)
             ,.to_mem_o(to_mem_flat_o)

             ,.barrier_o(barrier_o)
             ,.exception_o(exception_o)
             ,.debug_o(debug_flat_o)
             ,.data_mem_addr(data_mem_addr)
             );

endmodule

