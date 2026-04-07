//
//  MaterialListView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import SwiftUI
import SwiftData
import ColorSelector

struct MaterialListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var materials: [Material]
    @State private var searchText = ""
    @State private var selectedMaterialID: Material.ID?
    @State private var isAddingMaterial = false

    @State private var newColorName = ""
    @State private var newColor: Color? = .clear
    @State private var newType: MaterialType = .paracord
    @State private var newSize = 0.0
    @State private var newLength = 0.0
    
    @State private var sizeLabel = "Size"
    @State private var lengthLabel = "Length"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMaterialID) {
                ForEach(materials) { material in
                    MaterialRowView(material: material)
                        .tag(material.id)
                }
                .onDelete(perform: deleteMaterials)
            }
            .searchable(text: $searchText, prompt: "Search...")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button { isAddingMaterial = true } label: {
                        Label("Add Material", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        if let selectedMaterialID,
                           let material = materials.first(where: { $0.id == selectedMaterialID }) {
                            deleteMaterial(material)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedMaterialID == nil)
                }
            }
        } detail: {
            if let selectedMaterialID,
               let material = materials.first(where: { $0.id == selectedMaterialID }) {
                MaterialDetailView(material: material)
            } else {
                Text("Select a material")
            }
        }
        .sheet(isPresented: $isAddingMaterial) {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Material")
                    .font(.headline)

                HStack {
                    Text("Color Name").frame(width: 150)
                    Spacer()
                    TextField("Color Name", text: $newColorName)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Color").frame(width: 150)
                    Spacer()
                    ColorSelector(selection: $newColor)
                }

                Picker(selection: $newType, label: Text("Type").frame(width: 150)) {
                    ForEach(MaterialType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }.onChange(of: newType) { _, _ in
                    switch (newType) {
                    case .brace:
                        sizeLabel = "Size"
                        lengthLabel = "Count"
                    case .buckle:
                        sizeLabel = "Width"
                        lengthLabel = "Count"
                    default:
                        sizeLabel = "Size"
                        lengthLabel = "Length"
                    }
                }
                
                HStack {
                    Text(sizeLabel).frame(width: 150)
                    Spacer()
                    TextField(sizeLabel, value: $newSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text(lengthLabel).frame(width: 150)
                    Spacer()
                    TextField(lengthLabel, value: $newLength, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        isAddingMaterial = false
                        newColorName = ""
                        newType = .paracord
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Add") {
                        addMaterial()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newColorName.isEmpty)
                }
            }
            .padding(20)
            .frame(minWidth: 360)
        }
    }

    private func addMaterial() {
        let material = Material(colorName: newColorName, type: newType)
        if newSize != 0.0 {
            material.size = Float(newSize)
        }
        if newLength != 0.0 {
            material.totalLength = Float(newLength)
        }
        if newColor != .clear {
            material.colorValue = newColor?.toHex()
        }
        
        withAnimation {
            modelContext.insert(material)
        }
        
        isAddingMaterial = false
        newColorName = ""
        newType = .paracord
        newSize = 0.0
        newLength = 0.0
        newColor = .clear
    }

    private func deleteMaterials(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                deleteMaterial(materials[index])
            }
        }
    }

    private func deleteMaterial(_ material: Material) {
        if selectedMaterialID == material.id {
            selectedMaterialID = nil
        }
        modelContext.delete(material)
    }
}
