#!/bin/bash
# Build script for SPT >= 4.0.0 for the provided arch (C#/.NET-based)
# Builds from source using dotnet publish.
#
# Dependencies: git, git-lfs, dotnet-sdk (9.0+)
#
# Usage: ./build-csharp.sh <VERSION> <ARCH> <OUTPUT_ARCHIVE>

set -e

VERSION="$1"
ARCH="$2"
OUTPUT_ARCHIVE="$3"

if [[ -z "$VERSION" || -z "$ARCH" || -z "$OUTPUT_ARCHIVE" ]]; then
    echo "Usage: $0 <VERSION> <ARCH> <OUTPUT_ARCHIVE>"
    exit 1
fi

# Create temporary directories
TEMP_DIR=$(mktemp -d)
BUILD_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR' '$BUILD_DIR'" EXIT

echo "[csharp-$ARCH] Cloning SPT server-csharp repository (version $VERSION)..."
git clone --depth 1 --branch "$VERSION" \
    https://github.com/sp-tarkov/server-csharp.git "$TEMP_DIR"

echo "[csharp-$ARCH] Installing git-lfs..."
git -C "$TEMP_DIR" lfs install

echo "[csharp-$ARCH] Pulling LFS assets..."
git -C "$TEMP_DIR" lfs pull

# Extract version number and git commit info
COMMIT=$(git -C "$TEMP_DIR" rev-parse --short HEAD)
BUILD_TIME=$(date +%Y%m%d)

echo "[csharp-$ARCH] Building for linux-$ARCH (version: $VERSION, commit: $COMMIT, date: $BUILD_TIME)..."
dotnet publish "$TEMP_DIR/SPTarkov.Server/SPTarkov.Server.csproj" \
    -c Release \
    -r "linux-$ARCH" \
    -o "$BUILD_DIR" \
    --self-contained false \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -p:SptBuildType=RELEASE \
    -p:SptVersion="$VERSION" \
    -p:SptBuildTime="$BUILD_TIME" \
    -p:SptCommit="$COMMIT" \
    -p:IsPublish=true \
    -p:LangVersion=preview

# the linux-arm64 target creates the SPT.Server assembly
# the linux-amd64 target creates the SPT.Server.Linux assembly
# ensure that a consistent assembly is used (SPT.Server.Linux)
if [ -f "$BUILD_DIR/SPT.Server" ] && [ ! -f "$BUILD_DIR/SPT.Server.Linux" ]; then
    echo "[csharp-$ARCH] Relocating SPT.Server to SPT.Server.Linux..."
    mv "$BUILD_DIR/SPT.Server" "$BUILD_DIR/SPT.Server.Linux"
fi

echo "[csharp-$ARCH] Cleaning up debug symbols..."
find "$BUILD_DIR" -name "*.pdb" -delete

echo "[csharp-$ARCH] Creating output directory for archive..."
mkdir -p "$(dirname "$OUTPUT_ARCHIVE")"

echo "[csharp-$ARCH] Creating tar.gz archive..."
tar -C "$BUILD_DIR" -czf "$OUTPUT_ARCHIVE" .

echo "[csharp-$ARCH] Build completed: $OUTPUT_ARCHIVE"
