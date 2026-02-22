############################################################
# 3x3 Matrix Operations Library
# Implements:
# 1. matrix_input
# 2. matrix_print
# 3. matrix_add
# 4. matrix_multiply
# 5. matrix_transpose
############################################################

.data

matrixA:   .space 36     # 9 words (9 * 4 bytes)
matrixB:   .space 36
matrixC:   .space 36     # result matrix

menu: .asciiz "\n1.Input A\n2.Input B\n3.Print A\n4.Print B\n5.Add\n6.Multiply\n7.Transpose A\n8.Exit\nChoice: "
newline: .asciiz "\n"
space: .asciiz " "

.text
.globl main

############################################################
# MAIN MENU
############################################################
main:

menu_loop:
    li $v0, 4
    la $a0, menu
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    beq $t0, 1, inputA
    beq $t0, 2, inputB
    beq $t0, 3, printA
    beq $t0, 4, printB
    beq $t0, 5, addAB
    beq $t0, 6, multAB
    beq $t0, 7, transposeA
    beq $t0, 8, exit

    j menu_loop

############################################################
# MENU OPTIONS
############################################################

inputA:
    la $a0, matrixA
    jal matrix_input
    j menu_loop

inputB:
    la $a0, matrixB
    jal matrix_input
    j menu_loop

printA:
    la $a0, matrixA
    jal matrix_print
    j menu_loop

printB:
    la $a0, matrixB
    jal matrix_print
    j menu_loop

addAB:
    la $a0, matrixA
    la $a1, matrixB
    la $a2, matrixC
    jal matrix_add

    la $a0, matrixC
    jal matrix_print
    j menu_loop

multAB:
    la $a0, matrixA
    la $a1, matrixB
    la $a2, matrixC
    jal matrix_multiply

    la $a0, matrixC
    jal matrix_print
    j menu_loop

transposeA:
    la $a0, matrixA
    la $a1, matrixC
    jal matrix_transpose

    la $a0, matrixC
    jal matrix_print
    j menu_loop

exit:
    li $v0, 10
    syscall

############################################################
# PROCEDURE: matrix_input
# Purpose: Read 9 integers into matrix
# Input:  $a0 = base address
# Return: none
# Modified: $t0,$t1
############################################################
matrix_input:
    li $t0, 0

input_loop:
    beq $t0, 9, input_done

    li $v0, 5
    syscall

    sll $t1, $t0, 2
    add $t1, $a0, $t1
    sw $v0, 0($t1)

    addi $t0, $t0, 1
    j input_loop

input_done:
    jr $ra

############################################################
# PROCEDURE: matrix_print
# Purpose: Print 3x3 matrix formatted
# Input: $a0 = base address
# Return: none
# Modified: $t0,$t1,$t2
############################################################
matrix_print:
    li $t0, 0

print_loop:
    beq $t0, 9, print_done

    sll $t1, $t0, 2
    add $t1, $a0, $t1
    lw $a1, 0($t1)

    li $v0, 1
    move $a0, $a1
    syscall

    li $v0, 4
    la $a0, space
    syscall

    addi $t2, $t0, 1
    li $t3, 3
    div $t2, $t3
    mfhi $t4
    bne $t4, $zero, skip_newline

    li $v0, 4
    la $a0, newline
    syscall

skip_newline:
    addi $t0, $t0, 1
    j print_loop

print_done:
    jr $ra

############################################################
# PROCEDURE: matrix_add
# Purpose: C = A + B
# Input: $a0=A, $a1=B, $a2=C
# Return: none
############################################################
matrix_add:
    li $t0, 0

add_loop:
    beq $t0, 9, add_done

    sll $t1, $t0, 2

    add $t2, $a0, $t1
    lw $t3, 0($t2)

    add $t2, $a1, $t1
    lw $t4, 0($t2)

    add $t5, $t3, $t4

    add $t2, $a2, $t1
    sw $t5, 0($t2)

    addi $t0, $t0, 1
    j add_loop

add_done:
    jr $ra

############################################################
# PROCEDURE: matrix_multiply
# Purpose: C = A * B
# Input: $a0=A, $a1=B, $a2=C
# Uses nested loops
############################################################
matrix_multiply:

    addi $sp,$sp,-4
    sw $ra,0($sp)

    li $t0,0          # i

outer_i:
    beq $t0,3,mult_done

    li $t1,0          # j

outer_j:
    beq $t1,3,next_i

    li $t5,0          # sum
    li $t2,0          # k

inner_k:
    beq $t2,3,store_mult

    # A[i][k]
    mul $t3,$t0,3
    add $t3,$t3,$t2
    sll $t3,$t3,2
    add $t3,$a0,$t3
    lw $t6,0($t3)

    # B[k][j]
    mul $t4,$t2,3
    add $t4,$t4,$t1
    sll $t4,$t4,2
    add $t4,$a1,$t4
    lw $t7,0($t4)

    mul $t8,$t6,$t7
    add $t5,$t5,$t8

    addi $t2,$t2,1
    j inner_k

store_mult:
    mul $t3,$t0,3
    add $t3,$t3,$t1
    sll $t3,$t3,2
    add $t3,$a2,$t3
    sw $t5,0($t3)

    addi $t1,$t1,1
    j outer_j

next_i:
    addi $t0,$t0,1
    j outer_i

mult_done:
    lw $ra,0($sp)
    addi $sp,$sp,4
    jr $ra

############################################################
# PROCEDURE: matrix_transpose
# Purpose: C = transpose(A)
# Input: $a0=A, $a1=C
############################################################
matrix_transpose:

    li $t0,0  # i

trans_i:
    beq $t0,3,trans_done

    li $t1,0  # j

trans_j:
    beq $t1,3,next_trans_i

    # A[i][j]
    mul $t2,$t0,3
    add $t2,$t2,$t1
    sll $t2,$t2,2
    add $t2,$a0,$t2
    lw $t3,0($t2)

    # C[j][i]
    mul $t4,$t1,3
    add $t4,$t4,$t0
    sll $t4,$t4,2
    add $t4,$a1,$t4
    sw $t3,0($t4)

    addi $t1,$t1,1
    j trans_j

next_trans_i:
    addi $t0,$t0,1
    j trans_i

trans_done:
    jr $ra