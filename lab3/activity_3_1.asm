# Program: Calculating sum of squares
.data
prompt: .asciiz "Enter a number: "

result_msg: .asciiz "Sum of squares from 1 to n: "
newline: .asciiz "\n"
.text
.globl main
main:
# Get input
li $v0, 4
la $a0, prompt
syscall
li $v0, 5
syscall
move $a0, $v0
# Call sum_of_squares
jal sum_of_squares
move $t0, $v0
# Display result
li $v0, 4
la $a0, result_msg
syscall
li $v0, 1
move $a0, $t0
syscall
# Exit
li $v0, 10
syscall
# Procedure: sum_of_squares
# Input: $a0 = n
# Output: $v0 = 1^2 + 2^2 + ... + n^2
# This is a NON-LEAF procedure (calls square)
sum_of_squares:
# Save registers on stack
addi $sp, $sp, -12
sw $ra, 8($sp)
sw $s0, 4($sp)
sw $s1, 0($sp)

# Initialize
move $s1, $a0      # s1 = n (limit)
li   $s0, 0        # s0 = sum
li   $t0, 1        # t0 = i (counter)

loop:
    bgt  $t0, $s1, done   # if i > n, exit loop

    # Call square(i)
    move $a0, $t0
    jal  square

    # Add returned value to sum
    add  $s0, $s0, $v0

    # i++
    addi $t0, $t0, 1

    j loop

done:
    move $v0, $s0     # save result BEFORE restoring

    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12

    jr $ra
# Procedure: square (from previous task)
square:
mul $v0, $a0, $a0
jr $ra
