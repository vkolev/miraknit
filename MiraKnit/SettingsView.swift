//
//  SettingsView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//

import SwiftUI

enum SettingsKeys {
    static let ytDlpPath = "ytDlpPath"
    static let ffmpegPath = "ffmpegPath"

    static let defaultYtDlpPath = "/opt/homebrew/bin/yt-dlp"
    static let defaultFfmpegPath = "/opt/homebrew/bin/ffmpeg"
}

struct SettingsView: View {
    @AppStorage(SettingsKeys.ytDlpPath) private var ytDlpPath = SettingsKeys.defaultYtDlpPath
    @AppStorage(SettingsKeys.ffmpegPath) private var ffmpegPath = SettingsKeys.defaultFfmpegPath

    var body: some View {
        Form {
            Section("Tool Paths") {
                HStack {
                    TextField("yt-dlp", text: $ytDlpPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        if let path = browseForFile() {
                            ytDlpPath = path
                        }
                    }
                }

                HStack {
                    TextField("ffmpeg", text: $ffmpegPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        if let path = browseForFile() {
                            ffmpegPath = path
                        }
                    }
                }
            }

            Section {
                Button("Reset to Defaults") {
                    ytDlpPath = SettingsKeys.defaultYtDlpPath
                    ffmpegPath = SettingsKeys.defaultFfmpegPath
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 450)
        .padding()
    }

    private func browseForFile() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url.path
    }
}
