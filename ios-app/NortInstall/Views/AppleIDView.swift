import SwiftUI

struct AppleIDView: View {
    @AppStorage("anisetteServer") private var anisetteServer = ""

    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                TextField("Электронная почта", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Пароль", text: $password)
                TextField("Код 2FA (если попросит)", text: $code)
            } header: {
                Text("Apple ID")
            } footer: {
                Label(
                    "Данные не покидают устройство: они нужны только локально, " +
                    "чтобы запросить сертификат подписи.",
                    systemImage: "lock.shield"
                )
            }

            Section {
                TextField("https://…", text: $anisetteServer)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Anisette-сервер")
            } footer: {
                Text(
                    "Свой сервер поднимается из github.com/SideStore/anisette-v3-server. " +
                    "Чужому серверу доверять нельзя."
                )
            }

            Section {
                Button {
                    signIn()
                } label: {
                    if busy {
                        ProgressView()
                    } else {
                        Text("Войти")
                    }
                }
                .disabled(busy || email.isEmpty || password.isEmpty)
            }

            if let message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Apple ID")
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private func signIn() {
        busy = true
        message = nil

        guard let server = URL(string: anisetteServer), server.scheme == "https" else {
            message = AppError.invalidInput("anisette-сервер (https-ссылка)").localizedDescription
            busy = false
            return
        }

        Task {
            defer { busy = false }
            do {
                let session = try await AppleAuthService.signIn(
                    email: email,
                    password: password,
                    verificationCode: code,
                    anisetteServer: server
                )
                message = "Вход выполнен: \(session)"
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
