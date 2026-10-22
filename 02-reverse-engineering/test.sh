#!/usr/bin/env bash
set -e

echo "[+] Compiling and stripping crackme_v2..."
gcc -O0 -no-pie -o crackme_v2 crackme_v2.c
strip crackme_v2

echo "[+] Test 1: Testing correct input ('secret')..."
OUTPUT_CORRECT=$(echo "secret" | ./crackme_v2)
if echo "$OUTPUT_CORRECT" | grep -q "Correct!"; then
    echo "[PASS] Correct password verified: $OUTPUT_CORRECT"
else
    echo "[FAIL] Correct password test failed!"
    exit 1
fi

echo "[+] Test 2: Testing incorrect input ('wrongpass')..."
OUTPUT_WRONG=$(echo "wrongpass" | ./crackme_v2)
if echo "$OUTPUT_WRONG" | grep -q "Wrong password."; then
    echo "[PASS] Incorrect password rejected as expected: $OUTPUT_WRONG"
else
    echo "[FAIL] Incorrect password test failed!"
    exit 1
fi

echo "[SUCCESS] All automated tests passed for crackme_v2!"
