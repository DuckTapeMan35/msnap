#!/bin/sh
set -e

REPO="https://github.com/atheeq-rhxn/mango-utils.git"
TMP="$(mktemp -d)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/mango-utils"
QUICKSHELL_DIR="$HOME/.config/quickshell"

echo "Cloning mango-utils…"
git clone --depth=1 "$REPO" "$TMP"

echo "Installing binaries to $BIN_DIR…"
mkdir -p "$BIN_DIR"
chmod +x "$TMP/mcast/mcast" "$TMP/mshot/mshot"
cp "$TMP/mcast/mcast" "$BIN_DIR/mcast"
cp "$TMP/mshot/mshot" "$BIN_DIR/mshot"

echo "Installing configs to $CONFIG_DIR…"
mkdir -p "$CONFIG_DIR"
cp -n "$TMP/mcast/mcast.conf" "$CONFIG_DIR/"
cp -n "$TMP/mshot/mshot.conf" "$CONFIG_DIR/"

echo "Installing mutil to $QUICKSHELL_DIR/mutil"
mkdir -p "$QUICKSHELL_DIR/mutil"
cp "$TMP/mutil/shell.qml" "$QUICKSHELL_DIR/mutil"
cp "$TMP/mutil/RegionSelector.qml" "$QUICKSHELL_DIR/mutil"

echo "Cleaning up…"
rm -rf "$TMP"
echo

echo "Done!"
echo "✔ mcast, mshot → $BIN_DIR"
echo "✔ configs → $CONFIG_DIR"
echo "✔ mutil → $QUICKSHELL_DIR"
echo
echo "Make sure $BIN_DIR is in your PATH:"
echo "    export PATH=\"$BIN_DIR:\$PATH\""
