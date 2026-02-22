 .data
	 newline: .asciiz "\n"
 	msg: .asciiz "This is the number: "
 	prompt: .asciiz "Enter a number\n"
  
 .text 
 .globl main
 
 main:
 	la $a0, prompt
 	li $v0, 4
 	syscall
 	
 	li $v0, 5
 	syscall
 	
 	move $a1, $v0
 	la $a0, msg
 	li $v0, 4
 	syscall
 	
 	move $a0, $a1
 	li $v0, 1
 	syscall
 	
 	
 	li $v0, 10
 	syscall
 	
 	