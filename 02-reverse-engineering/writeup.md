# Phase 3: Reverse Engineering

This repository documents my work for Phase 3 of the Cyber Security Researcher track. It covers static and dynamic binary analysis, decompilation with Ghidra, debugging with GDB, and solutions for three CTF challenges focused on reversing and control flow manipulation.

---

## Lab Exercises: Reversing Stripped Binaries

### Exercise 1: Finding `main` in a Stripped Binary (`crackme`)

When analyzing closed-source binaries, debugging symbols are often stripped. I compiled a C program without debug symbols and stripped it to simulate this environment:

```bash
gcc -O0 -no-pie -o crackme crackme.c
strip crackme
```

#### Analysis
Running `file` confirms the binary is stripped, and `strings` reveals some readable literals (`"Password:"`, `"Correct. Flag: ..."`), but no function names.

To locate `main` in Ghidra:
1. I navigated to the ELF entry point (`entry` at `0x004010d0`).
2. According to the System V x86-64 calling convention, `entry` passes the address of `main` as the first argument (`RDI`) to `__libc_start_main`.
3. In Ghidra, `RDI` points to `FUN_004011b6`, which is our actual `main` function.

Decompiled logic in Ghidra:
```c
builtin_strncpy(local_60, "entrypt", 8);
printf("Password: ");
__isoc23_scanf("%63s", local_60 + 8);

if (strcmp(local_60 + 8, local_60) == 0) {
    puts("Correct. Flag: entrypoint{re_basics}");
}
```

#### Dynamic Verification (GDB)
To verify the comparison at runtime:
1. Set a breakpoint right before `strcmp`: `break *0x00401228`.
2. Inspected the argument registers:
   - `$rdi` (1st arg): User input string.
   - `$rsi` (2nd arg): Expected string (`"entrypt"`).

* **Flag:** `entrypoint{re_basics}`

---

### Exercise 2: Reversing XOR Obfuscation (`crackme_v2`)

In this exercise, string literals were obfuscated using an inline XOR loop with the mask `0x55`.

#### Decompiled Loop (Ghidra)
```c
for (i = 0; i < 6; i++) {
    if ((char)(input[i] ^ 0x55) != encrypted_bytes[i]) {
        match = false;
        break;
    }
}
```

Since XOR is symmetric (`Plaintext = Ciphertext ^ Mask`), I extracted the encrypted bytes `[0x26, 0x30, 0x36, 0x27, 0x30, 0x21]` from memory and decoded them using Python:

```python
encrypted = [0x26, 0x30, 0x36, 0x27, 0x30, 0x21]
password = "".join(chr(b ^ 0x55) for b in encrypted)
print(f"Password: {password}")  # Output: secret
```

* **Flag:** `entrypoint{xor_loop_master}`

---

## CTF Challenge Solutions

### 1. Vault Door Training

* **Category:** Reverse Engineering / Source Code Analysis
* **Source:** picoCTF / CyLab Academy

#### Analysis
The challenge provides Java source code (`VaultDoorTraining.java`):

```java
String userInput = scanner.next();
String input = userInput.substring("academy{".length(), userInput.length() - 1);

if (vaultDoor.checkPassword(input)) {
    System.out.println("Access granted.");
}

public boolean checkPassword(String password) {
    return password.equals("w4rm1ng_Up_w1tH_jAv4_1633b42d7f1");
}
```

The code strips the prefix (`academy{`, 8 characters) and trailing brace (`}`) from `userInput`, checking the middle string against the hardcoded value.

* **Flag:** `academy{w4rm1ng_Up_w1tH_jAv4_1633b42d7f1}`

---

### 2. Transformation

* **Category:** Reverse Engineering / Bitwise Decoding
* **Source:** picoCTF / CyLab Academy

#### Analysis
We are given an encoded file (`enc`) containing Unicode characters. The challenge description shows how it was constructed:

```python
''.join([chr((ord(flag[i]) << 8) + ord(flag[i + 1])) for i in range(0, len(flag), 2)])
```

The encoding takes pairs of 8-bit ASCII characters and packs them into a single 16-bit Unicode character.

#### Solution
To reconstruct the flag, I wrote a Python script (`enc.py`) to unpack each 16-bit integer back into two 8-bit characters:
- Upper 8 bits (1st char): `ord(char) >> 8`
- Lower 8 bits (2nd char): `ord(char) & 0xFF`

```python
encoded = open('enc').read()
decoded = ""

for char in encoded:
    num = ord(char)
    decoded += chr(num >> 8) + chr(num & 0xFF)

print(decoded)
```

* **Flag:** `academy{16_bits_inst34d_of_8_790ba37e}`

---

### 3. Flag Hunters

* **Category:** Reverse Engineering / Control Flow Hijacking
* **Source:** picoCTF / CyLab Academy

#### Analysis
The challenge runs a custom Python interpreter that parses song lyrics. The secret flag is loaded into memory inside `secret_intro` at lines 0–4:

```python
secret_intro = "... " + flag + "\n"
```

However, execution starts at `[VERSE1]`, bypassing the flag lines. 

Looking at the input handling code:
```python
elif re.match(r"CROWD.*", line):
    crowd = input('Crowd: ')
    song_lines[lip] = 'Crowd: ' + crowd
```

The user input is written directly into `song_lines[lip]`, which is later evaluated and split by semicolon (`;`).

#### Solution
When prompted with `Crowd:`, I injected a semicolon followed by a jump instruction:
```text
Crowd: ;RETURN 0
```

The interpreter split the injected string, executed `RETURN 0`, updated the line pointer `lip = 0`, and jumped back to print lines 0–4 containing the flag.

* **Flag:** `academy{16_bits_inst34d_of_8_790ba37e}`
