//
//  ItemDetailView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import SwiftUI
import AVKit

// MARK: - AVPlayerView wrapper with no built-in controls

struct PlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

// MARK: - Detail View

struct ItemDetailView: View {
    let item: Item

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var playbackSpeed: Float = 1.0
    @State private var volume: Float = 1.0
    @State private var isEditing = false
    @State private var isBuildingThis = false

    private let speeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title ?? "Untitled")
                        .font(.title)
                        .fontWeight(.bold)

                    Link(item.link.absoluteString, destination: item.link)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button {
                    isBuildingThis = true
                } label: {
                    Label("Build This", systemImage: "hammer")
                }

                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            .padding(20)

            if let player {
                PlayerView(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Playback controls
                HStack(spacing: 16) {
                    Button {
                        skip(by: -5)
                    } label: {
                        Image(systemName: "gobackward.5")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        togglePlayPause()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 24)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        skip(by: 5)
                    } label: {
                        Image(systemName: "goforward.5")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    // Volume control
                    HStack(spacing: 6) {
                        Image(systemName: volumeIcon)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Slider(value: $volume, in: 0...1)
                            .frame(width: 80)
                            .onChange(of: volume) {
                                player.volume = volume
                            }
                    }

                    // Speed picker
                    Picker("Speed", selection: $playbackSpeed) {
                        ForEach(speeds, id: \.self) { speed in
                            Text(speedLabel(speed))
                                .tag(speed)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .onChange(of: playbackSpeed) {
                        player.defaultRate = playbackSpeed
                        if isPlaying {
                            player.rate = playbackSpeed
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Notes section
                if let content = item.content, !content.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(content))
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            } else {
                ContentUnavailableView("Video not available", systemImage: "film")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: item.id) {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $isBuildingThis) {
            UseMaterialsView(item: item)
        }
        .sheet(isPresented: $isEditing) {
            ItemEditView(item: item)
        }
    }

    private var volumeIcon: String {
        if volume == 0 { return "speaker.slash.fill" }
        if volume < 0.33 { return "speaker.wave.1.fill" }
        if volume < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    private func speedLabel(_ speed: Float) -> String {
        speed == Float(Int(speed)) ? String(format: "%.0fx", speed) : String(format: "%.2gx", speed)
    }

    private func setupPlayer() {
        guard let videoURL = item.videoFilePath,
              FileManager.default.fileExists(atPath: videoURL.path) else {
            player = nil
            return
        }
        let newPlayer = AVPlayer(url: videoURL)
        newPlayer.defaultRate = playbackSpeed
        newPlayer.volume = volume
        player = newPlayer
        isPlaying = false
    }

    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.rate = playbackSpeed
        }
        isPlaying.toggle()
    }

    private func skip(by seconds: Double) {
        guard let player, let currentTime = player.currentItem?.currentTime() else { return }
        let newTime = CMTime(
            seconds: currentTime.seconds + seconds,
            preferredTimescale: currentTime.timescale
        )
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}
