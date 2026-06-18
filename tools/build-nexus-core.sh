#!/bin/bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/nexus-core/build"
mkdir -p "$BUILD"
CC_BIN="${CC:-}"
if [ -z "$CC_BIN" ]; then
  if command -v clang >/dev/null 2>&1; then
    CC_BIN=clang
  elif command -v gcc >/dev/null 2>&1; then
    CC_BIN=gcc
  else
    echo "Nenhum compilador C encontrado (clang/gcc)."
    exit 1
  fi
fi
COMMON_FLAGS=(-std=c11 -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -Wall -Wextra -Werror -I"$ROOT/nexus-core/kernel/include" -I"$ROOT/nexus-core/loader/include")
"$CC_BIN" "${COMMON_FLAGS[@]}" -c "$ROOT/nexus-core/kernel/src/kernel_main.c" -o "$BUILD/kernel_main.o"
"$CC_BIN" "${COMMON_FLAGS[@]}" -c "$ROOT/nexus-core/loader/src/uefi_loader.c" -o "$BUILD/uefi_loader.o"
echo "NexusOS core objects built:"
ls -lh "$BUILD"/kernel_main.o "$BUILD"/uefi_loader.o

# Full BOOTX64.EFI linking is intentionally separate because it requires a UEFI PE/COFF link profile.
# The object build validates clean-room C syntax and ABI-facing code without using Linux headers.
