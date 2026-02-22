# High-level pseudocode:
# sum = 0
# for i = 1 to 10:
# sum = sum + i
# print sum
.data
	result_msg: .asciiz "Sum = "
	newline: .asciiz "\n"
.text
.globl main
main:
	li $t0, 0 # sum = 0
	li $t1, 1 # i = 1
	li $t2, 10 # limit = 10
loop:
	add $t0, $t0, $t1 # sum = sum + i

	addi $t1, $t1, 1 # i = i + 1
	# Check if i <= limit
	slt $t3, $t2, $t1 # $t3 = 1 if limit < i
	beq $t3, $zero, loop # if $t3 == 0, continue loop
	# Print result
	li $v0, 4
	la $a0, result_msg
	syscall
	li $v0, 1
	move $a0, $t0
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	# Exit
	li $v0, 10
	syscall