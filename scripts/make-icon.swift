import AppKit

// Code-drawn icon: the original ENJIMO cyan drag square and stacked dark rows.
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
let folder = FileManager.default.temporaryDirectory.appendingPathComponent("enjimo-\(UUID()).iconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: folder) }
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let p = CGFloat(pixels)
        NSColor(red: 0.035, green: 0.05, blue: 0.063, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: p * 0.05, y: p * 0.05, width: p * 0.9, height: p * 0.9), xRadius: p * 0.18, yRadius: p * 0.18).fill()
        for (i, width) in [0.60, 0.46, 0.55].enumerated() {
            NSColor(red: i == 1 ? 0.36 : 0.80, green: i == 1 ? 0.89 : 0.87, blue: i == 1 ? 0.98 : 0.9, alpha: 1).setFill()
            NSBezierPath(rect: NSRect(x: p * 0.22, y: p * (0.59 - Double(i) * 0.17), width: p * width, height: p * 0.07)).fill()
        }
        NSColor(red: 0.36, green: 0.89, blue: 0.98, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: p * 0.12, y: p * 0.76, width: p * 0.13, height: p * 0.13)).fill()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name))
    }
}
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", folder.path, "-o", destination.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("iconutil failed") }
