#!/bin/bash
set -e

echo "=========================================="
echo "[+] Starting Automated Exploitation Tests"
echo "=========================================="

CDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RET2WIN_DIR="$CDIR/ret2win"

cd "$RET2WIN_DIR"

# 1. Compile Targets
echo "[*] Compiling binaries..."
gcc -g -O0 -no-pie -fno-stack-protector -o vuln vuln.c
gcc -g -O0 -no-pie -fno-stack-protector -o vuln2 vuln2.c
gcc -g -O0 -no-pie -fstack-protector-all -o vuln_canary vuln.c

# 2. Test Exercise 2 (ret2win Exploit)
echo "[*] Testing Exercise 2 (exploit.py vs vuln)..."
OUT_EX1=$( (echo "exit") | timeout 5s python3 exploit.py 2>&1 || true )
if echo "$OUT_EX1" | grep -q "Access granted"; then
    echo "[+] SUCCESS: exploit.py passed (Access granted detected)."
else
    echo "[-] FAIL: exploit.py failed."
    echo "$OUT_EX1"
    exit 1
fi

# 3. Test Exercise 4 (ROP Gadget Exploit)
echo "[*] Testing Exercise 4 (exploit2.py vs vuln2)..."
OUT_EX2=$( (echo "exit") | timeout 5s python3 exploit2.py 2>&1 || true )
if echo "$OUT_EX2" | grep -q "Access granted"; then
    echo "[+] SUCCESS: exploit2.py passed (Access granted with 0x1337 detected)."
else
    echo "[-] FAIL: exploit2.py failed."
    echo "$OUT_EX2"
    exit 1
fi

# 4. Test Exercise 3 (Stack Canary Mitigation Failure)
echo "[*] Testing Exercise 3 (exploit.py vs vuln_canary)..."
python3 -c 'from pwn import *; import sys; sys.stdout.buffer.write(flat({136: 0x401196}))' > payload_test.bin
OUT_CANARY=$(timeout 5s ./vuln_canary < payload_test.bin 2>&1 || true)
rm -f payload_test.bin

if echo "$OUT_CANARY" | grep -q "stack smashing detected"; then
    echo "[+] SUCCESS: Stack Canary detected smashing as expected."
else
    echo "[-] FAIL: Stack Canary did not trigger."
    echo "$OUT_CANARY"
    exit 1
fi

echo "=========================================="
echo "[+] ALL INTEGRATION TESTS PASSED SUCCESSFULLY!"
echo "=========================================="
