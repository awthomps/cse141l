//`include "definitions.v"
`include "/home/janis/cse141l/definitions.v"

// This a simple memory module which simulates the cache for the core, with handshake features. 
// Handshake method description: the core sends a request for read or write (valid signal). 
// Memory responses in time (yumi signal).
// Memory sends the valid signal afterwards and the required data if any. 
// Finally memory waits for the core until it receives the yumi signal from the core. 
// Input and output structures are defined in definitions.v file
// IDLE means the memory is waiting for a request. TRANS means the memory 
// is during a data transaction and it is waiting for the core to response yumi.
module data_mem #(parameter addr_width_p = 12)
                (input  clk
                ,input  reset
                ,input  [$bits(mem_in_s)-1:0]  port_flat_i 
                ,input  [addr_width_p-1:0]     addr
                ,output [$bits(mem_out_s)-1:0] port_flat_o
                ); 

// Flatten and Unflatten structs
mem_in_s port_i;
mem_out_s port_o;
assign port_i = port_flat_i;
assign port_flat_o = port_o;

logic [7:0] mem [(2**addr_width_p)-1:0];

//Registers
logic wen_r;
logic [31:0] read_data_r;

enum logic{
    IDLE  = 1'b0,
    TRANS = 1'b1
} state_r;

always_ff @ (posedge clk)
  begin
    port_o.valid     <= 1'b0;
    port_o.read_data <= 32'bx;
    read_data_r      <= 32'bx;
    if (!reset)
      begin
        state_r      <= IDLE;
      end
    else 
        unique case (state_r)
          IDLE:
            if (port_i.valid) 
              begin        
                state_r        <= TRANS;
                port_o.valid <= 1'b1;
                wen_r   <= port_i.wen;
                if (port_i.wen)
                  begin
                    if (port_i.byte_not_word)
                      mem [addr] <= port_i.write_data[7:0];
                    else
                      {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]}<=port_i.write_data;
                  end
                else
                  begin   
                    if (port_i.byte_not_word)
                      begin
                        port_o.read_data <= {{24{1'b0}}, {mem[addr]}};
                        read_data_r      <= {{24{1'b0}}, {mem[addr]}};
                      end

                    else
                      begin
                        port_o.read_data <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
                        read_data_r      <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
                      end
                  end
              end
            else
             state_r <= IDLE;
          TRANS:
            if (port_i.yumi)
              begin
                state_r        <= IDLE;
              end
            else
              begin
                port_o.valid <= 1'b1;
                state_r      <= TRANS;
                wen_r        <= wen_r;
                read_data_r  <= read_data_r;
                if (!wen_r)
                  port_o.read_data <= read_data_r;
              end
          default:
            begin
              state_r <= IDLE;
            end
        endcase
  end

// Since there is no delay for this memory, as soon as it gets the valid signal from 
// the core memory responses yumi which means I recieved the signal, and data in store mode.
always_comb
  begin
    port_o.yumi = port_i.valid;
  end

endmodule
