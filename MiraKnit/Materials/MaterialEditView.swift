//
//  MaterialEditView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//


import SwiftUI
import ColorSelector

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
