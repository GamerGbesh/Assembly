# Assignment 1 — Integer Properties Checker

Reads a single integer from the user and reports five properties:
parity, sign, divisibility, perfect-square status, and primality.

---

## Program Flow

```
Read integer n
  ├─ Parity check       → Even / Odd
  ├─ Sign check         → Positive / Negative / Zero
  ├─ Divisibility       → Divisible by 3 / 5 / 7  (each independent)
  ├─ Perfect square     → binary search over [0, n]
  └─ Prime check        → trial division
```

All five checks run sequentially on the same input; the program then exits.

---

## Checks

### Parity

```
n % 2 == 0  →  "Parity: Even"
n % 2 != 0  →  "Parity: Odd"
```

Uses the `rem` pseudo-instruction. Branches to `odd` on non-zero remainder,
falls through to even otherwise.

**Register:** `$t1` = n % 2

---

### Sign

```
n == 0  →  "Sign: Zero"
n < 0   →  "Sign: Negative"
n > 0   →  "Sign: Positive"   (fall-through)
```

Checked with `beqz` then `bltz`.

---

### Divisibility by 3, 5, and 7

Each check is independent — the number may print all three, some, or none.

```
n % 3 == 0  →  "Divisible by 3"
n % 5 == 0  →  "Divisible by 5"
n % 7 == 0  →  "Divisible by 7"
```

Each uses `rem` and `bnez` to skip the print on non-zero remainder.
The three checks are chained by label fall-through (`check_five`,
`check_seven`).

**Helper used:** `print_str` (see below) is called via `jal` for each message.

---

### Perfect Square

**Algorithm:** Binary search for an integer m such that m² = n.

```
if n < 0:  not a square
lo = 0,  hi = n
while lo <= hi:
    mid = (lo + hi) / 2
    if mid² == n:  perfect square
    if mid² < n:   lo = mid + 1
    else:          hi = mid - 1
not a square
```

**Key instructions:**

- `addu $t3, $t1, $t2` — unsigned add to avoid overflow on the sum before
  shifting (ensures correct positive midpoint when both bounds are large).
- `srl $t3, $t3, 1` — logical right shift by 1 = divide by 2.
- `mul $t4, $t3, $t3` — mid².

**Registers:**
| Register | Role |
|---|---|
| `$t1` | lo (left bound) |
| `$t2` | hi (right bound) |
| `$t3` | mid |
| `$t4` | mid² |

Negative numbers skip directly to `not_square`.

---

### Prime Check

**Algorithm:** Optimised trial division.

```
n <= 1        →  composite
n == 2        →  prime
n even        →  composite
i = 3, 5, 7, …  (odd divisors only):
    if i*i > n:    prime
    if n % i == 0: composite
    i += 2
```

**Registers:**
| Register | Role |
|---|---|
| `$t2` | trial divisor i (starts at 3, increments by 2) |
| `$t3` | i² |
| `$t4` | n % i |

The `bgt $t3, $t0, prime` check stops as soon as i² > n, guaranteeing
O(√n) iterations.

---

## Helper Procedure: `print_str`

A minimal leaf wrapper around syscall 4.

|            | Register | Description                       |
| ---------- | -------- | --------------------------------- |
| **Input**  | `$a0`    | Address of null-terminated string |
| **Output** | —        | (none)                            |

```mips
print_str:
    li  $v0, 4
    syscall
    jr  $ra
```

Saves three lines per call site at the cost of one `jal`/`jr` pair.
All callers pass the string address in `$a0` immediately before the `jal`.

No stack frame — leaf procedure.

---

## Register Map (main)

| Register | Role                             |
| -------- | -------------------------------- |
| `$t0`    | Input n (preserved throughout)   |
| `$t1`    | Remainder / loop left bound      |
| `$t2`    | Loop right bound / trial divisor |
| `$t3`    | Binary-search midpoint / i²      |
| `$t4`    | mid² / n % i                     |
| `$t5`    | (unused in main)                 |

---

## Sample Output

Input: `36`

```
Parity: Even
Sign: Positive
Divisible by 3
Perfect Square
Composite Number
```

Input: `7`

```
Parity: Odd
Sign: Positive
Divisible by 7
Not a perfect square
Prime Number
```

Input: `0`

```
Parity: Even
Sign: Zero
Divisible by 3
Divisible by 5
Divisible by 7
Perfect Square
Composite Number
```
