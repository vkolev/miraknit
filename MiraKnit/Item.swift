//
//  Item.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String?
    var link: URL
    var content: String?
    var timestamp: Date
    var isDownloading: Bool = true
    @Attribute(.externalStorage) var thumbnail: Data?
    
    init(timestamp: Date, link: URL) {
        self.link = link
        self.timestamp = timestamp
    }

    /// Extracts the YouTube video ID from the link URL.
    var videoID: String? {
        // youtu.be/VIDEO_ID
        if link.host?.contains("youtu.be") == true {
            return link.pathComponents.dropFirst().first
        }

        // youtube.com/watch?v=VIDEO_ID
        if let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
           let value = components.queryItems?.first(where: { $0.name == "v" })?.value,
           !value.isEmpty {
            return value
        }

        // youtube.com/embed/VIDEO_ID or youtube.com/shorts/VIDEO_ID
        if link.host?.contains("youtube.com") == true {
            let path = link.pathComponents
            if let idx = path.firstIndex(where: { $0 == "embed" || $0 == "shorts" }),
               idx + 1 < path.count {
                return path[idx + 1]
            }
        }

        return nil
    }

    /// The local directory for this video's files.
    var videoDirectory: URL? {
        guard let videoID else { return nil }
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("MiraKnit/Downloads/\(videoID)")
    }

    /// The local file path for the downloaded video.
    var videoFilePath: URL? {
        videoDirectory?.appendingPathComponent("video.mp4")
    }
}
