.data
	result_msg: .asciiz "Sum of even = "
	newline: .asciiz "\n"
	factorial_msg: .asciiz "Factorial = "
.text
.globl main
main:
	li $t0, 0 # sum = 0
	li $t1, 0 # i = 1
	li $t2, 20 # limit = 20
loop:
	add $t0, $t0, $t1 # sum = sum + i

	addi $t1, $t1, 2 # i = i + 1
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

	li $t1 5 # 5!
	li $t0 1 # factorial
	
factorial:
	beqz $t1 end_program
	mul $t0 $t1 $t0
	sub $t1 $t1 1
	j factorial
end_program:
	la $a0 factorial_msg
	li $v0 4
	syscall
	
	move $a0 $t0
	li $v0 1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	li $v0 10
	syscall
	
	
	

