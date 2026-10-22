# Phase 3: Reverse Engineering

This repository documents my work for Phase 3 of the Cyber Security Researcher track. It covers static decompilation with Ghidra, dynamic debugging with GDB, System V ABI calling convention verification, automated reproduction scripts, and CTF challenge writeups.

---

## Lab Exercises: Reversing Stripped Binaries

### Exercise 1: Finding `main` & Static Analysis (`crackme`)

When analyzing closed-source binaries, debugging symbols are stripped. I compiled a C reference program without debug symbols and stripped it to simulate a realistic target:

```bash
gcc -O0 -no-pie -o crackme crackme.c
strip crackme
```

#### Static Analysis (Ghidra)
Running `file crackme` confirms the binary is a stripped 64-bit ELF executable. Running `strings crackme` reveals literals like `"Password:"` and `"Correct. Flag: ..."`.

To locate `main` in Ghidra without symbol tables:
1. Navigated to the ELF entry point (`entry` at `0x004010d0`).
2. According to System V x86-64 calling conventions, `entry` passes the address of `main` as the first argument (`RDI`) to `__libc_start_main`.
3. In Ghidra, `RDI` points to `FUN_004011b6`, which represents the actual `main` logic.

Decompiled pseudocode in Ghidra:
```c
builtin_strncpy(local_60, "entrypt", 8);
printf("Password: ");
__isoc23_scanf("%63s", local_60 + 8);

if (strcmp(local_60 + 8, local_60) == 0) {
    puts("Correct. Flag: entrypoint{re_basics}");
}
```

#### Dynamic Verification (`strcmp`)
To verify string comparison at runtime:
1. Set an instruction-specific breakpoint right before `strcmp`: `break *0x00401228`.
2. Inspected the argument registers per System V ABI:
   - `$rdi` (1st arg): User input buffer (`x/s $rdi` -> `"test"`).
   - `$rsi` (2nd arg): Expected secret string (`x/s $rsi` -> `"entrypt"`).

* **Flag:** `entrypoint{re_basics}`

---

### Exercise 2: Calling Convention Verification (`scanf`)

To prove that a memory address represents the user input buffer at runtime (rather than relying solely on decompiler inference), I intercepted the `scanf` library call in GDB.

#### Execution & Register Inspection
```text
pwndbg> break __isoc23_scanf
pwndbg> run
```

When hitting the breakpoint prior to user input:
```text
pwndbg> info registers rdi rsi
rdi            0x402013            4202515
rsi            0x7fffffffd5d8      140737488344536

pwndbg> x/s $rdi
0x402013: "%63s"

pwndbg> p $rsi
$1 = (void *) 0x7fffffffd5d8
```

#### System V x86-64 Mapping
Under the System V ABI calling convention:
* **`RDI` (1st Argument):** Holds the address of the format specifier string (`"%63s"`).
* **`RSI` (2nd Argument):** Holds the memory address of the destination target buffer (`0x7fffffffd5d8`).

---

### Exercise 3: Reversing XOR Obfuscation & Automated Test (`crackme_v2`)

To test non-plaintext secrets, `crackme_v2` replaces `strcmp` with an inline XOR comparison loop using mask `0x55`.

#### Build & Compilation
```bash
gcc -O0 -no-pie -o crackme_v2 crackme_v2.c
strip crackme_v2
```

#### Static Decompilation (Ghidra)
```c
for (i = 0; i < 6; i++) {
    if ((char)(input[i] ^ 0x55) != encrypted_bytes[i]) {
        match = false;
        break;
    }
}
```

Extracting the array `[0x26, 0x30, 0x36, 0x27, 0x30, 0x21]` and decoding via Python (`Plaintext = Ciphertext ^ 0x55`):
```python
encrypted = [0x26, 0x30, 0x36, 0x27, 0x30, 0x21]
password = "".join(chr(b ^ 0x55) for b in encrypted)
print(f"Password: {password}")  # Output: secret
```

#### Automated Reproduction Script (`test.sh`)
An automated test script (`test.sh`) was added to verify both positive (`secret`) and negative (`wrongpass`) execution paths:
```bash
./test.sh
```

* **Flag:** `entrypoint{xor_loop_master}`

---

## CTF Challenge Solutions

### 1. Vault Door Training

* **Category:** Reverse Engineering
* **Source:** picoCTF / CyLab Academy

#### Analysis & Solution
Inspecting `VaultDoorTraining.java`:
```java
String input = userInput.substring("academy{".length(), userInput.length() - 1);
if (vaultDoor.checkPassword(input)) { ... }
```

* **Hypothesis / Assumption:** The hardcoded password in `checkPassword()` represents the inner flag content, and wrapping it in `academy{...}` satisfies the validation.
* **Verification / Evidence:** Running `java VaultDoorTraining` with input `academy{w4rm1ng_Up_w1tH_jAv4_1633b42d7f1}` returned `Access granted.`, confirming that the hardcoded string was indeed the exact inner secret.
* **Flag:** `academy{w4rm1ng_Up_w1tH_jAv4_1633b42d7f1}`

---

### 2. Transformation

* **Category:** Reverse Engineering / Bitwise Unpacking
* **Source:** picoCTF / CyLab Academy

#### Analysis & Solution
The challenge provides a 16-bit Unicode file generated via:
```python
''.join([chr((ord(flag[i]) << 8) + ord(flag[i + 1])) for i in range(0, len(flag), 2)])
```

* **Hypothesis / Assumption:** Reversing the packing bitwise (shifting right 8 bits for the upper byte and masking with `0xFF` for the lower byte) will reconstruct the original ASCII character pairs.
* **Verification / Evidence:** Executing `solve.py` unpacked the Unicode characters into the printable ASCII string `academy{16_bits_inst34d_of_8_790ba37e}`, matching standard CTF flag format rules.
* **Flag:** `academy{16_bits_inst34d_of_8_790ba37e}`

---

### 3. Flag Hunters

* **Category:** Reverse Engineering / Control Flow Hijacking
* **Source:** picoCTF / CyLab Academy

#### Analysis & Solution
The script evaluates lyrics line-by-line using a line pointer (`lip`). User input in `Crowd:` is stored directly into `song_lines[lip]` and split by `;`.

* **Hypothesis / Assumption:** Injecting `;RETURN 0` into the `Crowd:` prompt will cause `line.split(';')` to evaluate `RETURN 0` as a standalone command, updating `lip = 0` and jumping to the hidden `secret_intro`.
* **Verification / Evidence:** Submitting `;RETURN 0` in the live session successfully altered `lip` to `0`, and the interpreter outputted lines 0–4 containing the `secret_intro` flag on the second refrain iteration.
* **Flag:** `academy{16_bits_inst34d_of_8_790ba37e}`
