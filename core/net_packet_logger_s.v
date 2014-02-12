// MBT 1.30.2014
//
// Simple packet logger
//

`include "definitions.v"

module network_packet_s_logger
  #(parameter verbosity_p = 1)
   (input clk
    ,input reset // low true
    ,input net_packet_s net_packet_i
    ,input [31:0] cycle_counter_i
    ,input [mask_length_gp-1:0] barrier_OR_i
    );

   logic barrier_OR_r;

   always_ff @(posedge clk)
     barrier_OR_r <= barrier_OR_i;

   always @ (negedge clk)
     begin
        if (reset && barrier_OR_i !== barrier_OR_r)
          $display("{%8.8x} barrier OR changed from %8.8x to %8.8x"
                   , cycle_counter_i
                   , barrier_OR_r
                   , barrier_OR_i
                   );

        if (verbosity_p && net_packet_i.net_op != NULL)
          begin
             unique case (net_packet_i.net_op)
               INSTR:
                 $display ("{%8.8x} pkt <id %3.3x> IMEM[%4.4x] = %8.8x"
                           , cycle_counter_i
                           , net_packet_i.ID
                           , net_packet_i.net_addr[0+:imem_addr_width_gp]
                           , net_packet_i.net_data[0+:$bits(instruction_s)]
                           );
               REG:
                 $display ("{%8.8x} pkt <id %3.3x> REG[%4.4x]  = %8.8x"
                           , cycle_counter_i
                           , net_packet_i.ID
                           , net_packet_i.net_addr[0+:rs_imm_size_gp]
                           , net_packet_i.net_data
                           );
               BAR:
                 $display ("{%8.8x} pkt <id %3.3x> BM         = %8.8x"
                           , cycle_counter_i
                           , net_packet_i.ID
                           , net_packet_i.net_data[0+:mask_length_gp]
                           );

               PC:
                 $display ("{%8.8x} pkt <id %3.3x> PC         = %8.8x; BAR = %3.3x"
                           , cycle_counter_i
                           , net_packet_i.ID
                           , net_packet_i.net_addr[0+:imem_addr_width_gp]
                           , net_packet_i.net_data[0+:mask_length_gp]
                           );
               default:
                 $display ("{%8.8x} pkt <id %3.3x> unknown OP %1.1x, ADDR = %4.4x, DATA = %8.8x"
                           , cycle_counter_i
                           , net_packet_i.ID
                           , net_packet_i.net_op
                           , net_packet_i.net_addr
                           , net_packet_i.net_data
                           );
             endcase
          end
     end // always @ (negedge clk)
endmodule
