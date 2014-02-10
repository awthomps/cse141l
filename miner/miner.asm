// Vanilla Bitcoin Miner
// Author: Rich Park 
// Jan. 2014

// calling convention
// $R30 - link register for main program
// $R1 - $R6 subroutine call parameters and return values
// $R7 - $R12 nested subroutine call parameters and return values
// $R14 - $R30 preserved by callees
// $31 link register for 1st nested subroutine

// Intermediate values used in the SHA-256 computation
// $R21 to $R28 -> 'a' to 'h' 
// $R19 to $R20 -> T1 and T2

.data
// The midstate will be stored here
MIDSTATE:
.word 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 

// The last 4 words of Bitcoin Blockchain Header will get loaded here
WORK2:
.word 0x00000000 0x00000000 0x00000000 0x00000000 0x80000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000280

PADDING:
.word 0x80000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000000 0x00000100

W:
.fillword 64 0x00000000

// This is the output of the SHA-256 function i.e. the hash
H:
.fillword 8 0x00000000

// Initialization Vector
IV:
.word 0x6a09e667 0xbb67ae85 0x3c6ef372 0xa54ff53a 0x510e527f 0x9b05688c 0x1f83d9ab 0x5be0cd19       

// Constants defined by SHA-256 specification
K:
.word 0x428a2f98 0x71374491 0xb5c0fbcf 0xe9b5dba5 0x3956c25b 0x59f111f1 0x923f82a4 0xab1c5ed5 0xd807aa98 0x12835b01 0x243185be 0x550c7dc3 0x72be5d74 0x80deb1fe 0x9bdc06a7 0xc19bf174 0xe49b69c1 0xefbe4786 0x0fc19dc6 0x240ca1cc 0x2de92c6f 0x4a7484aa 0x5cb0a9dc 0x76f988da 0x983e5152 0xa831c66d 0xb00327c8 0xbf597fc7 0xc6e00bf3 0xd5a79147 0x06ca6351 0x14292967 0x27b70a85 0x2e1b2138 0x4d2c6dfc 0x53380d13 0x650a7354 0x766a0abb 0x81c2c92e 0x92722c85 0xa2bfe8a1 0xa81a664b 0xc24b8b70 0xc76c51a3 0xd192e819 0xd6990624 0xf40e3585 0x106aa070 0x19a4c116 0x1e376c08 0x2748774c 0x34b0bcb5 0x391c0cb3 0x4ed8aa4a 0x5b9cca4f 0x682e6ff3 0x748f82ee 0x78a5636f 0x84c87814 0x8cc70208 0x90befffa 0xa4506ceb 0xbef9a3f7 0xc67178f2

.kernel miner

// Constant Reg values
.const %FOUR, 4
.const %S32, 32
.const %S2, 2
.const %S11, 11
.const %S25, 25
.const %S7, 7
.const %S18, 18
.const %S3, 3
.const %S17, 17
.const %S19, 19
.const %S10, 10
.const %WLOOP, WLOOP
.const %S256, 256
.const %WORK2, WORK2
.const %MIDSTATE, MIDSTATE
.const %PADDING, PADDING
.const %W_BASE, W
.const %H_BASE, H
.const %IV_BASE, IV
.const %K_BASE, K
.const %XOR, XOR
.const %ROR, ROR
.const %SMSIG0, SMSIG0
.const %SMSIG1, SMSIG1
.const %BIGSIG0, BIGSIG0
.const %BIGSIG1, BIGSIG1
.const %MAJ, MAJ
.const %CH, CH
.const %SHAROUND, SHAROUND
.const %CODE_TEST,  0xC0DEC0DE
.const %DONE,  0x600DBEEF
.const %FAIL, 0xDEADDEAD

.text
COMMAND:
    MOV  $R21, $R20
    MOV  $R22, %S3
    SUBU $R22, %S2  
    SUBU $R22, $R21 
    BEQZ $R22, LOAD_WORK
    MOV  $R22, %S2
    SUBU  $R22, $R21
    BEQZ $R22, LOAD_NONCE
    SUBU  $R21, %S3
    BEQZ $R21, DONE

// Failure due to unknown command register
FAIL:
    MOV  $R1, %FAIL
    LW   $R1, $R0

