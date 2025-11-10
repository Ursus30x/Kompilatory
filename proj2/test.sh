#!/bin/bash
set -e

echo "[*] Building project..."
make

echo "[*] Running simula with test.sim (stdout only)..."
./simula < test.sim 2>/dev/null
