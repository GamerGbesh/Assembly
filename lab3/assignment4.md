# Assignment 4 — Calculator with Function Library

MIPS assembly calculator providing basic arithmetic, advanced math, single-
precision trigonometry, an infix expression evaluator, a result history ring
buffer, and inline help.

---

## Overview

| Section    | Operations                                              |
| ---------- | ------------------------------------------------------- |
| Basic      | Add, Subtract, Multiply, Divide                         |
| Advanced   | Power a^n, Factorial n!, GCD(a,b)                       |
| Scientific | sin(x), cos(x) via 6-term Taylor series                 |
| Expression | Infix evaluator with correct precedence (Shunting-yard) |
| Utility    | History (last 5 results), Help                          |

---

## Interactive Menu

| Choice | Operation            |
| ------ | -------------------- |
| 1      | Add                  |
| 2      | Subtract             |
| 3      | Multiply             |
| 4      | Divide               |
| 5      | Power a^n            |
| 6      | Factorial n!         |
| 7      | GCD(a, b)            |
| 8      | Sin (radians, float) |
| 9      | Cos (radians, float) |
| 10     | Expression evaluator |
| 11     | History              |
| 12     | Help                 |
| 0      | Exit                 |

---

## Section 1 — Basic Operations

All four operations read two signed integers (`a`, `b`) and print the result.
Integer results are passed to `add_to_history`.

### Add (`do_add`)

Checks for overflow before reporting success:

- If `a` and `b` have **different signs**, overflow is impossible.
- If they share a sign and the result's sign **differs** from the inputs,
  32-bit overflow occurred.

### Subtract (`do_sub`)

Mirror of add overflow check:

- If inputs share a sign, subtraction is safe.
- If they differ in sign and result's sign differs from `a`, overflow occurred.

### Multiply (`do_mul`)

Uses `mult` to obtain the full 64-bit product in `HI:LO`. Overflow is detected
by comparing `HI` with the sign-extension of `LO`:

```mips
mult $s0, $s1
mflo $s2
mfhi $t0
sra  $t1, $s2, 31      # sign-extension of lower word
bne  $t0, $t1, mul_ovf # HI != sign-ext → overflow
```

### Divide (`do_div`)

Guards against division by zero (`beqz $s1, div_bz`) before executing `div`.
Returns the integer quotient (truncated toward zero) from `LO`.

---

## Section 2 — Advanced Operations

### Power (`do_power`)

Iterative a^n using repeated multiplication with overflow check per step.
By convention 0^0 = 1. Negative exponents are rejected with an error message.

Loop:

```
accumulator = 1
repeat n times:
    accumulator *= base
    check HI == sign-extension of LO
```

**Range:** Limited to what fits in a signed 32-bit integer.

### Factorial (`do_fact`)

Computes n! iteratively. Valid range: 0 ≤ n ≤ 12.

- 12! = 479 001 600 fits in a signed 32-bit word.
- 13! = 6 227 020 800 overflows — inputs > 12 are rejected.

### GCD (`do_gcd`)

Iterative Euclidean algorithm (no call counter — no recursion):

```
gcd(a, 0) = a
while b != 0:
    (a, b) = (b, a mod b)
```

Inputs are normalised to non-negative before the loop.

---

## Section 3 — Scientific Functions

Float input is read with syscall 6 (result in `$f0`). Results are printed with
syscall 2 (`$f12`). Float results are **not** stored in the integer history.

### `sin_approx`

6-term Taylor series:

```
sin(x) = x − x³/3! + x⁵/5! − x⁷/7! + x⁹/9! − x¹¹/11!
```

Iterative term generation avoids computing large factorials directly:

```
term₁ = x
termₖ = termₖ₋₁ × x² / dₖ    where dₖ = (2k)(2k+1)
d values: 6, 20, 42, 72, 110
```

|              | Register | Description          |
| ------------ | -------- | -------------------- |
| **Input**    | `$f12`   | x (radians)          |
| **Output**   | `$f0`    | sin(x) (approximate) |
| **Internal** | `$f2`    | x² (constant)        |
|              | `$f4`    | current term         |
|              | `$f6`    | divisor constant     |

**Leaf procedure** — no stack frame needed.

### `cos_approx`

6-term Taylor series:

```
cos(x) = 1 − x²/2! + x⁴/4! − x⁶/6! + x⁸/8! − x¹⁰/10!
```

Iterative term generation:

```
term₁ = 1
termₖ = termₖ₋₁ × x² / dₖ    where dₖ = (2k−1)(2k)
d values: 2, 12, 30, 56, 90
```

Same register layout as `sin_approx`. **Leaf procedure.**

---

## Section 4 — Expression Evaluator (`expr_eval`)

Evaluates infix integer expressions with correct operator precedence using the
**Shunting-yard algorithm** (Dijkstra, 1961).

