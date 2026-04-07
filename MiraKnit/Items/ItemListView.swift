//
//  ItemListView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Item> { $0.isDownloading == false }) private var items: [Item]
    @State private var searchText = ""
    @State private var selectedItemID: Item.ID?
    @State private var isAddingItem = false
    @State private var newItemTitle = ""
    @State private var newItemURL = ""

    private let downloadService = DownloadService()

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItemID) {
                ForEach(items) { item in
                    ItemRowView(item: item)
                        .tag(item.id)
                }
                .onDelete(perform: deleteItems)
            }
            .searchable(text: $searchText, prompt: "Search...")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button { isAddingItem = true } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        if let selectedItemID,
                           let item = items.first(where: { $0.id == selectedItemID }) {
                            deleteItem(item)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedItemID == nil)
                }
            }
        } detail: {
            if let selectedItemID,
               let item = items.first(where: { $0.id == selectedItemID }) {
                ItemDetailView(item: item)
            } else {
                Text("Select an item")
            }
        }
        .sheet(isPresented: $isAddingItem) {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Item")
                    .font(.headline)

                TextField("Title", text: $newItemTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("URL", text: $newItemURL)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        isAddingItem = false
                        newItemTitle = ""
                        newItemURL = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Add") {
                        addItem()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newItemURL.isEmpty)
                }
            }
            .padding(20)
            .frame(minWidth: 360)
        }
    }

    private func addItem() {
        guard let url = URL(string: newItemURL) else { return }
        let newItem = Item(timestamp: Date(), link: url)
        newItem.title = newItemTitle.isEmpty ? nil : newItemTitle
        withAnimation {
            modelContext.insert(newItem)
        }
        isAddingItem = false
        newItemTitle = ""
        newItemURL = ""

        startDownload(for: newItem)
    }

    private func startDownload(for item: Item) {
        guard let outputPath = item.videoFilePath,
              let directory = item.videoDirectory else {
            item.isDownloading = false
            return
        }

        let url = item.link

        Task {
            do {
                try await downloadService.downloadVideo(url: url, to: outputPath)
                let thumbnailData = await downloadService.downloadThumbnail(url: url, to: directory)
                await MainActor.run {
                    item.thumbnail = thumbnailData
                    item.isDownloading = false
                }
            } catch {
                print("Download failed: \(error.localizedDescription)")
                await MainActor.run {
                    item.isDownloading = false
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                deleteItem(items[index])
            }
        }
    }

    private func deleteItem(_ item: Item) {
        if let directory = item.videoDirectory {
            try? FileManager.default.removeItem(at: directory)
        }

        if selectedItemID == item.id {
            selectedItemID = nil
        }

        modelContext.delete(item)
    }
}
