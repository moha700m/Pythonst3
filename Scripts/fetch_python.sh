#!/bin/sh
# Fetch the pinned Python-Apple-support build used by the Pythonst3 iOS app.
# Source: https://github.com/beeware/Python-Apple-support
set -eu

VERSION="3.13-b18"
ARCHIVE="Python-3.13-iOS-support.b18.tar.gz"
URL="https://github.com/beeware/Python-Apple-support/releases/download/${VERSION}/${ARCHIVE}"
SHA256="d06acf2a9c7964a8689566353a0e707402eff822037de5e29ba0e16040f7047d"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/Frameworks"

mkdir -p "$DEST"

if [ -d "$DEST/Python.xcframework" ]; then
    echo "Python.xcframework already present in Frameworks/."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading ${ARCHIVE} ..."
curl -fsSL "$URL" -o "$TMP/$ARCHIVE"

echo "Verifying SHA-256 ..."
echo "${SHA256}  $TMP/$ARCHIVE" | shasum -a 256 -c -

echo "Extracting ..."
tar -xzf "$TMP/$ARCHIVE" -C "$TMP"
cp -R "$TMP/Python.xcframework" "$DEST/Python.xcframework"
cp "$TMP/VERSIONS" "$DEST/Python-VERSIONS.txt"

echo "Installed Python.xcframework ($(cat "$DEST/Python-VERSIONS.txt" | head -1))"
