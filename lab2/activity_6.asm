# Program: Menu-driven calculator
.data
	menu: .asciiz "\n=== Calculator ===\n1. Add\n2. Subtract\n3. Multiply\n4. Divide\n5. Exit\nChoice: "
	prompt1: .asciiz "Enter first number: "
	prompt2: .asciiz "Enter second number: "
	result_msg: .asciiz "Result: "
	newline: .asciiz "\n"

	invalid_msg: .asciiz "Invalid choice!\n"
.text
.globl main
main:
menu_loop:
	# Display menu
	li $v0, 4
	la $a0, menu
	syscall
	# Get choice
	li $v0, 5
	syscall
	move $t0, $v0
	# Check for exit
	li $t1, 5
	beq $t0, $t1, exit_program
	# Get two numbers
	li $v0, 4
	la $a0, prompt1
	syscall
	li $v0, 5
	syscall
	move $s0, $v0 # First number in $s0
	li $v0, 4
	la $a0, prompt2
	syscall
	li $v0, 5
	syscall
	move $s1, $v0 # Second number in $s1

switch:
	beq $t0 1 add_case
	beq $t0 2 sub_case
	beq $t0 3 mul_case
	beq $t0 4 div_case
	j invalid_case 


add_case:
	add $s2, $s0, $s1
	j print_result
sub_case:
	sub $s2, $s0, $s1
	j print_result
mul_case:
	mul $s2, $s0, $s1
	j print_result

div_case:
	div $s0, $s1
	mflo $s2
	j print_result
invalid_case:
	li $v0, 4
	la $a0, invalid_msg
	syscall
	j menu_loop
print_result:
	li $v0, 4
	la $a0, result_msg
	syscall
	li $v0, 1
	move $a0, $s2
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	j menu_loop
exit_program:
	li $v0, 10
	syscall