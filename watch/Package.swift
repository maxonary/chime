// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "Haptic",
  platforms: [
    .watchOS(.v10),
  ],
  products: [
    .executable(
      name: "Haptic",
      targets: ["Haptic"]
    ),
  ],
  targets: [
    .executableTarget(
      name: "Haptic",
      dependencies: [],
      path: "Haptic"
    ),
  ]
)
