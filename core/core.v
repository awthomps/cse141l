//`include "definitions.v"
`include "/projects/lab3/cse141l/core/definitions.v"


// Importante note: Professor says that besides say, instruction, PC, and some
// control stuff, a lot of these things can be handled without explicitly being taken
// down the pipeline! For example, our state machine can be handled by adding some
// extra logic to the stall, but we don't have to carry it down!

//TODO:
// -make sure that the to_mem_o struct has the correct values going into it
// -make sure correct signals are going into the muxes in the last stage of the writeback
// -make sure correct signals going into barrier calculations
// -make sure correct instruction is being used to calculate the next PC
// -in ID/EX, make sure that the IDEX_en is getting all the correct checks for the instructions
//		that amend the registers.
// -remove the forwarding for now

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
logic [imem_addr_width_p-1:0] PC_r, PC_if_id, PC_id_ex, PC_ex_m, PC_n, IF_stage,
                              pc_plus1, imem_addr,
                              imm_jump_add;
// Ins. memory output
instruction_s instruction, imem_out, instruction_r, inT, instruction_id_ex, instruction_ex_m;

// Result of ALU, Register file outputs, Data memory output data
logic [31:0] alu_result_ex_m, alu_result_n, rs_val_or_zero, rs_val_or_zero_n,
rd_val_or_zero, rd_val_or_zero_n,
rs_val, rd_val, reg_20_val;

// Reg. File address
logic [($bits(instruction.rs_imm))-1:0] rd_addr;

// Data for Reg. File signals
logic [31:0] rf_wd;

//---- Control signals ----//
// ALU output to determin whether to jump or not
logic jump_now, jump_now_n;

// controller output signals
logic is_load_op_c,  op_writes_rf_c, valid_to_mem_c, branch_taken,
      is_store_op_c, is_mem_op_c, PC_wen,  IDEX_en, instruction_fetch_en1, 
		ex_mem_en, ex_mem_en1,
      is_byte_op_c,  PC_wen_r;

// Handshak protocol signals for memory
logic yumi_to_mem_c;

// Final signals after network interfere
logic imem_wen, rf_wen, rf_wen_id_ex, rf_wen_n;

// Network operation signals
logic net_ID_match,      net_PC_write_cmd,  net_imem_write_cmd,
      net_reg_write_cmd, net_bar_write_cmd, net_PC_write_cmd_IDLE;

// Memory stages and stall signals
logic [1:0] mem_stage_r, mem_stage_n;
logic stall, stall_non_mem, nop_stall;

// Exception signal
logic exception_n;

// State machine signals
state_e state_n, /*state_if_id, state_id_ex, state_ex_m,*/ state_r;

///////////////////////////////IF/ID stage//////////////////////////////////////////////
assign instruction_fetch_en1 = (~stall);
always_ff @(posedge clk) begin
if(!reset)
begin
instruction <= `kNOP;
PC_if_id <= 0;
//state_if_id <= IDLE;
end
else if(instruction_fetch_en1)
  begin
    instruction <= inT;   
	  PC_if_id <= PC_r;
//	  state_if_id <= state_n;
  end
end

// Decode controls:
decode_controls_s de_control_n, de_control_id_ex, de_control_ex_m;

//////////////////////////////ID/EX/////////////////////////////////////////////
assign IDEX_en = ( ~stall || (instruction != `kLW) || (instruction !=`kLBU));
always_ff @(posedge clk) begin
if(!reset)
begin
  rs_val_or_zero<= 0;
  PC_id_ex <= 0;
  rd_val_or_zero<=0;
//  state_id_ex         <= IDLE;
  de_control_id_ex <= 0;
  instruction_id_ex <= `kNOP;
  rf_wen_id_ex <= 0;
end
else if(IDEX_en)
  begin
     rs_val_or_zero <=rs_val_or_zero_n;
	   PC_id_ex <= PC_if_id;
//		state_id_ex   <= state_r;
		de_control_id_ex <= de_control_n;
	   rd_val_or_zero<=rd_val_or_zero_n;
		instruction_id_ex <= instruction;//if_id
		rf_wen_id_ex <= rf_wen_n;
  end
end

//////////////////////////////EX/MEM/////////////////////////////////////////////
assign ex_mem_en1 = ( ~stall);
always_ff @(posedge clk) begin
if(!reset)
begin
alu_result_ex_m <= 0;
PC_ex_m <= 0;
//state_ex_m <= IDLE;
de_control_ex_m <= 0;
instruction_ex_m <= `kNOP;
rf_wen <= 0;
jump_now <= 0;
end
else if(ex_mem_en1)
  begin
    alu_result_ex_m <= alu_result_n;
  	 PC_ex_m <= PC_id_ex;
//	 state_ex_m <= state_id_ex;
	 de_control_ex_m <= de_control_id_ex;
	 instruction_ex_m <= instruction_id_ex;
	 rf_wen <= rf_wen_id_ex;
	 jump_now <= jump_now_n;
  end
end


