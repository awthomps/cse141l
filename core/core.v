//`include "definitions.v"
`include "/projects/lab3/cse141l/core/definitions.v"

module core #(parameter imem_addr_width_p=10
                       ,net_ID_p = 10'b0000000001)
             (input  clk
             ,input  reset

             ,input  net_packet_s net_packet_i
             ,output net_packet_s net_packet_o

             ,input  mem_out_s from_mem_i
             ,output mem_in_s  to_mem_o

             ,output logic [mask_length_gp-1:0] barrier_o
             ,output logic                      exception_o
             ,output debug_s                    debug_o
             ,output logic [31:0]               data_mem_addr
             );

//---- Adresses and Data ----//
// Ins. memory address signals
logic [imem_addr_width_p-1:0] PC_r, PC_n,
                              pc_plus1, imem_addr,
                              imm_jump_add;
// Ins. memory output
instruction_s instruction, imem_out, instruction_r;

// Result of ALU, Register file outputs, Data memory output data
logic [31:0] alu_result, rs_val_or_zero, rd_val_or_zero, rs_val, rd_val;

// Reg. File address
logic [($bits(instruction.rs_imm))-1:0] rd_addr;

// Data for Reg. File signals
logic [31:0] rf_wd;

//---- Control signals ----//
// ALU output to determin whether to jump or not
logic jump_now;

// controller output signals
logic is_load_op_c,  op_writes_rf_c, valid_to_mem_c,
      is_store_op_c, is_mem_op_c,    PC_wen,
      is_byte_op_c,  PC_wen_r;

// Handshak protocol signals for memory
logic yumi_to_mem_c;

// Final signals after network interfere
logic imem_wen, rf_wen;

// Network operation signals
logic net_ID_match,      net_PC_write_cmd,  net_imem_write_cmd,
      net_reg_write_cmd, net_bar_write_cmd, net_PC_write_cmd_IDLE;

// Memory stages and stall signals
logic [1:0] mem_stage_r, mem_stage_n;
logic stall, stall_non_mem;

// Exception signal
logic exception_n;

// State machine signals
state_e state_r,state_n;

//---- network and barrier signals ----//
instruction_s net_instruction;
logic [mask_length_gp-1:0] barrier_r,      barrier_n,
                           barrier_mask_r, barrier_mask_n;

//---- Connection to external modules ----//

// Suppress warnings
assign net_packet_o = net_packet_i;

// Data_mem
assign to_mem_o = '{write_data    : rs_val_or_zero
                   ,valid         : valid_to_mem_c
                   ,wen           : is_store_op_c
                   ,byte_not_word : is_byte_op_c
                   ,yumi          : yumi_to_mem_c
                   };
assign data_mem_addr = alu_result;

// DEBUG Struct
assign debug_o = {PC_r, instruction, state_r, barrier_mask_r, barrier_r};

// Insruction memory
instr_mem #(.addr_width_p(imem_addr_width_p)) imem
           (.clk(clk)
           ,.addr_i(imem_addr)
           ,.instruction_i(net_instruction)
           ,.wen_i(imem_wen)
           ,.instruction_o(imem_out)
           );

// Since imem has one cycle delay and we send next cycle's address, PC_n,
// if the PC is not written, the instruction must not change
assign instruction = (PC_wen_r) ? imem_out : instruction_r;

// Register file
reg_file #(.addr_width_p($bits(instruction.rs_imm))) rf
          (.clk(clk)
          ,.rs_addr_i(instruction.rs_imm)
          ,.rd_addr_i(rd_addr)
          ,.wen_i(rf_wen)
          ,.write_data_i(rf_wd)
          ,.rs_val_o(rs_val)
          ,.rd_val_o(rd_val)
          );

assign rs_val_or_zero = instruction.rs_imm ? rs_val : 32'b0;
assign rd_val_or_zero = rd_addr            ? rd_val : 32'b0;

// ALU
alu alu_1 (.rd_i(rd_val_or_zero)
          ,.rs_i(rs_val_or_zero)
          ,.op_i(instruction)
          ,.result_o(alu_result)
          ,.jump_now_o(jump_now)
          );
			 
//new pipeline module "signal_controller:
controls_s controls_from_decode, if_id_o, id_ex_o, ex_m_o, m_wb_o;

signal_controller sig_control_1(
			.clk(clk)
			,.newControl(controls_from_decode)
			,.if_id_o(if_id)
			,.id_ex_o(id_ex)
			,.ex_m_o(ex_m)
			,.m_wb_o(m_wb)
);

//Add hazard detection here
/*
hazard_detection haz_det_1(
			.dec_op_src1_i({1'b0,id_ex_o.instruction.rd)
			,.dec_op_src2_i(id_ex_o.instruction.rs_imm)
			,.ex_op_dest_i()
			,.m_op_dest_i()
			,.wb_op_dest_i()
			,.net_reg_write_cmd_i()
			,.output pipeline_stall_o()
);*/

// select the input data for Register file, from network, the PC_plus1 for JALR,
// Data Memory or ALU result
always_comb
  begin
    if (net_reg_write_cmd)
      rf_wd = net_packet_i.net_data;

    else if (instruction==?`kJALR)
      rf_wd = pc_plus1;

    else if (is_load_op_c)
      rf_wd = from_mem_i.read_data;

    else
      rf_wd = alu_result;
  end

