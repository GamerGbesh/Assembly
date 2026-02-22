# Program: Generate 5x5 multiplication table
.data
	space: .asciiz " "
	newline: .asciiz "\n"
	tab: .asciiz "\t"
.text
.globl main

main:
	li $t0, 1 # outer loop counter (row)
	li $t5, 5 # outer loop limit
	
outer_loop:
	li $t1, 1 # inner loop counter (column)
	li $t6, 5 # inner loop limit
	
inner_loop:

	# Calculate product: row * column
	mul $t2, $t0, $t1
	# Print product
	li $v0, 1

	move $a0, $t2
	syscall
	# Print tab
	li $v0, 4
	la $a0, tab
	syscall
	# Increment inner counter
	addi $t1, $t1, 1
	# Check inner loop condition
	slt $t3, $t6, $t1
	beq $t3, $zero, inner_loop
	# Print newline after each row
	li $v0, 4
	la $a0, newline
	syscall
	# Increment outer counter
	addi $t0, $t0, 1
	# Check outer loop condition
	slt $t4, $t5, $t0
	beq $t4, $zero, outer_loop
	# Exit
	li $v0, 10