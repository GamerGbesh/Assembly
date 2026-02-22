############################################################
# Assignment 1: String Processing Library
# Implements: strlen, strcpy, strcmp, strcat, str_reverse
############################################################

.data

# Test strings
str1:        .asciiz "Hello"
str2:        .asciiz "World"
empty_str:   .asciiz ""

buffer1:     .space 100
buffer2:     .space 100

msg_strlen:  .asciiz "\nLength: "
msg_strcmp:  .asciiz "\nCompare result: "
msg_result:  .asciiz "\nResult: "
newline:     .asciiz "\n"

.text
.globl main

############################################################
# MAIN PROGRAM
# Demonstrates all 5 procedures
############################################################
main:

#########################
# Test strlen
#########################

    la $a0, str1
    jal strlen
    move $t0, $v0

    li $v0, 4
    la $a0, msg_strlen
    syscall

    li $v0, 1
    move $a0, $t0
    syscall


#########################
# Test strcpy
#########################

    la $a0, buffer1     # destination
    la $a1, str1        # source
    jal strcpy

    li $v0, 4
    la $a0, msg_result
    syscall

    li $v0, 4
    la $a0, buffer1
    syscall


#########################
# Test strcmp
#########################

    la $a0, str1
    la $a1, str2
    jal strcmp
    move $t0, $v0

    li $v0, 4
    la $a0, msg_strcmp
    syscall

    li $v0, 1
    move $a0, $t0
    syscall


#########################
# Test strcat
#########################

    la $a0, buffer1
    la $a1, str2
    jal strcat

    li $v0, 4
    la $a0, msg_result
    syscall

    li $v0, 4
    la $a0, buffer1
    syscall


#########################
# Test str_reverse
#########################

    la $a0, buffer1
    jal str_reverse

    li $v0, 4
    la $a0, msg_result
    syscall

    li $v0, 4
    la $a0, buffer1
    syscall


    li $v0, 10
    syscall


############################################################
# PROCEDURE: strlen
# Purpose: Calculate length of null-terminated string
# Input:  $a0 = address of string
# Return: $v0 = length (integer)
# Registers modified: $t0, $t1
############################################################
strlen:
    li $t0, 0          # counter

strlen_loop:
    lb $t1, 0($a0)
    beq $t1, $zero, strlen_done
    addi $t0, $t0, 1
    addi $a0, $a0, 1
    j strlen_loop

strlen_done:
    move $v0, $t0
    jr $ra


############################################################
# PROCEDURE: strcpy
# Purpose: Copy source string into destination
# Input:  $a0 = destination
#         $a1 = source
# Return: None
# Registers modified: $t0
############################################################
strcpy:
strcpy_loop:
    lb $t0, 0($a1)
    sb $t0, 0($a0)
    beq $t0, $zero, strcpy_done
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j strcpy_loop

strcpy_done:
    jr $ra


############################################################
# PROCEDURE: strcmp
# Purpose: Compare two strings
# Input:  $a0 = string1
#         $a1 = string2
# Return: $v0 = -1, 0, or 1
# Registers modified: $t0, $t1
############################################################
strcmp:
strcmp_loop:
    lb $t0, 0($a0)
    lb $t1, 0($a1)

    bne $t0, $t1, strcmp_diff
    beq $t0, $zero, strcmp_equal

    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j strcmp_loop

strcmp_diff:
    blt $t0, $t1, less
    li $v0, 1
    jr $ra

less:
    li $v0, -1
    jr $ra

strcmp_equal:
    li $v0, 0
    jr $ra


############################################################
# PROCEDURE: strcat
# Purpose: Append source to end of destination
# Input:  $a0 = destination
#         $a1 = source
# Return: None
# Registers modified: $t0
############################################################
strcat:

# Find end of destination
find_end:
    lb $t0, 0($a0)
    beq $t0, $zero, append
    addi $a0, $a0, 1
    j find_end

append:
strcat_loop:
    lb $t0, 0($a1)
    sb $t0, 0($a0)
    beq $t0, $zero, strcat_done
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j strcat_loop

strcat_done:
    jr $ra


############################################################
# PROCEDURE: str_reverse
# Purpose: Reverse string in place
# Input:  $a0 = address of string
# Return: None
# Registers modified: $t0-$t4
# Uses: strlen (non-leaf → uses stack)
############################################################
str_reverse:

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    move $t4, $a0       # save base pointer

    jal strlen
    move $t0, $v0       # length

    addi $t1, $zero, 0  # left index
    addi $t2, $t0, -1   # right index

reverse_loop:
    bge $t1, $t2, reverse_done

    add $t3, $t4, $t1
    lb $t0, 0($t3)

    add $t3, $t4, $t2
    lb $t5, 0($t3)

    add $t3, $t4, $t1
    sb $t5, 0($t3)

    add $t3, $t4, $t2
    sb $t0, 0($t3)

    addi $t1, $t1, 1
    addi $t2, $t2, -1
    j reverse_loop

reverse_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
