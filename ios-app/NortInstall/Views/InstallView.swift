import SwiftUI

struct InstallView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var engine = InstallEngine()
    @State private var urlString = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sourceCard
                    actionArea
                    if let info = engine.info { infoCard(info) }
                    if engine.step == .done { doneCard }
                    if let error = engine.lastError { errorCard(error) }
                }
                .padding(20)
                .animation(Theme.spring, value: engine.step)
                .animation(Theme.spring, value: engine.info)
            }
        }
        .navigationTitle("Установить IPA")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: appState.pendingInstallURL) { newValue in
            guard let newValue else { return }
            urlString = newValue.absoluteString
            appState.pendingInstallURL = nil
            install()
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ссылка на .ipa", systemImage: "link")
                .font(.headline)

            TextField("https://example.com/app.ipa", text: $urlString)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Theme.border)
                )
        }
        .cardStyle()
    }

    @ViewBuilder
    private var actionArea: some View {
        switch engine.step {
        case .downloading:
            VStack(spacing: 16) {
                if let fraction = engine.progress.fraction {
                    ProgressRing(fraction: fraction)
                } else {
                    ProgressView()
                        .scaleEffect(1.4)
                        .padding(30)
                }
                Text("Скачиваем…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            .transition(.opacity.combined(with: .scale))

        case .preparing:
            HStack {
                ProgressView()
                Text("Читаем IPA…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()

        default:
            Button {
                install()
            } label: {
                Label("Скачать и установить", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!urlIsValid)
            .opacity(urlIsValid ? 1 : 0.4)
        }
    }

    private func infoCard(_ info: IPAInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Из Info.plist", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
            LabeledContent("Название", value: info.name)
            LabeledContent("Bundle ID", value: info.bundleID)
            LabeledContent("Версия", value: info.version)
            if let minimumOS = info.minimumOS {
                LabeledContent("Минимальная iOS", value: minimumOS)
            }
            LabeledContent("Подпись", value: info.hasProvision == true ? "есть" : "нет")
            if let teamID = info.teamID {
                LabeledContent("Team ID", value: teamID)
            }
        }
        .font(.callout)
        .cardStyle()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var doneCard: some View {
        Label(
            "IPA распознан. Подписание и установка — следующий этап разработки (см. README).",
            systemImage: "hammer.circle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .cardStyle()
    }

    private func errorCard(_ error: Error) -> some View {
        Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .cardStyle()
    }

    private var urlIsValid: Bool {
        guard let url = URL(string: urlString), url.scheme == "https" else { return false }
        return url.pathExtension.lowercased() == "ipa"
    }

    private func install() {
        guard let url = URL(string: urlString) else { return }
        Task { await engine.install(from: url) }
    }
}

/// Анимированное кольцо прогресса загрузки.
private struct ProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.border, lineWidth: 9)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.gradient, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.spring, value: fraction)
            Text("\(Int(fraction * 100))%")
                .font(.title2.bold().monospacedDigit())
        }
        .frame(width: 120, height: 120)
    }
}
