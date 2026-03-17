#!/bin/bash
# Build script for SPT < 4.0.0 (Node.js-based)
#
# Dependencies: git, git-lfs, nodejs, npm
#
# Usage: ./build-legacy.sh <VERSION> <OUTPUT_ARCHIVE>

set -e

VERSION="$1"
OUTPUT_ARCHIVE="$2"

if [[ -z "$VERSION" || -z "$OUTPUT_ARCHIVE" ]]; then
    echo "Usage: $0 <VERSION> <OUTPUT_ARCHIVE>"
    exit 1
fi

# Create temporary directory for source checkout
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

echo "[legacy] Cloning SPT server repository (version $VERSION)..."
git clone --depth 1 --branch "$VERSION" \
    https://github.com/sp-tarkov/server.git "$TEMP_DIR"

echo "[legacy] Installing git-lfs..."
git -C "$TEMP_DIR" lfs install

echo "[legacy] Pulling LFS assets..."
git -C "$TEMP_DIR" lfs pull

echo "[legacy] Installing npm dependencies..."
npm -C "$TEMP_DIR/project" install

echo "[legacy] Building release..."
npm -C "$TEMP_DIR/project" run build:release

echo "[legacy] Creating output directory for archive..."
mkdir -p "$(dirname "$OUTPUT_ARCHIVE")"

echo "[legacy] Creating tar.gz archive..."
tar -C "$TEMP_DIR/project/build" -czf "$OUTPUT_ARCHIVE" .

echo "[legacy] Build completed: $OUTPUT_ARCHIVE"
