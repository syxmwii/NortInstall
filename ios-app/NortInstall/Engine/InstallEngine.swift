import Foundation

/// Оркестрирует установку: скачать → разобрать → профиль → подпись → установка.
///
/// Три последних шага требуют приватных API и entitlements, недоступных
/// обычному приложению, — SideStore решает это собственным демоном.
/// Здесь они помечены TODO, а движок честно останавливается после разбора IPA.
@MainActor
final class InstallEngine: ObservableObject {
    enum Step: Equatable {
        case idle
        case downloading
        case preparing
        case done
    }

    @Published private(set) var step: Step = .idle
    @Published private(set) var progress = DownloadProgress(bytesWritten: 0, totalBytes: nil)
    @Published private(set) var info: IPAInfo?
    @Published var lastError: Error?

    func install(from source: URL) async {
        lastError = nil
        info = nil
        progress = DownloadProgress(bytesWritten: 0, totalBytes: nil)
        step = .downloading

        do {
            let ipa = try await IPADownloader.download(source) { [weak self] progress in
                Task { @MainActor [weak self] in self?.progress = progress }
            }

            step = .preparing
            info = try RustFFI.ipaInfo(at: ipa)

            // TODO(roadmap): запрос provisioning-профиля через Apple ID (anisette).
            // TODO(roadmap): переподписание бинаря (ldid / codesign).
            // TODO(roadmap): установка через механизм с entitlement'ами (как у SideStore).
            step = .done
        } catch {
            step = .idle
            lastError = error
        }
    }
}
