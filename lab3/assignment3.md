# Assignment 3 — Recursive Algorithm Suite

MIPS assembly implementation of six recursive (and one iterative counterpart)
algorithms, each instrumented with a global call counter.

---

## Overview

| #   | Algorithm      | Type                     | Counter       |
| --- | -------------- | ------------------------ | ------------- |
| 1   | Fibonacci      | Recursive                | `fib_calls`   |
| 2   | Fibonacci      | Iterative                | —             |
| 3   | GCD            | Euclidean recursive      | `gcd_calls`   |
| 4   | Power x^n      | Recursive                | `pow_calls`   |
| 5   | Tower of Hanoi | Recursive (prints moves) | `hanoi_calls` |
| 6   | Binary Search  | Recursive                | `bs_calls`    |

---

## Call Counter Convention

Every recursive procedure increments its dedicated `.word` counter as its
very first instruction:

```mips
fib_rec:
    lw   $t0, fib_calls
    addi $t0, $t0, 1
    sw   $t0, fib_calls
    # ... rest of procedure
```

The menu handler resets the counter to 0 immediately before calling the
top-level function, then prints the count after it returns.

---

## Stack Frame Convention

All non-leaf recursive procedures use callee-saved registers:

- Allocate frame on `$sp` (subtract before first use).
- Save `$ra` at the **highest** word in the frame.
- Save each `$s` register used below `$ra`.
- Restore in **reverse** order before `jr $ra`.

Base-case returns that make no further `jal` are leaves and need no frame.

---

## Procedures

### `fib_rec` — Fibonacci (recursive)

**Recurrence:**

```
fib(0) = 0
fib(1) = 1
fib(n) = fib(n-1) + fib(n-2)
```

|            | Register | Description |
| ---------- | -------- | ----------- |
| **Input**  | `$a0`    | n (≥ 0)     |
| **Output** | `$v0`    | fib(n)      |

**Stack frame (12 bytes)** — allocated only for n ≥ 2:

```
8($sp)  saved $ra
4($sp)  saved $s0   (n — needed to compute n-2 after first call)
0($sp)  saved $s1   (fib(n-1) — needed for addition after second call)
```

**Call count:** 2·fib(n+1) − 1 (e.g. fib(5) → 15 calls)

**Example trace — fib(5):**

```
fib(5)
 ├─ fib(4)
 │   ├─ fib(3)
 │   │   ├─ fib(2)
 │   │   │   ├─ fib(1) = 1
 │   │   │   └─ fib(0) = 0  → fib(2) = 1
 │   │   └─ fib(1) = 1     → fib(3) = 2
 │   └─ fib(2) = 1         → fib(4) = 3
 └─ fib(3) = 2             → fib(5) = 5
Total calls: 15
```

---

### `fib_iter` — Fibonacci (iterative)

**Algorithm:** Sliding-window with three registers (`prev2`, `prev1`, `curr`).
O(n) time, O(1) space.

|            | Register | Description |
| ---------- | -------- | ----------- |
| **Input**  | `$a0`    | n (≥ 0)     |
| **Output** | `$v0`    | fib(n)      |

**Leaf procedure** — no stack frame, no call counter.

Handles base cases fib(0) and fib(1) directly; for n ≥ 2 iterates from i=2
to n, shifting the window each step.

---

### `gcd_rec` — GCD (Euclidean recursive)

**Recurrence:**

```
gcd(a, 0) = a
gcd(a, b) = gcd(b, a mod b)
```

|            | Register | Description      |
| ---------- | -------- | ---------------- |
| **Input**  | `$a0`    | a (non-negative) |
|            | `$a1`    | b (non-negative) |
| **Output** | `$v0`    | gcd(a, b)        |

Inputs are normalised to non-negative before the top-level call.

**Stack frame (8 bytes)** — allocated only when b ≠ 0:

```
4($sp)  saved $ra
0($sp)  saved $s0   (b — becomes new a in the recursive call)
```

**Example trace — gcd(48, 18):**

```
gcd(48, 18)  →  48 mod 18 = 12
gcd(18, 12)  →  18 mod 12 =  6
gcd(12,  6)  →  12 mod  6 =  0
gcd( 6,  0)  →  returns 6
Total calls: 4
```

---

### `pow_rec` — Power x^n (recursive)

**Recurrence:**

```
pow(x, 0) = 1
pow(x, n) = x × pow(x, n-1)
```

|            | Register | Description           |
| ---------- | -------- | --------------------- |
| **Input**  | `$a0`    | x (base, any integer) |
|            | `$a1`    | n (exponent, ≥ 0)     |
| **Output** | `$v0`    | xⁿ                    |

**Stack frame (12 bytes)** — allocated only when n > 0:

```
8($sp)  saved $ra
4($sp)  saved $s0   (x — must survive recursive call for final multiply)
0($sp)  saved $s1   (n — kept for documentation)
```

**Call count:** n + 1 (e.g. pow(2, 4) → 5 calls)

**Example trace — pow(2, 4):**

