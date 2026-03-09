//
//  RouterProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// TODO: Add sheet/fullScreenCover presentation helpers once navigation is fully designed
@MainActor
protocol RouterProtocol: AnyObject {
    func navigate(to route: AppRoute)
    func dismiss()
    func popToRoot()
}
