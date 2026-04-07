//
//  UseMaterialsView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//

import SwiftUI
import SwiftData

struct UseMaterialsView: View {
    let item: Item

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var materials: [Material]

    // Tracks the quantity for each selected material (keyed by persistent model ID)
    @State private var selectedQuantities: [PersistentIdentifier: Double] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build This")
                .font(.headline)

            if materials.isEmpty {
                Text("No materials available.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(materials) { material in
                            MaterialUsageRow(
                                material: material,
                                quantity: binding(for: material)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 400)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveTransactions()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedQuantities.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 400)
    }

    private func binding(for material: Material) -> Binding<Double?> {
        Binding<Double?>(
            get: { selectedQuantities[material.persistentModelID] },
            set: { newValue in
                if let value = newValue {
                    selectedQuantities[material.persistentModelID] = value
                } else {
                    selectedQuantities.removeValue(forKey: material.persistentModelID)
                }
            }
        )
    }

    private func saveTransactions() {
        let now = Date()
        for (id, quantity) in selectedQuantities where quantity > 0 {
            guard let material = materials.first(where: { $0.persistentModelID == id }) else { continue }
            let transaction = MaterialTransaction(
                item: item,
                material: material,
                quantity: quantity,
                date: now,
                type: .use
            )
            modelContext.insert(transaction)
        }
        dismiss()
    }
}

// MARK: - Row for a single material with toggle + quantity

private struct MaterialUsageRow: View {
    let material: Material
    @Binding var quantity: Double?

    private var isSelected: Bool { quantity != nil }

    private var circleColor: Color {
        if let hex = material.colorValue {
            return Color(hex: hex)
        }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { isSelected },
                set: { selected in
                    quantity = selected ? 1.0 : nil
                }
            )) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 16, height: 16)
                    Text(material.colorName)
                    Text(material.type.label)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .toggleStyle(.checkbox)

            if isSelected {
                HStack {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)
                    TextField("Quantity", value: Binding(
                        get: { quantity ?? 0 },
                        set: { quantity = $0 }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }
                .padding(.leading, 28)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
