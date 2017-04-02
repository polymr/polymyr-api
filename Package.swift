// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "polymr-api",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/mysql-provider.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/jwt.git", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/auth-provider.git", majorVersion: 0)
    ],
    exclude: [
        "Config",
        "Database",
        "Public"
    ]
)
