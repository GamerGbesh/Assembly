# assignment3.asm
# Menu-driven star-pattern printer.
# The user picks a pattern (1-5) and a row count (1-20):
#   1) Right-Angled Triangle  — row i has i stars
#   2) Isosceles Triangle     — centred triangle, row i has (2i-1) stars
#   3) Diamond Pattern        — isosceles upper half + reversed lower half
#   4) Hollow Square          — N×N border of stars, interior is spaces
#   5) Pascal's Triangle      — prints the row numbers (currently all 1s — placeholder)
#  -1) Exit
# Input validation is performed on both the menu choice and the row count.

.data
menu: .asciiz "\n1) Right-Angled Triangle\n2) Isosceles Triangle\n3) Diamond Pattern\n4) Hollow Square\n5) Pascal's Triangle\n-1) End Program\nUser Choice: "
row_prompt: .asciiz "Number of rows (1-20): "
invalid: .asciiz "Invalid Choice\n"
invalid_size: .asciiz "Invalid size. Enter 1-20\n"
ending: .asciiz "Ending the program\n"
newline: .asciiz "\n"
star: .asciiz "*"
space: .asciiz " "

.text
.globl main

main:
menu_loop:
    # -------------------------------------------------------
    # Print menu and read the user's choice into $t0
    # -------------------------------------------------------
    li $v0, 4
    la $a0, menu
    syscall

    li $v0, 5              # syscall 5 = read integer
    syscall
    move $t0, $v0          # $t0 = menu choice

    li $t9, -1
    beq $t0, $t9, end_program  # choice == -1 => exit

    # Validate choice: must be 1..5
    blt $t0, 1, invalid_choice
    bgt $t0, 5, invalid_choice

    # Ask for the number of rows
    li $v0, 4
    la $a0, row_prompt
    syscall

    li $v0, 5              # read integer
    syscall
    move $t4, $v0          # $t4 = number of rows (N)

    # Validate size: must be 1..20
    blt $t4, 1, invalid_size_label
    bgt $t4, 20, invalid_size_label

    li $t1, 1              # $t1 = outer loop counter i (1-based row number)

    # Dispatch to the chosen pattern
    beq $t0, 1, right_triangle
    beq $t0, 2, isosceles_triangle
    beq $t0, 3, diamond_pattern
    beq $t0, 4, hollow_square
    beq $t0, 5, pascal_triangle


    # -------------------------------------------------------
    # 1) RIGHT-ANGLED TRIANGLE
    # Row i: print exactly i stars, then a newline.
    # Example (N=4):  *
    #                 **
    #                 ***
    #                 ****
    # -------------------------------------------------------
right_triangle:
outer_rt:
    bgt $t1, $t4, menu_loop    # if i > N, done
    li $t2, 1                  # $t2 = inner counter j = 1
inner_rt:
    bgt $t2, $t1, next_rt      # print j stars per row (j goes 1..i)
    li $v0, 4
    la $a0, star
    syscall
    addi $t2, $t2, 1           # j++
    j inner_rt
next_rt:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, 1           # i++
    j outer_rt


    # -------------------------------------------------------
    # 2) ISOSCELES TRIANGLE
    # Row i: (N-i) leading spaces, then (2i-1) stars, then newline.
    # Example (N=4):    *
    #                  ***
    #                 *****
    #                *******
    # -------------------------------------------------------
isosceles_triangle:
outer_iso:
    bgt $t1, $t4, menu_loop    # if i > N, done

    # Print (N - i) leading spaces to centre the row
    sub $t5, $t4, $t1          # $t5 = number of spaces = N - i
    li $t2, 0                  # space counter = 0
space_iso:
    bge $t2, $t5, star_iso     # once we've printed enough spaces, print stars
    li $v0, 4
    la $a0, space
    syscall
    addi $t2, $t2, 1
    j space_iso

star_iso:
    li $t2, 1                  # star counter j = 1
    mul $t6, $t1, 2            # $t6 = 2*i
    addi $t6, $t6, -1          # $t6 = 2*i - 1  (number of stars on this row)
star_loop_iso:
    bgt $t2, $t6, next_iso     # printed all stars for this row
    li $v0, 4
    la $a0, star
    syscall
    addi $t2, $t2, 1
    j star_loop_iso

