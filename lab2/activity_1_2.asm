# High-level pseudocode:
# if (a > b):
# print "A is greater"
# else:
# print "B is greater or equal"

.data
	greater_msg: .asciiz "First number is greater\n"
	less_msg: .asciiz "Second number is greater or equal\n"
.text
.globl main

main:

	li $t0, 28
	li $t1, 15

	bgt $t0, $t1, greater_case

	li $v0, 4
	la $a0, less_msg
	syscall
	j end_program
greater_case:
	li $v0, 4
	la $a0, greater_msg
	syscall
end_program:
	li $v0, 10

	syscall