############################################################
# Assignment 4 (Lab 3) : Calculator with Function Library
#
# Sections
#   1  Basic      : add, subtract, multiply, divide
#   2  Advanced   : power (a^n), factorial (n!), GCD(a,b)
#   3  Scientific : sin, cos  — 6-term Taylor series (float)
#   4  Expression : infix evaluator with correct precedence
#                   (Shunting-yard algorithm, stack-based)
#   +  History    : ring buffer of last 5 integer results
#   +  Help       : inline help text
#
# Architecture notes
#   • Every operation is a self-contained, commented procedure.
#   • All do_X routines are reached via branch (not jal) from
#     menu_loop, so they never need to preserve $ra for a
#     caller.  They end with  j menu_loop.
#   • Leaf procedures (add_to_history, sin_approx, cos_approx)
#     are called via jal and return via jr $ra.
#   • expr_eval contains no jal calls; all stack operations are
#     inlined using $t registers, so no frame is needed.
#   • Overflow is detected in multiply and power by inspecting
#     the HI register after mult.
#   • Float results (sin/cos) are not stored in history because
#     the history ring buffer holds signed 32-bit integers only.
############################################################

.data

# ── UI strings ────────────────────────────────────────────
title:        .asciiz "\n==================================\n  MIPS Calculator  (Lab 3 Asgn 4)\n==================================\n"
menu_str:     .asciiz "\n 1) Add              2) Subtract\n 3) Multiply         4) Divide\n 5) Power  (a^n)     6) Factorial (n!)\n 7) GCD (a,b)        8) Sin  (radians)\n 9) Cos  (radians)  10) Expression\n11) History         12) Help\n 0) Exit\n> "
prompt_a:     .asciiz "a = "
prompt_b:     .asciiz "b = "
prompt_n:     .asciiz "n = "
prompt_x:     .asciiz "x (radians, float) = "
prompt_expr:  .asciiz "Expression (e.g.  3 + 4 * 2) : "
res_int:      .asciiz "\nResult : "
res_flt:      .asciiz "\nResult : "
nl:           .asciiz "\n"

# ── Error messages ─────────────────────────────────────────
err_div0:     .asciiz "\nError: division by zero\n"
err_ovf:      .asciiz "\nError: arithmetic overflow\n"
err_negfac:   .asciiz "\nError: factorial requires n >= 0\n"
err_bigfac:   .asciiz "\nError: n too large (max 12 for 32-bit)\n"
err_negexp:   .asciiz "\nError: negative exponent not supported\n"
err_expr:     .asciiz "\nError: invalid expression\n"

# ── Help text ──────────────────────────────────────────────
help_str:     .asciiz "\n[Help]\nAdd/Sub/Mul/Div  —  two signed integers; overflow checked\nPower   a^n      —  integer n >= 0; overflow checked per step\nFactorial n!     —  integer 0 <= n <= 12 (13! overflows 32-bit)\nGCD(a,b)         —  Euclidean algorithm; inputs normalised to >= 0\nSin / Cos        —  float radians input; 6-term Taylor approximation\nExpression       —  infix integer expression with + - * /\n                    spaces optional, e.g.  3+4*2  or  3 + 4 * 2\n                    * and / bind tighter than + and -\nHistory          —  last 5 integer results stored in a ring buffer\n"

# ── History ring buffer ───────────────────────────────────
hist_hdr:     .asciiz "\n[History — last 5 results]\n"
hist_lbr:     .asciiz "  ["
hist_rbr:     .asciiz "] "
hist_empty:   .asciiz "  (no history yet)\n"
              .align 2
hist_buf:     .space 20        # 5 × 4 bytes
hist_cnt:     .word  0         # entries stored so far   (0–5)
hist_wptr:    .word  0         # next-write slot index   (0–4)

# ── Expression evaluator buffers ─────────────────────────
expr_buf:     .space 128       # raw input string  (max 127 chars + null)
              .align 2