next_iso:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, 1           # i++
    j outer_iso


    # -------------------------------------------------------
    # 3) DIAMOND PATTERN
    # Upper half: same as isosceles triangle (rows 1..N)
    # Lower half: reverse of upper half (rows N-1..1)
    # -------------------------------------------------------
diamond_pattern:
    # --- Upper half (identical logic to isosceles) ---
    li $t1, 1                  # i = 1
upper_d:
    bgt $t1, $t4, lower_d      # upper half done when i > N

    sub $t5, $t4, $t1          # spaces = N - i
    li $t2, 0
space_ud:
    bge $t2, $t5, star_ud
    li $v0, 4
    la $a0, space
    syscall
    addi $t2, $t2, 1
    j space_ud
star_ud:
    li $t2, 1
    mul $t6, $t1, 2
    addi $t6, $t6, -1          # stars = 2*i - 1
star_loop_ud:
    bgt $t2, $t6, next_ud
    li $v0, 4
    la $a0, star
    syscall
    addi $t2, $t2, 1
    j star_loop_ud
next_ud:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, 1
    j upper_d

    # --- Lower half (rows N-1 down to 1) ---
lower_d:
    addi $t1, $t4, -1          # i starts at N-1
lower_loop:
    blez $t1, menu_loop        # when i == 0 we are done

    sub $t5, $t4, $t1          # spaces = N - i (mirror of upper)
    li $t2, 0
space_ld:
    bge $t2, $t5, star_ld
    li $v0, 4
    la $a0, space
    syscall
    addi $t2, $t2, 1
    j space_ld
star_ld:
    li $t2, 1
    mul $t6, $t1, 2
    addi $t6, $t6, -1          # stars = 2*i - 1
star_loop_ld:
    bgt $t2, $t6, next_ld
    li $v0, 4
    la $a0, star
    syscall
    addi $t2, $t2, 1
    j star_loop_ld
next_ld:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, -1          # i-- (counting down)
    j lower_loop


    # -------------------------------------------------------
    # 4) HOLLOW SQUARE
    # N×N grid: print a star on the border (first/last row or
    # first/last column), a space everywhere else.
    # -------------------------------------------------------
hollow_square:
    li $t1, 1                  # row i = 1
outer_h:
    bgt $t1, $t4, menu_loop    # if i > N, done
    li $t2, 1                  # column j = 1
inner_h:
    bgt $t2, $t4, next_h       # if j > N, end of row

    # Print a star if on a border cell, else a space
    beq $t1, 1, print_star_h   # top row
    beq $t1, $t4, print_star_h # bottom row
    beq $t2, 1, print_star_h   # left column
    beq $t2, $t4, print_star_h # right column
    li $v0, 4                  # interior cell => space
    la $a0, space
    syscall
    j cont_h
print_star_h:
    li $v0, 4
    la $a0, star
    syscall
cont_h:
    addi $t2, $t2, 1           # j++
    j inner_h
next_h:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, 1           # i++
    j outer_h


    # -------------------------------------------------------
    # 5) PASCAL'S TRIANGLE  (placeholder — prints all 1s)
    # Row i (0-based) prints (i+1) values separated by spaces.
    # NOTE: The actual binomial coefficients are not computed;
    #       every value is printed as 1.
    # -------------------------------------------------------
pascal_triangle:
    li $t1, 0                  # row i = 0 (0-based)
outer_p:
    bge $t1, $t4, menu_loop    # if i >= N, done
    li $t2, 0                  # column j = 0
inner_p:
    bgt $t2, $t1, next_p       # print (i+1) values per row
    li $v0, 1
    li $a0, 1                  # placeholder: always print 1
    syscall
    li $v0, 4
    la $a0, space              # space between values
    syscall
    addi $t2, $t2, 1           # j++
    j inner_p
next_p:
    li $v0, 4
    la $a0, newline
    syscall
    addi $t1, $t1, 1           # i++
    j outer_p


invalid_choice:
    li $v0, 4
    la $a0, invalid            # print error and return to menu
    syscall
    j menu_loop

invalid_size_label:
    li $v0, 4
    la $a0, invalid_size       # print error and return to menu
    syscall
    j menu_loop


end_program:
    li $v0, 4
    la $a0, ending             # print goodbye message
    syscall
    li $v0, 10                 # syscall 10 = exit
    syscall