**Supported operators:** `+` `-` `*` `/`
**Precedence:** `*` and `/` bind tighter than `+` and `-`
**Operands:** Multi-digit non-negative integers
**Spaces:** Optional between tokens

|            | Register | Description                                      |
| ---------- | -------- | ------------------------------------------------ |
| **Input**  | `$a0`    | Address of null-terminated expression string     |
| **Output** | `$v0`    | Integer result                                   |
|            | `$v1`    | 0 = success, 1 = error (message already printed) |

### Two-stack data structures (global, .data)

| Buffer    | Size                | Purpose                      |
| --------- | ------------------- | ---------------------------- |
| `val_stk` | 44 bytes (11 words) | Operand (value) stack        |
| `op_stk`  | 24 bytes            | Operator stack (ASCII bytes) |
| `val_top` | word                | Current depth of `val_stk`   |
| `op_top`  | word                | Current depth of `op_stk`    |

**Alignment:** `.align 2` precedes `val_stk` to ensure word-aligned `lw`/`sw`
accesses.

### Algorithm summary

1. **Digit sequence:** Parse full multi-digit integer, push onto `val_stk`.
2. **Operator:** Run shunting loop — while `op_stk` is non-empty and its top
   operator has precedence ≥ the incoming operator, pop and apply. Then push
   the incoming operator.
3. **End of input:** Flush remaining operators from `op_stk`, applying each.
4. **Result:** Pop the sole remaining value from `val_stk`.

**No `jal` calls** are made inside `expr_eval`; all stack operations are
inlined using `$t` registers — no stack frame is required.

### Register map (expr_eval)

| Register | Role                                    |
| -------- | --------------------------------------- |
| `$t9`    | Current character pointer               |
| `$t8`    | Saved current operator                  |
| `$t0`    | Current character / temp                |
| `$t1`    | Number accumulator / operand b          |
| `$t2`    | Comparison temp / effective address     |
| `$t3`    | Operand a / computed result             |
| `$t4`    | Stack base address                      |
| `$t5`    | Stack top index                         |
| `$t6`    | Precedence of current op / push address |
| `$t7`    | Precedence of stack-top op              |

### Error conditions

| Error              | Trigger                                                             |
| ------------------ | ------------------------------------------------------------------- |
| Division by zero   | Encountered during evaluation                                       |
| Invalid expression | Unknown character, or val_stk has < 2 entries when operator applied |

---

## Section 5 — History Ring Buffer

Stores the last 5 integer results in a circular buffer.

### Data layout

```
hist_buf:   .space 20    # 5 × 4 bytes (word-aligned via .align 2)
hist_cnt:   .word  0     # entries stored (0–5)
hist_wptr:  .word  0     # next-write slot index (0–4)
```

### `add_to_history`

|              | Register    | Description                        |
| ------------ | ----------- | ---------------------------------- |
| **Input**    | `$a0`       | Integer result to record           |
| **Modified** | `$t0`–`$t3` | Address calc, write pointer, count |

Writes `$a0` to `hist_buf[wptr]`, advances `wptr` modulo 5, increments
`hist_cnt` up to a ceiling of 5.

**Leaf procedure** — no stack frame needed.

### Display order (do_hist)

Oldest entry first. The start index is computed as:

```
oldest = (wptr − cnt + 5) mod 5
```

Walking forward from `oldest` with wrap-around prints entries in
chronological order.

---

## Overflow and Error Handling Summary

| Condition         | Detection method                | Message                                    |
| ----------------- | ------------------------------- | ------------------------------------------ |
| Add/Sub overflow  | XOR sign-bit test               | `"Error: arithmetic overflow"`             |
| Mul/Pow overflow  | `HI != sign-ext(LO)`            | `"Error: arithmetic overflow"`             |
| Division by zero  | `beqz` guard                    | `"Error: division by zero"`                |
| Negative exponent | `bltz` guard                    | `"Error: negative exponent not supported"` |
| Factorial n < 0   | `bltz` guard                    | `"Error: factorial requires n >= 0"`       |
| Factorial n > 12  | `bgt` guard                     | `"Error: n too large (max 12 for 32-bit)"` |
| Bad expression    | Stack depth < 2 or unknown char | `"Error: invalid expression"`              |

---

## Procedure Summary

| Procedure        | Type          | Frame | Called from                                                                        |
| ---------------- | ------------- | ----- | ---------------------------------------------------------------------------------- |
| `sin_approx`     | Leaf          | none  | `do_sin`                                                                           |
| `cos_approx`     | Leaf          | none  | `do_cos`                                                                           |
| `expr_eval`      | Leaf (no jal) | none  | `do_expr`                                                                          |
| `add_to_history` | Leaf          | none  | `do_add`, `do_sub`, `do_mul`, `do_div`, `do_power`, `do_fact`, `do_gcd`, `do_expr` |