val_stk:      .space 44        # value  stack — 11 words (extra guard slot)
op_stk:       .space 24        # operator stack — 24 bytes
val_top:      .word  0         # number of items currently in val_stk
op_top:       .word  0         # number of items currently in op_stk

# ── Single-precision float constants for Taylor series ────
#
#  sin(x)  =  x - x³/3! + x⁵/5! - x⁷/7! + x⁹/9! - x¹¹/11!
#  Each successive term: term[k] = term[k-1] * x² / ((2k)(2k+1))
#  Denominators:  2×3=6,  4×5=20,  6×7=42,  8×9=72,  10×11=110
f_one:        .float 1.0
f_sd1:        .float 6.0
f_sd2:        .float 20.0
f_sd3:        .float 42.0
f_sd4:        .float 72.0
f_sd5:        .float 110.0

#  cos(x)  =  1 - x²/2! + x⁴/4! - x⁶/6! + x⁸/8! - x¹⁰/10!
#  Each successive term: term[k] = term[k-1] * x² / ((2k-1)(2k))
#  Denominators:  1×2=2,  3×4=12,  5×6=30,  7×8=56,  9×10=90
f_cd1:        .float 2.0
f_cd2:        .float 12.0
f_cd3:        .float 30.0
f_cd4:        .float 56.0
f_cd5:        .float 90.0

.text
.globl main

############################################################
# MAIN — print the banner once, then run the menu loop
############################################################
main:
    li   $v0, 4
    la   $a0, title
    syscall

menu_loop:
    li   $v0, 4
    la   $a0, menu_str
    syscall

    li   $v0, 5               # read integer choice → $v0
    syscall
    move $t0, $v0

    beq  $t0, 0,  do_exit
    beq  $t0, 1,  do_add
    beq  $t0, 2,  do_sub
    beq  $t0, 3,  do_mul
    beq  $t0, 4,  do_div
    beq  $t0, 5,  do_power
    beq  $t0, 6,  do_fact
    beq  $t0, 7,  do_gcd
    beq  $t0, 8,  do_sin
    beq  $t0, 9,  do_cos
    beq  $t0, 10, do_expr
    beq  $t0, 11, do_hist
    beq  $t0, 12, do_help
    j    menu_loop             # unrecognised choice → re-prompt

do_exit:
    li   $v0, 10
    syscall

############################################################
# SECTION 1 — BASIC OPERATIONS
############################################################

# ─────────────────────────────────────────────────────────
# do_add   result = a + b
#
# Overflow check:
#   If a and b have different signs, addition never overflows.
#   If they share a sign but the result has the opposite sign,
#   a 32-bit overflow occurred.
# ─────────────────────────────────────────────────────────
do_add:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = a

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0              # s1 = b

    add  $s2, $s0, $s1         # s2 = tentative result

    # MSB of (a XOR b) is 1 when signs differ → overflow impossible
    xor  $t0, $s0, $s1
    bltz $t0, add_ok

    # Same-sign inputs: overflow if result sign differs from inputs
    xor  $t0, $s0, $s2
    bltz $t0, add_ovf

add_ok:
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s2
    jal  add_to_history        # record in history
    j    menu_loop

add_ovf:
    li   $v0, 4
    la   $a0, err_ovf
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_sub   result = a - b
#
# Overflow check (mirror of do_add):
#   If a and b share a sign, subtraction is safe.
#   If they differ in sign AND result's sign differs from a,
#   overflow occurred.
# ─────────────────────────────────────────────────────────
do_sub:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0

    sub  $s2, $s0, $s1

    # MSB of (a XOR b) is 0 when signs are equal → safe
    xor  $t0, $s0, $s1
    bgez $t0, sub_ok

    # Different-sign inputs: overflow if result sign differs from a
    xor  $t0, $s0, $s2
    bltz $t0, sub_ovf

sub_ok:
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s2
    jal  add_to_history
    j    menu_loop

