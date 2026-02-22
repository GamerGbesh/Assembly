############################################################
# Assignment 3 (Lab 3) : Recursive Algorithm Suite
#
# Implements:
#   1. Fibonacci        — recursive  (with call counter)
#   2. Fibonacci        — iterative  (comparison)
#   3. GCD              — Euclidean recursive
#   4. Power            — x^n recursive
#   5. Tower of Hanoi   — prints every move
#   6. Binary Search    — recursive on a predefined sorted array
#
# Stack-frame convention (callee-saved):
#   Every recursive procedure that makes at least one jal:
#     • Allocates a frame on $sp
#     • Saves $ra at the highest word in the frame
#     • Saves every $s register it uses below $ra
#     • Restores them in reverse order before jr $ra
#   Base-case returns that make no further jal are leaves and
#   need no frame.
#
# Call counters:
#   Each recursive function increments a global .word counter
#   on its very first instruction.  The menu handler resets the
#   counter to 0 before calling and prints the count after,
#   giving the total number of invocations per operation.
#
# Example traces included in section comments below.
############################################################

.data

# ── UI strings ─────────────────────────────────────────────
title:       .asciiz "\n==================================\n  Recursive Algorithm Suite\n  (Lab 3  Assignment 3)\n==================================\n"
menu_str:    .asciiz "\n 1) Fibonacci  (recursive)\n 2) Fibonacci  (iterative)\n 3) GCD        (Euclidean)\n 4) Power      x^n\n 5) Tower of Hanoi\n 6) Binary Search\n 0) Exit\n> "
prompt_n:    .asciiz "n = "
prompt_a:    .asciiz "a = "
prompt_b:    .asciiz "b = "
prompt_x:    .asciiz "x = "
prompt_key:  .asciiz "key = "
nl:          .asciiz "\n"
res_str:     .asciiz "\nResult     : "
calls_str:   .asciiz "Total calls: "

# ── Section headers ────────────────────────────────────────
fib_r_hdr:   .asciiz "\n--- Fibonacci (recursive) ---\n"
fib_i_hdr:   .asciiz "\n--- Fibonacci (iterative) ---\n"
gcd_hdr:     .asciiz "\n--- GCD (Euclidean recursive) ---\n"
pow_hdr:     .asciiz "\n--- Power x^n (recursive) ---\n"
hanoi_hdr:   .asciiz "\n--- Tower of Hanoi ---\n"
bs_hdr:      .asciiz "\n--- Binary Search (recursive) ---\n"

# ── Tower of Hanoi output ──────────────────────────────────
move_disk:   .asciiz "  Move disk "
from_peg:    .asciiz " from peg "
to_peg:      .asciiz " to peg "

# ── Binary search output ────────────────────────────────────
arr_label:   .asciiz "Array: [2 5 8 12 16 23 38 42 56 72]\n"
found_str:   .asciiz "Found at index : "
nfound_str:  .asciiz "Not found\n"

# ── Error messages ─────────────────────────────────────────
err_neg:     .asciiz "\nError: n must be >= 0\n"
err_range:   .asciiz "\nError: n must be 1-15 for Hanoi\n"

# ── Call counters (one per recursive algorithm) ─────────────
fib_calls:   .word 0
gcd_calls:   .word 0
pow_calls:   .word 0
hanoi_calls: .word 0
bs_calls:    .word 0

# ── Sorted array for binary search ─────────────────────────
             .align 2
sorted_arr:  .word 2, 5, 8, 12, 16, 23, 38, 42, 56, 72
arr_size:    .word 10

.text
.globl main

############################################################
# MAIN
############################################################
main:
    li   $v0, 4
    la   $a0, title
    syscall

menu_loop:
    li   $v0, 4
    la   $a0, menu_str
    syscall

    li   $v0, 5
    syscall
    move $t0, $v0

    beq  $t0, 0, do_exit
    beq  $t0, 1, do_fib_rec
    beq  $t0, 2, do_fib_iter
    beq  $t0, 3, do_gcd
    beq  $t0, 4, do_power
    beq  $t0, 5, do_hanoi
    beq  $t0, 6, do_bsearch
    j    menu_loop

do_exit:
    li   $v0, 10
    syscall

