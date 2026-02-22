.data
	result_msg: .asciiz "Comparison result: "
	newline: .asciiz "\n"
.text
.globl main
main:
	li $t0, 15 # First number
	li $t1, 23 # Second number
	# Set less than: if $t0 < $t1, then $t2 = 1, else $t2 = 0
	slt $t2, $t0, $t1
	# Print result
	li $v0, 4
	la $a0, result_msg
	syscall
	li $v0, 1
	move $a0, $t2
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	# Exit
	li $v0, 10
	syscall