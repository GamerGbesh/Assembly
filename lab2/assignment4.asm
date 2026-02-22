# assignment4.asm
# Grade-book program for 10 students, each with 5 subject scores.
# All 50 scores are stored in a flat array (students × subjects in row order).
#
# After input the program:
#   - Computes and prints each student's average score and letter grade
#   - Computes and prints the class average (total sum / 50)
#   - Identifies and prints the highest- and lowest-averaging student
#   - Prints the grade distribution (count of A / B / C / D / F)
#
# Grade thresholds: A >= 90, B >= 80, C >= 70, D >= 60, F < 60
#
# Register map (maintained throughout main):
#   $t0   student counter  (1-10)
#   $t1   subject counter  (1-5)
#   $s0   base address of array
#   $a1   flat array index (0-49); also reused as student number in avg phase
#   $s1   running total of ALL scores (used for class average)
#   $s2   student number with the lowest  average
#   $s3   student number with the highest average
#   $s4   lowest  average seen so far (initialised to 100)
#   $s5   highest average seen so far (initialised to 0)
#   $s6   count of A grades
#   $s7   count of B grades
#   $t7   count of C grades
#   $t8   count of D grades
#   $t9   count of F grades

.data
	array: .space 200 # Reserving 200 bytes for 10 students with 5 subjects each. 4 bytes for a score for 5 subjects is 20bytes and for 10 students 200bytes
	prompt_start: .asciiz "Enter score for student "
	prompt_end: .asciiz " subject "
	average_start: .asciiz "Average of student "
	class_average: .asciiz "Class average: "
	highest_student: .asciiz "Highest student is student "
	lowest_student: .asciiz "Lowest student is student "
	A_count: .asciiz "Count of As: "
	B_count: .asciiz "Count of Bs: "
	C_count: .asciiz "Count of Cs: "
	D_count: .asciiz "Count of Ds: "
	F_count: .asciiz "Count of Fs: "
	A: .asciiz "Grade: A\n"
	B: .asciiz "Grade: B\n"
	C: .asciiz "Grade: C\n"
	D: .asciiz "Grade: D\n"
	F: .asciiz "Grade: F\n"
	end: .asciiz "Ended the input\n"
	colon: .asciiz ": "
	ending: .asciiz "Ending program\n"
	newline: .asciiz "\n"
.text
.globl main
main:
	# --- Initialise all counters and accumulators ---
	li $t0 1           # student number: starts at 1
	li $t1 1           # subject number: starts at 1
	la $s0 array       # $s0 = base address of the score array
	li $a1 0           # flat index into array (increments 0-49 across all 50 scores)
	li $s1 0           # sum of all scores (for class average)
	li $s2 1           # student number with the lowest  average (default 1)
	li $s3 1           # student number with the highest average (default 1)
	li $s4 100         # lowest  average seen (seeded high so first student wins)
	li $s5 0           # highest average seen (seeded low  so first student wins)
	li $s6 0           # count of A grades
	li $s7 0           # count of B grades
	li $t7 0           # count of C grades
	li $t8 0           # count of D grades
	li $t9 0           # count of F grades

    # -------------------------------------------------------
    # INPUT LOOP
    # Outer iteration: students 1-10  ($t0)
    # Inner iteration: subjects 1-5   ($t1)
    # enter_input stores each score and accumulates $s1.
    # -------------------------------------------------------
input_loop:
	bgt $t0 10 end_input     # if student > 10, all scores entered
	jal enter_input           # prompt and store one score; uses $t0, $t1, $a1
	addi $a1 $a1 1            # advance flat array index for the next score
	addi $t1 $t1 1            # subject++
	bgt $t1 5 change_student  # if subject > 5, move to next student
	j input_loop

change_student:
	addi $t0 $t0 1   # student++
	li $t1 1         # reset subject to 1
	j input_loop

