import Foundation

/// То, что rust-core вытащил из IPA (Info.plist + embedded.mobileprovision).
struct IPAInfo: Codable, Equatable {
    let name: String
    let bundleID: String
    let version: String
    let minimumOS: String?
    /// Есть ли внутри embedded.mobileprovision (т.е. сборка подписана).
    let hasProvision: Bool?
    /// Team ID из provisioning-профиля, если он есть.
    let teamID: String?

    enum CodingKeys: String, CodingKey {
        case name
        case bundleID = "bundle_id"
        case version
        case minimumOS = "minimum_os"
        case hasProvision = "has_provision"
        case teamID = "team_id"
    }
}
