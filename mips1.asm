 .data
	 newline: .asciiz "\n"
 	msg: .asciiz "This is the number: "
  
 .text 
 .globl main
 
 main:
 	li $t2, 3
 	li $t3, 4
 	
 	add $t1, $t2, $t3
 	move $a0, $t1
 	li $v0, 1
 	syscall
 	
 	la $a0, newline
 	li $v0, 4 
 	syscall
 	
 	li $v0, 5
 	syscall 
 	
 	move $t6, $v0
 	syscall	
 	
 	la $a0, msg
 	li $v0, 4
 	syscall
 	
 	
 	move $a0, $t6
 	li $v0, 1
 	syscall
 	
 	la $a0, newline
 	li $v0 4
 	syscall
 	
 	li $v0, 10
 	syscall
 	
 	
