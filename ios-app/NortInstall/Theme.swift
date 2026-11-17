import SwiftUI

/// Дизайн-система NortInstall — те же цвета, что на сайте.
enum Theme {
    /// #26d83c — фирменный зелёный
    static let accent = Color(red: 0x26 / 255, green: 0xd8 / 255, blue: 0x3c / 255)
    /// #0ea968 — второй цвет градиента
    static let accentEnd = Color(red: 0x0e / 255, green: 0xa9 / 255, blue: 0x68 / 255)
    /// #04140a — текст на акцентных кнопках
    static let onAccent = Color(red: 0x04 / 255, green: 0x14 / 255, blue: 0x0a / 255)

    static let background = Color(red: 0x0b / 255, green: 0x0d / 255, blue: 0x12 / 255)
    static let card = Color(red: 0x14 / 255, green: 0x18 / 255, blue: 0x22 / 255)
    static let border = Color.white.opacity(0.08)

    static let gradient = LinearGradient(
        colors: [accent, accentEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)
}

/// Внешние ссылки (синхронизированы с web/config.js — смените на свои).
enum Links {
    static let localDevVPN = URL(string: "https://apps.apple.com/app/id6755608044")!
    // Сайт проекта на GitHub Pages (при форке замените владельца).
    static let dnsProfile = URL(string: "https://syxmwii.github.io/NortInstall/NortInstallDNS.mobileconfig")!
    static let certificates = URL(string: "https://syxmwii.github.io/NortInstall/certificates.html")!
}

// MARK: - Стили

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(Theme.onAccent)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .foregroundStyle(.primary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

/// Плавное появление карточек на главном экране (каскадом).
struct StaggeredAppear: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(Theme.spring.delay(Double(index) * 0.06), value: appeared)
    }
}
