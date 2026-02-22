.data
	prompt: .asciiz "Enter a number: "
	ans: .asciiz "The sum of squares from 1 is: "
	newline: .asciiz "\n"
	
.text
.globl main

main:
	la $a0 prompt
	li $v0 4
	syscall
	
	li $v0 5
	syscall
	
	
	move $t4 $v0
	li $t0 0
	li $t1 0
	
	la $a0 newline
	li $v0 4
	syscall
	
	
loop:
	beq $t4 $t1 end_program
	addi $t1 $t1 1
	mul $t3 $t1 $t1
	add $t0 $t0 $t3
	j loop
	
end_program:
	la $a0 ans
	li $v0 4
	syscall
	
	move $a0 $t0
	li $v0 1
	syscall
	

	li $v0 10
	syscall
