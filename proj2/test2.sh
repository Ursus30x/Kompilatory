#!/bin/bash
set -e

echo "[*] Building project..."
make

echo "[*] Running simula with test2.sim (stdout only)..."
./simula < test2.sim 2>/dev/null