end_input:
	la $a0 end       # print "Ended the input"
	li $v0 4
	syscall

	# Re-use $a1 as the student-number argument for per_student_avg (1-10).
	# $a2 is the flat array index that per_student_avg advances internally.
	li $a1 1         # current student number = 1
	li $a2 0         # flat index = 0 (start of array)

    # -------------------------------------------------------
    # STUDENT AVERAGES PHASE
    # Calls per_student_avg for each student.
    # That function reads 5 scores, prints the average and
    # letter grade, and updates min/max student tracking.
    # $a2 is NOT reset between calls — per_student_avg
    # increments it by 5 each call, walking through the array.
    # -------------------------------------------------------
student_averages:
	bgt $a1 10 class_average_label  # all 10 students processed
	jal per_student_avg              # compute and print average for student $a1
	addi $a1 $a1 1                   # next student
	j student_averages

    # -------------------------------------------------------
    # CLASS AVERAGE
    # $s1 holds the sum of all 50 scores gathered during input.
    # Dividing by 50 gives the overall class average.
    # -------------------------------------------------------
class_average_label:
	div $t1 $s1 50   # $t1 = class average (integer division)

	la $a0 class_average
	li $v0 4
	syscall

	move $a0 $t1
	li $v0 1         # syscall 1 = print integer
	syscall

	la $a0 newline
	li $v0 4
	syscall

    # -------------------------------------------------------
    # HIGHEST / LOWEST STUDENT
    # $s3 holds the student number with the highest average.
    # $s2 holds the student number with the lowest  average.
    # -------------------------------------------------------
high_low:
	la $a0 highest_student
	li $v0 4
	syscall

	move $a0 $s3
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	la $a0 lowest_student
	li $v0 4
	syscall

	move $a0 $s2
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

    # -------------------------------------------------------
    # GRADE DISTRIBUTION
    # Prints the count of each letter grade across all students.
    # -------------------------------------------------------
distribution:
	# Count of A
	la $a0 A_count
	li $v0 4
	syscall

	move $a0 $s6     # $s6 = A count
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# Count of B
	la $a0 B_count
	li $v0 4
	syscall

	move $a0 $s7     # $s7 = B count
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# Count of C
	la $a0 C_count
	li $v0 4
	syscall

	move $a0 $t7     # $t7 = C count
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# Count of D
	la $a0 D_count
	li $v0 4
	syscall

	move $a0 $t8     # $t8 = D count
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# Count of F
	la $a0 F_count
	li $v0 4
	syscall

	move $a0 $t9     # $t9 = F count
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# NOTE: A_count is printed a second time here — this appears to be a duplicate.
	la $a0 A_count
	li $v0 4
	syscall

	move $a0 $s6
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

end_program:
	la $a0 ending
	li $v0 4
	syscall

	li $v0 10        # syscall 10 = exit
	syscall

# -------------------------------------------------------
# Function: enter_input
#   Prompts "Enter score for student X subject Y: "
#   Reads the score (syscall 5) and stores it at array[$a1 * 4].
#   Also adds the score to $s1 (running total).
#   Uses: $t0 (student#), $t1 (subject#), $a1 (flat index), $s0 (array base)
#   Returns: via $ra
# -------------------------------------------------------
enter_input:
	la $a0 prompt_start    # "Enter score for student "
	li $v0 4
	syscall

	move $a0 $t0           # print student number
	li $v0 1
	syscall

	la $a0 prompt_end      # " subject "
	li $v0 4
	syscall

	move $a0 $t1           # print subject number
	li $v0 1
	syscall

	la $a0 colon           # ": "
	li $v0 4
	syscall

	li $v0 5               # read integer from user -> $v0
	syscall

	# Store score at array[a1 * 4]
	mul $t2 $a1 4          # byte offset = flat_index * 4
	add $t2 $s0 $t2        # effective address = base + offset
	sw $v0 0($t2)          # store score

	add $s1 $s1 $v0        # accumulate total sum of all marks

	jr $ra

