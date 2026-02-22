# Program: Sum positive numbers until negative input
.data
	prompt: .asciiz "Enter a number (negative to stop): "
	result_msg: .asciiz "Sum of positive numbers: "
	count_msg: .asciiz "Count of numbers entered: "
	newline: .asciiz "\n"
.text
.globl main
main:
	li $t0, 0 # sum = 0
	li $t1, 0 # count = 0
input_loop:

	# Prompt user
	li $v0, 4
	la $a0, prompt
	syscall
	# Read integer
	li $v0, 5
	syscall
	move $t2, $v0 # Store input in $t2
# YOUR CODE HERE
# Check if number is negative (use slt or bltz)
# If negative, exit loop
# Otherwise, add to sum and increment count
# Jump back to input_loop
	bltz $t2 end_loop
	addi $t1 $t1 1
	add $t0 $t2 $t0
	j input_loop
	
end_loop:
# Print results
# YOUR CODE HERE
# Exit
	la $a0 result_msg
	li $v0 4
	syscall
	
	move $a0 $t0
	li $v0 1
	syscall
	
	la $a0 newline
	li $v0 4
	syscall
	
	la $a0 count_msg
	li $v0 4
	syscall
	
	move $a0 $t1
	li $v0 1
	syscall
	
	la $a0 newline
	li $v0 4
	syscall
	
	li $v0, 10
	syscall