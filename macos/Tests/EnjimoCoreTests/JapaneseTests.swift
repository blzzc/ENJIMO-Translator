import XCTest
import AppKit
@testable import EnjimoCore

final class JapaneseTests: XCTestCase {
    func testEmptyAndWhitespace() {
        XCTAssertEqual(Japanese.romaji(""), "")
        XCTAssertEqual(Japanese.romaji("  \n"), "  \n")
    }

    func testKanjiGetsDictionaryReading() {
        let reading = Japanese.romaji("私は学生です。").folding(options: .diacriticInsensitive, locale: Locale(identifier: "ja"))
        XCTAssertTrue(reading.lowercased().contains("gakusei"), reading)
        XCTAssertFalse(reading.contains("学生"), reading)
        XCTAssertTrue(reading.hasSuffix("。"), reading)
    }

    func testKanaAndLineBreaks() {
        let reading = Japanese.romaji("こんにちは！\nカメラです。")
        XCTAssertEqual(reading.components(separatedBy: "\n").count, 2)
        XCTAssertTrue(reading.lowercased().contains("kamera"), reading)
        XCTAssertTrue(reading.contains("！"), reading)
    }

    func testNonJapaneseContentIsPreserved() {
        let reading = Japanese.romaji("Hello 123 😊\n！？")
        XCTAssertTrue(reading.contains("Hello"), reading)
        XCTAssertTrue(reading.contains("123"), reading)
        XCTAssertTrue(reading.contains("😊"), reading)
        XCTAssertTrue(reading.hasSuffix("\n！？"), reading)
    }

    func testInvalidImageReportsUsefulError() {
        XCTAssertThrowsError(try Japanese.recognize(imageAt: URL(fileURLWithPath: "/no-such-enjimo-image.png"))) { error in
            XCTAssertTrue(error.localizedDescription.contains("无法读取图片"))
        }
    }

    func testJapaneseOCRFromRenderedImage() throws {
        let size = NSSize(width: 900, height: 170)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        ("日本語の勉強をします。" as NSString).draw(at: NSPoint(x: 30, y: 60), withAttributes: [
            .font: NSFont.systemFont(ofSize: 50), .foregroundColor: NSColor.black
        ])
        image.unlockFocus()
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let text = try Japanese.recognize(image: cgImage)
        XCTAssertTrue(text.contains("日本語"), text)
        XCTAssertTrue(text.contains("勉強"), text)
    }

    func testBlankImageDoesNotInventText() throws {
        let image = NSImage(size: NSSize(width: 300, height: 100))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 300, height: 100)).fill()
        image.unlockFocus()
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertThrowsError(try Japanese.recognize(image: cgImage))
    }
}