//Counter setup
logic [1:0] counter;
always_ff @ (posedge clk) begin
	if(!reset)
		counter	<= 2'b11;
	else if(~stall || state_n == RUN)
		counter <= (counter + 2'b01) % 4;

end
always_comb begin
	if(counter == 2'b00)
		nop_stall = 0;
	else
		nop_stall = 1;
end



//--------------------------------------stage & stall-----------------------------------------------------//

//---- network and barrier signals ---//
instruction_s net_instruction;
logic [mask_length_gp-1:0] barrier_r,      barrier_n,
                           barrier_mask_r, barrier_mask_n;

//---- Connection to external modules ----//

// Suppress warnings
assign net_packet_o = net_packet_i;

// Data_mem
assign to_mem_o = '{write_data    : rs_val_or_zero
                   ,valid         : valid_to_mem_c
                   ,wen           : de_control_ex_m.is_store_op_c
                   ,byte_not_word : de_control_ex_m.is_byte_op_c
                   ,yumi          : yumi_to_mem_c
                   };
assign data_mem_addr = alu_result_ex_m;

// DEBUG Struct
assign debug_o = {PC_if_id, instruction_ex_m, state_r, barrier_mask_r, barrier_r};

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
//assign instruction = (PC_wen_r) ? imem_out : instruction_r;//////////////////////////////////
//assign inT = (PC_wen_r) ? imem_out : instruction_r;
assign inT = (nop_stall) ? `kNOP : ((PC_wen_r) ? imem_out : instruction_r);
// Register file
reg_file #(.addr_width_p($bits(instruction.rs_imm))) rf
          (.clk(clk)
          ,.rs_addr_i(instruction.rs_imm) //if_id
          ,.rd_addr_i(rd_addr)
          ,.wen_i(rf_wen)
          ,.write_data_i(rf_wd)
          ,.rs_val_o(rs_val)
          ,.rd_val_o(rd_val)
          //,.reg_20_val_o(reg_20_val)
          );

assign rs_val_or_zero_n = instruction.rs_imm ? rs_val : 32'b0; //if_id
assign rd_val_or_zero_n = rd_addr            ? rd_val : 32'b0;

// ALU
alu alu_1 (.rd_i(rd_val_or_zero)
          ,.rs_i(rs_val_or_zero)
          //,.reg_20_i(reg_20_val)
          ,.op_i(instruction_id_ex)
          ,.result_o(alu_result_n)
          ,.jump_now_o(jump_now_n)
          );

// select the input data for Register file, from network, the PC_plus1 for JALR,
// Data Memory or ALU result
always_comb
  begin
    if (net_reg_write_cmd)
      rf_wd = net_packet_i.net_data;

    else if (instruction_ex_m==?`kJALR)
      rf_wd = pc_plus1;

    else if (de_control_ex_m.is_load_op_c)
      rf_wd = from_mem_i.read_data;
      
    else
      rf_wd = alu_result_ex_m;
  end

// Determine next PC
assign pc_plus1     = PC_r + 1'b1;
assign pc_plus0 	  = PC_r;
assign imm_jump_add = $signed(instruction_id_ex.rs_imm)  + $signed(PC_r);

// Next pc is based on network or the instruction
always_comb
  begin
    PC_n = pc_plus0;
	 if(counter == 2'b11) begin
		PC_n = pc_plus1;
		if (net_PC_write_cmd_IDLE)
			PC_n = net_packet_i.net_addr;
		else
			unique casez (instruction_id_ex)
			  `kJALR:
				 PC_n = alu_result_ex_m[0+:imem_addr_width_p];
			  `kBNEQZ,`kBEQZ,`kBLTZ,`kBGTZ:
				 if (jump_now)
					PC_n = imm_jump_add;
			  default: begin end
			endcase
		end
  end

assign PC_wen = (net_PC_write_cmd_IDLE || ~stall) && (counter == 2'b11);

// Sequential part, including PC, barrier, exception and state
always_ff @ (posedge clk)
  begin
    if (!reset)
      begin
        PC_r            <= 0;
        barrier_mask_r  <= {(mask_length_gp){1'b0}};
        barrier_r       <= {(mask_length_gp){1'b0}};
        state_r         <= IDLE; //original
//		  state_n			<= IDLE;
        instruction_r   <= 0;
        PC_wen_r        <= 0;
        exception_o     <= 0;
        mem_stage_r     <= 2'b00;
		  //nop_stall			<= 0;
      end

    else
      begin
        if (PC_wen)
          PC_r         <= PC_n;
        barrier_mask_r <= barrier_mask_n;
        barrier_r      <= barrier_n;
        state_r        <= state_n; //original
//		  state_n			<= state_ex_m;
        instruction_r  <= instruction_id_ex;
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
cl_decode decode (.instruction_i(instruction) //if_id
                  ,.is_load_op_o(de_control_n.is_load_op_c)
                  ,.op_writes_rf_o(de_control_n.op_writes_rf_c)
                  ,.is_store_op_o(de_control_n.is_store_op_c)
                  ,.is_mem_op_o(de_control_n.is_mem_op_c)
                  ,.is_byte_op_o(de_control_n.is_byte_op_c)
                  );

// State machine
cl_state_machine state_machine (.instruction_i(instruction) //if_id
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
assign net_PC_write_cmd_IDLE = (net_PC_write_cmd && (state_r ==IDLE));

// Barrier final result, in the barrier mask, 1 means not mask and 0 means mask
assign barrier_o = barrier_mask_r & barrier_r;

// The instruction write is just for network
assign imem_wen  = net_imem_write_cmd;

// Register write could be from network or the controller
assign rf_wen_n    = (net_reg_write_cmd || (de_control_n.op_writes_rf_c && ~stall));

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
                   : ((inT==?`kBAR) & ~stall) //calculate new barrier from 'last' instruction (had been instruction_id_ex)
                     ? alu_result_n [0+:mask_length_gp]
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