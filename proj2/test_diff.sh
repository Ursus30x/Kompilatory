#!/bin/bash
set -e

echo "[*] Building project..."
make

echo "[*] Running simula with test.sim (stdout only)..."
./simula < test.sim 2>/dev/null > output.out

echo
echo "[*] Comparing output.out with reference.out (ignoring whitespace)..."
if diff --color=always -u --ignore-all-space --strip-trailing-cr reference.out output.out; then
    echo
    echo "[✓] Outputs match (ignoring whitespace)."
else
    echo
    echo "[✗] Differences found!"
    echo "You can open 'output.out' and 'reference.out' to inspect manually."
    exit 1
fi
