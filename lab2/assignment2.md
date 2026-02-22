# Assignment 2 — Array Statistics

Reads up to 20 integers from the user into an array, then computes and prints
eight statistics: count, sum, average, minimum, maximum, range, positive count,
and negative count.

Input is terminated by the sentinel value **−9999** or when the array is full
(20 elements).

---

## Program Flow

```
Input Phase
  └─ Prompt repeatedly until -9999 or 20 entries stored

Statistics Phase
  └─ Single pass over the array accumulates all values
     ├─ sum
     ├─ min  (seeded from first element)
     ├─ max  (seeded from first element)
     ├─ positive count
     └─ negative count

Derived values
  ├─ average = sum / count  (integer, truncated)
  └─ range   = max - min

Print Results
```

If no numbers were entered before the sentinel, a `"No numbers entered."` message
is printed and the program exits without computing statistics.

---

## Data Layout

```
array:  .space 80    # 20 × 4 bytes, row-order flat array
```

The array is accessed via a running pointer `$s0` that starts at `array` and
advances by 4 bytes per store/load.

---

## Input Phase

**Loop:** `input_loop` / `input_done`

|       | Register                                          | Description |
| ----- | ------------------------------------------------- | ----------- |
| `$s0` | Write pointer into `array` (starts at array base) |
| `$s1` | Element count (0 → up to 20)                      |
| `$t7` | Sentinel constant −9999                           |

Termination conditions (checked in order):

1. User enters −9999 (`beq $v0, $t7, input_done`)
2. Count reaches 20 (`beq $s1, 20, input_done`)

Each accepted value is stored with `sw` at the current pointer, then the
pointer and count are both incremented.

---

## Statistics Phase

**Loop:** `process_loop` / `processing_done`

The loop index `$t1` runs from 0 to `count − 1`. The array pointer `$s0` is
reset to the base address before the loop begins. The first element is loaded
before the loop to seed `min` and `max`.

| Register | Role                            |
| -------- | ------------------------------- |
| `$s2`    | min (seeded from first element) |
| `$s3`    | max (seeded from first element) |
| `$s4`    | sum (starts at 0)               |
| `$s5`    | positive count                  |
| `$s6`    | negative count                  |
| `$t0`    | current element                 |
| `$t1`    | loop index                      |

Per-element actions:

1. `sum += value`
2. Sign classification: `bgt` → positive++, `blt` → negative++, equal zero → skip
3. Min/max update: replace `$s2`/`$s3` if a new extreme is found

---

## Derived Statistics

After the loop:

```mips
div  $s4, $s1          # integer division: sum / count → LO
mflo $s7               # $s7 = average
sub  $t2, $s3, $s2     # $t2 = range = max - min
```

---

## Output

Eight values printed in order:

| Label          | Register                  |
| -------------- | ------------------------- |
| Count          | `$s1`                     |
| Sum            | `$s4`                     |
| Average        | `$s7` (truncated integer) |
| Minimum        | `$s2`                     |
| Maximum        | `$s3`                     |
| Range          | `$t2`                     |
| Positive count | `$s5`                     |
| Negative count | `$s6`                     |

---

## Edge Cases

| Condition            | Behaviour                                         |
| -------------------- | ------------------------------------------------- |
| First input is −9999 | Prints "No numbers entered." and exits            |
| All values identical | min == max, range == 0                            |
| All values zero      | positive count = 0, negative count = 0            |
| 20 values entered    | Array full; further input silently ignored        |
| Negative inputs      | min may be negative; negative count reflects them |

---

## Sample Output

Input: `10 -3 7 0 -9999`

```
Count: 4
Sum: 14
Average: 3
Minimum: -3
Maximum: 10
Range: 13
Positive count: 2
Negative count: 1
```
