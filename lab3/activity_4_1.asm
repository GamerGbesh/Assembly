# Program: Calculate result = (a * b) + (c * d)
.data
result_msg: .asciiz "Result: "
newline: .asciiz "\n"
.text
.globl main
main:
# Load test values
li $a0, 5 # a = 5
li $a1, 7 # b = 7
li $a2, 3 # c = 3
li $a3, 4 # d = 4
# Call procedure
jal calculate
move $t0, $v0
# Print result
li $v0, 4
la $a0, result_msg
syscall
li $v0, 1
move $a0, $t0
syscall
# Exit

li $v0, 10
syscall
# Procedure: calculate
# Input: $a0 = a, $a1 = b, $a2 = c, $a3 = d
# Output: $v0 = (a * b) + (c * d)
calculate:
mul $t0, $a0, $a1 # $t0 = a * b
mul $t1, $a2, $a3 # $t1 = c * d
add $v0, $t0, $t1 # $v0 = (a*b) + (c*d)
jr $ra