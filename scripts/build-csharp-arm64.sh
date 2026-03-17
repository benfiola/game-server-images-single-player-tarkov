#!/bin/bash
# Build script for SPT >= 4.0.0 on arm64 (C#/.NET-based)
# Builds from source using dotnet publish for linux-arm64
#
# Dependencies: git, git-lfs, dotnet-sdk (9.0+)
#
# Usage: ./build-csharp-arm64.sh <VERSION> <OUTPUT_DIR>

set -e

VERSION="$1"
OUTPUT_DIR="$2"

if [[ -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <VERSION> <OUTPUT_DIR>"
    exit 1
fi

# Create temporary directory for source checkout
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

echo "[csharp-arm64] Cloning SPT server-csharp repository (version $VERSION)..."
git clone --depth 1 --branch "$VERSION" \
    https://github.com/sp-tarkov/server-csharp.git "$TEMP_DIR"

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
