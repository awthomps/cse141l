// Purpose of this assembly file is to test every instruction in vanilla core.
// In each test a counter is increased and if the test is passed, it is written
// to place 0xC0FFEEEE in the data memory, otherwise it will be written in the
// 0xDEADDEAD location and the wrong calculated value will be written in 0xC0DEC0DE
// Location, which these location accesses will cause the testbench to stop.

// There is a function which gets the test number, the calculated value and the
// desired value, and implements the mentioned work. However, before calling this
// subroutine, the instructions which are used within it are tested separately.
// First of all a BEQ in forward and backward direction, then the mov instruction,
// ADDU, SUBU and JALR are tested in order. IF all of them are passed, the subroutine
// can be called, and rest of the instructions are tested using this subroutine. 

// It is assumed that SW instruction is correct, otherwise there would not be any 
// writes at all which can be detected in the test bench.

.data
LW_Test:
.word 0xAAAA5555
LBU_TEST:
.word 0x00000000

.kernel tester

// Constant values of 1 and 6 which are required during the program
.const %ONE      , 1
.const %SIX      , 6

.text

// Test for BEQ
BEQZ  $R0,START
//MOV   %R0,%R0

// Check_answer subroutine

// Preconditions: $R5 = test number, $R6 = good answer, 
//                $R7 = actual answer, $R1 = return address
// Postconditions: $R7 is contaminated. 
//                 If the actual answer is correct, the test number will be 
//                 stored in the data memory pointed by $R10. IF it is wrong,
//                 the computed value and test number will be stored in the 
//                 data memory pointed by $R11 and $R12, respectively. Moreover,
//                 $R11 and $R12 are increased by one for future error occurance. 
// Invariants: test number and good answer is still valid.

// Address of the subroutine
.const %CHECK    , CHECK_ANSWER

CHECK_ANSWER:

SUBU  $R7,$R6
BEQZ  $R7,PASS
//MOV   %R0,%R0

ADDU  $R7, $R6           // Reconstruct wrong answer
SW    $R11, $R7    // Output wrong answer
SW    $R12, $R5    // Indicate failed test
ADDU  $R11, %ONE
ADDU  $R12, %ONE
JALR  $R0,$R1
//MOV   %R0,%R0

PASS:

SW    $R10, $R5    // indicate passed test
JALR  $R0,$R1
//MOV   %R0,%R0

// Backward jump test
START0:
BEQZ  $R0,START1
//MOV   %R0,%R0

// Start of the test
START:
BEQZ  $R0,START0
//MOV   %R0,%R0

START1:

// Test for MOV
MOV   $R5,%ONE
.const %CODE_Test,  0xC0DEC0DE
.const %FAIL_Test,  0xDEADDEAD
.const %PASS_Test,  0xC0FFEEEE
.const %DONE_Test,  0x600DBEEF
MOV   $R10,%PASS_Test
MOV   $R11,%CODE_Test
MOV   $R12,%FAIL_Test
MOV   $R13,%DONE_Test

BEQZ  $R5, WRONG1
//MOV   %R0,%R0
SW    $R10,$R5   // indicate passed test
BEQZ  $R0, CONT0
//MOV   %R0,%R0

WRONG1:
SW    $R11,$R5  // Output wrong answer
SW    $R12,$R5  // Indicate failed test

CONT0:
// Test for ADDU
.constreg $C5, 0x11111111
.constreg $C6, 0xEEEEEEEF
ADDU  $R5,%ONE      // Update test counter 
MOV   $R7,$C5
ADDU  $R7,$C6
BEQZ  $R7,CONT1
//MOV   %R0,%R0
SW    $R11,$R5   // Output wrong answer
SW    $R12,$R5   // Indicate failed test

CONT1:
SW    $R10,$R5   // Indicate passed test

// Test for SUBU
ADDU  $R5,%ONE      // Update test counter 
MOV   $R7,$R0
SUBU  $R7,%ONE
ADDU  $R7,%ONE
BEQZ  $R7,CONT2
//MOV   %R0,%R0
SW    $R11,$R5   // Output wrong answer
SW    $R12,$R5   // Indicate failed test

CONT2:
SW    $R10,$R5   // Indicate passed test

// Test for ADDU and SUBU
ADDU  $R5,%ONE      // Update test counter 
MOV   $R7,$R0
SUBU  $R7,%ONE
ADDU  $R7,%ONE
BEQZ  $R7,CONT3
//MOV   %R0,%R0
SW    $R11,$R5   // Output wrong answer
SW    $R12,$R5   // Indicate failed test

CONT3:
SW    $R10,$R5   // Indicate passed test

// Test for JALR
ADDU  $R5,%ONE
.const %NEXT     , NEXT
JALR  $R1,%NEXT
//MOV   %R0,%R0
SW    $R12, $R5    // Indicate failed test

