#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "正在构建 ENJIMO（需要 macOS 15+ 和 Xcode Command Line Tools）…"
if ! xcrun --find swift >/dev/null 2>&1; then
  echo "请先运行 xcode-select --install，完成后重新打开此文件。"
  read -r -p "按回车关闭…"
  exit 1
fi
bash "$ROOT/scripts/build-macos.sh"
mkdir -p "$HOME/Applications"
if [[ -e "$HOME/Applications/ENJIMO.app" ]]; then
  echo "已有 ENJIMO.app。请先退出旧版并将它移走，再运行此安装器。"
  read -r -p "按回车关闭…"
  exit 1
fi
ditto "$ROOT/dist/ENJIMO.app" "$HOME/Applications/ENJIMO.app"
open "$HOME/Applications/ENJIMO.app"
