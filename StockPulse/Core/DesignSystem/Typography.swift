//
//  Typography.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

// TODO: Replace with custom font family once brand fonts are decided; wire Dynamic Type
extension Font {
    // MARK: - Display
    static let spLargeTitle = Font.largeTitle.weight(.bold)
    static let spTitle = Font.title.weight(.semibold)
    static let spTitle2 = Font.title2.weight(.semibold)

    // MARK: - Body
    static let spBody = Font.body
    static let spBodyBold = Font.body.weight(.semibold)
    static let spCaption = Font.caption
    static let spCaption2 = Font.caption2
}