############################################################
# SECTION 1 — FIBONACCI  (recursive)
#
# Recurrence:
#   fib(0) = 0
#   fib(1) = 1
#   fib(n) = fib(n-1) + fib(n-2)
#
# Example trace — fib(5):
#   fib(5)
#    ├─ fib(4)
#    │   ├─ fib(3)
#    │   │   ├─ fib(2)
#    │   │   │   ├─ fib(1) = 1
#    │   │   │   └─ fib(0) = 0  → fib(2) = 1
#    │   │   └─ fib(1) = 1     → fib(3) = 2
#    │   └─ fib(2) = 1         → fib(4) = 3
#    └─ fib(3) = 2             → fib(5) = 5
#   Total calls: 15
############################################################

do_fib_rec:
    li   $v0, 4
    la   $a0, fib_r_hdr
    syscall

    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = n

    bltz $s0, frec_err

    li   $t0, 0
    sw   $t0, fib_calls        # reset counter before call

    move $a0, $s0
    jal  fib_rec               # fib_rec(n) → $v0
    move $s1, $v0              # save result before syscalls

    li   $v0, 4
    la   $a0, res_str
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    li   $v0, 4
    la   $a0, calls_str
    syscall
    lw   $a0, fib_calls
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

frec_err:
    li   $v0, 4
    la   $a0, err_neg
    syscall
    j    menu_loop

############################################################
# SECTION 2 — FIBONACCI  (iterative)
#
# Sliding-window approach — three registers:
#   prev2 ← fib(i-2),  prev1 ← fib(i-1),  curr ← fib(i)
# O(n) time, O(1) space.  No call counter (no recursion).
############################################################

do_fib_iter:
    li   $v0, 4
    la   $a0, fib_i_hdr
    syscall

    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0

    bltz $s0, fiter_err

    move $a0, $s0
    jal  fib_iter              # fib_iter(n) → $v0
    move $s1, $v0

    li   $v0, 4
    la   $a0, res_str
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

fiter_err:
    li   $v0, 4
    la   $a0, err_neg
    syscall
    j    menu_loop

############################################################
# SECTION 3 — GCD  (Euclidean recursive)
#
# Recurrence:
#   gcd(a, 0) = a
#   gcd(a, b) = gcd(b, a mod b)
#
# Example trace — gcd(48, 18):
#   gcd(48, 18)  →  a mod b = 12
#   gcd(18, 12)  →  a mod b =  6
#   gcd(12,  6)  →  a mod b =  0
#   gcd( 6,  0)  →  returns 6
#   Total calls: 4
############################################################

do_gcd:
    li   $v0, 4
    la   $a0, gcd_hdr
    syscall

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

    bgez $s0, gcd_abs_b        # normalise inputs to non-negative
    neg  $s0, $s0
gcd_abs_b:
    bgez $s1, gcd_ready
    neg  $s1, $s1

gcd_ready:
    li   $t0, 0
    sw   $t0, gcd_calls

    move $a0, $s0
    move $a1, $s1
    jal  gcd_rec               # gcd_rec(a, b) → $v0
    move $s2, $v0

    li   $v0, 4
    la   $a0, res_str
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    li   $v0, 4
    la   $a0, calls_str
    syscall
    lw   $a0, gcd_calls
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

############################################################
# SECTION 4 — POWER  (x^n, recursive)
#
# Recurrence:
#   pow(x, 0) = 1
#   pow(x, n) = x * pow(x, n-1)
#
# Example trace — pow(2, 4):
#   pow(2,4) = 2 * pow(2,3)
#   pow(2,3) = 2 * pow(2,2)
#   pow(2,2) = 2 * pow(2,1)
#   pow(2,1) = 2 * pow(2,0)
#   pow(2,0) = 1             → base case
#   Total calls: 5  (n+1)
############################################################

do_power:
    li   $v0, 4
    la   $a0, pow_hdr
    syscall

    li   $v0, 4
    la   $a0, prompt_x
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = x

    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0              # s1 = n

    bltz $s1, pow_err

    li   $t0, 0
    sw   $t0, pow_calls

    move $a0, $s0
    move $a1, $s1
    jal  pow_rec               # pow_rec(x, n) → $v0
    move $s2, $v0

    li   $v0, 4
    la   $a0, res_str
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    li   $v0, 4
    la   $a0, calls_str
    syscall
    lw   $a0, pow_calls
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

pow_err:
    li   $v0, 4
    la   $a0, err_neg
    syscall
    j    menu_loop

