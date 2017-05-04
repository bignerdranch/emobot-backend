import PackageDescription

let package = Package(
    name: "emobot",
    targets: [
        Target(name: "App", dependencies: ["Models"]),
        Target(name: "Bot", dependencies: ["Models"]),
        Target(name: "Models"),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 5),
        .Package(url: "https://github.com/vapor/postgresql-provider.git", majorVersion: 1, minor: 0),
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)
