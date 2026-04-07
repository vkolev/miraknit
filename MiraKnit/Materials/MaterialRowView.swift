//
//  MaterialRowView.swift
//  MiraKnit
//
//  Created by Vladimir Kolev on 02.04.26.
//

import SwiftUI

struct MaterialRowView: View {
    let material: Material

    private var circleColor: Color {
        if let hex = material.colorValue {
            return Color(hex: hex)
        }
        return .secondary
    }

    /// Fraction of stock remaining: 1.0 = full, 0.0 = fully used.
    private var remainingFraction: Double? {
        guard let total = material.totalLength, total > 0 else { return nil }
        let used = Double(material.currentLength ?? 0)
        return max(0, min(1, (Double(total) - used) / Double(total)))
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(circleColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(material.colorName) \(String(material.size!))")
                    .font(.headline)
                    .lineLimit(1)

                if let fraction = remainingFraction {
                    ProgressView(value: fraction)
                        .tint(fraction > 0.25 ? .accentColor : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