```
pow(2,4) = 2 × pow(2,3)
pow(2,3) = 2 × pow(2,2)
pow(2,2) = 2 × pow(2,1)
pow(2,1) = 2 × pow(2,0)
pow(2,0) = 1              ← base case
Total calls: 5
```

---

### `hanoi_rec` — Tower of Hanoi

**Recurrence:**

```
hanoi(1, src, dst, aux):
    print "Move disk 1 from src to dst"
hanoi(n, src, dst, aux):
    hanoi(n-1, src, aux, dst)   ← top n-1 disks out of the way
    print "Move disk n from src to dst"
    hanoi(n-1, aux, dst, src)   ← settle n-1 on top
```

Pegs are passed as ASCII character codes: `'A'`=65, `'B'`=66, `'C'`=67.
The procedure prints each move directly using syscall 11 (print char) and
syscall 1 (print int).

|            | Register | Description                      |
| ---------- | -------- | -------------------------------- |
| **Input**  | `$a0`    | n (disk count, 1–15)             |
|            | `$a1`    | src peg (ASCII)                  |
|            | `$a2`    | dst peg (ASCII)                  |
|            | `$a3`    | aux peg (ASCII)                  |
| **Output** | —        | (none; moves printed to console) |

**Stack frame (20 bytes)** — allocated only when n > 1:

```
16($sp)  saved $ra
12($sp)  saved $s0   (n)
 8($sp)  saved $s1   (src)
 4($sp)  saved $s2   (dst)
 0($sp)  saved $s3   (aux)
```

**Base case (n = 1):** Saves src/dst into `$t1`/`$t2` before any syscalls
to prevent `$a0` clobbering; no stack frame allocated.

**Call count:** 2ⁿ − 1 (e.g. Hanoi(3) → 7 calls)

**Example trace — hanoi(3, A, C, B):**

```
Move disk 1 from peg A to peg C
Move disk 2 from peg A to peg B
Move disk 1 from peg C to peg B
Move disk 3 from peg A to peg C
Move disk 1 from peg B to peg A
Move disk 2 from peg B to peg C
Move disk 1 from peg A to peg C
Total calls: 7
```

**Input validation:** n must be 1–15 (n=0 and n>15 both print an error).

---

### `bsearch_rec` — Binary Search (recursive)

**Recurrence:**

```
bsearch(arr, key, lo, hi):
    if lo > hi:           return -1       ← not found
    mid = (lo + hi) / 2
    if arr[mid] == key:   return mid      ← leaf return
    if arr[mid] <  key:   return bsearch(arr, key, mid+1, hi)
    else:                 return bsearch(arr, key, lo, mid-1)
```

|            | Register | Description                                |
| ---------- | -------- | ------------------------------------------ |
| **Input**  | `$a0`    | Base address of sorted word array          |
|            | `$a1`    | Search key                                 |
|            | `$a2`    | lo index (inclusive)                       |
|            | `$a3`    | hi index (inclusive)                       |
| **Output** | `$v0`    | Index of key (0-based), or −1 if not found |

**Stack frame (24 bytes)** — allocated only when recursion is needed (i.e.
the element at mid is not the key):

```
20($sp)  saved $ra
16($sp)  saved $s0   (array base address)
12($sp)  saved $s1   (key)
 8($sp)  saved $s2   (lo)
 4($sp)  saved $s3   (hi)
 0($sp)  saved $s4   (mid — saved before $t4 may be reused)
```

**Predefined array:** `[2 5 8 12 16 23 38 42 56 72]` (indices 0–9)

**Example trace — search for 23:**

```
call 1: lo=0  hi=9  mid=4  arr[4]=16 < 23  → right
call 2: lo=5  hi=9  mid=7  arr[7]=42 > 23  → left
call 3: lo=5  hi=6  mid=5  arr[5]=23 == 23 → found at index 5
Total calls: 3
```

---

## Stack Frame Summary

| Procedure     | Frame size  | Saved registers     |
| ------------- | ----------- | ------------------- |
| `fib_rec`     | 12 bytes    | `$ra`, `$s0`, `$s1` |
| `fib_iter`    | none (leaf) | —                   |
| `gcd_rec`     | 8 bytes     | `$ra`, `$s0`        |
| `pow_rec`     | 12 bytes    | `$ra`, `$s0`, `$s1` |
| `hanoi_rec`   | 20 bytes    | `$ra`, `$s0`–`$s3`  |
| `bsearch_rec` | 24 bytes    | `$ra`, `$s0`–`$s4`  |

---

## Interactive Menu

The `main` routine runs a persistent menu loop:

| Choice | Algorithm             | Inputs prompted |
| ------ | --------------------- | --------------- |
| 1      | Fibonacci (recursive) | n               |
| 2      | Fibonacci (iterative) | n               |
| 3      | GCD                   | a, b            |
| 4      | Power x^n             | x, n            |
| 5      | Tower of Hanoi        | n (1–15)        |
| 6      | Binary Search         | key             |
| 0      | Exit                  | —               |

After each recursive operation, the program prints both the result and the
total call count. The iterative Fibonacci prints only the result (no counter).