############################################################
# SECTION 5 — TOWER OF HANOI
#
# Recurrence:
#   hanoi(1, src, dst, aux):
#     print "Move disk 1 from src to dst"
#   hanoi(n, src, dst, aux):
#     hanoi(n-1, src, aux, dst)      ← move top n-1 out of way
#     print "Move disk n from src to dst"
#     hanoi(n-1, aux, dst, src)      ← settle n-1 on top
#
# Pegs passed as ASCII: 'A'=65, 'B'=66, 'C'=67.
# Capped at n ≤ 15  (2^15 − 1 = 32767 moves).
#
# Example trace — hanoi(3, A, C, B):
#   Move disk 1 from peg A to peg C
#   Move disk 2 from peg A to peg B
#   Move disk 1 from peg C to peg B
#   Move disk 3 from peg A to peg C
#   Move disk 1 from peg B to peg A
#   Move disk 2 from peg B to peg C
#   Move disk 1 from peg A to peg C
#   Total calls: 7  (2^n − 1)
############################################################

do_hanoi:
    li   $v0, 4
    la   $a0, hanoi_hdr
    syscall

    li   $v0, 4
    la   $a0, prompt_n
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0

    blez $s0, hanoi_err
    bgt  $s0, 15, hanoi_err

    li   $t0, 0
    sw   $t0, hanoi_calls

    move $a0, $s0              # n
    li   $a1, 65               # src = 'A'
    li   $a2, 67               # dst = 'C'
    li   $a3, 66               # aux = 'B'
    jal  hanoi_rec

    li   $v0, 4
    la   $a0, calls_str
    syscall
    lw   $a0, hanoi_calls
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

hanoi_err:
    li   $v0, 4
    la   $a0, err_range
    syscall
    j    menu_loop

############################################################
# SECTION 6 — BINARY SEARCH  (recursive)
#
# Array: [2 5 8 12 16 23 38 42 56 72]  (indices 0-9)
#
# Recurrence:
#   bsearch(arr, key, lo, hi):
#     if lo > hi:          return -1
#     mid = (lo + hi) / 2
#     if arr[mid] == key:  return mid
#     if arr[mid] <  key:  return bsearch(arr, key, mid+1, hi)
#     else:                return bsearch(arr, key, lo, mid-1)
#
# Example trace — searching for 23:
#   call 1: lo=0  hi=9  mid=4  arr[4]=16 < 23  → go right
#   call 2: lo=5  hi=9  mid=7  arr[7]=42 > 23  → go left
#   call 3: lo=5  hi=6  mid=5  arr[5]=23 == 23  → found at 5
#   Total calls: 3
############################################################

do_bsearch:
    li   $v0, 4
    la   $a0, bs_hdr
    syscall
    li   $v0, 4
    la   $a0, arr_label
    syscall

    li   $v0, 4
    la   $a0, prompt_key
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # s0 = key

    li   $t0, 0
    sw   $t0, bs_calls

    la   $a0, sorted_arr       # base address of array
    move $a1, $s0              # key
    li   $a2, 0                # lo = 0
    lw   $a3, arr_size
    addi $a3, $a3, -1          # hi = size - 1  (= 9)
    jal  bsearch_rec           # returns index in $v0, or -1

    move $s1, $v0

    bltz $s1, bs_not_found

    li   $v0, 4
    la   $a0, found_str
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall
    j    bs_show_calls

bs_not_found:
    li   $v0, 4
    la   $a0, nfound_str
    syscall

bs_show_calls:
    li   $v0, 4
    la   $a0, calls_str
    syscall
    lw   $a0, bs_calls
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    j    menu_loop

############################################################
# PROCEDURE: fib_rec
#   Input  : $a0 = n  (n >= 0)
#   Output : $v0 = fib(n)
#
#   Stack frame (12 bytes) — only allocated for n >= 2:
#     0($sp) = saved $s1  (fib(n-1) result, needed when fib(n-2) is computed)
#     4($sp) = saved $s0  (n, needed to compute n-2 after first recursive call)
#     8($sp) = saved $ra
############################################################
fib_rec:
    lw   $t0, fib_calls        # increment global call counter
    addi $t0, $t0, 1
    sw   $t0, fib_calls

    beqz $a0, fib_base0        # fib(0) = 0
    li   $t0, 1
    beq  $a0, $t0, fib_base1   # fib(1) = 1

    # n >= 2: build frame and recurse
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    move $s0, $a0              # s0 = n

    addi $a0, $s0, -1          # compute fib(n-1)
    jal  fib_rec
    move $s1, $v0              # s1 = fib(n-1)

    addi $a0, $s0, -2          # compute fib(n-2)
    jal  fib_rec
                               # $v0 = fib(n-2)
    add  $v0, $s1, $v0         # fib(n) = fib(n-1) + fib(n-2)

    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

