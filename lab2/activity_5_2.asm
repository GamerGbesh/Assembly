.data
	space: .asciiz " "
	newline: .asciiz "\n"
	tab: .asciiz "\t"
.text
.globl main

main:
	li $t0 1
	li $t1 5
outer:
	li $t2 1
	addi $t3 $t0 1
inner:	
	move $a0 $t2
	li $v0 1
	syscall
	
	la $a0 space
	li $v0 4
	syscall
	
	addi $t2 $t2 1
	blt $t2 $t3 inner
	
	addi $t0 $t0 1
	la $a0 newline
	li $v0 4
	syscall
	
	ble  $t0 $t1 outer
	
	li $v0 10
	syscall