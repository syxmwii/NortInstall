import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        statusChips
                        menu
                        footer
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 60, height: 60)
                .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("NortInstall")
                    .font(.title.bold())
                Text("Sideload без компьютера")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var statusChips: some View {
        HStack(spacing: 10) {
            StatusChip(
                title: "Сертификат",
                active: appState.certificate != nil
            )
            StatusChip(
                title: "Сопряжение",
                active: appState.pairingFileImported
            )
        }
    }

    private var menu: some View {
        VStack(spacing: 12) {
            NavigationLink { InstallView() } label: {
                MenuCardRow(
                    icon: "arrow.down.app.fill",
                    title: "Установить IPA",
                    subtitle: "По ссылке или из браузера",
                    highlighted: true
                )
            }
            .buttonStyle(.plain)
            .modifier(StaggeredAppear(index: 0, appeared: appeared))

            NavigationLink { AppleIDView() } label: {
                MenuCardRow(
                    icon: "person.icloud.fill",
                    title: "Apple ID",
                    subtitle: "Локальный вход для подписи"
                )
            }
            .buttonStyle(.plain)
            .modifier(StaggeredAppear(index: 1, appeared: appeared))

            NavigationLink { PairingFileView() } label: {
                MenuCardRow(
                    icon: "link.badge.plus",
                    title: "Файл сопряжения",
                    subtitle: appState.pairingFileImported ? "Импортирован" : "Нужен для iOS 17.4–26.x"
                )
            }
            .buttonStyle(.plain)
            .modifier(StaggeredAppear(index: 2, appeared: appeared))

            NavigationLink { CertificatesView() } label: {
                MenuCardRow(
                    icon: "checkmark.seal.fill",
                    title: "Сертификаты",
                    subtitle: appState.certificate != nil ? "Сертификат сохранён" : "Импорт .p12"
                )
            }
            .buttonStyle(.plain)
            .modifier(StaggeredAppear(index: 3, appeared: appeared))

            NavigationLink { HelpView() } label: {
                MenuCardRow(
                    icon: "questionmark.circle.fill",
                    title: "Справка",
                    subtitle: "DNS-профиль и доверие"
                )
            }
            .buttonStyle(.plain)
            .modifier(StaggeredAppear(index: 4, appeared: appeared))
        }
        .onAppear { appeared = true }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notice = appState.schemeNotice {
                Label(notice, systemImage: "link")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text("Каркас проекта: подписание и установка пока в разработке — см. README.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
}

/// Строка-меню в виде карточки.
private struct MenuCardRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var highlighted = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(highlighted ? Theme.onAccent : Theme.accent)
                .frame(width: 44, height: 44)
                .background(
                    highlighted ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.accent.opacity(0.12)),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(highlighted ? Theme.accent.opacity(0.45) : .clear, lineWidth: 1)
        )
    }
}

/// Маленький индикатор «настроено / не настроено».
private struct StatusChip: View {
    let title: String
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? Theme.accent : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.medium))
            Text(active ? "готово" : "нет")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.border))
        .animation(Theme.spring, value: active)
    }
}
