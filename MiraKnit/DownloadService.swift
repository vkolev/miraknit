//
//  DownloadService.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import Foundation

actor DownloadService {

    private nonisolated var ytDlpPath: String {
        UserDefaults.standard.string(forKey: "ytDlpPath") ?? "/opt/homebrew/bin/yt-dlp"
    }

    private nonisolated var ffmpegPath: String {
        UserDefaults.standard.string(forKey: "ffmpegPath") ?? "/opt/homebrew/bin/ffmpeg"
    }

    /// Downloads a video from the given URL to the specified output path.
    func downloadVideo(url: URL, to outputPath: URL) async throws {
        // Create the output directory if needed
        let directory = outputPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        // Verify yt-dlp exists
        guard FileManager.default.isExecutableFile(atPath: ytDlpPath) else {
            throw DownloadError.ytDlpNotFound
        }

        // Run yt-dlp as a subprocess
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = [
            "-o", outputPath.path,
            "--merge-output-format", "mp4",
            url.absoluteString
        ]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()

        // Wait for completion without blocking a thread
        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        // Check exit status
        guard process.terminationStatus == 0 else {
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw DownloadError.processFailure(
                exitCode: process.terminationStatus,
                message: errorMessage
            )
        }
    }

    /// Downloads the YouTube thumbnail into the video's directory as "thumbnail.jpg".
    func downloadThumbnail(url: URL, to directory: URL) async -> Data? {
        guard FileManager.default.isExecutableFile(atPath: ytDlpPath) else { return nil }

        let thumbnailPath = directory.appendingPathComponent("thumbnail")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = [
            "--skip-download",
            "--write-thumbnail",
            "--ffmpeg-location", ffmpegPath,
            "--convert-thumbnails", "jpg",
            "-o", thumbnailPath.path,
            url.absoluteString
        ]

        do {
            try process.run()
            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
        } catch {
            print("Thumbnail download failed: \(error.localizedDescription)")
            return nil
        }

        // yt-dlp writes the file as thumbnail.jpg
        let jpgPath = directory.appendingPathComponent("thumbnail.jpg")
        return try? Data(contentsOf: jpgPath)
    }

    enum DownloadError: LocalizedError {
        case ytDlpNotFound
        case processFailure(exitCode: Int32, message: String)

        var errorDescription: String? {
            switch self {
            case .ytDlpNotFound:
                return "yt-dlp not found. Check the path in Settings."
            case .processFailure(let code, let message):
                return "yt-dlp exited with code \(code): \(message)"
            }
        }
    }
}
