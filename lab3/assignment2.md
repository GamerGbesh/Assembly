# Assignment 2 — 3×3 Matrix Operations Library

MIPS assembly implementation of five matrix operations on 3×3 integer matrices
stored in row-major order as flat arrays of 9 words (36 bytes each).

---

## Memory Layout

Each matrix is a contiguous 36-byte region (`.space 36`). Elements are stored
in row-major order:

```
Index:  0  1  2  3  4  5  6  7  8
        ┌─────────────────────────┐
Row 0:  │ [0,0] [0,1] [0,2] │
Row 1:  │ [1,0] [1,1] [1,2] │
Row 2:  │ [2,0] [2,1] [2,2] │
        └─────────────────────────┘
```

Element `M[i][j]` is at byte offset `(i*3 + j) * 4` from the base address.

---

## Procedures

### `matrix_input`

Reads 9 integers from the user (via syscall 5) and stores them into a matrix
in row-major order.

|              | Register     | Description                        |
| ------------ | ------------ | ---------------------------------- |
| **Input**    | `$a0`        | Base address of destination matrix |
| **Output**   | —            | (none)                             |
| **Modified** | `$t0`, `$t1` | Loop counter, element address      |

**Algorithm:** Loop `i` from 0 to 8; for each iteration read an integer and
store it at `base + i*4`.

**Leaf procedure** — no stack frame needed.

---

### `matrix_print`

Prints all 9 elements of a matrix, inserting a newline after every third
element (end of each row).

|              | Register    | Description            |
| ------------ | ----------- | ---------------------- |
| **Input**    | `$a0`       | Base address of matrix |
| **Output**   | —           | (none)                 |
| **Modified** | `$t0`–`$t5` | Various temporaries    |

**Algorithm:** Loop `i` from 0 to 8; print `matrix[i]` followed by a space.
After every element where `(i+1) mod 3 == 0` print a newline.

**Important:** `$a0` is saved into `$t5` at the start because syscalls
overwrite `$a0` — using `$t5` as the base pointer throughout the loop prevents
the array base from being lost.

**Leaf procedure** — no stack frame needed.

---

### `matrix_add`

Computes element-wise sum `C = A + B`.

|              | Register    | Description                           |
| ------------ | ----------- | ------------------------------------- |
| **Input**    | `$a0`       | Base address of matrix A              |
|              | `$a1`       | Base address of matrix B              |
|              | `$a2`       | Base address of result matrix C       |
| **Output**   | —           | (none; result written to C)           |
| **Modified** | `$t0`–`$t5` | Loop index, offsets, operands, result |

**Algorithm:** For `i` in 0–8: `C[i] = A[i] + B[i]`, computing the word address
as `base + i*4` for each matrix.

**Leaf procedure** — no stack frame needed.

---

### `matrix_multiply`

Computes the matrix product `C = A × B` using the standard O(n³) algorithm.

|              | Register    | Description                             |
| ------------ | ----------- | --------------------------------------- |
| **Input**    | `$a0`       | Base address of matrix A                |
|              | `$a1`       | Base address of matrix B                |
|              | `$a2`       | Base address of result matrix C         |
| **Output**   | —           | (none; result written to C)             |
| **Modified** | `$t0`–`$t8` | Loop indices i/j/k, addresses, operands |

**Algorithm:** Three nested loops over `i`, `j`, `k` (each 0–2):

```
C[i][j] = Σ_{k=0}^{2}  A[i][k] × B[k][j]
```

Element addresses:

- `A[i][k]` at `$a0 + (i*3 + k)*4`
- `B[k][j]` at `$a1 + (k*3 + j)*4`
- `C[i][j]` at `$a2 + (i*3 + j)*4`

**Non-leaf procedure** — saves `$ra` on the stack (though no `jal` is made
inside; the frame guards against being extended in future revisions).

**Stack frame (4 bytes):**

```
0($sp)  saved $ra
```

---

### `matrix_transpose`

Computes the transpose `C = Aᵀ` (does not modify A in-place; writes to a
separate result buffer).

|              | Register    | Description                     |
| ------------ | ----------- | ------------------------------- |
| **Input**    | `$a0`       | Base address of source matrix A |
|              | `$a1`       | Base address of result matrix C |
| **Output**   | —           | (none; result written to C)     |
| **Modified** | `$t0`–`$t4` | Loop indices, addresses, value  |

**Algorithm:** Two nested loops over `i`, `j` (each 0–2):

```
C[j][i] = A[i][j]
```

**Leaf procedure** — no stack frame needed.

---

## Stack Frame Summary

| Procedure          | Frame size  | Saves |
| ------------------ | ----------- | ----- |
| `matrix_input`     | none (leaf) | —     |
| `matrix_print`     | none (leaf) | —     |
| `matrix_add`       | none (leaf) | —     |
| `matrix_multiply`  | 4 bytes     | `$ra` |
| `matrix_transpose` | none (leaf) | —     |

---

## Interactive Menu

The `main` routine runs a persistent menu loop:

| Choice | Action             |
| ------ | ------------------ |
| 1      | Input matrix A     |
| 2      | Input matrix B     |
| 3      | Print matrix A     |
| 4      | Print matrix B     |
| 5      | C = A + B, print C |
| 6      | C = A × B, print C |
| 7      | C = Aᵀ, print C    |
| 8      | Exit               |

Global matrices: `matrixA`, `matrixB`, `matrixC` (each 36 bytes / 9 words).