// Place new work from testbench into buffers in the data memory.
// 
// Preconditions: Testbench must ensure the following
// $R1-$R8  will contain the midstate 
// $R9-$R11 will contain the last 3 words of the block header not including the nonce
//
// Input: $R12 - base address of Midstate buffer
//        $R13 - base address of Work2 buffer
LOAD_WORK:
   MOV  $R12, %MIDSTATE
   MOV  $R13, %WORK2

   // Store Midstate
   SW   $R12, $R1
   ADDU $R12, %FOUR
   SW   $R12, $R2
   ADDU $R12, %FOUR
   SW   $R12, $R3
   ADDU $R12, %FOUR
   SW   $R12, $R4
   ADDU $R12, %FOUR
   SW   $R12, $R5
   ADDU $R12, %FOUR
   SW   $R12, $R6
   ADDU $R12, %FOUR
   SW   $R12, $R7
   ADDU $R12, %FOUR
   SW   $R12, $R8

   // Store last 3 words of header 
   SW   $R13, $R9
   ADDU $R13, %FOUR
   SW   $R13, $R10
   ADDU $R13, %FOUR
   SW   $R13, $R11

   BAR  $R0  // PC:32
   DONE

// Write to DONE address, signalling success
DONE:
    MOV  $R1, %DONE
    SW   $R1, $R0

// Place new nonce into buffer in memory and hash the block
//
// Preconditions: Testbench must ensure the following
// $R1 will contain the new nonce 
LOAD_NONCE:
    MOV  $R12, %WORK2
    ADDU $R12, %S2
    ADDU $R12, %S10
    SW   $R12, $R1

// Compute Message Schedule
W_INIT1:
    MOV  $R29, $R0
    MOV  $R16, %WORK2
    MOV  $R17, %W_BASE
// Set W_j for 0 <= j < 16
// W_j = DataMemory[W_BASE + j * 4]
W_LOOP0: 
    LW   $R18, $R16
    SW   $R17, $R18
    ADDU $R16, %FOUR
    ADDU $R17, %FOUR
    ADDU $R29, %FOUR
    MOV  $R14, %S32
    ADDU $R14, %S32
    SUBU $R14, $R29
    BNEQZ $R14, W_LOOP0
    JALR $R13, %WLOOP

// initialize 'a' to 'h' intermediate values
    MOV  $R14, %MIDSTATE
    LW   $R21, $R14
    ADDU $R14, %FOUR
    LW   $R22, $R14
    ADDU $R14, %FOUR
    LW   $R23, $R14
    ADDU $R14, %FOUR
    LW   $R24, $R14
    ADDU $R14, %FOUR
    LW   $R25, $R14
    ADDU $R14, %FOUR
    LW   $R26, $R14
    ADDU $R14, %FOUR
    LW   $R27, $R14
    ADDU $R14, %FOUR
    LW   $R28, $R14
    
    MOV  $R29, $R0
    JALR $R17, %SHAROUND

// sum 'a' to 'h' with midstate to get first hash
    MOV  $R29, %MIDSTATE 
    LW   $R1, $R29
    ADDU $R29, %FOUR
    LW   $R2, $R29
    ADDU $R29, %FOUR
    LW   $R3, $R29
    ADDU $R29, %FOUR
    LW   $R4, $R29
    ADDU $R29, %FOUR
    LW   $R5, $R29
    ADDU $R29, %FOUR
    LW   $R6, $R29
    ADDU $R29, %FOUR
    LW   $R7, $R29
    ADDU $R29, %FOUR
    LW   $R8, $R29

    ADDU $R1, $R21
    ADDU $R2, $R22
    ADDU $R3, $R23
    ADDU $R4, $R24
    ADDU $R5, $R25
    ADDU $R6, $R26
    ADDU $R7, $R27
    ADDU $R8, $R28

    MOV  $R29, %H_BASE
    SW   $R29, $R1
    ADDU $R29, %FOUR
    SW   $R29, $R2
    ADDU $R29, %FOUR
    SW   $R29, $R3
    ADDU $R29, %FOUR
    SW   $R29, $R4
    ADDU $R29, %FOUR
    SW   $R29, $R5
    ADDU $R29, %FOUR
    SW   $R29, $R6
    ADDU $R29, %FOUR
    SW   $R29, $R7
    ADDU $R29, %FOUR
    SW   $R29, $R8

