mips
# Program: Stack Demonstration
.data
msg1: .asciiz "Stack pointer initially: "
msg2: .asciiz "After pushes: "
msg3: .asciiz "After pops: "
newline: .asciiz "\n"
.text
.globl main
main:
# Display initial stack pointer
li $v0, 4
la $a0, msg1
syscall
li $v0, 34 # Print hex
move $a0, $sp
syscall
li $v0, 4
la $a0, newline
syscall
# Push three values onto stack
addi $sp, $sp, -12 # Allocate space for 3 words
li $t0, 100
sw $t0, 8($sp) # Store first value
li $t1, 200
sw $t1, 4($sp) # Store second value
li $t2, 300
sw $t2, 0($sp) # Store third value
# Display stack pointer after pushes
li $v0, 4
la $a0, msg2
syscall
li $v0, 34
move $a0, $sp

syscall
li $v0, 4
la $a0, newline
syscall
# Pop values back
lw $t3, 0($sp) # Load values in reverse order
lw $t4, 4($sp)
lw $t5, 8($sp)
addi $sp, $sp, 12 # Deallocate space
# Display stack pointer after pops
li $v0, 4
la $a0, msg3
syscall
li $v0, 34
move $a0, $sp
syscall
# Exit
li $v0, 10
syscall