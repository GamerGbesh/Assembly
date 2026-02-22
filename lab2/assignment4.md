# Assignment 4 — Grade Book

Grade-book program for **10 students** each with **5 subject scores** (50
scores total). All scores are entered interactively, stored in a flat array,
then the program computes and prints per-student averages and letter grades,
the class average, the highest- and lowest-averaging student, and the overall
grade distribution.

---

## Data Layout

```
array:  .space 200    # 10 students × 5 subjects × 4 bytes = 200 bytes
```

Scores are stored in row-major order: `array[student * 5 + subject]`.
A flat index `$a1` / `$a2` running from 0 to 49 is used to address elements
as `base + index * 4`.

---

## Grade Thresholds

| Grade | Condition    |
| ----- | ------------ |
| A     | average ≥ 90 |
| B     | average ≥ 80 |
| C     | average ≥ 70 |
| D     | average ≥ 60 |
| F     | average < 60 |

---

## Program Phases

### Phase 1 — Input

**Loops:** `input_loop` / `change_student` / `end_input`

Outer counter `$t0` iterates students 1–10; inner counter `$t1` iterates
subjects 1–5. Each iteration calls `enter_input` via `jal`.

After subject 5, `$t1` overflows to 6 → `change_student` increments `$t0`
and resets `$t1` to 1.

The current flat index `$a1` is incremented after every call and passed to
`enter_input` to determine where to store the score.

**Running sum:** `$s1` accumulates the total of all 50 scores during input
for use in the class-average calculation.

---

### Phase 2 — Student Averages

**Loop:** `student_averages`

Calls `per_student_avg` once per student (`$a1` = 1–10). `$a2` is a shared
flat-index pointer that starts at 0 and is advanced by 5 inside each call —
it is **not reset** between calls, so each call reads the next block of 5
scores.

`per_student_avg` also updates the min/max tracking registers (`$s2`–`$s5`).

---

### Phase 3 — Class Average

```mips
div $t1, $s1, 50    # integer division
```

Prints the result directly without storing it.

---

### Phase 4 — Highest / Lowest Student

Prints the student numbers stored in `$s3` (highest average) and `$s2`
(lowest average).

---

### Phase 5 — Grade Distribution

Prints the count of each letter grade across all 10 students.

**Note:** The source code prints the `A_count` label and value **twice** at
the end of the distribution section. This appears to be a duplicate and can
be ignored.

---

## Functions

### `enter_input`

Prompt format: `"Enter score for student X subject Y: "`

|                 | Register | Description                        |
| --------------- | -------- | ---------------------------------- |
| **Input**       | `$t0`    | Student number (1–10)              |
|                 | `$t1`    | Subject number (1–5)               |
|                 | `$a1`    | Flat array index (0–49)            |
|                 | `$s0`    | Array base address                 |
| **Side effect** | `$s1`    | Running total incremented by score |

Computes byte address as `$s0 + $a1 * 4`, stores the score, then adds it to
`$s1`.

**Leaf procedure** — no stack frame.

---

### `per_student_avg`

Reads 5 consecutive scores for one student (loop unrolled × 5), computes
the integer average, prints it, then assigns and prints the letter grade.
Also updates min/max tracking.

|              | Register | Description                                  |
| ------------ | -------- | -------------------------------------------- |
| **Input**    | `$a1`    | Student number (1–10)                        |
|              | `$a2`    | Flat index of first score for this student   |
| **Modified** | `$a2`    | Advanced by 5 (past this student's 5 scores) |
|              | `$t3`    | Sum of 5 scores                              |
|              | `$t4`    | Student average (sum / 5)                    |

**Min/max update flow:**

```
if $t4 < $s4 → update_min → check_max
if $t4 > $s5 → update_max → grade
              ↓
           grade (assign letter grade)
```

`update_min` sets `$s4 = $t4` and `$s2 = $a1`, then falls through to
`check_max`.

`update_max` sets `$s5 = $t4` and `$s3 = $a1`, then falls through to
`grade`.

Grade labels (`A_grade`–`F_grade`) each print the grade string, increment
their counter, and return via `jr $ra`.

**Leaf procedure** — no stack frame.

---

## Global Register Map

| Register | Role                                            |
| -------- | ----------------------------------------------- |
| `$t0`    | Student counter (input phase)                   |
| `$t1`    | Subject counter (input phase) / class average   |
| `$s0`    | Base address of `array`                         |
| `$a1`    | Flat index (input) / student number (avg phase) |
| `$a2`    | Flat index (avg phase, shared across calls)     |
| `$s1`    | Sum of all 50 scores                            |
| `$s2`    | Student number with lowest average              |
| `$s3`    | Student number with highest average             |
| `$s4`    | Lowest average seen (initialised to 100)        |
| `$s5`    | Highest average seen (initialised to 0)         |
| `$s6`    | Count of A grades                               |
| `$s7`    | Count of B grades                               |
| `$t7`    | Count of C grades                               |
| `$t8`    | Count of D grades                               |
| `$t9`    | Count of F grades                               |

---

## Sample Output (abbreviated)

```
Enter score for student 1 subject 1: ...
...
Ended the input
Average of student 1: 85
Grade: B
Average of student 2: 92
Grade: A
...
Class average: 78
Highest student is student 2
Lowest student is student 7
Count of As: 2
Count of Bs: 4
Count of Cs: 3
Count of Ds: 1
Count of Fs: 0
```
