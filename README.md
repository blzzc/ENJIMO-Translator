# ENJIMO

**框选日语，马上看到原文、罗马音和中文。**

ENJIMO 现在包含两个独立入口：macOS 截图翻译应用，以及原来的 Chrome 悬浮翻译扩展。桌面版延续深色分行界面、青色拖动方块和极简工具栏，支持浏览器、视频画面、PDF 和其他应用中的日语。
旨在帮助和我一样使用《大家的日语》学习的初学者快速记忆

## Mac 安装（推荐）

**[下载最新版 →](https://github.com/blzzc/ENJIMO-Translator/releases/latest)**

1. 下载 `ENJIMO-macOS-universal.dmg`，双击打开。
2. 将 **ENJIMO.app** 拖进 **Applications / 应用程序**。
3. 在启动台打开 ENJIMO，或按 `⌘ Space` 搜索 ENJIMO。可以将它固定到 Dock。
4. 首次截图时，按提示允许 ENJIMO 的屏幕录制权限；首次翻译时，允许系统下载日语与中文语言包。

需要 **macOS 15（Sequoia）或更新版本**。安装包包含 Apple Silicon 和 Intel 两种架构，无需 Python、Node、浏览器扩展或 API Key。若 Releases 尚未生成，查看 [构建状态](https://github.com/blzzc/ENJIMO-Translator/actions/workflows/macos.yml)，也可从源码构建。

当前版本使用临时本机签名（ad-hoc），**尚未通过 Apple Developer ID 签名和公证**。首次打开若被 macOS 拦截，先尝试打开一次，再到「系统设置 → 隐私与安全性 → 仍要打开」确认。不要关闭系统整体安全检查。详见 [安装说明](macos/INSTALL.zh-CN.md)。

## 桌面版使用

| 操作 | 方式 |
| --- | --- |
| 框选屏幕中的日语 | **⌘⇧2**，或点击「截图」 |
| 取消框选 | **Esc** |
| 显示 / 隐藏悬浮窗 | **⌘⇧9**，或菜单栏图标 |
| 编辑 OCR 结果并重新翻译 | 修改第一行，按 **⌘↩** |
| 粘贴截图或文字 | **⌘⇧V**，或剪贴板按钮 |
| 导入现有图片 | **⌘O**，或图片按钮 |
| 朗读日语 / 停止朗读 | 扬声器按钮 |
| 复制日语、罗马音和中文 | 复制按钮 |
| 移动窗口 | 拖动左上角青色方块 |
| 调整窗口 | 拖动窗口边缘 |
| 配色、透明度、字号、置顶 | 齿轮按钮，或右键青色方块 |
| 完全退出 | **⌘Q**，或菜单栏「退出 ENJIMO」 |

收起窗口后应用仍在菜单栏运行。也可以在 macOS「系统设置 → 通用 → 登录项」中自行添加 ENJIMO，开机后直接用快捷键。

### 识别、读音与隐私

- 使用 Apple Vision 在本机识别文字，使用系统日语词典生成罗马音，使用 Apple Translation 翻译为简体中文。
- 首次下载语言包需要网络。语言包安装完成后的翻译在本机进行；本应用不上传截图、不调用第三方翻译接口、不保存识别历史。
- 临时截图在识别结束后删除；只保存窗口位置、尺寸和外观偏好。
- 罗马音是自动推测的读音，**人名、多音字、特殊写法可能不准确**；没有词典读音的汉字会保留原文。可修改第一行后重试，并用日语朗读辅助核对。
- 优先适配清晰的横排日语。竖排漫画、多栏、花体、小字及模糊画面可能识别错字或打乱顺序。
- DRM 保护的视频可能无法截图；系统权限不能绕过这类保护。可使用图片导入或粘贴文字。
- 快捷键被其他应用占用时，设置中会提示；仍可使用菜单栏和按钮。

## 原 Chrome 扩展

仓库根目录的 `manifest.json`、`content.js`、`background.js` 仍是原版扩展。它提供中文、英文、西班牙语、日语和韩语的文字翻译，不包含桌面版的截图 / 罗马音功能。

1. 使用支持内置 Translator API 的桌面版 Chrome 138+。
2. 打开 `chrome://extensions`，启用「开发者模式」。
3. 选择「加载已解压的扩展程序」，选中本仓库根目录，再刷新网页。
4. `Ctrl+Shift+9` 显示 / 隐藏；输入后自动翻译；选中文字也可右键翻译。

语言和配色仍通过拖动色块设置。Chrome 内部页面、应用商店、原生视频全屏以及浏览器外的软件不能注入该扩展界面。

## 从源码构建桌面版

在 macOS 15+ 安装 Xcode 16+，或包含 Swift 6 和 macOS 15+ SDK 的 Command Line Tools，然后执行：

```bash
git clone https://github.com/blzzc/ENJIMO-Translator.git
cd ENJIMO-Translator
bash scripts/build-macos.sh
open dist/ENJIMO.app
```

也可运行 `bash scripts/install-macos.command`，安装到当前用户的 `~/Applications` 并打开。已有安装时会停止，避免覆盖正在运行的版本。普通用户直接下载 DMG 即可。

```bash
# 测试日语词典读音、标点换行、OCR 和错误输入
cd macos
swift test

# 在仓库根目录打包 DMG（先构建应用）
bash scripts/package-dmg.sh
```

GitHub Actions 会在 macOS runner 上运行测试、构建双架构应用、启动应用做冒烟测试并生成 DMG / ZIP / SHA-256 校验文件。只有全部成功，main 分支才会按 `Info.plist` 的版本号发布新 Release；已有版本不会覆盖，后续发版需递增版本号。

CI 不会自动授权屏幕录制或下载用户语言包，因此系统权限对话框、真实跨应用截图和首次翻译下载仍需在用户的 Mac 上验证。Apple Developer ID 签名和公证需要仓库维护者自己的证书，当前未配置。
