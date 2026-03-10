//
//  RouterProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

/// Full router capability: coordinator + observable navigation state.
protocol RouterProtocol: CoordinatorProtocol, ObservableObject {
    var path: NavigationPath { get set }
    var presentedSheet: SheetRoute? { get set }
    var presentedFullScreen: SheetRoute? { get set }
    var activeDetent: PresentationDetent { get set }

    func presentSheet(_ route: SheetRoute)
    func presentFullScreen(_ route: SheetRoute)
    func dismissSheet()
    func dismissFullScreen()
    func setDetent(_ detent: PresentationDetent)
}
