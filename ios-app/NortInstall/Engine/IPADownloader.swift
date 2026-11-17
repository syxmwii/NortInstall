import Foundation

struct DownloadProgress: Equatable {
    let bytesWritten: Int64
    let totalBytes: Int64?

    /// 0…1, если сервер сообщил размер.
    var fraction: Double? {
        totalBytes.flatMap { $0 > 0 ? Double(bytesWritten) / Double($0) : nil }
    }
}

/// Скачивание IPA с прогрессом. Хранит файл во временной папке.
enum IPADownloader {
    static func download(
        _ source: URL,
        onProgress: @escaping (DownloadProgress) -> Void
    ) async throws -> URL {
        let (bytes, response) = try await URLSession.shared.bytes(from: source)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.downloadFailed("сервер ответил \(response)")
        }

        let expected = response.expectedContentLength > 0 ? response.expectedContentLength : nil
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("ipa")

        var data = Data()
        data.reserveCapacity(expected.map(Int.init) ?? 1 << 20)

        var sinceLastUpdate = 0
        for try await byte in bytes {
            data.append(byte)
            sinceLastUpdate += 1
            // обновляем прогресс не чаще, чем раз в 256 КБ
            if sinceLastUpdate >= 262_144 {
                sinceLastUpdate = 0
                onProgress(DownloadProgress(bytesWritten: Int64(data.count), totalBytes: expected))
            }
        }
        onProgress(DownloadProgress(bytesWritten: Int64(data.count), totalBytes: expected))

        try data.write(to: destination, options: .atomic)
        return destination
    }
}
