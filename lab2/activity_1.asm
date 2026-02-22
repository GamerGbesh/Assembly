.data
	equal_msg: .asciiz "Numbers are equal\n"
	not_equal_msg: .asciiz "Numbers are not equal\n"
	greater_msg: .asciiz "First number is greater\n"
	less_msg: .asciiz "First number is less\n"
.text
.globl main

main:
	# Initialize test values
	li $t0, 12
	li $t1, 10
	# Branch if equal
	beq $t0, $t1, equal_case
	# This executes if NOT equal
	li $v0, 4
	la $a0, not_equal_msg
	syscall
	j end_program
equal_case:
	li $v0, 4
	la $a0, equal_msg
	syscall
end_program:
	li $v0, 10

	syscall