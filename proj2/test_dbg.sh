#!/bin/bash
set -e

echo "[*] Building project..."
make

echo "[*] Running simula with test.sim (showing stdout + stderr)..."
./simula < test.sim 2>&1
