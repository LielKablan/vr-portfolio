### 1: Stack Frame of greet

The local buffer `name` starts at: `0x7fffffffdc80`

The saved RBP is stored at: `0x7fffffffdca0`

The return address is stored at: `0x7fffffffdca8`

**According to the Assembly:**
* `name` is accessed at `[rbp-0x20]`, so the buffer is located 32 bytes below RBP.
* The saved RBP is located at RBP.
* The return address is located at RBP+8.

Therefore, the distance from the beginning of `name` to the return address is:
`0x7fffffffdca8 - 0x7fffffffdc80 = 0x28 = 40 bytes`

**Stack Layout**

*Higher addresses*

    0x7fffffffdca8   ← Return Address
    0x7fffffffdca0   ← Saved RBP
    0x7fffffffdc80   ← name[32]

*Lower addresses*

**GDB Evidence**

    pwndbg> p &name
    $1 = (char (*)[32]) 0x7fffffffdc80

    pwndbg> info frame
    Saved registers:
      rbp at 0x7fffffffdca0, rip at 0x7fffffffdca8

    pwndbg> x/6gx $rbp
    0x7fffffffdca0:  0x00007fffffffdcb0  0x00000000004011b9

---

### 2: Buffer Size Changed To 100

The buffer size changed from:
`char name[32];`
to:
`char name[100];`

After recompiling, the Assembly of `greet` changed as follows:

**Before:**

    sub rsp,0x20
    lea rax,[rbp-0x20]
    mov esi,0x20

**After:**

    sub rsp,0x70
    lea rax,[rbp-0x70]
    mov esi,0x64

* `0x64` equals 100, which is the size of the `name` buffer.
* `0x70` equals 112, which is the amount of stack allocated by the compiler for the local area.

The buffer is now located at `RBP - 0x70`.
The return address is located at `RBP + 8`.

Therefore, the distance from the beginning of the buffer to the return address is:
`0x70 + 8 = 0x78 = 120 bytes`

**Assembly Evidence**

    40115e:    sub    rsp,0x70
    40117d:    lea    rax,[rbp-0x70]
    401181:    mov    esi,0x64

---

### 3: Order of Local Buffers

Two local buffers with different sizes were declared:

    char first[8];
    char second[20];

The addresses found in GDB were:
* `first = 0x7fffffffdcd8`
* `second = 0x7fffffffdcc0`

Therefore, `second` is located at a lower memory address than `first`.

The experiment shows that the order in which local variables are declared in the source code does not necessarily determine their order in the stack.
The compiler determines the layout of the local variables in the Stack Frame, so their actual memory addresses should be checked rather than assumed from their declaration order.

---

### 4: Input Longer Than the Buffer

More than 32 characters were entered, but no overflow occurred.

The `fgets` function did not take all of the entered characters because it receives `sizeof(name)` as a parameter, which is 32.
This tells the function the size of the buffer and prevents it from writing beyond its boundary.

With `gets`, no buffer size is provided. If more characters than the buffer can hold are entered, the input can continue writing beyond the buffer and overwrite adjacent data in the Stack Frame, such as the saved RBP and return address.
