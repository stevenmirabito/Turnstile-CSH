import PackageDescription

let package = Package(
    name: "TurnstileCSH",
    dependencies: [
      .Package(url: "https://github.com/stormpath/Turnstile.git", majorVersion: 1),
      .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1)
    ]
)
