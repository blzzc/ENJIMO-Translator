import Foundation
import CoreFoundation
import Vision
import ImageIO

public enum Japanese {
    /// Dictionary readings, not a character-by-character kanji transliteration.
    /// Preserve punctuation, emoji and line breaks that the word tokenizer skips.
    public static func romaji(_ text: String) -> String {
        text.components(separatedBy: "\n").map(romanizeLine).joined(separator: "\n")
    }

    private static func romanizeLine(_ text: String) -> String {
        let source = text as NSString
        guard source.length > 0 else { return "" }
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault, text as CFString,
            CFRange(location: 0, length: source.length),
            kCFStringTokenizerUnitWord | kCFStringTokenizerAttributeLatinTranscription,
            CFLocaleCreate(kCFAllocatorDefault, "ja_JP" as CFString)
        )!
        var output = ""
        var cursor = 0
        while CFStringTokenizerAdvanceToNextToken(tokenizer).rawValue != 0 {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            guard range.location >= cursor, range.length > 0 else { continue }
            let gap = source.substring(with: NSRange(location: cursor, length: range.location - cursor))
            let original = source.substring(with: NSRange(location: range.location, length: range.length))
            let reading = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer, kCFStringTokenizerAttributeLatinTranscription
            ) as? String
            // Kana still has a useful fallback; unknown kanji stays visible rather than inventing a reading.
            let fallback = original.applyingTransform(.hiraganaToKatakana, reverse: true)?
                .applyingTransform(.toLatin, reverse: false) ?? original
            let hasKanji = original.unicodeScalars.contains { (0x3400...0x9FFF).contains($0.value) }
            let token = reading ?? (hasKanji ? original : fallback)
            if gap.isEmpty, !output.isEmpty { output += " " }
            output += gap + token
            cursor = range.location + range.length
        }
        output += source.substring(from: cursor)
        return output
    }

    public static func recognize(imageAt url: URL) throws -> String {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw RecognitionError.invalidImage
        }
        return try recognize(image: image)
    }

    public static func recognize(image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RecognitionError.noText }
        return text
    }
}

public enum RecognitionError: LocalizedError {
    case invalidImage, noText
    public var errorDescription: String? {
        switch self {
        case .invalidImage: return "无法读取图片，请选择 PNG、JPEG 或 TIFF 图片。"
        case .noText: return "没有识别到文字。请放大日语区域后重新截图，或直接粘贴文字。"
        }
    }
}
