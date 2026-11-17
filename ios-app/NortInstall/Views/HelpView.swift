import SwiftUI

/// Справка внутри приложения — повторяет туториал с сайта: DNS-профиль
/// и «доверять» enterprise-сертификату.
struct HelpView: View {
    var body: some View {
        Form {
            Section {
                Text("DNS-профиль не даёт Apple отзывать сертификаты: он направляет "
                    + "запросы к ocsp*.apple.com и ppq.apple.com через заблокированный "
                    + "DoH-резолвер.")
                    .font(.callout)
            } header: {
                Text("Зачем нужен DNS-профиль")
            }

            Section {
                Link("Скачать готовый DNS-профиль", destination: Links.dnsProfile)
                helpRow("1", "Скачайте профиль проекта кнопкой выше — настраивать NextDNS не нужно.")
                helpRow("2", "Настройки → «Профиль загружен» → Установить.")
                helpRow("3", "Проверка: Настройки → Основные → VPN и DNS → NortInstall DNS.")
                helpRow("4", "После установки SideStore профиль можно удалить там же.")
            } header: {
                Text("Установка DNS-профиля")
            } footer: {
                Text("При подписи своим Apple ID DNS-профиль не нужен.")
            }

            Section {
                helpRow("1", "Откройте подписанный .ipa — увидите «Ненадёжный разработчик».")
                helpRow("2", "Настройки → Основные → VPN и управление устройствами.")
                helpRow("3", "Выберите сертификат, которым подписано приложение.")
                helpRow("4", "Нажмите «Доверять» и подтвердите.")
                helpRow("5", "Откройте приложение ещё раз — оно запустится.")
            } header: {
                Text("Как разрешить приложение")
            }

            Section {
                Label(
                    "Если приложение вдруг перестало открываться — сертификат отозван. "
                        + "Включите DNS-профиль и переустановите сборку.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Справка")
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private func helpRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.monospaced().bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.tint, in: Circle())

            Text(text).font(.callout)
        }
        .padding(.vertical, 2)
    }
}