sub_ovf:
    li   $v0, 4
    la   $a0, err_ovf
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_mul   result = a * b
#
# Overflow check: uses mult to obtain the full 64-bit product
# in HI:LO.  For a valid signed 32-bit result, HI must equal
# the sign-extension of LO (i.e. HI = sra(LO,31)).
# ─────────────────────────────────────────────────────────
do_mul:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0

    mult $s0, $s1              # HI:LO = a × b  (full 64-bit)
    mflo $s2                   # lower 32 bits
    mfhi $t0                   # upper 32 bits
    sra  $t1, $s2, 31          # sign-extension of lower word
    bne  $t0, $t1, mul_ovf     # HI ≠ sign-ext → overflow

    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s2
    jal  add_to_history
    j    menu_loop

mul_ovf:
    li   $v0, 4
    la   $a0, err_ovf
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_div   result = a / b  (integer, truncated toward zero)
#
# Error: b = 0 is caught before the div instruction.
# ─────────────────────────────────────────────────────────
do_div:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0

    beqz $s1, div_bz           # guard: divisor must be non-zero

    div  $s0, $s1              # LO = a/b,  HI = a%b
    mflo $s2

    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s2
    jal  add_to_history
    j    menu_loop

div_bz:
    li   $v0, 4
    la   $a0, err_div0
    syscall
    j    menu_loop

############################################################
# SECTION 2 — ADVANCED OPERATIONS
############################################################

# ─────────────────────────────────────────────────────────
# do_power   result = a^n   (n >= 0, integer)
#
# Uses repeated multiplication.  Overflow is detected after
# every step using the same HI/sign-extension test as do_mul.
# By convention 0^0 = 1 (the accumulator is never touched
# when n = 0, so it stays at its initial value of 1).
# ─────────────────────────────────────────────────────────
do_power:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = base

    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0              # s1 = exponent

    bltz $s1, pow_neg          # negative exponent → error

    li   $s2, 1                # s2 = accumulator (result)
    li   $s3, 0                # s3 = iteration counter

pow_loop:
    beq  $s3, $s1, pow_done    # counter reached n → finished
    mult $s2, $s0              # HI:LO = accumulator × base
    mflo $s2
    mfhi $t0
    sra  $t1, $s2, 31
    bne  $t0, $t1, pow_ovf     # overflow guard
    addi $s3, $s3, 1
    j    pow_loop

pow_done:
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s2
    jal  add_to_history
    j    menu_loop

pow_neg:
    li   $v0, 4
    la   $a0, err_negexp
    syscall
    j    menu_loop

pow_ovf:
    li   $v0, 4
    la   $a0, err_ovf
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_fact   result = n!    (0 <= n <= 12)
#
# 12! = 479 001 600 fits in a signed 32-bit word.
# 13! = 6 227 020 800 overflows, so 13 is rejected.
# The loop multiplies result by every integer from 1 to n.
# ─────────────────────────────────────────────────────────
do_fact:
    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = n

    bltz $s0, fact_neg
    bgt  $s0, 12, fact_big

    li   $s1, 1                # s1 = result
    li   $t0, 1                # t0 = loop index i

fact_loop:
    bgt  $t0, $s0, fact_done
    mul  $s1, $s1, $t0         # result *= i  (safe: n ≤ 12)
    addi $t0, $t0, 1
    j    fact_loop

fact_done:
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s1
    jal  add_to_history
    j    menu_loop

fact_neg:
    li   $v0, 4
    la   $a0, err_negfac
    syscall
    j    menu_loop

fact_big:
    li   $v0, 4
    la   $a0, err_bigfac
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_gcd   result = GCD(a, b)
#
# Classic Euclidean algorithm:  GCD(a,b) = GCD(b, a mod b)
# repeated until b = 0, at which point GCD = a.
# Inputs are normalised to non-negative values before the loop
# so the algorithm works correctly for any signed integers.
# ─────────────────────────────────────────────────────────
do_gcd:
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = a

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0              # s1 = b

    bgez $s0, gcd_abs_b        # ensure a >= 0
    neg  $s0, $s0
