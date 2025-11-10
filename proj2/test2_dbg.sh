#!/bin/bash
set -e

echo "[*] Building project..."
make

echo "[*] Running simula with test2.sim (showing stdout + stderr)..."
./simula < test2.sim 2>&1
