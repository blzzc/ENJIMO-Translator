// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Enjimo",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "Enjimo", targets: ["Enjimo"])],
    targets: [
        .target(name: "EnjimoCore"),
        .executableTarget(name: "Enjimo", dependencies: ["EnjimoCore"]),
        .testTarget(name: "EnjimoCoreTests", dependencies: ["EnjimoCore"])
    ],
    swiftLanguageModes: [.v5]
)
