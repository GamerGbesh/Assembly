# Recursive Fibonacci with call counter

.data
result_msg:   .asciiz "Fibonacci result: "
calls_msg:    .asciiz "\nRecursive calls: "
newline:      .asciiz "\n"
call_count:   .word 0          # global counter

.text
.globl main

main:
    li $a0, 10          # fib(10)
    jal fib

    move $t0, $v0       # save fib result

    # Print Fibonacci result
    li $v0, 4
    la $a0, result_msg
    syscall

    li $v0, 1
    move $a0, $t0
    syscall

    # Print call counter
    li $v0, 4
    la $a0, calls_msg
    syscall

    lw $a0, call_count
    li $v0, 1
    syscall

    li $v0, 10
    syscall


# --------------------------------
# Recursive Fibonacci
# Input:  $a0 = n
# Output: $v0 = fib(n)
# --------------------------------

fib:

    # Increment call counter
    lw   $t0, call_count
    addi $t0, $t0, 1
    sw   $t0, call_count

    # Base case: if n == 0 → return 0
    beq  $a0, $zero, fib_zero

    # Base case: if n == 1 → return 1
    li   $t1, 1
    beq  $a0, $t1, fib_one

    # ---- Recursive Case ----
    # Create stack frame
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $a0, 4($sp)     # save original n

    # fib(n-1)
    addi $a0, $a0, -1
    jal  fib
    sw   $v0, 0($sp)     # store fib(n-1)

    # Restore original n
    lw   $a0, 4($sp)

    # fib(n-2)
    addi $a0, $a0, -2
    jal  fib

    # Add fib(n-1) + fib(n-2)
    lw   $t2, 0($sp)
    add  $v0, $v0, $t2

    # Restore registers
    lw   $ra, 8($sp)
    addi $sp, $sp, 12

    jr   $ra


fib_zero:
    li $v0, 0
    jr $ra

fib_one:
    li $v0, 1
    jr $ra