// Perform Second SHA-256
// initialize W_1 to W_7 with first hash
    SUBU  $R29, $R29
    MOV   $R16, %H_BASE
    MOV  $R17, %W_BASE
W_INIT2_1: 
    LW   $R1, $R16
    SW   $R17, $R1
    ADDU $R29, %FOUR
    ADDU $R16, %FOUR
    ADDU $R17, %FOUR
    MOV  $R14, $R29
    SUBU $R14, %S32
    BNEQZ $R14, W_INIT2_1

// initialize W_8 to W_15 with padding
    MOV  $R16, %PADDING
W_INIT2_2: 
    LW   $R1, $R16
    SW   $R17, $R1
    ADDU $R29, %FOUR
    ADDU $R16, %FOUR
    ADDU $R17, %FOUR
    MOV  $R14, $R29
    SUBU $R14, %S32
    SUBU $R14, %S32
    BNEQZ $R14, W_INIT2_2
    JALR $R13, %WLOOP

// initialize 'a' to 'h' with initialization vector 
    MOV  $R14, %IV_BASE
    LW   $R21, $R14
    ADDU $R14, %FOUR
    LW   $R22, $R14
    ADDU $R14, %FOUR
    LW   $R23, $R14
    ADDU $R14, %FOUR
    LW   $R24, $R14
    ADDU $R14, %FOUR
    LW   $R25, $R14
    ADDU $R14, %FOUR
    LW   $R26, $R14
    ADDU $R14, %FOUR
    LW   $R27, $R14
    ADDU $R14, %FOUR
    LW   $R28, $R14
    
    MOV  $R29, $R0
    JALR $R17, %SHAROUND
    
// sum 'a' to 'h' with IV to get first hash
    MOV  $R29, %IV_BASE  
    LW   $R1, $R29
    ADDU $R29, %FOUR
    LW   $R2, $R29
    ADDU $R29, %FOUR
    LW   $R3, $R29
    ADDU $R29, %FOUR
    LW   $R4, $R29
    ADDU $R29, %FOUR
    LW   $R5, $R29
    ADDU $R29, %FOUR
    LW   $R6, $R29
    ADDU $R29, %FOUR
    LW   $R7, $R29
    ADDU $R29, %FOUR
    LW   $R8, $R29

    ADDU $R1, $R21  
    ADDU $R2, $R22
    ADDU $R3, $R23
    ADDU $R4, $R24
    ADDU $R5, $R25
    ADDU $R6, $R26
    ADDU $R7, $R27
    ADDU $R8, $R28

    MOV  $R29, %H_BASE
    SW   $R29, $R1
    ADDU $R29, %FOUR
    SW   $R29, $R2
    ADDU $R29, %FOUR
    SW   $R29, $R3
    ADDU $R29, %FOUR
    SW   $R29, $R4
    ADDU $R29, %FOUR
    SW   $R29, $R5
    ADDU $R29, %FOUR
    SW   $R29, $R6
    ADDU $R29, %FOUR
    SW   $R29, $R7
    ADDU $R29, %FOUR
    SW   $R29, $R8

// *** Output Hash and Signal DONE
    MOV  $R9, %CODE_TEST
    SW   $R9, $R1
    SW   $R9, $R2
    SW   $R9, $R3
    SW   $R9, $R4
    SW   $R9, $R5
    SW   $R9, $R6
    SW   $R9, $R7
    SW   $R9, $R8
// ****************
    
// For the lab, the Target value has
// been hard coded to a very "easy" value.
// If your hash has 4-bits of trailing zeros then
// a Bitcoin is successfully mined.
//
// "Optimizing" this target check is cheating!
// DO NOT MODIFY THIS SUBROUTINE!
CHECK_HASH:
    SLLV $R8, %S18
    SLLV $R8, %S10
    BEQZ $R8, BTC
    BAR $R0 
    DONE

// DO NOT MODIFY THIS SUBROUTINE!
BTC:
    MOV  $R1, %S3
    SUBU $R1, %S2
    BAR  $R1
    DONE
    
