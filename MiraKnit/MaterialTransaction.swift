//
//  MaterialTransaction.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 07.04.26.
//
import SwiftData
import Foundation

@Model
final class MaterialTransaction {
    var item: Item?
    var material: Material
    var quantity: Double
    var date: Date
    var type: TransactionType
    
    init(item: Item?, material: Material, quantity: Double, date: Date, type: TransactionType) {
        self.item = item
        self.material = material
        self.quantity = quantity
        self.date = date
        self.type = type
    }
}

enum TransactionType: String, Codable, Sendable {
    case use
    case topUp
    
    var label: String {
        switch self {
            case .use: "Use"
            case .topUp: "Top Up"
        }
    }
}
