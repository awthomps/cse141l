`include "definitions.v"

// Comment out the line below when running a gate-level i.e. timing simulation in ModelSim
// `define BEHAVIORAL 
`define half_period 1.5
//`timescale 100 ns / 1 ns

module core_tb();

logic clk, reset, reset_r;
integer i;

// 5 is the op-code size
localparam instr_length_p = rd_size_p + rs_imm_size_p+ 5; 
localparam instr_buffer_size_p = 1024;
localparam data_buffer_size_p = 1024;
localparam reg_packet_width_p = 40;

reg [instr_length_p-1:0] ins_packet [instr_buffer_size_p-1:0];
reg [31:0] data_packet [data_buffer_size_p-1:0];
reg [reg_packet_width_p-1:0] reg_packet [(2**rs_imm_size_p)-1:0];

instruction_s instruct_t;

// Data memory connected to core
mem_in_s mem_in2,mem_in1, mem_in;
logic [$bits(mem_in_s)-1:0] mem_in1_flat, mem_in_flat; 
assign mem_in1 = mem_in1_flat;
assign mem_in_flat = mem_in;

mem_out_s mem_out;
logic [$bits(mem_out_s)-1:0] mem_out_flat;
assign mem_out = mem_out_flat;
logic select;
logic [31:0] data_mem_addr,data_mem_addr1,data_mem_addr2;
data_mem datamem_1
                (.clk(clk)
                ,.reset(reset_r)
                ,.port_flat_i(mem_in_flat) 
                ,.addr(data_mem_addr[data_mem_addr_width_p-1:0])
                ,.port_flat_o(mem_out_flat)
                );

// Main core
net_packet_s core_in, core_out, packet;
logic [$bits(net_packet_s)-1:0] core_in_flat, core_out_flat;
assign core_in_flat = core_in;
assign core_out = core_out_flat;

logic [mask_length_p-1:0] barrier_mask;
debug_s debug;
logic exception;

core_flattened dut
      (.clk(clk)
      ,.reset(reset_r)
      ,.net_packet_flat_i(core_in_flat)
      ,.net_packet_flat_o(core_out_flat)
      ,.from_mem_flat_i(mem_out_flat)
      ,.to_mem_flat_o(mem_in1_flat)
      ,.barrier_o(barrier_mask)
      ,.exception_o(exception)
      ,.debug_flat_o(debug)
      ,.data_mem_addr(data_mem_addr1)
      );