fib_base0:
    li   $v0, 0
    jr   $ra

fib_base1:
    li   $v0, 1
    jr   $ra

############################################################
# PROCEDURE: fib_iter
#   Input  : $a0 = n  (n >= 0)
#   Output : $v0 = fib(n)
#   Leaf — no stack frame required.
############################################################
fib_iter:
    beqz $a0, fi_ret0          # fib(0) = 0
    li   $t0, 1
    beq  $a0, $t0, fi_ret1     # fib(1) = 1

    li   $t1, 0                # prev2 = fib(0)
    li   $t2, 1                # prev1 = fib(1)
    li   $t3, 2                # i = 2

fi_loop:
    bgt  $t3, $a0, fi_done
    add  $t4, $t1, $t2         # curr = prev2 + prev1
    move $t1, $t2              # prev2 ← prev1
    move $t2, $t4              # prev1 ← curr
    addi $t3, $t3, 1           # i++
    j    fi_loop

fi_done:
    move $v0, $t2
    jr   $ra

fi_ret0:
    li   $v0, 0
    jr   $ra

fi_ret1:
    li   $v0, 1
    jr   $ra

############################################################
# PROCEDURE: gcd_rec
#   Input  : $a0 = a, $a1 = b  (both non-negative)
#   Output : $v0 = gcd(a, b)
#
#   Stack frame (8 bytes) — only allocated when b != 0:
#     0($sp) = saved $s0  (b — must survive the recursive call to become new a)
#     4($sp) = saved $ra
############################################################
gcd_rec:
    lw   $t0, gcd_calls
    addi $t0, $t0, 1
    sw   $t0, gcd_calls

    beqz $a1, gcd_base         # gcd(a, 0) = a

    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)

    move $s0, $a1              # s0 = b  (will become new a)
    div  $a0, $a1              # HI = a mod b
    mfhi $a1                   # a1 = a mod b
    move $a0, $s0              # a0 = b

    jal  gcd_rec               # gcd(b, a mod b) → $v0

    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

gcd_base:
    move $v0, $a0
    jr   $ra

############################################################
# PROCEDURE: pow_rec
#   Input  : $a0 = x, $a1 = n  (n >= 0)
#   Output : $v0 = x^n
#
#   Stack frame (12 bytes) — only allocated when n > 0:
#     0($sp) = saved $s1  (n — kept for documentation; not strictly needed)
#     4($sp) = saved $s0  (x — must survive recursive call for final multiply)
#     8($sp) = saved $ra
############################################################
pow_rec:
    lw   $t0, pow_calls
    addi $t0, $t0, 1
    sw   $t0, pow_calls

    beqz $a1, pow_base         # x^0 = 1

    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    move $s0, $a0              # s0 = x
    move $s1, $a1              # s1 = n  (for reference)

    addi $a1, $a1, -1          # n - 1
    jal  pow_rec               # pow(x, n-1) → $v0

    mul  $v0, $s0, $v0         # x * pow(x, n-1)

    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

pow_base:
    li   $v0, 1
    jr   $ra

############################################################
# PROCEDURE: hanoi_rec
#   Input  : $a0 = n    (disk count)
#            $a1 = src  (source peg, ASCII 'A'/'B'/'C')
#            $a2 = dst  (destination peg, ASCII)
#            $a3 = aux  (helper peg, ASCII)
#   Output : none  (prints one "Move disk …" line per call)
#
#   Stack frame (20 bytes) — only allocated when n > 1:
#     0($sp) = saved $s3  (aux)
#     4($sp) = saved $s2  (dst)
#     8($sp) = saved $s1  (src)
#    12($sp) = saved $s0  (n)
#    16($sp) = saved $ra
############################################################
hanoi_rec:
    lw   $t0, hanoi_calls
    addi $t0, $t0, 1
    sw   $t0, hanoi_calls

    li   $t0, 1
    beq  $a0, $t0, hanoi_base  # n == 1: base case (leaf)

    addi $sp, $sp, -20
    sw   $ra, 16($sp)
    sw   $s0, 12($sp)
    sw   $s1,  8($sp)
    sw   $s2,  4($sp)
    sw   $s3,  0($sp)

    move $s0, $a0              # s0 = n
    move $s1, $a1              # s1 = src
    move $s2, $a2              # s2 = dst
    move $s3, $a3              # s3 = aux

    # Step 1: hanoi(n-1, src, aux, dst)
    #         move top n-1 disks from src to aux (using dst as helper)
    addi $a0, $s0, -1
    move $a1, $s1              # src
    move $a2, $s3              # aux  (temporary destination)
    move $a3, $s2              # dst  (temporary helper)
    jal  hanoi_rec

    # Step 2: print "Move disk N from src to dst"
    li   $v0, 4
    la   $a0, move_disk
    syscall
    li   $v0, 1
    move $a0, $s0              # disk number = N
    syscall
    li   $v0, 4
    la   $a0, from_peg
    syscall
    li   $v0, 11
    move $a0, $s1              # src peg character
    syscall
    li   $v0, 4
    la   $a0, to_peg
    syscall
    li   $v0, 11
    move $a0, $s2              # dst peg character
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    # Step 3: hanoi(n-1, aux, dst, src)
    #         move n-1 disks from aux to dst (using src as helper)
    addi $a0, $s0, -1
    move $a1, $s3              # aux  (now acts as source)
    move $a2, $s2              # dst
    move $a3, $s1              # src  (now acts as helper)
    jal  hanoi_rec

    lw   $s3,  0($sp)
    lw   $s2,  4($sp)
    lw   $s1,  8($sp)
    lw   $s0, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# ── Base case: n == 1, print the single move and return ────
