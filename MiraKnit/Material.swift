//
//  Material.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//
import Foundation
import SwiftData
import SwiftUI

enum MaterialType: Codable, CaseIterable, Sendable {
    case paracord
    case buckle
    case brace
    case other

    var label: String {
        switch self {
        case .paracord: "Paracord"
        case .buckle: "Buckle"
        case .brace: "Brace"
        case .other: "Other"
        }
    }
}

@Model
final class Material {
    var colorName: String = ""
    var colorValue: String?
    var type: MaterialType = MaterialType.other
    var size: Float?
    var totalLength: Float?
    var currentLength: Float?
    @Attribute(.externalStorage) var thumbnail: Data?
    
    init(colorName: String, type: MaterialType) {
        self.colorName = colorName
        self.type = type
    }
}
