//This file defines the structs and parameters used in the core

`ifndef _definitions_v_
`define _definitions_v_

// Instruction map
`define kADDU  16'b00000_?????_??????
`define kSUBU  16'b00001_?????_??????
`define kSLLV  16'b00010_?????_??????
`define kSRAV  16'b00011_?????_??????
`define kSRLV  16'b00100_?????_??????
`define kBRLU  16'b01011_?????_??????
`define kAND   16'b00101_?????_??????
`define kOR    16'b00110_?????_??????
`define kNOR   16'b00111_?????_??????

`define kSLT   16'b01000_?????_??????
`define kSLTU  16'b01001_?????_??????

`define kMOV   16'b01010_?????_??????
// 11
// Synthesis hangs on ALU in Quartus, so we use
// smaller wildcard
// `define kBAR   16'b01100_10000_??????
`define kBAR   16'b01100_100??_??????
`define kDONE  16'b01100_00000_000000
// 14
// 15
`define kBEQZ  16'b10000_?????_??????
`define kBNEQZ 16'b10001_?????_??????
`define kBGTZ  16'b10010_?????_??????
`define kBLTZ  16'b10011_?????_??????
// 20
// 21
// 22
`define kJALR  16'b10111_?????_??????

`define kLW    16'b11000_?????_??????
`define kLBU   16'b11001_?????_??????
`define kSW    16'b11010_?????_??????
`define kSB    16'b11011_?????_??????
// 28
// 29
// 30
// 31

//---- Controller states ----//
// WORK state means start of any operation or wait for the 
// response of memory in acknowledge of the command
// MEM_WAIT state means the memory acknowledged the command, 
// but it did not send the valid signal and core is waiting for it
typedef enum logic [1:0] {
IDLE = 2'b00,
RUN  = 2'b01,    
ERR  = 2'b11
} state_e;


// size of rd and rs field in the instruction, 
// which is log of register file size as well
parameter rd_size_p             = 5;
parameter rd_size_gp             = 5;
parameter rs_imm_size_p         = 6; 
parameter rs_imm_size_gp         = 6; 
parameter instruction_size_p    = 16;
// instruction memory and data memory address widths, 
// which is log of their sizes as well
parameter ins_mem_addr_width_p  = 10; 
parameter data_mem_addr_width_p = 12;  

// Length of ID part in network packet
parameter ID_length_p = 10;

// Length of barrier output, which is equal to its mask size 
parameter mask_length_p = 3;
parameter mask_length_gp = 3;

// a struct for instructions
typedef struct packed{
        logic [4:0]  opcode;
        logic [rd_size_p-1:0] rd;
        logic [rs_imm_size_p-1:0] rs_imm;
        } instruction_s;

// Types of network packets
typedef enum logic [2:0] {
// Nothing
NULL  = 3'b000,
// Instruction for instruction memory
INSTR = 3'b001,
// Value for a register
REG   = 3'b010,
// Change PC 
PC    = 3'b011,
// Barrier mask
BAR   = 3'b100
} net_op_e;

// a struct for network packets
typedef struct packed{
        logic [ID_length_p-1:0] ID;
        net_op_e net_op;        
        logic [31:0] net_data;
        logic [ins_mem_addr_width_p-1:0] net_add;
        } net_packet_s;

// a struct for the packets froms core to memory
typedef struct packed{
        logic [31:0] write_data;
        logic valid;
        logic wen;
        logic byte_not_word;
        // in response to data memory
        logic yumi;    
        } mem_in_s;

// a struct for the packets from data memory to core
typedef struct packed{
        logic [31:0] read_data;
        logic valid;
        // in response to core
        logic yumi;    
        } mem_out_s;

// a struct for debugging the core during timing simulation
typedef struct packed {
        logic [ins_mem_addr_width_p-1:0] PC_r_f;
        logic [$bits(instruction_s)-1:0] instruction_i_f;
        logic [1:0] state_r_f;
        logic [mask_length_p-1:0] barrier_mask_r_f;
        logic [mask_length_p-1:0] barrier_r_f;
} debug_s;

`endif
