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

// MARK: - Material Edit

struct MaterialEditView: View {
    let material: Material

    @Environment(\.dismiss) private var dismiss
    @State private var colorName: String = ""
    @State private var color: Color? = .clear
    @State private var type: MaterialType = .paracord
    @State private var size: Double = 0.0
    @State private var totalLength: Double = 0.0

    private var sizeLabel: String {
        switch type {
        case .buckle: "Width"
        default: "Size"
        }
    }

    private var lengthLabel: String {
        switch type {
        case .buckle, .brace: "Count"
        default: "Length"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Material")
                .font(.headline)

            HStack {
                Text("Color Name").frame(width: 150)
                Spacer()
                TextField("Color Name", text: $colorName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Color").frame(width: 150)
                Spacer()
                ColorSelector(selection: $color)
            }

            Picker(selection: $type, label: Text("Type").frame(width: 150)) {
                ForEach(MaterialType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }

            HStack {
                Text(sizeLabel).frame(width: 150)
                Spacer()
                TextField(sizeLabel, value: $size, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Initial \(lengthLabel)").frame(width: 150)
                Spacer()
                TextField("Initial \(lengthLabel)", value: $totalLength, format: .number)
                    .textFieldStyle(.roundedBorder)
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
                .disabled(colorName.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 360)
        .onAppear {
            colorName = material.colorName
            type = material.type
            size = Double(material.size ?? 0)
            totalLength = Double(material.totalLength ?? 0)
            if let hex = material.colorValue {
                color = Color(hex: hex)
            } else {
                color = .clear
            }
        }
    }

    private func save() {
        material.colorName = colorName
        material.type = type
        material.size = size != 0 ? Float(size) : nil
        material.totalLength = totalLength != 0 ? Float(totalLength) : nil
        if color != .clear {
            material.colorValue = color?.toHex()
        } else {
            material.colorValue = nil
        }
        dismiss()
    }
}
// MARK: - Transaction Edit

struct TransactionEditView: View {
    let transaction: MaterialTransaction

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double = 0
    @State private var type: TransactionType = .use
    @State private var date: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Transaction")
                .font(.headline)

            Picker(selection: $type, label: Text("Type").frame(width: 150)) {
                Text(TransactionType.topUp.label).tag(TransactionType.topUp)
                Text(TransactionType.use.label).tag(TransactionType.use)
            }

            HStack {
                Text("Quantity").frame(width: 150)
                Spacer()
                TextField("Quantity", value: $quantity, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            DatePicker("Date", selection: $date, displayedComponents: .date)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    transaction.quantity = quantity
                    transaction.type = type
                    transaction.date = date
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(quantity <= 0)
            }
        }
        .padding(20)
        .frame(minWidth: 320)
        .onAppear {
            quantity = transaction.quantity
            type = transaction.type
            date = transaction.date
        }
    }
}

