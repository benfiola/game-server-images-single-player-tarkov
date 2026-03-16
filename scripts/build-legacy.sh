#!/bin/bash
# Build script for SPT < 4.0.0 (Node.js-based)
#
# Dependencies: git, git-lfs, nodejs, npm
#
# Usage: ./build-legacy.sh <TEMP_DIR> <VERSION> <OUTPUT_DIR>

set -e

TEMP_DIR="$1"
VERSION="$2"
OUTPUT_DIR="$3"

if [[ -z "$TEMP_DIR" || -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <TEMP_DIR> <VERSION> <OUTPUT_DIR>"
    exit 1
fi

echo "[legacy] Installing git-lfs..."
git -C "$TEMP_DIR" lfs install

echo "[legacy] Pulling LFS assets..."
git -C "$TEMP_DIR" lfs pull

echo "[legacy] Installing npm dependencies..."
npm -C "$TEMP_DIR" install

echo "[legacy] Building release..."
npm -C "$TEMP_DIR" run build:release

echo "[legacy] Creating output directory..."
mkdir -p "$OUTPUT_DIR"

echo "[legacy] Copying artifacts..."
cp -r "$TEMP_DIR/dist/." "$OUTPUT_DIR"

echo "[legacy] Build completed: $OUTPUT_DIR"
