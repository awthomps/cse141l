//	This is essentially a "Scratch paper" file. I used it to help
//myself convert the assembly into the system verilog mathematically.
//I hope it helps you understand my thought process when creating the
//new instructions. -Andrei


// Small sigma 0 function from SHA-256
// $R1 : X value
// $R2 : return value
SMSIG0:
r1 = rd_i
    MOV  $R7, $R1
r7 = rd_i
    MOV  $R8, %S7
r8 = 7
    ROR  $R7, $R8
r7 = (r7 >> r8) | (r7 << (32 - r8));
r7 = (rd_i >> 7) | (rd_i << 25);
    MOV  $R3, $R7  // term 1
r3 = r7
r3 = (rd_i >> 7) | (rd_i << 25);
    MOV  $R7, $R1
r7 = r1
r7 = rd_i
    MOV  $R8, %S18
r8 = 18
    ROR  $R7, $R8
r7 = (r7 >> r8) | (r7 << (32 - r8));
r7 = (rd_i >> 18) | (rd_i << 14);
    MOV  $R8, $R3
r8 = r3
r8 = (rd_i >> 7) | (rd_i << 25);
    XOR  $R7, $R8
r7 = r7 ^ r8
r7 = ((rd_i >> 18) | (rd_i << 14)) ^ ((rd_i >> 7) | (rd_i << 25));
    MOV  $R8, $R1
r8 = r1
r8 = rd_i
    SRLV $R8, %S3
r8 = $unsigned (rd_i) >> 3
    XOR  $R7, $R8
r7 = r7 ^ r8
r7 = (((rd_i >> 18) | (rd_i << 14)) ^ ((rd_i >> 7) | (rd_i << 25))) ^ ($unsigned (rd_i) >> 3)
    MOV  $R2, $R7
r2 = (((rd_i >> 18) | (rd_i << 14)) ^ ((rd_i >> 7) | (rd_i << 25))) ^ ($unsigned (rd_i) >> 3)
    JALR $R31, $R30

//SO:
result_o = (((rd_i >> 18) | (rd_i << 14)) ^ ((rd_i >> 7) | (rd_i << 25))) ^ ($unsigned (rd_i) >> 3)




// Small sigma 1 function from SHA-256
// $R1 : X value
// $R2 : return value
SMSIG1:
r1 = rd_i
    MOV  $R7, $R1
r7 = r1
r7 = rd_i
    MOV  $R8, %S17
r8 = 17
    ROR  $R7, $R8
r7 = (r7 >> r8) | (r7 << (32 - r8))
r7 = (rd_i >> 17) | (rd_i << 15)
    MOV  $R3, $R7  // term 1
r3 = r7
r3 = (rd_i >> 17) | (rd_i << 15)
    MOV  $R7, $R1
r7 = r1
r7 = rd_i
    MOV  $R8, %S19
r8 = 19
    ROR  $R7, $R8
r7 = (r7 >> r8) | (r7 << (32 - r8))
r7 = (rd_i >> 19) | (rd_i << 13)
    MOV  $R8, $R3
r8 = r3
r8 = (rd_i >> 17) | (rd_i << 15)
    XOR  $R7, $R8
r7 = r7 ^ r8
r7 = ((rd_i >> 19) | (rd_i << 13)) ^ ((rd_i >> 17) | (rd_i << 15))
    MOV  $R8, $R1
r8 = r1
r8 = rd_i
    SRLV $R8, %S10
r8 = $unsigned (rd_i) >> 10
    XOR  $R7, $R8
r7 = r7 ^ r8
r7 = (((rd_i >> 19) | (rd_i << 13)) ^ ((rd_i >> 17) | (rd_i << 15))) ^ ($unsigned (rd_i) >> 10)

    MOV  $R2, $R7
r2 = r7
r2 = (((rd_i >> 19) | (rd_i << 13)) ^ ((rd_i >> 17) | (rd_i << 15))) ^ ($unsigned (rd_i) >> 10)
    JALR $R31, $R30
//SO
result_o = (((rd_i >> 19) | (rd_i << 13)) ^ ((rd_i >> 17) | (rd_i << 15))) ^ ($unsigned (rd_i) >> 10);

