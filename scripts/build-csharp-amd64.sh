#!/bin/bash
# Build script for SPT >= 4.0.0 on amd64 (C#/.NET-based)
# Downloads pre-compiled binaries from GitHub releases
#
# Dependencies: git, curl, 7z (p7zip)
#
# Usage: ./build-csharp-amd64.sh <VERSION> <OUTPUT_DIR>

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

echo "[csharp-amd64] Cloning SPT server-csharp repository (version $VERSION)..."
git clone --depth 1 --branch "$VERSION" \
    https://github.com/sp-tarkov/server-csharp.git "$TEMP_DIR"

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
