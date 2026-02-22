# assignment1.asm
# Reads a single integer from the user and reports:
#   - Parity      : Even or Odd
#   - Sign        : Positive, Negative, or Zero
#   - Divisibility: whether the number is divisible by 3, 5, and/or 7
#   - Perfect square check (binary search over [0, x])
#   - Prime / Composite classification

.data
	newline: .asciiz "\n"
	prompt: .asciiz "Enter an integer: "
	is_even: .asciiz "Parity: Even\n"
	is_odd: .asciiz "Parity: Odd\n"
	is_positive: .asciiz "Sign: Positive\n"
	is_negative: .asciiz "Sign: Negative\n"
	is_zero: .asciiz "Sign: Zero\n"
	div_three: .asciiz "Divisible by 3\n"
	div_five: .asciiz "Divisible by 5\n"
	div_seven: .asciiz "Divisible by 7\n"
	is_square_num: .asciiz "Perfect Square\n"
	is_not_square: .asciiz "Not a perfect square\n"
	is_prime: .asciiz "Prime Number\n"
	is_composite: .asciiz "Composite Number\n"

.text
.globl main
main:
	# --- Prompt and read integer ---
	la $a0 prompt          # load address of prompt string
	li $v0 4               # syscall 4 = print string
	syscall

	li $v0 5               # syscall 5 = read integer
	syscall

	move $t0 $v0           # $t0 = user input (n)

	# -------------------------------------------------------
	# PARITY CHECK: test whether n % 2 == 0
	# -------------------------------------------------------
	rem $t1 $t0 2          # $t1 = n % 2
	bnez $t1 odd           # if remainder != 0 => odd
	la $a0 is_even         # else print "Even"
	li $v0 4
	syscall
	j end_parity

odd:
	la $a0 is_odd          # print "Odd"
	li $v0 4
	syscall

end_parity:
	# -------------------------------------------------------
	# SIGN CHECK: zero -> negative -> (fall-through) positive
	# -------------------------------------------------------
	beqz $t0 zero          # if n == 0 jump to zero
	bltz $t0 negative      # if n < 0  jump to negative
	la $a0 is_positive     # else n > 0 : print "Positive"
	li $v0 4
	syscall
	j end_sign

zero:
	la $a0 is_zero         # print "Zero"
	li $v0 4
	syscall
	j end_sign

negative:
	la $a0 is_negative     # print "Negative"
	li $v0 4
	syscall

end_sign:
    # -------------------------------------------------------
    # DIVISIBILITY CHECKS (3, 5, 7) — independent of each other
    # -------------------------------------------------------

    # Check divisible by 3
    rem  $t1, $t0, 3
    bnez $t1, check_five   # if remainder != 0, not divisible by 3
    la   $a0, div_three
    jal  print_str

check_five:
    # Check divisible by 5
    rem  $t1, $t0, 5
    bnez $t1, check_seven  # if remainder != 0, not divisible by 5
    la   $a0, div_five
    jal  print_str

check_seven:
    # Check divisible by 7
    rem  $t1, $t0, 7
    bnez $t1, is_perfect_square  # if remainder != 0, not divisible by 7
    la   $a0, div_seven
    jal  print_str

    # -------------------------------------------------------
    # PERFECT SQUARE CHECK — binary search over [0, n]
    # Looks for an integer m such that m*m == n
    # -------------------------------------------------------
is_perfect_square:
    bltz  $t0, not_square      # negative numbers cannot be perfect squares

    li    $t1, 0               # left  = 0  (lower bound of search range)
    move  $t2, $t0             # right = n  (upper bound of search range)

loop:
    bgt   $t1, $t2, not_square # if left > right: search exhausted, not a square

    addu  $t3, $t1, $t2        # t3 = left + right (unsigned to avoid overflow)
    srl   $t3, $t3, 1          # mid = (left + right) / 2  (logical right shift by 1)

    mul   $t4, $t3, $t3        # square = mid * mid

    beq   $t4, $t0, is_square  # if mid^2 == n => perfect square
    blt   $t4, $t0, go_right   # if mid^2 < n  => mid too small, search right half

    # mid^2 > n => mid too large, search left half
    addi  $t2, $t3, -1         # right = mid - 1
    j     loop

go_right:
    addi  $t1, $t3, 1          # left = mid + 1
    j     loop

is_square:
    la $a0 is_square_num       # print "Perfect Square"
    jal print_str
    j is_prime_check

not_square:
    la $a0 is_not_square       # print "Not a perfect square"
    jal print_str

    # -------------------------------------------------------
    # PRIME CHECK
    # Algorithm:
    #   - n <= 1        => composite
    #   - n == 2        => prime
    #   - n even        => composite
    #   - trial division by odd numbers 3, 5, 7, ...
    #     stopping when i*i > n (no divisor found => prime)
    # -------------------------------------------------------
is_prime_check:
    ble  $t0, 1, composite     # n <= 1 is not prime
    beq  $t0, 2, prime         # 2 is the only even prime

    rem  $t1, $t0, 2
    beqz $t1, composite        # any other even number is composite

    li   $t2, 3                # start trial divisor at 3

prime_loop:
    mul  $t3, $t2, $t2         # i*i
    bgt  $t3, $t0, prime       # if i*i > n, no divisor found => prime

    rem  $t4, $t0, $t2         # n % i
    beqz $t4, composite        # n divisible by i => composite

    addi $t2, $t2, 2           # i += 2  (only test odd divisors)
    j    prime_loop

prime:
    la $a0 is_prime            # print "Prime Number"
    jal print_str
    j end_program

composite:
    la $a0 is_composite        # print "Composite Number"
    jal print_str


end_program:
	li $v0 10              # syscall 10 = exit
	syscall

# -------------------------------------------------------
# Helper: print_str
#   Expects: $a0 = address of null-terminated string
#   Uses:    $v0 = 4 (print string syscall)
#   Returns: via $ra
# -------------------------------------------------------
print_str:
	li $v0 4
	syscall
	jr $ra                 # return to caller




