import AppKit
import SwiftUI
import Translation

struct PanelView: View {
    @ObservedObject var model: Model
    @AppStorage("panelOpacity") private var opacity = 0.96
    @AppStorage("panelTheme") private var theme = "gray"
    @AppStorage("fontSize") private var fontSize = 15.0
    @AppStorage("alwaysOnTop") private var alwaysOnTop = true
    private var accent: Color { theme == "warm" ? Color(red: 0.85, green: 0.51, blue: 0.32) : Color(red: 0.36, green: 0.89, blue: 0.98) }
    private var sourceColor: Color { theme == "warm" ? Color(red: 0.15, green: 0.12, blue: 0.10) : Color(red: 0.094, green: 0.118, blue: 0.133) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                DragHandle(color: NSColor(accent)) { model.settingsVisible.toggle() }
                    .frame(width: 13, height: 13)
                    .help("拖动方块移动窗口 · 右键打开设置")
                    .accessibilityLabel("拖动窗口；右键设置")
                Text("ENJIMO").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(3)
                Spacer()
                Text("JA → ZH").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                tool("gearshape", help: "设置") { model.settingsVisible.toggle() }
                    .popover(isPresented: $model.settingsVisible) { settings.frame(width: 320).preferredColorScheme(.dark) }
                tool("minus", help: "收起到菜单栏 · ⌘⇧9") { model.hideAction?() }
            }
            .padding(.horizontal, 13).padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 5) {
                rowLabel("日本語", code: "INPUT::JA_JP", color: Color(red: 1, green: 0.39, blue: 0.69))
                TextEditor(text: Binding(get: { model.source }, set: { model.source = $0; model.sourceChanged() }))
                    .font(.system(size: fontSize)).scrollContentBackground(.hidden)
                    .frame(minHeight: 44, idealHeight: 64, maxHeight: .infinity)
                    .overlay(alignment: .topLeading) {
                        if model.source.isEmpty {
                            Text("截图，或在这里输入日语…").font(.system(size: fontSize))
                                .foregroundStyle(.secondary).padding(.top, 1).padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("日语原文，可修改识别结果")
            }.padding(12).background(sourceColor)

            resultRow("罗马音", code: "READING::ROMAJI", text: model.romaji,
                      placeholder: "nihongo no yomikata", color: accent, mono: true)
                .background(Color(red: 0.06, green: 0.082, blue: 0.098))
            resultRow("中文", code: "OUTPUT::ZH_CN", text: model.chinese,
                      placeholder: "中文翻译会显示在这里", color: Color(red: 1, green: 0.54, blue: 0.51), mono: false)
                .background(sourceColor)

            HStack(spacing: 6) {
                Button { model.captureAction?() } label: {
                    Label("截图", systemImage: "viewfinder").font(.system(size: 12, weight: .semibold))
                }.buttonStyle(.borderedProminent).tint(accent).foregroundStyle(.black)
                Button("翻译") { model.translate() }.keyboardShortcut(.return, modifiers: .command)
                Spacer(minLength: 0)
                tool("doc.on.clipboard", help: "粘贴图片或文字 · ⌘⇧V") { model.paste() }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                tool("photo", help: "打开图片 · ⌘O") { model.openImage() }.keyboardShortcut("o")
                tool("speaker.wave.2", help: "朗读或停止日语") { model.speak() }.disabled(model.source.isEmpty)
                tool("doc.on.doc", help: "复制全部结果") { model.copyAll() }.disabled(model.source.isEmpty)
            }.buttonStyle(.borderless).padding(.horizontal, 12).padding(.top, 10)
            HStack(alignment: .top, spacing: 6) {
                if model.busy { ProgressView().controlSize(.mini).scaleEffect(0.7) }
                Text(model.status).font(.system(size: 10)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                Spacer(minLength: 0)
            }.padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 11)

        }
        .foregroundStyle(Color(red: 0.86, green: 0.91, blue: 0.93))
        .background(Color(red: 0.035, green: 0.05, blue: 0.063))
        .opacity(opacity)
        .preferredColorScheme(.dark)
        .frame(minWidth: 340, idealWidth: 410, minHeight: 360)
        .translationTask(model.configuration) { session in await model.performTranslation(using: session) }
        .alert("需要屏幕录制权限", isPresented: $model.showPermissionHelp) {
            Button("打开系统设置") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("在「隐私与安全性 → 屏幕与系统音频录制」中允许 ENJIMO。若系统要求，请退出并重新打开应用。也可以先用「粘贴」或「打开图片」。")
        }
    }

    private func rowLabel(_ title: String, code: String, color: Color) -> some View {
        HStack {
            Rectangle().fill(color).frame(width: 5, height: 5)
            Text(title).font(.system(size: 9, weight: .semibold))
            Spacer()
            Text(code).font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(.secondary)
        }
    }

    private func resultRow(_ title: String, code: String, text: String, placeholder: String, color: Color, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            rowLabel(title, code: code, color: color)
            ScrollView {
                Text(text.isEmpty ? placeholder : text)
                    .font(.system(size: fontSize, design: mono ? .monospaced : .default))
                    .foregroundStyle(text.isEmpty ? Color.secondary : (mono ? accent : Color.primary))
                    .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            }.frame(minHeight: 38, idealHeight: 52, maxHeight: .infinity)
        }.padding(12)
    }

    private func tool(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 23, height: 23) }
            .buttonStyle(.plain).help(help).accessibilityLabel(help)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack {
                Text("配色")
                Picker("配色", selection: $theme) { Text("冷灰").tag("gray"); Text("暖灰").tag("warm") }.labelsHidden()
                Toggle("置顶", isOn: $alwaysOnTop).onChange(of: alwaysOnTop) { _, _ in
                    NotificationCenter.default.post(name: .enjimoAppearanceChanged, object: nil)
                }
            }
            HStack { Text("透明度"); Slider(value: $opacity, in: 0.65...1) }
            HStack { Text("字号"); Slider(value: $fontSize, in: 12...24, step: 1); Text("\(Int(fontSize))") }
            Text("截图 ⌘⇧2  ·  显示 / 隐藏 ⌘⇧9  ·  翻译 ⌘↩\n框选时按 Esc 取消。拖动方块移动窗口，拖动窗口边缘调整尺寸。")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            if !model.shortcutWarning.isEmpty { Text(model.shortcutWarning).foregroundStyle(.orange) }
            Text("识别、读音和翻译在本机处理。人名、多音字及竖排漫画可能需要手动校对。")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }.font(.system(size: 11)).padding(12)
    }
}

extension Notification.Name {
    static let enjimoAppearanceChanged = Notification.Name("enjimoAppearanceChanged")
}

struct DragHandle: NSViewRepresentable {
    var color: NSColor
    var onRightClick: () -> Void
    func makeNSView(context: Context) -> HandleView { HandleView() }
    func updateNSView(_ view: HandleView, context: Context) {
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.onRightClick = onRightClick
    }
    final class HandleView: NSView {
        var onRightClick: (() -> Void)?
        override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
        override func rightMouseDown(with event: NSEvent) { onRightClick?() }
    }
}
