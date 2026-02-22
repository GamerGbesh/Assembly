# Assignment 3 — Star Pattern Printer

Menu-driven program that prints one of five ASCII star patterns. The user
selects a pattern (1–5) and supplies a row count N (1–20). Both inputs are
validated; invalid values print an error and return to the menu.

---

## Menu

| Choice | Pattern                                           |
| ------ | ------------------------------------------------- |
| 1      | Right-Angled Triangle                             |
| 2      | Isosceles Triangle                                |
| 3      | Diamond Pattern                                   |
| 4      | Hollow Square                                     |
| 5      | Pascal's Triangle _(placeholder — prints all 1s)_ |
| −1     | Exit                                              |

---

## Input Validation

| Input       | Valid range | Error message                |
| ----------- | ----------- | ---------------------------- |
| Menu choice | 1–5 or −1   | `"Invalid Choice"`           |
| Row count N | 1–20        | `"Invalid size. Enter 1-20"` |

Both errors jump back to `menu_loop` without printing a pattern.

---

## Patterns

### 1 — Right-Angled Triangle

Row `i` (1-based, 1 ≤ i ≤ N) contains exactly `i` stars.

```
N = 4:
*
**
***
****
```

**Registers:** `$t1` = outer row counter i, `$t2` = inner star counter j

**Loops:**

- `outer_rt`: i from 1 to N
- `inner_rt`: j from 1 to i, prints one star per iteration

---

### 2 — Isosceles Triangle

Row `i` has `(N − i)` leading spaces followed by `(2i − 1)` stars.

```
N = 4:
   *
  ***
 *****
*******
```

**Key computation:**

```mips
sub $t5, $t4, $t1      # spaces = N - i
mul $t6, $t1, 2
addi $t6, $t6, -1      # stars = 2*i - 1
```

**Registers:** `$t5` = space count, `$t6` = star count, `$t2` = sub-counter

---

### 3 — Diamond Pattern

Upper half: identical to the isosceles triangle (rows 1 → N).
Lower half: mirror — row `i` counts down from `N−1` to `1`.

```
N = 4:
   *       ← upper half row 1
  ***
 *****
*******    ← upper half row N (widest)
 *****     ← lower half row N-1
  ***
   *       ← lower half row 1
```

Uses the same space/star formula for both halves:

- spaces = `N − i` (both halves use current i)
- stars = `2i − 1`

Lower half loop decrements `$t1` (`addi $t1, $t1, -1`) and terminates
when `$t1 == 0` (`blez $t1, menu_loop`).

---

### 4 — Hollow Square

N×N grid. A cell at row `i`, column `j` is a star if it is on the border
(first/last row or first/last column); otherwise a space.

```
N = 5:
*****
*   *
*   *
*   *
*****
```

**Border conditions (checked in order):**

```mips
beq $t1, 1,   print_star_h   # top row
beq $t1, $t4, print_star_h   # bottom row
beq $t2, 1,   print_star_h   # left column
beq $t2, $t4, print_star_h   # right column
# else: space
```

**Registers:** `$t1` = row i, `$t2` = column j, `$t4` = N

---

### 5 — Pascal's Triangle _(placeholder)_

Intended to print Pascal's triangle row values (binomial coefficients).
**Current implementation prints `1` for every entry.**

Row `i` (0-based) prints `i + 1` values separated by spaces.

```
N = 4  (placeholder output):
1
1 1
1 1 1
1 1 1 1
```

The actual binomial coefficients are not computed. This is noted in the
source as a placeholder.

---

## Register Usage (main dispatch)

| Register | Role                               |
| -------- | ---------------------------------- |
| `$t0`    | Menu choice                        |
| `$t4`    | Row count N                        |
| `$t1`    | Outer loop counter i               |
| `$t2`    | Inner loop counter j / sub-counter |
| `$t5`    | Space count (patterns 2, 3)        |
| `$t6`    | Star count (patterns 2, 3)         |
| `$t9`    | Constant −1 (exit sentinel)        |

---

## Control Flow

```
menu_loop:
  print menu, read choice ($t0)
  if choice == -1 → end_program
  validate choice (1-5)
  read N ($t4), validate (1-20)
  dispatch via beq chain → pattern labels
  (each pattern ends with j menu_loop)
```

All patterns return to `menu_loop` via an unconditional jump — there are no
`jal`/`jr` calls for the pattern drawing code.
