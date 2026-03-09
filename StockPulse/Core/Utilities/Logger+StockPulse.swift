//
//  Logger+StockPulse.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import OSLog

// TODO: Add log-level filtering based on build configuration (DEBUG / RELEASE)
extension Logger {
    private static let subsystem = "com.sweta.stockpulse"

    static let network = Logger(subsystem: subsystem, category: "Network")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let useCase = Logger(subsystem: subsystem, category: "UseCase")
}
