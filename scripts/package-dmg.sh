#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto "$ROOT/dist/ENJIMO.app" "$STAGING/ENJIMO.app"
ln -s /Applications "$STAGING/Applications"
cp "$ROOT/macos/INSTALL.zh-CN.md" "$STAGING/安装说明.txt"
hdiutil create -volname ENJIMO -srcfolder "$STAGING" -ov -format UDZO "$ROOT/dist/ENJIMO-macOS-universal.dmg"
cd "$ROOT/dist"
shasum -a 256 ENJIMO-macOS-universal.dmg ENJIMO-macOS-universal.zip > SHA256SUMS.txt
