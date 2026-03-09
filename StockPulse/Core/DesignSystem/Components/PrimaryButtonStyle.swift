//
//  PrimaryButtonStyle.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

// TODO: Add pressed / loading / disabled states; wire to Color.spPrimary once asset is added
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.spBodyBold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        // TODO: Replace accentColor with Color.spPrimary
    }
}

#Preview {
    Button("Sign In") {}
        .buttonStyle(PrimaryButtonStyle())
        .padding()
}