// Set W_j for 16 <= j <= 63
WLOOP:
    MOV  $R16, $R29
    MOV  $R20, %S2
    SLLV $R20, %S2  // r20 = 8
    SUBU $R16, $R20 // W_j - 2
    ADDU $R16, %W_BASE
    LW   $R16, $R16

    MOV  $R17, $R29
    ADDU $R20, %S10
    ADDU $R20, %S10 // R20 = 28
    SUBU $R17, $R20 // W_j - 7
    ADDU $R17, %W_BASE
    LW   $R17, $R17

    MOV  $R18, $R29
    ADDU $R20, %S32  // R20 = 60
    SUBU $R18, $R20 // W_j - 15
    ADDU $R18, %W_BASE
    LW   $R18, $R18

    MOV  $R14, $R29
    ADDU $R20, %FOUR  // R20 = 64
    SUBU $R14, $R20 // W_j - 16
    ADDU $R14, %W_BASE
    LW   $R14, $R14
    MOV  $R1, $R16
    JALR $R30, %SMSIG1
    MOV  $R16, $R2

    MOV  $R1, $R18
    JALR $R30, %SMSIG0
    MOV  $R18, $R2

    ADDU $R16, $R18
    ADDU $R16, $R17
    ADDU $R16, $R14 
    
    MOV  $R14, $R29
    ADDU $R14, %W_BASE

    SW   $R14, $R16 // Store the W_j value

    ADDU $R29, %FOUR
    MOV  $R14, $R29
    SUBU $R14, %S256
    BEQZ $R14, WLOOP_done 
    JALR $R0, %WLOOP
WLOOP_done:
    JALR $R0, $R13

// The main compression loop of SHA-256
// PRECONDITION: $R29 must be initialized to zero
SHAROUND:
    // Compute T1
    MOV  $R19, $R28
    MOV  $R1, $R25
    JALR $R30, %BIGSIG1
    ADDU $R19, $R2  // Add BigSig1(e)
    MOV  $R1, $R25
    MOV  $R2, $R26
    MOV  $R3, $R27
    JALR $R30, %CH
    ADDU $R19, $R4  // Add Ch(e,f,g)
    MOV  $R1, $R29
    ADDU $R1, %K_BASE // Compute offset from K
    LW   $R1, $R1
    ADDU $R19, $R1  // Add K_j
    MOV  $R1, $R29
    ADDU $R1, %W_BASE
    LW   $R1, $R1
    ADDU $R19, $R1  // Add W_j

    // Compute T2
    MOV  $R1, $R21
    JALR $R30, %BIGSIG0
    MOV  $R20, $R2 
    MOV  $R1, $R21
    MOV  $R2, $R22
    MOV  $R3, $R23
    JALR $R30, %MAJ
    ADDU $R20, $R4

    // Update 'a' to 'h'
    MOV  $R28, $R27 // h
    MOV  $R27, $R26 // g
    MOV  $R26, $R25 // f
    MOV  $R25, $R24 // e
    ADDU $R25, $R19
    MOV  $R24, $R23 // d
    MOV  $R23, $R22 // c
    MOV  $R22, $R21 // b
    MOV  $R21, $R19 // a
    ADDU $R21, $R20

    ADDU $R29, %FOUR
    MOV  $R14, %S256
    SUBU $R14, $R29
    BEQZ $R14, SHAROUND_done 
    JALR  $R31, %SHAROUND
SHAROUND_done:
    JALR  $R31, $R17

// right rotate subroutine
// $R7 : data to be rotated
// $R8 : rotate amount
// $R9 : return value
ROR:
    MOV  $R9, $R7
    MOV  $R10, %S32
    SUBU $R10, $R8
    SRLV $R7, $R8
    SLLV $R9, $R10
    OR   $R9, $R7 
    JALR $R7, $R31

// xor subroutine
// $R7 : A
// $R8 : B
// $R9 : return value
XOR:
    MOV $R9, $R7
    MOV $R10, $R8
    NOR $R9, $R9 // ~A
    NOR $R10, $R10 // ~B
    NOR $R9, $R10 // ~A NOR ~B
    NOR $R7, $R8 // A NOR B
    NOR $R9, $R7
    JALR $R7, $R31

    