NEXT:
//Change the return address to the PASSED_JALR line.
ADDU  $R1,%SIX    
JALR  $R0,$R1
//MOV   %R0,%R0
SW    $R12, $R5    // Indicate failed test

PASSED_JALR:
SW    $R10, $R5    // indicate passed test


// Test for LBU
ADDU  $R5,%ONE
.constreg $C1, 0xAAAA5555
.constreg $C2, 0x000000AA
.const %LBU_TEST, LBU_TEST
MOV   $R8,%LBU_TEST
SW    $R8,$C1
ADDU  $R8,%ONE
ADDU  $R8,%ONE
LBU   $R7,$R8
MOV   $R6,$C2
// Call the checker subroutine, $R5 = test number, 
// $R6 = good answer, $R7 = actual answer, $R1 = return address
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for LW
ADDU  $R5,%ONE
.const %LW_Test, LW_Test, 3
MOV   $R7,$R0
LW    $R7,$C3
MOV   $R6,$C1
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for SB
ADDU  $R5,%ONE
.constreg $C4,0xAA005555
MOV   $R8,%LBU_TEST
ADDU  $R8,%ONE
ADDU  $R8,%ONE
SB    $R8,$R0
MOV   $R7,$R0
LW    $R7,%LBU_TEST
MOV   $R6,$C4
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for BNEQZ
ADDU  $R5,%ONE
MOV   $R2,$R0
ADDU  $R2,%ONE
BNEQZ $R2,CONT4
//MOV   %R0,%R0
SW    $R12,$R5   // Indicate failed test
BEQZ  $R0, CONT5
//MOV   %R0,%R0
CONT4:
SW    $R10,$R5  //Indicate Passed Test
CONT5:

// Test for BLTZ
ADDU  $R5,%ONE
MOV   $R2,$R0
SUBU  $R2,%ONE
BLTZ  $R2,CONT6
SW    $R12,$R5   // Indicate failed test
BEQZ  $R0, CONT7
//MOV   %R0,%R0
CONT6:
SW    $R10,$R5  //Indicate Passed Test
CONT7:

// Test for BGTZ
ADDU  $R5,%ONE
MOV   $R2,$R0
ADDU  $R2,%ONE
BGTZ  $R2,CONT8
//MOV   %R0,%R0
SW    $R12,$R5   // Indicate failed test
BEQZ  $R0, CONT9
//MOV   %R0,%R0
CONT8:
SW    $R10,$R5  //Indicate Passed Test
CONT9:

// Test for SLT
ADDU  $R5,%ONE
MOV   $R7,$R0
SUBU  $R7,%ONE
SLT   $R7,$R0
MOV   $R6,%ONE
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for SLTU
ADDU  $R5,%ONE
MOV   $R7,$R0
SUBU  $R7,%ONE
SLTU  $R7,$R0
MOV   $R6,$R0
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for AND
.const %LOGIC1   , 0x0000FFFF
.const %LOGIC2   , 0x00FF00FF
.const %AND_ANS  , 0x000000FF
ADDU  $R5,%ONE
MOV   $R7,%LOGIC1
MOV   $R2,%LOGIC2
AND   $R7,$R2
MOV   $R6,%AND_ANS
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for OR
.const %OR_ANS   , 0x00FFFFFF
ADDU  $R5,%ONE
MOV   $R7,%LOGIC1
MOV   $R2,%LOGIC2
OR    $R7,$R2
MOV   $R6,%OR_ANS
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for NOR
.const %NOR_ANS  , 0xFF000000
ADDU  $R5,%ONE
MOV   $R7,%LOGIC1
MOV   $R2,%LOGIC2
NOR   $R7,$R2
MOV   $R6,%NOR_ANS
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for SLLV
.const %SHIFT_INP, 0x80000000
ADDU  $R5,%ONE
MOV   $R7,%SHIFT_INP
SLLV  $R7,%ONE
MOV   $R6,$R0
JALR  $R1,%CHECK
//MOV   %R0,%R0

// Test for SRAV
.const %SRAV_ANS , 0xC0000000
ADDU  $R5,%ONE
MOV   $R7,%SHIFT_INP
SRAV  $R7,%ONE
MOV   $R6,%SRAV_ANS
JALR  $R1,%CHECK
//MOV   %R0,%R0


// Test for SRLV
.const %SRLV_ANS , 0x40000000
ADDU  $R5,%ONE
MOV   $R7,%SHIFT_INP
SRLV  $R7,%ONE
MOV   $R6,%SRLV_ANS
JALR  $R1,%CHECK
//MOV   %R0,%R0

// We can check the correctness of BAR instrution 
// through the output barrier signal.
.const %BARRIER  , 0xFF
BAR %BARRIER
SW    $R13, $R5    // Indicate the test is finished

DONE
// In case the DONE instruction is problematic.
ADDU  $R5,%ONE
SW    $R12, $R5    // Indicate failed test
