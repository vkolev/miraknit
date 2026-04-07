//
//  MaterialDetailView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import SwiftUI
import SwiftData
import ColorSelector

struct MaterialDetailView: View {
    let material: Material

    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var isToppingUp = false
    @State private var topUpAmount: Double = 0
    @State private var editingTransaction: MaterialTransaction?

    @Query private var transactions: [MaterialTransaction]

    init(material: Material) {
        self.material = material
        let id = material.persistentModelID
        _transactions = Query(
            filter: #Predicate<MaterialTransaction> { $0.material.persistentModelID == id }
        )
    }

    private var totalTopUps: Double {
        transactions
            .filter { $0.type == .topUp }
            .reduce(0) { $0 + $1.quantity }
    }

    private var totalUsage: Double {
        transactions
            .filter { $0.type == .use }
            .reduce(0) { $0 + $1.quantity }
    }

    private var startingStock: Double {
        Double(material.totalLength ?? 0)
    }

    private var currentStock: Double {
        startingStock + totalTopUps - totalUsage
    }

    private var stockFraction: Double? {
        let total = startingStock + totalTopUps
        guard total > 0 else { return nil }
        return max(0, min(1, currentStock / total))
    }

    private var sortedTransactions: [MaterialTransaction] {
        transactions.sorted { $0.date > $1.date }
    }

    private var lengthLabel: String {
        switch material.type {
        case .buckle, .brace: "Count"
        default: "Length"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(material.colorName)
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    isToppingUp = true
                } label: {
                    Label("Top Up", systemImage: "plus.circle")
                }

                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            LabeledContent("Type") {
                Text(material.type.label)
            }

            if let size = material.size {
                LabeledContent("Size") {
                    Text("\(size, specifier: "%.1f")")
                }
            }

                LabeledContent("Total Available \(lengthLabel)") {
                Text("\(currentStock, specifier: "%.1f")")
                    .fontWeight(.semibold)
                    .foregroundStyle(currentStock > 0 ? Color.primary : Color.red)
            }

            if let fraction = stockFraction {
                ProgressView(value: fraction)
                    .tint(fraction > 0.25 ? .accentColor : .red)
            }

            Divider()

            Text("Transactions")
                .font(.headline)

            if sortedTransactions.isEmpty {
                Text("No transactions yet.")
                    .foregroundStyle(.secondary)
            } else {
                List(sortedTransactions) { transaction in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transaction.type.label)
                                .fontWeight(.medium)
                            if let item = transaction.item {
                                Text(item.title ?? "Unknown")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(transaction.type == .topUp ? "+\(transaction.quantity, specifier: "%.1f")" : "-\(transaction.quantity, specifier: "%.1f")")
                            .foregroundStyle(transaction.type == .topUp ? Color.green : Color.red)
                            .fontWeight(.medium)

                        Text(transaction.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            editingTransaction = transaction
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isEditing) {
            MaterialEditView(material: material)
        }
        .sheet(isPresented: $isToppingUp) {
            topUpSheet
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionEditView(transaction: transaction)
        }
    }

    private var topUpSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Up \(material.colorName)")
                .font(.headline)

            HStack {
                Text(lengthLabel).frame(width: 150)
                Spacer()
                TextField(lengthLabel, value: $topUpAmount, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    topUpAmount = 0
                    isToppingUp = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    let transaction = MaterialTransaction(
                        item: nil,
                        material: material,
                        quantity: topUpAmount,
                        date: Date(),
                        type: .topUp
                    )
                    modelContext.insert(transaction)
                    topUpAmount = 0
                    isToppingUp = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(topUpAmount <= 0)
            }
        }
        .padding(20)
        .frame(minWidth: 320)
    }
}




