#!/bin/bash

echo "[*] Compiling with 32-byte buffer..."
sed -i 's/char name\[.*\];/char name\[32\];/' mem.c
gcc -g -O0 -no-pie -fno-stack-protector -o mem mem.c
echo "Evidence for 32 bytes:"
objdump -d -M intel mem | grep "sub    rsp" | head -n 1

echo -e "\n[*] Compiling with 100-byte buffer..."
sed -i 's/char name\[.*\];/char name\[100\];/' mem.c
gcc -g -O0 -no-pie -fno-stack-protector -o mem mem.c
echo "Evidence for 100 bytes:"
objdump -d -M intel mem | grep "sub    rsp" | head -n 1
