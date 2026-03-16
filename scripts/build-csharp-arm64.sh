#!/bin/bash
# Build script for SPT >= 4.0.0 on arm64 (C#/.NET-based)
# Builds from source using dotnet publish for linux-arm64
#
# Dependencies: git, git-lfs, dotnet-sdk (9.0+)
#
# Usage: ./build-csharp-arm64.sh <TEMP_DIR> <VERSION> <OUTPUT_DIR>

set -e

TEMP_DIR="$1"
VERSION="$2"
OUTPUT_DIR="$3"

if [[ -z "$TEMP_DIR" || -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <TEMP_DIR> <VERSION> <OUTPUT_DIR>"
    exit 1
fi

echo "[csharp-arm64] Installing git-lfs..."
git -C "$TEMP_DIR" lfs install

echo "[csharp-arm64] Pulling LFS assets..."
git -C "$TEMP_DIR" lfs pull

echo "[csharp-arm64] Publishing for linux-arm64..."
dotnet publish "$TEMP_DIR/SPTarkov.Server/SPTarkov.Server.csproj" \
    -c Release \
    -r linux-arm64 \
    -o "$OUTPUT_DIR"

echo "[csharp-arm64] Cleaning up debug symbols..."
find "$OUTPUT_DIR" -name "*.pdb" -delete

echo "[csharp-arm64] Build completed: $OUTPUT_DIR"