gcd_abs_b:
    bgez $s1, gcd_loop         # ensure b >= 0
    neg  $s1, $s1

gcd_loop:
    beqz $s1, gcd_done         # GCD(a, 0) = a
    div  $s0, $s1              # HI = a mod b
    mfhi $s2
    move $s0, $s1              # a ← b
    move $s1, $s2              # b ← a mod b
    j    gcd_loop

gcd_done:
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s0
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s0
    jal  add_to_history
    j    menu_loop

############################################################
# SECTION 3 — SCIENTIFIC FUNCTIONS  (single-precision float)
############################################################

# ─────────────────────────────────────────────────────────
# do_sin   Read float radians, compute sin, print float.
# Note: float results are not stored in the integer history.
# ─────────────────────────────────────────────────────────
do_sin:
    li   $v0, 4
    la   $a0, prompt_x
    syscall
    li   $v0, 6
    syscall                    # read float → $f0
    mov.s $f12, $f0
    jal  sin_approx            # sin_approx($f12) → $f0

    li   $v0, 4
    la   $a0, res_flt
    syscall
    mov.s $f12, $f0
    li   $v0, 2
    syscall                    # print float from $f12
    li   $v0, 4
    la   $a0, nl
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_cos   Read float radians, compute cos, print float.
# ─────────────────────────────────────────────────────────
do_cos:
    li   $v0, 4
    la   $a0, prompt_x
    syscall
    li   $v0, 6
    syscall
    mov.s $f12, $f0
    jal  cos_approx            # cos_approx($f12) → $f0

    li   $v0, 4
    la   $a0, res_flt
    syscall
    mov.s $f12, $f0
    li   $v0, 2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# PROCEDURE: sin_approx
#   Input  : $f12 = x  (radians, single-precision)
#   Output : $f0  = approximate sin(x)
#
#   6-term Taylor series:
#     sin(x) = x - x³/3! + x⁵/5! - x⁷/7! + x⁹/9! - x¹¹/11!
#
#   Iterative term generation — avoids computing large factorials:
#     term₁ = x
#     termₖ = termₖ₋₁ × x² / dₖ   where dₖ = (2k)(2k+1)
#     d values: 6, 20, 42, 72, 110
#
#   Signs alternate starting from +, so odd terms are added
#   and even terms are subtracted.
#
#   Register map:
#     $f0  — running result (accumulator)
#     $f2  — x²  (constant throughout)
#     $f4  — current term
#     $f6  — divisor constant  (loaded from .data per step)
# ─────────────────────────────────────────────────────────
sin_approx:
    mul.s $f2, $f12, $f12      # f2 = x²
    mov.s $f4, $f12            # term₁ = x
    mov.s $f0, $f12            # result = x  (first term, sign +)

    l.s   $f6, f_sd1           # divisor = 6.0  (= 2×3)
    mul.s $f4, $f4, $f2        # f4 = x³
    div.s $f4, $f4, $f6        # f4 = x³/3!
    sub.s $f0, $f0, $f4        # result −= term₂  (sign −)

    l.s   $f6, f_sd2           # divisor = 20.0  (= 4×5)
    mul.s $f4, $f4, $f2        # f4 = x⁵/3!
    div.s $f4, $f4, $f6        # f4 = x⁵/5!
    add.s $f0, $f0, $f4        # result += term₃  (sign +)

    l.s   $f6, f_sd3           # divisor = 42.0  (= 6×7)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x⁷/7!
    sub.s $f0, $f0, $f4

    l.s   $f6, f_sd4           # divisor = 72.0  (= 8×9)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x⁹/9!
    add.s $f0, $f0, $f4

    l.s   $f6, f_sd5           # divisor = 110.0  (= 10×11)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x¹¹/11!
    sub.s $f0, $f0, $f4        # result −= term₆  (sign −)

    jr    $ra

