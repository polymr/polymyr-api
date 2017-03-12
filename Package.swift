import PackageDescription

let package = Package(
    name: "polymr-api",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/sanitized.git", majorVersion: 0),
//        .Package(url: "https://github.com/mxcl/PromiseKit.git", majorVersion: 0),
    ],
    exclude: [
        "Config",
        "Database",
        "Public"
    ]
)

