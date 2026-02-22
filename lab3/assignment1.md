# Assignment 1 — String Processing Library

MIPS assembly implementation of five classic C-string functions operating on
null-terminated ASCII strings.

---

## Procedures

### `strlen`

Counts the number of characters in a null-terminated string (not including
the terminating `\0`).

|              | Register     | Description           |
| ------------ | ------------ | --------------------- |
| **Input**    | `$a0`        | Address of string     |
| **Output**   | `$v0`        | Length (integer ≥ 0)  |
| **Modified** | `$t0`, `$t1` | Counter, current byte |

**Algorithm:** Walk byte-by-byte from `$a0` until `lb` returns 0, incrementing
a counter each step.

**Leaf procedure** — no stack frame needed.

**Example:**

```
strlen("Hello")  →  $v0 = 5
strlen("")        →  $v0 = 0
```

---

### `strcpy`

Copies a source string (including the null terminator) into a destination
buffer.

|              | Register | Description                |
| ------------ | -------- | -------------------------- |
| **Input**    | `$a0`    | Destination buffer address |
|              | `$a1`    | Source string address      |
| **Output**   | —        | (none)                     |
| **Modified** | `$t0`    | Current byte               |

**Algorithm:** Copy bytes one at a time until a `\0` byte is stored (the loop
test runs _after_ the store, so the null terminator is always written).

**Leaf procedure** — no stack frame needed.

**Note:** The destination buffer must be large enough to hold the source string
plus its null terminator.

---

### `strcmp`

Lexicographically compares two null-terminated strings.

|              | Register     | Description                                   |
| ------------ | ------------ | --------------------------------------------- |
| **Input**    | `$a0`        | Address of string 1                           |
|              | `$a1`        | Address of string 2                           |
| **Output**   | `$v0`        | `0` if equal, `-1` if s1 < s2, `1` if s1 > s2 |
| **Modified** | `$t0`, `$t1` | Bytes from s1, s2                             |

**Algorithm:** Compare corresponding bytes in a loop. On the first mismatch,
return `1` or `-1` based on which byte is larger. If both bytes reach `\0`
simultaneously, the strings are equal and `0` is returned.

**Leaf procedure** — no stack frame needed.

**Example:**

```
strcmp("Hello", "World")  →  $v0 = -1   ('H' < 'W')
strcmp("World", "Hello")  →  $v0 =  1
strcmp("Hello", "Hello")  →  $v0 =  0
```

---

### `strcat`

Appends a source string to the end of a destination string (in-place).

|              | Register | Description                |
| ------------ | -------- | -------------------------- |
| **Input**    | `$a0`    | Destination string address |
|              | `$a1`    | Source string address      |
| **Output**   | —        | (none)                     |
| **Modified** | `$t0`    | Current byte               |

**Algorithm:**

1. Advance `$a0` past the existing null terminator (`find_end` loop).
2. Copy bytes from `$a1` to the new end of `$a0` until `\0` is stored
   (`strcat_loop`).

**Leaf procedure** — no stack frame needed.

**Note:** The destination buffer must have capacity for its original content
plus the appended source plus one null byte.

---

### `str_reverse`

Reverses a string in-place using a two-pointer swap from both ends.

|              | Register    | Description         |
| ------------ | ----------- | ------------------- |
| **Input**    | `$a0`       | Address of string   |
| **Output**   | —           | (none)              |
| **Modified** | `$t0`–`$t5` | Various temporaries |

**Algorithm:**

1. Call `strlen` to find the length → store in `$t0`.
2. Set `$t1 = 0` (left index), `$t2 = length - 1` (right index).
3. While `$t1 < $t2`: swap `str[$t1]` and `str[$t2]`, advance `$t1`, retreat
   `$t2`.

**Non-leaf procedure** — calls `strlen`, so needs a stack frame.

**Stack frame (4 bytes):**

```
0($sp)  saved $ra
```

**Example:**

```
str_reverse("HelloWorld")  →  "dlroWolleH"
```

---

## Stack Frame Summary

| Procedure     | Frame size  | Saves |
| ------------- | ----------- | ----- |
| `strlen`      | none (leaf) | —     |
| `strcpy`      | none (leaf) | —     |
| `strcmp`      | none (leaf) | —     |
| `strcat`      | none (leaf) | —     |
| `str_reverse` | 4 bytes     | `$ra` |

---

## Test Program (main)

The `main` routine exercises all five procedures in sequence using:

- `str1 = "Hello"` and `str2 = "World"` (read-only source strings)
- `buffer1` and `buffer2` (100-byte writable work buffers)

Execution order:

1. `strlen(str1)` → prints `5`
2. `strcpy(buffer1, str1)` → prints `Hello`
3. `strcmp(str1, str2)` → prints `-1`
4. `strcat(buffer1, str2)` → prints `HelloWorld`
5. `str_reverse(buffer1)` → prints `dlroWolleH`
