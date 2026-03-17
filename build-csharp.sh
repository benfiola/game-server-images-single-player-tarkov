#!/bin/bash
# Build script for SPT >= 4.0.0 for the provided arch (C#/.NET-based)
# Builds from source using dotnet publish.
#
# Dependencies: git, git-lfs, dotnet-sdk (9.0+)
#
# Usage: ./build-csharp.sh <VERSION> <ARCH> <OUTPUT_DIR>

set -e

VERSION="$1"
ARCH="$2"
OUTPUT_DIR="$3"

if [[ -z "$VERSION" || -z "$ARCH" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <VERSION> <ARCH> <OUTPUT_DIR>"
    exit 1
fi

# Create temporary directory for source checkout
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

echo "[csharp-$ARCH] Cloning SPT server-csharp repository (version $VERSION)..."
git clone --depth 1 --branch "$VERSION" \
    https://github.com/sp-tarkov/server-csharp.git "$TEMP_DIR"

echo "[csharp-$ARCH] Installing git-lfs..."
git -C "$TEMP_DIR" lfs install

echo "[csharp-$ARCH] Pulling LFS assets..."
git -C "$TEMP_DIR" lfs pull

echo "[csharp-$ARCH] Publishing for linux-$ARCH..."
dotnet publish "$TEMP_DIR/SPTarkov.Server/SPTarkov.Server.csproj" \
    -c Release \
    -r "linux-$ARCH" \
    -o "$OUTPUT_DIR"

echo "[csharp-$ARCH] Cleaning up debug symbols..."
find "$OUTPUT_DIR" -name "*.pdb" -delete

echo "[csharp-$ARCH] Build completed: $OUTPUT_DIR"
