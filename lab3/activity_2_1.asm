# Program: Multiple math procedures demo

.data
    prompt: .asciiz "Enter a number: "
    prompt2: .asciiz "Enter second number (for max): "
    square_msg: .asciiz "Square: "
    cube_msg: .asciiz "Cube: "
    abs_msg: .asciiz "Absolute value: "
    max_msg: .asciiz "Maximum: "
    newline: .asciiz "\n"

.text
.globl main
main:

    # ---- Read first number ----
    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 5
    syscall
    move $s0, $v0       # save first input in $s0

    # ---- Call square ----
    move $a0, $s0
    jal square
    move $t0, $v0       # store square result

    # ---- Call cube ----
    move $a0, $s0
    jal cube
    move $t1, $v0       # store cube result

    # ---- Call absolute ----
    move $a0, $s0
    jal absolute
    move $t2, $v0       # store absolute result

    # ---- Read second number (for max) ----
    li $v0, 4
    la $a0, prompt2
    syscall

    li $v0, 5
    syscall
    move $s1, $v0       # second input

    # ---- Call max_two ----
    move $a0, $s0
    move $a1, $s1
    jal max_two
    move $t3, $v0       # store max result

    # ---- Print Results ----

    # Square
    li $v0, 4
    la $a0, square_msg
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Cube
    li $v0, 4
    la $a0, cube_msg
    syscall
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Absolute
    li $v0, 4
    la $a0, abs_msg
    syscall
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Maximum
    li $v0, 4
    la $a0, max_msg
    syscall
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Exit
    li $v0, 10
    syscall


    # --------------------------
    # Procedure: square
    # Input: $a0
    # Output: $v0
square:
    mul $v0, $a0, $a0
    jr $ra


    # --------------------------
    # Procedure: cube
    # Input: $a0
    # Output: $v0
cube:
    mul $t4, $a0, $a0
    mul $v0, $t4, $a0
    jr $ra


    # --------------------------
    # Procedure: absolute value
    # Input: $a0
    # Output: $v0
absolute:
    bltz $a0, make_positive
    move $v0, $a0
    jr $ra

make_positive:
    sub $v0, $zero, $a0
    jr $ra


# --------------------------
# Procedure: max of two numbers
# Input: $a0, $a1
# Output: $v0
max_two:
    bgt $a0, $a1, first_is_max
    move $v0, $a1
    jr $ra

first_is_max:
    move $v0, $a0
    jr $ra