// CH function from SHA-256
// $R1 : X value
// $R2 : Y value
// $R3 : Z value
// $R4 : return value
CH:
    MOV  $R5, $R1
    NOR  $R5, $R5  // ~X
    AND  $R1, $R2  // X and Y
    AND  $R5, $R3  // ~X and Z
    MOV  $R7, $R1
    MOV  $R8, $R5
    JALR $R31, %XOR 
    MOV  $R4, $R9
    JALR $R31, $R30

// MAJ function from SHA-256
// $R1 : X value
// $R2 : Y value
// $R3 : Z value
// $R4 : return value
MAJ:
   MOV  $R5, $R1
   MOV  $R6, $R2
   AND  $R5, $R2 // XY
   AND  $R6, $R3 // YZ
   AND  $R1, $R3 // XZ
   MOV  $R7, $R1
   MOV  $R8, $R5
   JALR $R31, %XOR 
   MOV  $R7, $R9
   MOV  $R8, $R6
   JALR $R31, %XOR
   MOV  $R4, $R9
   JALR $R31, $R30

// Big sigma 0 function from SHA-256 
// $R1 : X value
// $R2 : return value
BIGSIG0:
    MOV  $R7, $R1
    MOV  $R8, %S2
    JALR $R31, %ROR
    MOV  $R3, $R9  // term 1
    MOV  $R7, $R1
    MOV  $R8, %S3
    ADDU $R8, %S3
    ADDU $R8, %S7
    JALR $R31, %ROR
    MOV  $R4, $R9 // term 2
    MOV  $R7, $R1
    MOV  $R8, %S11
    ADDU $R8, %S11
    JALR $R31, %ROR
    MOV  $R7, $R9 // term 3
    MOV  $R8, $R4
    JALR $R31, %XOR
    MOV  $R7, $R9
    MOV  $R8, $R3
    JALR $R31, %XOR
    MOV  $R2, $R9
    JALR $R31, $R30

    
// Big sigma 1 function from SHA-256 
// $R1 : X value
// $R2 : return value
BIGSIG1:
    MOV  $R7, $R1
    MOV  $R8, %S3
    ADDU $R8, %S3
    JALR $R31, %ROR
    MOV  $R3, $R9 // term 1
    MOV  $R7, $R1
    MOV  $R8, %S11
    JALR $R31, %ROR
    MOV  $R4, $R9 // term 2
    MOV  $R7, $R1
    MOV  $R8, %S18
    ADDU $R8, %S7
    JALR $R31, %ROR
    MOV  $R7, $R9 // term 3
    MOV  $R8, $R4
    JALR $R31, %XOR
    MOV  $R7, $R9
    MOV  $R8, $R3
    JALR $R31, %XOR
    MOV  $R2, $R9
    JALR $R31, $R30

// Small sigma 0 function from SHA-256
// $R1 : X value
// $R2 : return value
SMSIG0:
    MOV  $R7, $R1
    MOV  $R8, %S7
    JALR $R31, %ROR
    MOV  $R3, $R9  // term 1
    MOV  $R7, $R1
    MOV  $R8, %S18
    JALR $R31, %ROR
    MOV  $R7, $R9  // term 2
    MOV  $R8, $R3
    JALR $R31, %XOR
    MOV  $R7, $R9
    MOV  $R8, $R1
    SRLV $R8, %S3
    JALR $R31, %XOR
    MOV  $R2, $R9
    JALR $R31, $R30


// Small sigma 1 function from SHA-256
// $R1 : X value
// $R2 : return value
SMSIG1:
    MOV  $R7, $R1
    MOV  $R8, %S17
    JALR $R31, %ROR
    MOV  $R3, $R9  // term 1
    MOV  $R7, $R1
    MOV  $R8, %S19
    JALR $R31, %ROR
    MOV  $R7, $R9  // term 2
    MOV  $R8, $R3
    JALR $R31, %XOR
    MOV  $R7, $R9
    MOV  $R8, $R1
    SRLV $R8, %S10
    JALR $R31, %XOR
    MOV  $R2, $R9
    JALR $R31, $R30

// EOF