# ─────────────────────────────────────────────────────────
# PROCEDURE: cos_approx
#   Input  : $f12 = x  (radians, single-precision)
#   Output : $f0  = approximate cos(x)
#
#   6-term Taylor series:
#     cos(x) = 1 - x²/2! + x⁴/4! - x⁶/6! + x⁸/8! - x¹⁰/10!
#
#   Iterative term generation:
#     term₁ = 1
#     termₖ = termₖ₋₁ × x² / dₖ   where dₖ = (2k-1)(2k)
#     d values: 2, 12, 30, 56, 90
#
#   Register map: same layout as sin_approx;
#   both $f0 and $f4 start at 1.0.
# ─────────────────────────────────────────────────────────
cos_approx:
    mul.s $f2, $f12, $f12      # f2 = x²

    l.s   $f0, f_one           # result = 1.0
    l.s   $f4, f_one           # term₁  = 1.0

    l.s   $f6, f_cd1           # divisor = 2.0  (= 1×2)
    mul.s $f4, $f4, $f2        # f4 = x²
    div.s $f4, $f4, $f6        # f4 = x²/2!
    sub.s $f0, $f0, $f4        # result −= term₂

    l.s   $f6, f_cd2           # divisor = 12.0  (= 3×4)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x⁴/4!
    add.s $f0, $f0, $f4

    l.s   $f6, f_cd3           # divisor = 30.0  (= 5×6)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x⁶/6!
    sub.s $f0, $f0, $f4

    l.s   $f6, f_cd4           # divisor = 56.0  (= 7×8)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x⁸/8!
    add.s $f0, $f0, $f4

    l.s   $f6, f_cd5           # divisor = 90.0  (= 9×10)
    mul.s $f4, $f4, $f2
    div.s $f4, $f4, $f6        # f4 = x¹⁰/10!
    sub.s $f0, $f0, $f4

    jr    $ra

############################################################
# SECTION 4 — EXPRESSION EVALUATOR
#
# Supports infix integer expressions with the four operators
# + - * / and correct precedence  (* / bind tighter than + -).
# Spaces between tokens are optional.
# Multi-digit non-negative integer operands are supported.
#
# Algorithm: Shunting-yard (Dijkstra, 1961) with two stacks.
#
#   val_stk  — operand  stack (integer words)
#   op_stk   — operator stack (ASCII bytes for  + - * /)
#
# On reading a digit sequence: parse the full number, push
# onto val_stk.
#
# On reading an operator:
#   While op_stk is non-empty AND the top operator has
#   precedence >= the incoming operator, pop the top operator
#   and its two operands, evaluate, push result onto val_stk.
#   Then push the incoming operator onto op_stk.
#
# At end of input:
#   Pop and evaluate remaining operators in op_stk.
#
# Final result is the sole value remaining in val_stk.
############################################################

# ─────────────────────────────────────────────────────────
# do_expr   Read expression string, evaluate, print result.
# ─────────────────────────────────────────────────────────
do_expr:
    li   $v0, 4
    la   $a0, prompt_expr
    syscall
    la   $a0, expr_buf
    li   $a1, 127
    li   $v0, 8
    syscall                    # read string → expr_buf

    la   $a0, expr_buf
    jal  expr_eval             # $v0 = result, $v1 = error flag

    beq  $v1, 1, menu_loop     # error already printed by expr_eval

    move $s0, $v0              # save result before syscalls clobber $v0
    li   $v0, 4
    la   $a0, res_int
    syscall
    li   $v0, 1
    move $a0, $s0
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    move $a0, $s0
    jal  add_to_history
    j    menu_loop

# ─────────────────────────────────────────────────────────
# PROCEDURE: expr_eval
#   Input  : $a0 = address of null-terminated expression
#   Output : $v0 = integer result
#            $v1 = 0 (success) / 1 (error, message printed)
#
#   No jal calls are made inside this procedure, so all stack
#   operations are inlined and only $t registers are needed.
#   No stack frame is required.
#
#   Register map:
#     $t9  current character pointer (walks through expr_buf)
#     $t8  saved current operator  (persists through shunting loop)
#     $t0  current character / temp
#     $t1  number accumulator / popped operand b
#     $t2  comparison temp / effective address
#     $t3  popped operand a / computed result
#     $t4  stack base address
#     $t5  stack top index / effective address
#     $t6  precedence of current operator / push address temp
#     $t7  precedence of stack-top operator
# ─────────────────────────────────────────────────────────
expr_eval:
    li   $t0, 0
    sw   $t0, val_top          # reset value  stack
    sw   $t0, op_top           # reset operator stack
    move $t9, $a0              # t9 = current char pointer