# $a0=1, $a1=src, $a2=dst are live on entry.
# Save src/dst into $t1/$t2 immediately so syscalls may use $a0.
hanoi_base:
    move $t1, $a1              # t1 = src peg char
    move $t2, $a2              # t2 = dst peg char

    li   $v0, 4
    la   $a0, move_disk
    syscall
    li   $v0, 1
    li   $a0, 1                # disk number is always 1 at the base case
    syscall
    li   $v0, 4
    la   $a0, from_peg
    syscall
    li   $v0, 11
    move $a0, $t1              # src peg char
    syscall
    li   $v0, 4
    la   $a0, to_peg
    syscall
    li   $v0, 11
    move $a0, $t2              # dst peg char
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    jr   $ra

############################################################
# PROCEDURE: bsearch_rec
#   Input  : $a0 = base address of sorted word array
#            $a1 = key
#            $a2 = lo index (inclusive)
#            $a3 = hi index (inclusive)
#   Output : $v0 = index of key (0-based), or -1 if not found
#
#   Stack frame (24 bytes) — only allocated when recursion needed:
#     0($sp) = saved $s4  (mid — index of midpoint)
#     4($sp) = saved $s3  (hi)
#     8($sp) = saved $s2  (lo)
#    12($sp) = saved $s1  (key)
#    16($sp) = saved $s0  (array base address)
#    20($sp) = saved $ra
############################################################
bsearch_rec:
    lw   $t0, bs_calls
    addi $t0, $t0, 1
    sw   $t0, bs_calls

    bgt  $a2, $a3, bs_notfound # lo > hi → key not present

    add  $t4, $a2, $a3
    srl  $t4, $t4, 1           # t4 = mid = (lo + hi) / 2

    sll  $t0, $t4, 2
    add  $t0, $a0, $t0
    lw   $t1, 0($t0)           # t1 = arr[mid]

    beq  $t1, $a1, bs_found    # arr[mid] == key → done (leaf return)

    # Need to recurse; build stack frame
    addi $sp, $sp, -24
    sw   $ra, 20($sp)
    sw   $s0, 16($sp)
    sw   $s1, 12($sp)
    sw   $s2,  8($sp)
    sw   $s3,  4($sp)
    sw   $s4,  0($sp)

    move $s0, $a0              # base address
    move $s1, $a1              # key
    move $s2, $a2              # lo
    move $s3, $a3              # hi
    move $s4, $t4              # mid (save before $t4 may be reused)

    blt  $t1, $a1, bsr_right   # arr[mid] < key → search upper half

bsr_left:
    # Search [lo, mid-1]
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    addi $a3, $s4, -1          # hi = mid - 1
    jal  bsearch_rec
    j    bsr_restore

bsr_right:
    # Search [mid+1, hi]
    move $a0, $s0
    move $a1, $s1
    addi $a2, $s4, 1           # lo = mid + 1
    move $a3, $s3
    jal  bsearch_rec

bsr_restore:
    lw   $s4,  0($sp)
    lw   $s3,  4($sp)
    lw   $s2,  8($sp)
    lw   $s1, 12($sp)
    lw   $s0, 16($sp)
    lw   $ra, 20($sp)
    addi $sp, $sp, 24
    jr   $ra

bs_found:
    move $v0, $t4              # return the index
    jr   $ra

bs_notfound:
    li   $v0, -1
    jr   $ra
