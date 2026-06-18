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
    @Bindable var item: Item

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var playbackSpeed: Float = 1.0
    @State private var volume: Float = 1.0
    @State private var isEditing = false
    @State private var isBuildingThis = false
    @State private var showDownloadError = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isScrubbing = false
    @State private var timeObserverToken: Any?
    @State private var isDetached = false
    @State private var detachedWindow: NSWindow?
    @State private var detachedEventMonitor: Any?
    @State private var playerStatusObserver: NSKeyValueObservation?
    @FocusState private var keyboardFocused: Bool

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

            if item.isDownloading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Downloading video…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let player {
                Group {
                    if isDetached {
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Playing in separate window")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.windowBackgroundColor))
                    } else {
                        PlayerView(player: player)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    Button {
                        if isDetached {
                            reattachPlayer()
                        } else {
                            detachPlayer(player: player)
                        }
                    } label: {
                        Image(systemName: isDetached ? "pip.exit" : "pip.enter")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .buttonStyle(.borderless)
                    .padding(12)
                    .help(isDetached ? "Embed player" : "Open in separate window")
                }

                // Progress bar
                Slider(
                    value: $currentTime,
                    in: 0...max(duration, 0.001),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing {
                            let newTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                            player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
                            keyboardFocused = true
                        }
                    }
                )
                .disabled(duration <= 0)
                .padding(.horizontal, 20)
                .padding(.top, 8)

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
                                keyboardFocused = true
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
                        keyboardFocused = true
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
        .focusable()
        .focused($keyboardFocused)
        .focusEffectDisabled()
        .onKeyPress(.space) {
            togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            skip(by: -5)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            skip(by: 5)
            return .handled
        }
        .task(id: item.id) {
            setupPlayer()
            keyboardFocused = true
        }
        .onDisappear {
            closeDetachedWindow()
            removeTimeObserver()
            playerStatusObserver?.invalidate()
            playerStatusObserver = nil
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $isBuildingThis) {
            UseMaterialsView(item: item)
        }
        .onChange(of: item.isDownloading) {
            if !item.isDownloading && item.downloadError == nil {
                setupPlayer()
            }
        }
        .onChange(of: item.downloadError) {
            showDownloadError = item.downloadError != nil
        }
        .alert("Download Failed", isPresented: $showDownloadError) {
            Button("OK") {
                item.downloadError = nil
            }
        } message: {
            Text(item.downloadError ?? "An unknown error occurred.")
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
        closeDetachedWindow()
        removeTimeObserver()
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        guard !item.isDownloading,
              let videoURL = item.videoFilePath,
              FileManager.default.fileExists(atPath: videoURL.path) else {
            player = nil
            return
        }
        let newPlayer = AVPlayer(url: videoURL)
        newPlayer.defaultRate = playbackSpeed
        newPlayer.volume = volume
        player = newPlayer
        isPlaying = false
        currentTime = 0
        duration = 0
        addPeriodicTimeObserver(to: newPlayer)
        playerStatusObserver = newPlayer.observe(\.timeControlStatus, options: [.new]) { observed, _ in
            DispatchQueue.main.async {
                isPlaying = observed.timeControlStatus != .paused
            }
        }
        Task { @MainActor in
            if let assetDuration = try? await newPlayer.currentItem?.asset.load(.duration) {
                let seconds = assetDuration.seconds
                if seconds.isFinite {
                    duration = seconds
                }
            }
        }
    }

    private func addPeriodicTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !isScrubbing {
                currentTime = time.seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
    }

    private func togglePlayPause() {
        guard let player else { return }
        if player.timeControlStatus == .paused {
            player.rate = playbackSpeed
        } else {
            player.pause()
        }
    }

    private func skip(by seconds: Double) {
        guard let player, let currentTime = player.currentItem?.currentTime() else { return }
        let newTime = CMTime(
            seconds: currentTime.seconds + seconds,
            preferredTimescale: currentTime.timescale
        )
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func detachPlayer(player: AVPlayer) {
        let rootView = PlayerView(player: player)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = item.title ?? "Player"
        window.setContentSize(NSSize(width: 800, height: 600))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            isDetached = false
            detachedWindow = nil
            if let monitor = detachedEventMonitor {
                NSEvent.removeMonitor(monitor)
                detachedEventMonitor = nil
            }
        }

        detachedEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.window === window else { return event }
            switch event.keyCode {
            case 49: // space
                togglePlayPause()
                return nil
            case 123: // left arrow
                skip(by: -5)
                return nil
            case 124: // right arrow
                skip(by: 5)
                return nil
            default:
                return event
            }
        }

        detachedWindow = window
        isDetached = true
    }

    private func reattachPlayer() {
        closeDetachedWindow()
    }

    private func closeDetachedWindow() {
        detachedWindow?.close()
        detachedWindow = nil
        isDetached = false
        if let monitor = detachedEventMonitor {
            NSEvent.removeMonitor(monitor)
            detachedEventMonitor = nil
        }
    }
}
