import AppKit
import SwiftUI

@main
enum EnjimoApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = Model()
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private let hotKeys = HotKeys()
    private var captureProcess: Process?
    private var capturing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["alwaysOnTop": true, "panelOpacity": 0.96, "fontSize": 15.0])
        let hosting = NSHostingView(rootView: PanelView(model: model))
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 410, height: 390),
                          styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "ENJIMO"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.minSize = NSSize(width: 340, height: 390)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = hosting
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("EnjimoPanel")
        // Recover a window saved on a monitor that is no longer attached.
        if !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(window.frame) }) { window.center() }
        updateAppearance()
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppearance), name: .enjimoAppearanceChanged, object: nil)
        model.captureAction = { [weak self] in self?.capture() }
        model.showAction = { [weak self] in self?.show() }
        model.hideAction = { [weak self] in self?.window.orderOut(nil) }
        installMenus()
        hotKeys.action = { [weak self] id in
            Task { @MainActor in
                if id == 1 { self?.capture() } else { self?.toggle() }
            }
        }
        if !hotKeys.register() {
            model.shortcutWarning = "快捷键被其他应用占用，请通过菜单栏或截图按钮操作。"
        }
        show()
        if CommandLine.arguments.contains("--smoke-test") {
            // CI proves the packaged application boots without requiring screen-recording permission.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("ENJIMO_SMOKE_OK")
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show(); return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func windowShouldClose(_ sender: NSWindow) -> Bool { sender.orderOut(nil); return false }
    func applicationWillTerminate(_ notification: Notification) { captureProcess?.terminate() }

    @objc private func updateAppearance() {
        window.level = UserDefaults.standard.bool(forKey: "alwaysOnTop") ? .floating : .normal
    }

    @objc private func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggle() { if window.isVisible { window.orderOut(nil) } else { show() } }
    @objc private func openImage() { show(); model.openImage() }
    @objc private func paste() { show(); model.paste() }
    @objc private func settings() { model.settingsVisible = true; show() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func capture() {
        guard !capturing else { return }
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            model.showPermissionHelp = true
            show()
            return
        }
        capturing = true
        let wasVisible = window.isVisible
        window.orderOut(nil)
        Task {
            // Let the compositing server remove our floating panel before opening the system selector.
            try? await Task.sleep(for: .milliseconds(250))
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("enjimo-\(UUID()).png")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-x", "-t", "png", url.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            captureProcess = process
            do {
                let code: Int32 = try await withCheckedThrowingContinuation { continuation in
                    process.terminationHandler = { completed in continuation.resume(returning: completed.terminationStatus) }
                    do { try process.run() } catch {
                        process.terminationHandler = nil
                        continuation.resume(throwing: error)
                    }
                }
                capturing = false
                captureProcess = nil
                if code == 0, FileManager.default.fileExists(atPath: url.path) {
                    show()
                    model.readImage(url, removeAfter: true)
                } else {
                    try? FileManager.default.removeItem(at: url)
                    model.status = "截图已取消或未生成图片 · 可重新截图"
                    if wasVisible { show() }
                }
            } catch {
                capturing = false
                captureProcess = nil
                try? FileManager.default.removeItem(at: url)
                model.status = "无法启动截图：\(error.localizedDescription)"
                show()
            }
        }
    }

    private func item(_ title: String, _ selector: Selector, key: String = "", modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = self
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private func installMenus() {
        let appMenu = NSMenu()
        appMenu.addItem(item("显示 / 隐藏 ENJIMO", #selector(toggle)))
        appMenu.addItem(item("截图识别日语  ⌘⇧2", #selector(capture)))
        appMenu.addItem(item("打开图片…", #selector(openImage), key: "o"))
        appMenu.addItem(item("粘贴图片或文字", #selector(paste), key: "v", modifiers: [.command, .shift]))
        appMenu.addItem(.separator())
        appMenu.addItem(item("设置…", #selector(settings), key: ","))
        appMenu.addItem(item("退出 ENJIMO", #selector(quit), key: "q"))
        let main = NSMenu()
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        main.addItem(appItem)
        let edit = NSMenu(title: "编辑")
        for (title, action, key) in [("撤销", "undo:", "z"), ("剪切", "cut:", "x"), ("复制", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            edit.addItem(NSMenuItem(title: title, action: Selector(action), keyEquivalent: key))
        }
        let editItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        editItem.submenu = edit
        main.addItem(editItem)
        NSApp.mainMenu = main
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "ENJIMO 截图翻译")
        statusItem.button?.toolTip = "ENJIMO · 截图识别日语"
        statusItem.menu = appMenu.copy() as? NSMenu
    }
}
