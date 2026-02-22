.data
	prompt: .asciiz "What is your name\n"
	msg: .asciiz "Your name is: "
	ans: .space 100
.text
.globl main

main:
	la $a0, prompt
	li $v0, 4
	syscall
	
	li $v0, 8
	la $a0, ans
	li $a1, 100
	syscall
	
	la  $a0, msg
	li $v0, 4
	syscall
	
	la $a0, ans
	li $v0, 4
	syscall
	
	
	
	