# ── Main parse loop ───────────────────────────────────────
expr_parse:
    lb   $t0, 0($t9)           # load next character
    beqz $t0, expr_flush       # null terminator → end of input
    li   $t2, 10
    beq  $t0, $t2, expr_flush  # newline (from syscall 8) → end
    li   $t2, 32
    beq  $t0, $t2, expr_next_ch  # space → skip

    # Is it a digit?  ('0' = 48 … '9' = 57)
    li   $t2, 48
    blt  $t0, $t2, expr_try_op
    li   $t2, 57
    bgt  $t0, $t2, expr_try_op

    # ── Parse a complete multi-digit integer ──────────────
    li   $t1, 0                # number accumulator = 0
expr_numloop:
    lb   $t0, 0($t9)
    li   $t2, 48
    blt  $t0, $t2, expr_end_num
    li   $t2, 57
    bgt  $t0, $t2, expr_end_num
    mul  $t1, $t1, 10
    sub  $t0, $t0, 48          # digit value
    add  $t1, $t1, $t0         # accumulator = accumulator×10 + digit
    addi $t9, $t9, 1
    j    expr_numloop

expr_end_num:
    # Push parsed integer onto val_stk
    la   $t4, val_stk
    lw   $t5, val_top
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    sw   $t1, 0($t2)           # val_stk[top] = number
    addi $t5, $t5, 1
    sw   $t5, val_top
    j    expr_parse            # t9 already advanced past the number

expr_next_ch:
    addi $t9, $t9, 1
    j    expr_parse

# ── Operator token encountered ────────────────────────────
expr_try_op:
    li   $t2, 43
    beq  $t0, $t2, expr_got_op   # '+'
    li   $t2, 45
    beq  $t0, $t2, expr_got_op   # '-'
    li   $t2, 42
    beq  $t0, $t2, expr_got_op   # '*'
    li   $t2, 47
    beq  $t0, $t2, expr_got_op   # '/'
    j    expr_err_bad             # unknown character

expr_got_op:
    addi $t9, $t9, 1           # advance past operator character
    move $t8, $t0              # t8 = current operator (preserved through loop)

# ── Shunting-yard: apply higher-or-equal precedence ops first
expr_shunt_loop:
    lw   $t5, op_top
    beqz $t5, expr_shunt_push  # op_stk empty → push current operator

    # Precedence of current operator ($t8) → $t6
    li   $t6, 1                # default: low precedence  (+ -)
    li   $t2, 42
    beq  $t8, $t2, esl_hi      # '*' → prec 2
    li   $t2, 47
    beq  $t8, $t2, esl_hi      # '/' → prec 2
    j    esl_cur_done
esl_hi:
    li   $t6, 2
esl_cur_done:

    # Peek top of op_stk (do NOT pop yet) → $t0
    la   $t4, op_stk
    lw   $t5, op_top
    addi $t5, $t5, -1          # index of top element
    add  $t2, $t4, $t5
    lb   $t0, 0($t2)           # t0 = top operator

    # Precedence of top operator → $t7
    li   $t7, 1
    li   $t2, 42
    beq  $t0, $t2, esl_top_hi  # '*'
    li   $t2, 47
    beq  $t0, $t2, esl_top_hi  # '/'
    j    esl_top_done
esl_top_hi:
    li   $t7, 2