# -------------------------------------------------------
# Function: per_student_avg
#   Reads 5 consecutive scores for the current student
#   starting at flat index $a2 (incremented 5 times here).
#   Computes average, prints it, assigns grade, and updates
#   min/max student tracking.
#
#   Arguments:
#     $a1 = student number (1-10)   — for printing and min/max tracking
#     $a2 = flat array index of first score for this student
#   Modifies: $a2 (advanced by 5), $t3, $t4, $t1, $t2
#   Returns: via $ra
#
#   The 5 score loads are manually unrolled (no inner loop).
# -------------------------------------------------------
per_student_avg:
	li $t3 0               # $t3 = sum of this student's 5 scores

	# Load score 1
	mul $t1 $a2 4
	add $t2 $s0 $t1        # address = base + (a2 * 4)
	lw $t0 0($t2)
	add $t3 $t3 $t0        # sum += score[0]
	addi $a2 $a2 1         # flat index++

	# Load score 2
	mul $t1 $a2 4
	add $t2 $s0 $t1
	lw $t0 0($t2)
	add $t3 $t3 $t0        # sum += score[1]
	addi $a2 $a2 1

	# Load score 3
	mul $t1 $a2 4
	add $t2 $s0 $t1
	lw $t0 0($t2)
	add $t3 $t3 $t0        # sum += score[2]
	addi $a2 $a2 1

	# Load score 4
	mul $t1 $a2 4
	add $t2 $s0 $t1
	lw $t0 0($t2)
	add $t3 $t3 $t0        # sum += score[3]
	addi $a2 $a2 1

	# Load score 5
	mul $t1 $a2 4
	add $t2 $s0 $t1
	lw $t0 0($t2)
	add $t3 $t3 $t0        # sum += score[4]
	addi $a2 $a2 1

	div $t4 $t3 5          # $t4 = student average  (integer division)

	# Print "Average of student X: Y"
	la $a0 average_start
	li $v0 4
	syscall

	move $a0 $a1           # student number
	li $v0 1
	syscall

	la $a0 colon
	li $v0 4
	syscall

	move $a0 $t4           # average value
	li $v0 1
	syscall

	la $a0 newline
	li $v0 4
	syscall

	# Check if this student has the new minimum average
	blt $t4 $s4 update_min
check_max:
	# Check if this student has the new maximum average
	bgt $t4 $s5 update_max

    # -------------------------------------------------------
    # GRADE ASSIGNMENT
    # Compares $t4 (student average) against thresholds.
    # Falls through to F if none of the higher bands match.
    # -------------------------------------------------------
grade:
	bge $t4 90 A_grade     # average >= 90 => A
	bge $t4 80 B_grade     # average >= 80 => B
	bge $t4 70 C_grade     # average >= 70 => C
	bge $t4 60 D_grade     # average >= 60 => D
	# average < 60 => F
	la $a0 F
	li $v0 4
	syscall

	addi $t9 $t9 1         # F count++
	jr $ra

A_grade:
	la $a0 A
	li $v0 4
	syscall
	addi $s6 $s6 1         # A count++
	jr $ra
B_grade:
	la $a0 B
	li $v0 4
	syscall
	addi $s7 $s7 1         # B count++
	jr $ra
C_grade:
	la $a0 C
	li $v0 4
	syscall
	addi $t7 $t7 1         # C count++
	jr $ra
D_grade:
	la $a0 D
	li $v0 4
	syscall
	addi $t8 $t8 1         # D count++
	jr $ra

# -------------------------------------------------------
# update_min: called when $t4 < current lowest average ($s4)
#   Updates $s4 (lowest average) and $s2 (lowest student #).
#   Falls through to check_max afterwards.
# -------------------------------------------------------
update_min:
	move $s4 $t4           # $s4 = new lowest average
	move $s2 $a1           # $s2 = student number with lowest average
	j check_max

# -------------------------------------------------------
# update_max: called when $t4 > current highest average ($s5)
#   Updates $s5 (highest average) and $s3 (highest student #).
#   Falls through to grade assignment afterwards.
# -------------------------------------------------------
update_max:
	move $s5 $t4           # $s5 = new highest average
	move $s3 $a1           # $s3 = student number with highest average
	j grade
