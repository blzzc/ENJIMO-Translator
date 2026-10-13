#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "请在 macOS 15+ 上构建，或下载 GitHub Releases 中的应用。" >&2
  exit 1
fi
cd "$ROOT/macos"
swift build -c release --arch arm64
ARM_BIN="$(swift build -c release --arch arm64 --show-bin-path)/Enjimo"
swift build -c release --arch x86_64
INTEL_BIN="$(swift build -c release --arch x86_64 --show-bin-path)/Enjimo"
APP="$ROOT/dist/ENJIMO.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$ARM_BIN" "$INTEL_BIN" -output "$APP/Contents/MacOS/Enjimo"
cp Resources/Info.plist "$APP/Contents/Info.plist"
swift "$ROOT/scripts/make-icon.swift" "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
lipo "$APP/Contents/MacOS/Enjimo" -verify_arch arm64 x86_64
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/ENJIMO-macOS-universal.zip"
echo "已构建：$APP"
