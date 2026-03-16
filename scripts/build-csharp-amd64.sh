#!/bin/bash
# Build script for SPT >= 4.0.0 on amd64 (C#/.NET-based)
# Downloads pre-compiled binaries from GitHub releases
#
# Dependencies: git, git-lfs, curl, 7z (p7zip)
#
# Usage: ./build-csharp-amd64.sh <TEMP_DIR> <VERSION> <OUTPUT_DIR>

set -e

TEMP_DIR="$1"
VERSION="$2"
OUTPUT_DIR="$3"

if [[ -z "$TEMP_DIR" || -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <TEMP_DIR> <VERSION> <OUTPUT_DIR>"
    exit 1
fi

# Remove 'v' prefix if present
VERSION_CLEAN="${VERSION#v}"

echo "[csharp-amd64] Downloading pre-compiled binaries for version $VERSION_CLEAN..."
RELEASE_URL="https://github.com/sp-tarkov/server-csharp/releases/download/v${VERSION_CLEAN}/spt.7z"

cd "$TEMP_DIR"
if ! curl -L -f -o spt.7z "$RELEASE_URL"; then
    echo "[csharp-amd64] ERROR: Failed to download from $RELEASE_URL"
    exit 1
fi

echo "[csharp-amd64] Extracting 7z archive..."
if ! 7zr x spt.7z; then
    echo "[csharp-amd64] ERROR: Failed to extract spt.7z"
    exit 1
fi

echo "[csharp-amd64] Creating output directory..."
mkdir -p "$OUTPUT_DIR"

echo "[csharp-amd64] Moving extracted contents..."
mv "$TEMP_DIR"/* "$OUTPUT_DIR/" || true

echo "[csharp-amd64] Build completed: $OUTPUT_DIR"
