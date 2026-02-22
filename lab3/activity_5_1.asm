# Program: Recursive factorial
.data
    prompt: .asciiz "Enter n for factorial: "
    result_msg: .asciiz "Factorial: "
    newline: .asciiz "\n"
.text
.globl main
main:
    li $v0, 4
    la $a0, prompt
    syscall
    li $v0, 5
    syscall
    move $a0, $v0
    jal factorial
    move $t0, $v0
    li $v0, 4
    la $a0, result_msg
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 10
    syscall
    # Procedure: factorial
    # Input: $a0 = n
    # Output: $v0 = n!
    # Recursive: factorial(n) = n * factorial(n-1)
    # Base case: factorial(0) = 1
factorial:
    # Save return address and argument
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    # Base case: if n == 0, return 1

    li $t0, 1
    beq $a0, $zero, base_case
    # Recursive case: n * factorial(n-1)
    addi $a0, $a0, -1 # n - 1
    jal factorial # Recursive call
    # Restore n from stack
    lw $a0, 0($sp)
    # Multiply n * factorial(n-1)
    mul $v0, $a0, $v0
    j factorial_return
    base_case:
    li $v0, 1
factorial_return:
    # Restore return address
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
