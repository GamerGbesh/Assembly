# assignment2.asm
# Reads integers from the user into an array (max 20 entries).
# The sentinel value -9999 terminates input early.
# After input the program computes and prints:
#   Count, Sum, Average (integer), Min, Max, Range,
#   Positive count, Negative count.
# If no numbers were entered, a message is shown instead.

.data
array:      .space 80              # 20 integers × 4 bytes = 80 bytes of storage

prompt:     .asciiz "Enter number (-9999 to stop): "
no_data:    .asciiz "\nNo numbers entered.\n"

count_msg:  .asciiz "\nCount: "
sum_msg:    .asciiz "\nSum: "
avg_msg:    .asciiz "\nAverage: "
min_msg:    .asciiz "\nMinimum: "
max_msg:    .asciiz "\nMaximum: "
range_msg:  .asciiz "\nRange: "
pos_msg:    .asciiz "\nPositive count: "
neg_msg:    .asciiz "\nNegative count: "
newline:    .asciiz "\n"

.text
.globl main

main:
    # --- Register initialisation ---
    la   $s0, array       # $s0 = current write pointer into the array
    li   $s1, 0           # $s1 = element count (starts at 0)
    li   $t7, -9999       # $t7 = sentinel value that stops input

    # -------------------------------------------------------
    # INPUT LOOP
    # Keeps asking for numbers until the user types -9999
    # or 20 numbers have been stored.
    # -------------------------------------------------------
input_loop:
    li   $v0, 4            # syscall 4 = print string
    la   $a0, prompt
    syscall

    li   $v0, 5            # syscall 5 = read integer; result in $v0
    syscall

    beq  $v0, $t7, input_done   # user typed sentinel => stop collecting
    beq  $s1, 20, input_done    # array is full (20 elements) => stop

    sw   $v0, 0($s0)       # store the entered value at current array position
    addi $s0, $s0, 4       # advance pointer by 4 bytes (one word)
    addi $s1, $s1, 1       # count++

    j input_loop

input_done:
    beqz $s1, no_numbers   # if count == 0 nothing to process

    # --- Initialise statistics accumulators ---
    la   $s0, array        # reset pointer back to start of array
    lw   $t0, 0($s0)       # read first element to seed min/max

    move $s2, $t0          # $s2 = min  (start at first value)
    move $s3, $t0          # $s3 = max  (start at first value)
    move $s4, $zero        # $s4 = sum  = 0
    move $s5, $zero        # $s5 = positive count = 0
    move $s6, $zero        # $s6 = negative count = 0

    li   $t1, 0            # $t1 = loop index (0-based)

    # -------------------------------------------------------
    # PROCESS LOOP
    # Iterates over all stored values computing statistics.
    # -------------------------------------------------------
process_loop:
    beq  $t1, $s1, processing_done   # if index == count, done

    lw   $t0, 0($s0)       # load current element

    add  $s4, $s4, $t0     # sum += current value

    # Classify the value as positive, negative, or zero
    bgt  $t0, $zero, positive
    blt  $t0, $zero, negative
    j check_minmax         # value is zero: skip sign counters

positive:
    addi $s5, $s5, 1       # positive count++
    j check_minmax

negative:
    addi $s6, $s6, 1       # negative count++

check_minmax:
    blt  $t0, $s2, update_min   # value < current min => new min
    bgt  $t0, $s3, update_max   # value > current max => new max
    j next                       # no update needed

update_min:
    move $s2, $t0          # $s2 = new minimum
    j next

update_max:
    move $s3, $t0          # $s3 = new maximum

next:
    addi $s0, $s0, 4       # advance to next array element
    addi $t1, $t1, 1       # index++
    j process_loop

processing_done:
    # --- Compute derived statistics ---
    div  $s4, $s1          # HI:LO = sum / count  (integer division)
    mflo $s7               # $s7 = average (quotient)

    sub  $t2, $s3, $s2     # $t2 = range = max - min

    # -------------------------------------------------------
    # PRINT RESULTS
    # Each value is printed with syscall 4 (string) followed
    # by syscall 1 (print integer).
    # -------------------------------------------------------
print_results:

    # Count
    li $v0, 4
    la $a0, count_msg
    syscall
    li $v0, 1
    move $a0, $s1          # print count
    syscall

    # Sum
    li $v0, 4
    la $a0, sum_msg
    syscall
    li $v0, 1
    move $a0, $s4          # print sum
    syscall

    # Average
    li $v0, 4
    la $a0, avg_msg
    syscall
    li $v0, 1
    move $a0, $s7          # print average (truncated integer)
    syscall

    # Minimum
    li $v0, 4
    la $a0, min_msg
    syscall
    li $v0, 1
    move $a0, $s2          # print minimum
    syscall

    # Maximum
    li $v0, 4
    la $a0, max_msg
    syscall
    li $v0, 1
    move $a0, $s3          # print maximum
    syscall

    # Range
    li $v0, 4
    la $a0, range_msg
    syscall
    li $v0, 1
    move $a0, $t2          # print range (max - min)
    syscall

    # Positive count
    li $v0, 4
    la $a0, pos_msg
    syscall
    li $v0, 1
    move $a0, $s5          # print positive count
    syscall

    # Negative count
    li $v0, 4
    la $a0, neg_msg
    syscall
    li $v0, 1
    move $a0, $s6          # print negative count
    syscall

    j end_program

# -------------------------------------------------------
# No numbers were entered: print message and exit.
# -------------------------------------------------------
no_numbers:
    li $v0, 4
    la $a0, no_data
    syscall

end_program:
    li $v0, 10             # syscall 10 = exit
    syscall
