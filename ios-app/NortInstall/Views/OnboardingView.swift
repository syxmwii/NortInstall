import SwiftUI

/// Онбординг при первом запуске — тот же мастер, что install.html на сайте:
/// приветствие → LocalDevVPN → DNS → сертификат/доверие → готово.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var step = 0
    @State private var direction = 1.0
    private let total = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 22) {
                progress
                Text("Шаг \(step + 1) из \(total)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                    ))

                HStack(spacing: 12) {
                    if step > 0 {
                        Button("Назад") { go(-1) }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    Button(step == total - 1 ? "Открыть NortInstall" : "Дальше") {
                        step == total - 1 ? onFinish() : go(1)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(20)
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Theme.accent : Theme.border)
                    .frame(height: 5)
            }
        }
        .padding(.top, 12)
        .animation(Theme.spring, value: step)
    }

    private func go(_ delta: Int) {
        direction = Double(delta)
        withAnimation(Theme.spring) {
            step = min(max(step + delta, 0), total - 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            shell(icon: "arrow.down.app.fill", title: "Sideload на iPhone.\nБез компьютера.") {
                Text(
                    "NortInstall скачивает, подписывает и устанавливает IPA " +
                    "прямо на вашем устройстве. Пройдём настройку за минуту."
                )
            }
        case 1:
            shell(icon: "network", title: "Установите LocalDevVPN") {
                Text(
                    "Бесплатное приложение из App Store создаёт туннель к самому iPhone — " +
                    "через него NortInstall ставит приложения. После установки включите VPN."
                )
                Link("Открыть в App Store", destination: Links.localDevVPN)
                    .buttonStyle(SecondaryButtonStyle())
            }
        case 2:
            shell(icon: "shield.lefthalf.filled", title: "Включите DNS-профиль") {
                Text(
                    "Профиль проекта уже настроен — он не даёт Apple отозвать сертификат. " +
                    "Скачайте, затем Настройки → «Профиль загружен» → Установить."
                )
                Link("Скачать DNS-профиль", destination: Links.dnsProfile)
                    .buttonStyle(SecondaryButtonStyle())
                Text("Если подписываете своим Apple ID — DNS не нужен, просто идите дальше.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case 3:
            shell(icon: "checkmark.seal.fill", title: "Сертификат и доверие") {
                Text(
                    "Выберите активный сертификат на сайте и установите NortInstall. " +
                    "Затем разрешите запуск:"
                )
                VStack(alignment: .leading, spacing: 8) {
                    Label("Настройки → Основные", systemImage: "1.circle.fill")
                    Label("VPN и управление устройствами", systemImage: "2.circle.fill")
                    Label("Сертификат → Доверять", systemImage: "3.circle.fill")
                }
                .font(.callout)
                Link("Выбрать сертификат", destination: Links.certificates)
                    .buttonStyle(SecondaryButtonStyle())
            }
        default:
            shell(icon: "checkmark.circle.fill", title: "Всё готово!") {
                Text(
                    "Войдите со своим Apple ID, добавьте файл сопряжения — " +
                    "и устанавливайте любые IPA."
                )
            }
        }
    }

    private func shell<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.gradient)
                .padding(.top, 12)

            Text(title)
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 14) { content() }
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
