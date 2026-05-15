import SwiftUI
import SwiftData

enum DataCategory: String, CaseIterable {
    case items = "Items"
    case materials = "Materials"
}

struct ContentView: View {
    @Environment(DeepLinkManager.self) private var deepLinkManager
    @State private var selectedCategory: DataCategory = .items

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(DataCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Spacer()
            }

            switch selectedCategory {
            case .items:
                ItemListView()
            case .materials:
                MaterialListView()
            }
        }
        .onChange(of: deepLinkManager.pendingURL) {
            if deepLinkManager.pendingURL != nil {
                selectedCategory = .items
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(DeepLinkManager())
        .modelContainer(for: [Item.self, Material.self, MaterialTransaction.self], inMemory: true)
}