esl_top_done:

    blt  $t7, $t6, expr_shunt_push  # top-prec < cur-prec → stop popping

    # ── Pop top operator and apply it ─────────────────────
    # Pop operator from op_stk
    lw   $t5, op_top
    addi $t5, $t5, -1
    sw   $t5, op_top
    la   $t4, op_stk
    add  $t2, $t4, $t5
    lb   $t0, 0($t2)           # t0 = popped operator

    # Guard: need at least 2 values in val_stk
    lw   $t5, val_top
    blt  $t5, 2, expr_err_bad

    # Pop b (top) → $t1
    la   $t4, val_stk
    addi $t5, $t5, -1
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    lw   $t1, 0($t2)
    sw   $t5, val_top

    # Pop a (new top) → $t3
    lw   $t5, val_top
    addi $t5, $t5, -1
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    lw   $t3, 0($t2)           # $t4 still = val_stk base from la above
    sw   $t5, val_top

    # Compute a op b → $t3
    li   $t2, 43
    beq  $t0, $t2, esl_add    # '+'
    li   $t2, 45
    beq  $t0, $t2, esl_sub    # '-'
    li   $t2, 42
    beq  $t0, $t2, esl_mul    # '*'
    # '/' — division by zero check
    beqz $t1, expr_err_div0
    div  $t3, $t1
    mflo $t3
    j    esl_push
esl_add:
    add  $t3, $t3, $t1
    j    esl_push
esl_sub:
    sub  $t3, $t3, $t1
    j    esl_push
esl_mul:
    mul  $t3, $t3, $t1        # falls through to esl_push

esl_push:
    # Push result onto val_stk
    # ($t6 reused as address temp; will be recomputed next iteration)
    la   $t4, val_stk
    lw   $t5, val_top
    sll  $t6, $t5, 2
    add  $t6, $t4, $t6
    sw   $t3, 0($t6)
    addi $t5, $t5, 1
    sw   $t5, val_top
    j    expr_shunt_loop       # loop: may need to apply more operators

expr_shunt_push:
    # Push current operator ($t8) onto op_stk
    la   $t4, op_stk
    lw   $t5, op_top
    add  $t2, $t4, $t5
    sb   $t8, 0($t2)
    addi $t5, $t5, 1
    sw   $t5, op_top
    j    expr_parse

# ── Flush remaining operators after end of input ──────────
expr_flush:
    lw   $t5, op_top
    beqz $t5, expr_return      # op_stk empty → done

    # Pop operator
    addi $t5, $t5, -1
    sw   $t5, op_top
    la   $t4, op_stk
    add  $t2, $t4, $t5
    lb   $t0, 0($t2)           # t0 = operator

    # Guard: need at least 2 values
    lw   $t5, val_top
    blt  $t5, 2, expr_err_bad

    # Pop b → $t1
    la   $t4, val_stk
    addi $t5, $t5, -1
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    lw   $t1, 0($t2)
    sw   $t5, val_top

    # Pop a → $t3
    lw   $t5, val_top
    addi $t5, $t5, -1
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    lw   $t3, 0($t2)
    sw   $t5, val_top

    # Apply operator
    li   $t2, 43
    beq  $t0, $t2, efl_add
    li   $t2, 45
    beq  $t0, $t2, efl_sub
    li   $t2, 42
    beq  $t0, $t2, efl_mul
    beqz $t1, expr_err_div0
    div  $t3, $t1
    mflo $t3
    j    efl_push
efl_add:
    add  $t3, $t3, $t1
    j    efl_push
efl_sub:
    sub  $t3, $t3, $t1
    j    efl_push
efl_mul:
    mul  $t3, $t3, $t1

efl_push:
    la   $t4, val_stk
    lw   $t5, val_top
    sll  $t6, $t5, 2
    add  $t6, $t4, $t6
    sw   $t3, 0($t6)
    addi $t5, $t5, 1
    sw   $t5, val_top
    j    expr_flush            # loop until op_stk is empty

