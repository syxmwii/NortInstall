import Foundation

/// Аутентификация Apple ID. Шаг 1 (anisette-заголовки) — реальный HTTP-запрос;
/// дальше нужен SRP-6a handshake с gsa.apple.com — он помечен TODO.
enum AppleAuthService {
    static func signIn(
        email: String,
        password: String,
        verificationCode: String,
        anisetteServer: URL
    ) async throws -> String {
        guard email.contains("@"), !password.isEmpty else {
            throw AppError.invalidInput("почта и пароль")
        }

        // Реальный запрос к anisette-серверу: эти заголовки нужны каждому
        // обращению к GrandSlam (GSA) — без них Apple отвечает ошибкой.
        let headers = try await AnisetteClient.fetch(from: anisetteServer)
        _ = headers

        _ = verificationCode
        // TODO(roadmap): SRP-6a handshake с gsa.apple.com/grandslam/GsService2
        // (init → complete), затем 2FA, если потребуется. Описание протокола —
        // в исходниках SideStore/AltStore (AppleAuthentication.swift).
        throw AppError.notImplemented("SRP-6a handshake с Apple ID (GSA)")
    }
}
