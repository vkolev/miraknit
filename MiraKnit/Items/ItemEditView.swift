//
//  ItemEditView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//
import SwiftUI
import AVKit

struct ItemEditView: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss

    @State private var editTitle: String = ""
    @State private var editContent: String = ""
    @State private var thumbnailImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Item")
                .font(.headline)

            TextField("Title", text: $editTitle)
                .textFieldStyle(.roundedBorder)

            // Thumbnail
            VStack(alignment: .leading, spacing: 8) {
                Text("Thumbnail")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if let thumbnailImage {
                        Image(nsImage: thumbnailImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                            .frame(width: 120, height: 68)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }

                    Button("Choose Image...") {
                        chooseThumbnail()
                    }
                }
            }

            // Content / Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (Markdown)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $editContent)
                    .font(.body.monospaced())
                    .frame(minHeight: 150)
                    .border(Color.secondary.opacity(0.3))
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 400)
        .onAppear {
            editTitle = item.title ?? ""
            editContent = item.content ?? ""
            if let data = item.thumbnail, let img = NSImage(data: data) {
                thumbnailImage = img
            }
        }
    }

    private func chooseThumbnail() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                thumbnailImage = image
            }
        }
    }

    private func save() {
        item.title = editTitle.isEmpty ? nil : editTitle
        item.content = editContent.isEmpty ? nil : editContent

        if let thumbnailImage {
            item.thumbnail = thumbnailImage.tiffRepresentation.flatMap {
                NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
            }
        }

        dismiss()
    }
}
