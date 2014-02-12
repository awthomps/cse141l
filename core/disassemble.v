// MBT 1/31/2014
//
// Dissembler for the Vanilla ISA
// This file is intended to be tick-included
// into the main test bench.

// It will not work in timing simulation,
// as it reaches into the verilog hierarchy.
//
// If you change the way that you instantiate
// the core, you will have to update the variable
// ROOT.
//
//
// If you add an instruction, you will
// have to augment the casez statement.

`define ROOT dut.core1

`ifdef DISASSEMBLE
     always @(negedge clk)
       begin
          if (reset &&  `ROOT.state_r != IDLE) // low true
            begin

               // s = stall, n = net stall, ? = unknown stall
               $write("{%8.8x} %c PC=%3.3x INSTR=%2.2x "
                      , cycle_counter_r
                      , `ROOT.PC_wen
                      ? " "
                      : (`ROOT.net_PC_write_cmd_IDLE
                         ? "n"
                         : (`ROOT.stall
                            ? "s"
                            : "?"
                            )
                         )
                      , `ROOT.PC_r
                      , `ROOT.instruction.opcode
                      );

    // dissassembler
    // C_Q(BLAH) generates something that looks like `kBLAH: $write ("%5.5s ","kBLAH");
    // C_Q4 does it for four instructions

    `define C_Q(Y)  `k``Y: $write("%-5.5s ",`"Y`")
    `define C_Q2(E,F) `C_Q(E); `C_Q(F)
    `define C_Q3(E,F,G) `C_Q2(E,F); `C_Q(G)
    `define C_Q4(A,B,C,D)  `C_Q2(A,B); `C_Q2(C,D)

               unique casez (`ROOT.instruction)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
                    // `C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase // unique casez (`ROOT.instruction)

               $write("%2.2x %2.2x; "
                      , `ROOT.instruction.rd
                      , `ROOT.instruction.rs_imm
                      );

               if (`ROOT.rf_wen)
                 $write("RF[%2.2x] = %8.8x; "
                        , `ROOT.rd_addr
                        , `ROOT.rf_wd
                        );
               else
                 $write("       =         ; ");

               if (`ROOT.to_mem_o.valid)
                 begin
                    if (`ROOT.to_mem_o.wen)
                      $write("MEM%c[%8.8x] = %8.8x; "
                             , `ROOT.to_mem_o.byte_not_word ? "1" : "4"
                             , `ROOT.data_mem_addr
                             , `ROOT.to_mem_o.write_data
                             );
                    else
                      $write("MEM%c[%8.8x] READREQ; "
                             , `ROOT.to_mem_o.byte_not_word ? "1" : "4"
                             , `ROOT.data_mem_addr
                             );
                 end

               if (`ROOT.to_mem_o.yumi)
                 $write(" \\-> MEM YUMI (%8.8x); "
                        , `ROOT.from_mem_i.read_data);
               $write("\n");

            end
       end // always @ (negedge clk)
   `endif //  `ifdef DISSASSEMBLE