// To select between core or test bench data and address for the data memory
assign mem_in        = select ? mem_in1        : mem_in2;
assign data_mem_addr = select ? data_mem_addr1 : data_mem_addr2;
// ----------------------------------------------------------------
initial begin
// TODO: Edit the file names below to match your Assembler output files.
// read from assembled files and store in buffers
$readmemh ("tester_i.hex",ins_packet);
$readmemh ("tester_d.hex",data_packet);
$readmemh ("tester_r.hex",reg_packet);

  // The signals are initialized and the core is reset
  packet = 0;
  reset = 1'b1;
  clk   = 1'b0;

  reset=1'b0; 
  @ (negedge clk)
  @ (negedge clk)
    reset = 1'b1;
  
  // Initialize the data memory, by sending each data as a store
  select = 1'b0;
  mem_in2.valid = 1'b1;
  mem_in2.yumi  = 1'b1;
  mem_in2.byte_not_word = 1'b0;
  mem_in2.wen = 1'b1;
  for(i=0;i<data_buffer_size_p;i=i+1)
    begin
      @ (negedge clk)
      @ (negedge clk)
      data_mem_addr2 = i*4;
      mem_in2.write_data = data_packet[i];
    end
                                                
  @ (negedge clk)
  mem_in2.valid = 1'b0;
  mem_in2.yumi  = 1'b0;
  @ (negedge clk)
  
  // Connect the core to the memory
  select = 1'b1;
  
  // Insert instructions: Read from the buffers 
  // and send the instructions as packets to the core
  for(i=0;i<instr_buffer_size_p;i=i+1)
    begin
      instruct_t='{opcode: ins_packet[i][15:11]
                  ,rd:     ins_packet[i][10:6]
                  ,rs_imm: ins_packet[i][5:0]};
      
      @ (negedge clk)
        packet  ='{ID:       10'b0000000001
                  ,net_op:   INSTR
                  ,net_data: {{(16){1'b0}},{instruct_t}} 
                  ,net_add:  i};
    end
  
  // Insert register values: Read from the buffers 
  // and send the register values as packets to the core
  for(i=0;i<(2**rs_imm_size_p);i=i+1)
    begin
      @ (negedge clk)
        packet  ='{ID:       10'b0000000001
                  ,net_op:   REG
                  ,net_data: reg_packet[i][31:0]
                  ,net_add:  reg_packet[i][37:32]};
    end
  
  // Now the core is initialized. Its time to start it!
  
  // Set the PC to zero
  @ (negedge clk)
    packet  ='{ID:       10'b0000000001
              ,net_op:   PC
              ,net_data: 32'h5 
              ,net_add:  10'd0 }; 
  
  // Set the Barrier mask
  @ (negedge clk)
    packet  ='{ID:       10'b0000000001
              ,net_op:   BAR
              ,net_data: 32'h2
              ,net_add:  10'd24}; 
  
  // No more network interfere
  @ (negedge clk)
    packet  ='{ID:       10'b0000000001
              ,net_op:   NULL
              ,net_data: 32'hFFFFFFFE
              ,net_add:  10'd24};
  
  $display ("--------CORE TEST---------");
  
  `ifdef BEHAVIORAL
  // Display some signals for debug
  $display ({"clk\t reset\t intr\t\t     PC\t $r6\t\t" 
           ,"$r7\t\t PC_wr\t ij_add\t  B_res\t mem_data\t"
           ,"M_tnx\t M_val\t tnx\t valid\t barr\t barin\t"
           ,"mask\t state\t m_state exception"});
  
  $monitor ({"%b\t %b\t %b %d\t %h\t %h\t %b\t %d\t    %b\t"
           ,"\%h\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b"}
            ,clk,reset, dut.core1.instruction, dut.core1.PC_r 
            ,dut.core1.rf.RF[6'd6], dut.core1.rf.RF[6'd7]
            ,dut.core1.PC_wen, dut.core1.imm_jump_add,dut.core1.jump_now
            ,mem_out.read_data, mem_out.yumi, mem_out.valid
            ,dut.core1.yumi_to_mem_c, dut.core1.valid_to_mem_c, barrier_mask
            ,dut.core1.barrier_r, dut.core1.barrier_mask_r,dut.core1.state_r
            ,datamem_1.state_r, exception); 
  `endif
end

// Clock generator
always 
    // Toggle clock every 1 ticks
    #`half_period clk = ~clk; 

always @ (negedge clk)
  begin
    if ((data_mem_addr1 == 32'hDEADDEAD) && mem_out.valid)
      begin
        $display ("TEST FAILED, NUMBER: %d", mem_in.write_data);
        $stop;
      end
    
    if ((data_mem_addr1 == 32'h600DBEEF) && mem_out.valid)
      begin
        $display ("TEST FINISHED");
        $stop;
      end
    
    if ((data_mem_addr1 == 32'hC0DEC0DE) && mem_out.valid)
        $display ("WRONG RESULT : 0x%h", mem_in.write_data);
    
    if ((data_mem_addr1 == 32'hC0FFEEEE) && mem_out.valid)
        $display ("TEST PASSED, Number: %d", mem_in.write_data);
    
    if (barrier_mask != 3'b000) 
      begin                                                      
        $display ("BARRIER TEST PASSED");
      end
  end

// The packets become available to the core at positive edge of the clock, to be synchronous 
always_ff @ (posedge clk)
  begin
    reset_r <= reset;
    core_in <= packet;
  end

endmodule

