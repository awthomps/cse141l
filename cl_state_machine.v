//`include "definitions.v"
`include "/home/andrei/Documents/Lab2a/cse141l/definitions.v"

module cl_state_machine(input instruction_s instruction_i
                       ,input state_e state_i
                       ,input exception_i
                       ,input net_PC_write_cmd_IDLE_i
                       ,input stall_i

                       ,output state_e state_o
                       );

// state_n, the next state in state machine
always_comb
  begin
    unique case (state_i)
              
      // Initial state on reset
      IDLE:
        begin
         // Change PC packet 
         if (net_PC_write_cmd_IDLE_i)   
            state_o = RUN;
          else
            state_o = IDLE;
        end

      RUN:
        unique casez (instruction_i)
                              
          `kDONE:
            state_o = IDLE;

          default:
            state_o = RUN;
                          
        endcase
             
      ERR:
        state_o = ERR;
              
      default:
        state_o = ERR;
    endcase

  // Finish current instruction before exception
  if (~stall_i && exception_i)
    state_o = ERR;
  
  end
 
endmodule