// Determine next PC
assign pc_plus1     = PC_r + 1'b1;
assign imm_jump_add = $signed(instruction.rs_imm)  + $signed(PC_r);

// Next pc is based on network or the instruction
always_comb
  begin
    PC_n = pc_plus1;
    if (net_PC_write_cmd_IDLE)
      PC_n = net_packet_i.net_addr;
    else
      unique casez (instruction)
        `kJALR:
          PC_n = alu_result[0+:imem_addr_width_p];

        `kBNEQZ,`kBEQZ,`kBLTZ,`kBGTZ:
          if (jump_now)
            PC_n = imm_jump_add;

        default: begin end
      endcase
  end

assign PC_wen = (net_PC_write_cmd_IDLE || ~stall);

// Sequential part, including PC, barrier, exception and state
always_ff @ (posedge clk)
  begin
    if (!reset)
      begin
        PC_r            <= 0;
        barrier_mask_r  <= {(mask_length_gp){1'b0}};
        barrier_r       <= {(mask_length_gp){1'b0}};
        state_r         <= IDLE;
        instruction_r   <= 0;
        PC_wen_r        <= 0;
        exception_o     <= 0;
        mem_stage_r     <= 2'b00;
      end

    else
      begin
        if (PC_wen)
          PC_r         <= PC_n;
        barrier_mask_r <= barrier_mask_n;
        barrier_r      <= barrier_n;
        state_r        <= state_n;
        instruction_r  <= instruction;
        PC_wen_r       <= PC_wen;
        exception_o    <= exception_n;
        mem_stage_r    <= mem_stage_n;
      end
  end

// stall and memory stages signals
// rf structural hazard and imem structural hazard (can't load next instruction)
assign stall_non_mem = (net_reg_write_cmd && op_writes_rf_c)
                    || (net_imem_write_cmd);
// Stall if LD/ST still active; or in non-RUN state
assign stall = stall_non_mem || (mem_stage_n != 0) || (state_r != RUN);

// Launch LD/ST
assign valid_to_mem_c = is_mem_op_c & (mem_stage_r < 2'b10);

always_comb
  begin
    yumi_to_mem_c = 1'b0;
    mem_stage_n   = mem_stage_r;

    if (valid_to_mem_c)
        mem_stage_n   = 2'b01;

    if (from_mem_i.yumi)
        mem_stage_n   = 2'b10;

    // If we can commit the LD/ST this cycle, the acknowledge dmem's response
    if (from_mem_i.valid & ~stall_non_mem)
      begin
        mem_stage_n   = 2'b00;
        yumi_to_mem_c = 1'b1;
      end
  end

// Decode module
cl_decode decode (.instruction_i(instruction)
						,.clk(clk)
						
						//get information from reg_file for pipelining
						,.rs_pipe_i(rs_val)
						,.rd_pipe_i(rd_val)
						
                  ,.is_load_op_o(is_load_op_c)
                  ,.op_writes_rf_o(op_writes_rf_c)
                  ,.is_store_op_o(is_store_op_c)
                  ,.is_mem_op_o(is_mem_op_c)
                  ,.is_byte_op_o(is_byte_op_c)
						
						//to sig_control
						,.controls_o(controls_from_decode)
                  );

// State machine
cl_state_machine state_machine (.instruction_i(instruction)
                               ,.state_i(state_r)
                               ,.exception_i(exception_o)
                               ,.net_PC_write_cmd_IDLE_i(net_PC_write_cmd_IDLE)
                               ,.stall_i(stall)
                               ,.state_o(state_n)
                               );

//---- Datapath with network ----//
// Detect a valid packet for this core
assign net_ID_match = (net_packet_i.ID==net_ID_p);

// Network operation
assign net_PC_write_cmd      = (net_ID_match && (net_packet_i.net_op==PC));
assign net_imem_write_cmd    = (net_ID_match && (net_packet_i.net_op==INSTR));
assign net_reg_write_cmd     = (net_ID_match && (net_packet_i.net_op==REG));
assign net_bar_write_cmd     = (net_ID_match && (net_packet_i.net_op==BAR));
assign net_PC_write_cmd_IDLE = (net_PC_write_cmd && (state_r==IDLE));

// Barrier final result, in the barrier mask, 1 means not mask and 0 means mask
assign barrier_o = barrier_mask_r & barrier_r;

// The instruction write is just for network
assign imem_wen  = net_imem_write_cmd;

// Register write could be from network or the controller
assign rf_wen    = (net_reg_write_cmd || (op_writes_rf_c && ~stall));

// Selection between network and core for instruction address
assign imem_addr = (net_imem_write_cmd) ? net_packet_i.net_addr
                                       : PC_n;

// Selection between network and address included in the instruction which is exeuted
// Address for Reg. File is shorter than address of Ins. memory in network data
// Since network can write into immediate registers, the address is wider
// but for the destination register in an instruction the extra bits must be zero
assign rd_addr = (net_reg_write_cmd)
                 ? (net_packet_i.net_addr [0+:($bits(instruction.rs_imm))])
                 : ({{($bits(instruction.rs_imm)-$bits(instruction.rd)){1'b0}}
                    ,{instruction.rd}});

// Instructions are shorter than 32 bits of network data
assign net_instruction = net_packet_i.net_data [0+:($bits(instruction))];

// barrier_mask_n, which stores the mask for barrier signal
always_comb
  // Change PC packet
  if (net_bar_write_cmd && (state_r != ERR))
    barrier_mask_n = net_packet_i.net_data [0+:mask_length_gp];
  else
    barrier_mask_n = barrier_mask_r;

// barrier_n signal, which contains the barrier value
// it can be set by PC write network command if in IDLE
// or by an an BAR instruction that is committing
assign barrier_n = net_PC_write_cmd_IDLE
                   ? net_packet_i.net_data[0+:mask_length_gp]
                   : ((instruction==?`kBAR) & ~stall)
                     ? alu_result [0+:mask_length_gp]
                     : barrier_r;

// exception_n signal, which indicates an exception
// We cannot determine next state as ERR in WORK state, since the instruction
// must be completed, WORK state means start of any operation and in memory
// instructions which could take some cycles, it could mean wait for the
// response of the memory to aknowledge the command. So we signal that we recieved
// a wrong package, but do not stop the execution. Afterwards the exception_r
// register is used to avoid extra fetch after this instruction.
always_comb
  if ((state_r==ERR) || (net_PC_write_cmd && (state_r!=IDLE)))
    exception_n = 1'b1;
  else
    exception_n = exception_o;

endmodule
