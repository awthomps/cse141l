.data
// The two first fibonnaci numbers.
FIBO:
.word 0x01
.word 0x01

.kernel test
// Some required constans.
.const %four,4
.const %one, 1
// Pointing to start of the list of fibonnaci numbers.
.const %start,FIBO
// Desired number of new fibonnaci numbers to be calculated.
.const %length,10
// Pointing to the fib_add_next function. 
.const %fib_add_next, fib_add_next
// Desired Barrier output. 
.const %barrier, 0x7

.text
// Making $r2 and $r3 point to data memory location of the first two fibonnaci values.
mov $r2,%start
mov $r3,%start
addu $r3,%four
// Using $r4 as the loop variable, which produces the fibonnaci numbers.
mov $r4,%length
loop:
// End of loop condition
beqz $r4,end    
// Calling the fib_add_next function, which computes the next fibonnaci number and updates the $r2 and $r3 to point to the new last two fibonnaci numbers of the list.
jalr $r1,%fib_add_next
subu $r4,%one
// An unconditional jump
beqz $r0,loop

end:
bar %barrier
done

// Preconditions: r2 and r3 are pointers to the last two fibonnaci numbers of a list of fibonnaci numbers.
// Postconditions: r5 and r6 are contaminated. 
//                 *(r3 + 4) contains the next fibonnaci number.
// Invariants: r2 and r3 point to the new last two fibonnaci numbers of the updated list of fibonnaci numbers..
fib_add_next:
// Loading the values from the data memory.
mov $r5,$r0
lw  $r5,$r2
mov $r6,$r0
lw  $r6,$r3
// Computing the new fibonnaci number.
addu $r5,$r6
// Updating $r2 and $r3 to point to the new last two fibonnaci numbers.
mov  $r2,$r3
addu $r3,%four
// Storing the new fibonnaci number.
sw   $r3,$r5
// Returning from the subroutine.
jalr $r0,$r1
