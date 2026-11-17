import Foundation

enum AppError: Error, LocalizedError {
    case invalidURL
    case invalidInput(String)
    case invalidIPA(String)
    case downloadFailed(String)
    case notImplemented(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректная ссылка. Нужен https-адрес, оканчивающийся на .ipa."
        case .invalidInput(let what):
            return "Заполните поля: \(what)."
        case .invalidIPA(let why):
            return "Файл не похож на IPA: \(why)"
        case .downloadFailed(let why):
            return "Не удалось скачать IPA: \(why)"
        case .notImplemented(let what):
            return "Пока не реализовано: \(what). См. README, раздел «Roadmap»."
        }
    }
}
