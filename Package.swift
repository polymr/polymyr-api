// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "polymr-api",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/mysql-provider.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/jwt.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/hhanesand/auth-provider.git", Version(1, 0, 0, prereleaseIdentifiers: ["beta"]))
    ],
    exclude: [
        "Config",
        "Database",
        "Public"
    ]
)