# ── Return final value ─────────────────────────────────────
expr_return:
    lw   $t5, val_top
    beqz $t5, expr_err_bad     # empty stack → malformed expression
    addi $t5, $t5, -1
    la   $t4, val_stk
    sll  $t2, $t5, 2
    add  $t2, $t4, $t2
    lw   $v0, 0($t2)           # $v0 = result
    li   $v1, 0                # no error
    jr   $ra

# ── Error exits ───────────────────────────────────────────
expr_err_div0:
    li   $v0, 4
    la   $a0, err_div0
    syscall
    li   $v1, 1
    li   $v0, 0
    jr   $ra

expr_err_bad:
    li   $v0, 4
    la   $a0, err_expr
    syscall
    li   $v1, 1
    li   $v0, 0
    jr   $ra

############################################################
# SECTION 5 — HISTORY AND HELP
############################################################

# ─────────────────────────────────────────────────────────
# do_hist   Print the contents of the ring buffer in
#           chronological order (oldest first).
#
# The oldest entry is at index  (wptr − cnt + 5) mod 5.
# We walk forward from there, wrapping at index 5, printing
# cnt entries total.
# ─────────────────────────────────────────────────────────
do_hist:
    li   $v0, 4
    la   $a0, hist_hdr
    syscall

    lw   $t0, hist_cnt         # t0 = number of stored entries
    beqz $t0, hist_empty_msg

    # Compute oldest-entry index: (wptr - cnt + 5) mod 5
    lw   $t1, hist_wptr        # t1 = next-write pointer
    sub  $t1, $t1, $t0         # may be negative
    li   $t2, 5
    add  $t1, $t1, $t2         # ensure non-negative
    div  $t1, $t2
    mfhi $t1                   # t1 = oldest read index  (0–4)

    li   $t4, 0                # t4 = display counter  (0-based)

hist_loop:
    bge  $t4, $t0, menu_loop   # printed all entries → return to menu

    # Print label  "  [N] "
    li   $v0, 4
    la   $a0, hist_lbr
    syscall
    addi $a0, $t4, 1           # 1-based entry number
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, hist_rbr
    syscall

    # Print hist_buf[t1]
    la   $t5, hist_buf
    sll  $t6, $t1, 2
    add  $t6, $t5, $t6
    lw   $a0, 0($t6)
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    # Advance read index with wrap-around
    addi $t1, $t1, 1
    li   $t2, 5
    blt  $t1, $t2, hist_no_wrap
    li   $t1, 0
hist_no_wrap:
    addi $t4, $t4, 1
    j    hist_loop

hist_empty_msg:
    li   $v0, 4
    la   $a0, hist_empty
    syscall
    j    menu_loop

# ─────────────────────────────────────────────────────────
# do_help   Print inline help text.
# ─────────────────────────────────────────────────────────
do_help:
    li   $v0, 4
    la   $a0, help_str
    syscall
    j    menu_loop

############################################################
# UTILITY PROCEDURES
############################################################

# ─────────────────────────────────────────────────────────
# PROCEDURE: add_to_history
#   Input  : $a0 = integer result to record
#
#   Writes $a0 into hist_buf at the current write-pointer
#   slot, increments the pointer modulo 5, and increments
#   hist_cnt up to a ceiling of 5 (ring buffer is now full).
#
#   Registers used: $t0–$t3  (all caller-saved; safe to use)
# ─────────────────────────────────────────────────────────
add_to_history:
    la   $t0, hist_buf
    lw   $t1, hist_wptr        # current write slot index

    sll  $t2, $t1, 2
    add  $t2, $t0, $t2
    sw   $a0, 0($t2)           # hist_buf[wptr] = value

    addi $t1, $t1, 1           # advance write pointer
    li   $t3, 5
    blt  $t1, $t3, ath_no_wrap
    li   $t1, 0                # wrap around at 5
ath_no_wrap:
    sw   $t1, hist_wptr

    lw   $t1, hist_cnt
    bge  $t1, 5, ath_done      # already at maximum capacity
    addi $t1, $t1, 1
    sw   $t1, hist_cnt
ath_done:
    jr   $ra
