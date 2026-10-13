# ENJIMO 安装与首次使用

系统要求：macOS 15 或更新版本。

1. 打开 ENJIMO-macOS-universal.dmg。
2. 把 ENJIMO.app 拖到 Applications（应用程序）。
3. 双击应用，或按 Command + Space 搜索 ENJIMO。
4. 点击「截图」，在系统提示中允许屏幕录制权限。
5. 按 Command + Shift + 2，框选一小块清晰的日语。Esc 取消。
6. 第一次翻译时确认系统的日语 / 中文语言包下载，下载后重试即可。

首次打开被拦截？

当前应用为独立开发版本，使用 ad-hoc 签名，尚未经过 Apple Developer ID 签名及公证。
确认安装包来自 blzzc/ENJIMO-Translator 的 GitHub Release 后，先尝试打开一次，
再进入「系统设置 → 隐私与安全性」，找到 ENJIMO 并选择「仍要打开」。
无需关闭 Gatekeeper，也不要运行不明来源的解除隔离脚本。

截图仍不能使用？

在「系统设置 → 隐私与安全性 → 屏幕与系统音频录制」（名称随系统版本变化）中允许 ENJIMO。
若系统要求，完全退出 ENJIMO 后重新打开。可以先用图片按钮导入截图，或 Command + Shift + V 粘贴图片。

如何更方便地打开？

- 固定到 Dock，或用 Spotlight 搜索 ENJIMO。
- 打开后常驻菜单栏；Command + Shift + 9 显示 / 隐藏窗口。
- 可以在「系统设置 → 通用 → 登录项」手动添加 ENJIMO。
- 减号按钮仅隐藏窗口；Command + Q 才会退出。

如何卸载？

先退出应用，将 /Applications/ENJIMO.app 移到废纸篓；如果添加了登录项，将其移除。
应用不保存截图和翻译历史。外观偏好由 macOS 保存在 com.blzzc.enjimo 的用户默认设置中。
