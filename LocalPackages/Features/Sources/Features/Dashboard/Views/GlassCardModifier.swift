//
//  GlassCardModifier.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

// MARK: - GlassCardModifier

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26, *) {
                content
                    .glassEffect()
            } else {
                content
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - View extension

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
