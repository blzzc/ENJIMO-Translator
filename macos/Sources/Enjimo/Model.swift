import AppKit
import SwiftUI
import Translation
import AVFoundation
import UniformTypeIdentifiers
import EnjimoCore

@MainActor
final class Model: ObservableObject {
    @Published var source = ""
    @Published var romaji = ""
    @Published var chinese = ""
    @Published var status = "框选屏幕上的日语 · ⌘⇧2"
    @Published var busy = false
    @Published var configuration: TranslationSession.Configuration?
    @Published var settingsVisible = false
    @Published var shortcutWarning = ""
    @Published var showPermissionHelp = false
    private(set) var generation = 0
    private(set) var requestedText = ""
    private var requestedGeneration = 0
    private let speech = AVSpeechSynthesizer()
    var captureAction: (() -> Void)?
    var showAction: (() -> Void)?
    var hideAction: (() -> Void)?

    func sourceChanged() {
        // Invalidate an in-flight result as soon as the user edits the source.
        generation += 1
        romaji = ""
        chinese = ""
        busy = false
        status = "修改后按 ⌘↩ 翻译"
    }

    func translate(_ newText: String? = nil) {
        if let newText { source = newText }
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        generation += 1
        chinese = ""
        romaji = ""
        guard !text.isEmpty else {
            busy = false
            status = "先截图，或输入日语"
            return
        }
        guard text.count <= 5000 else {
            busy = false
            status = "一次最多翻译 5000 字，请缩小截图区域。"
            return
        }
        romaji = Japanese.romaji(text)
        requestedText = text
        requestedGeneration = generation
        busy = true
        status = "正在翻译 · 首次请按系统提示下载语言包"
        if configuration == nil {
            configuration = .init(source: Locale.Language(identifier: "ja"),
                                  target: Locale.Language(identifier: "zh-Hans"))
        } else {
            configuration?.invalidate()
        }
    }

    func performTranslation(using session: TranslationSession) async {
        let version = requestedGeneration
        let text = requestedText
        guard version == generation else { return }
        do {
            let response = try await session.translate(text)
            guard !Task.isCancelled, version == generation else { return }
            chinese = response.targetText
            status = "完成 · 读音仅供参考，可朗读核对"
        } catch {
            guard !Task.isCancelled, version == generation else { return }
            status = "翻译未完成：\(error.localizedDescription) · 可点击翻译重试"
        }
        if version == generation { busy = false }
    }

    func readImage(_ url: URL, removeAfter: Bool = false) {
        generation += 1
        let version = generation
        busy = true
        romaji = ""
        chinese = ""
        status = "正在识别日语…"
        Task {
            defer { if removeAfter { try? FileManager.default.removeItem(at: url) } }
            do {
                let text = try await Task.detached(priority: .userInitiated) {
                    try Japanese.recognize(imageAt: url)
                }.value
                guard generation == version else { return }
                translate(text)
            } catch {
                guard generation == version else { return }
                busy = false
                status = error.localizedDescription
            }
        }
    }

    func openImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { readImage(url) }
    }

    func paste() {
        let clipboard = NSPasteboard.general
        if let image = NSImage(pasteboard: clipboard), let data = image.tiffRepresentation {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("enjimo-\(UUID()).tiff")
            do {
                try data.write(to: url)
                readImage(url, removeAfter: true)
            } catch { status = "无法读取剪贴板图片：\(error.localizedDescription)" }
        } else if let text = clipboard.string(forType: .string) {
            translate(text)
        } else { status = "剪贴板里没有图片或文字" }
    }

    func copyAll() {
        let text = [source, romaji, chinese].filter { !$0.isEmpty }.joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        status = "已复制日语、罗马音和中文"
    }

    func speak() {
        if speech.isSpeaking { speech.stopSpeaking(at: .immediate); return }
        guard !source.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: source)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        speech.speak(utterance)
    }
}
