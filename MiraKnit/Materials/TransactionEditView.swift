//
//  TransactionEditView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//


import SwiftUI

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
