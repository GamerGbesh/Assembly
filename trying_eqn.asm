# 3x + 2
 .data
	 newline: .asciiz "\n"
 	 ans: .asciiz "3("
 	 ans2: .asciiz ") + 2 is: "
 .text 
 .globl main
 
 main:
 
 	li $t1, 3
 	li $t2, 2
 	# Store 2 in t1 and 3 in t2
 	
 	li $v0, 5
 	syscall
 	
 	move $t0, $v0 # Store the x value in t0
 	mult $t0, $t1 # 3 * x
 	mflo $t3
 	add $t3, $t3, $t2 # 3x + 2
 	
 	li $v0, 4
 	la $a0, ans
 	syscall
 	
 	move $a0, $t0
 	li $v0, 1
 	syscall
 	
 	li $v0 4
 	la $a0, ans2
 	syscall
 	
 	move $a0, $t3
 	li $v0, 1
 	syscall

 	li $v0, 10
 	syscall
 	
