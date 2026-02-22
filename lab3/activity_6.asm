# Program: Complex procedure with local variables
.text
.globl main
main:
    li $a0, 10
    li $a1, 20
    jal complex_proc
    move $t0, $v0
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 10

    syscall
    # Procedure: complex_proc
    # Demonstrates complete stack frame with:
    # - Saved registers
    # - Local variables
    # - Nested procedure call
complex_proc:
    # Create stack frame
    # Frame layout (from high to low address):
    # +16: saved $ra
    # +12: saved $s0
    # +8: saved $s1
    # +4: local var 1
    # +0: local var 2
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    # Use parameters and create local variables
    move $s0, $a0 # Save first parameter
    move $s1, $a1 # Save second parameter
    # Local var 1 = a0 * 2
    mul $t0, $s0, 2
    sw $t0, 4($sp)
    # Local var 2 = a1 * 3
    mul $t1, $s1, 3
    sw $t1, 0($sp)
    # Call helper procedure
    move $a0, $s0
    jal helper_proc
    move $t2, $v0
    # Compute final result using local variables
    lw $t3, 4($sp) # Load local var 1
    lw $t4, 0($sp) # Load local var 2
    add $v0, $t3, $t4
    add $v0, $v0, $t2
    # Restore and return
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
helper_proc:
    mul $v0, $a0, $a0
    jr $ra