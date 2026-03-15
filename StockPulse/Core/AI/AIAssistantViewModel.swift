//
//  AIAssistantViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import Combine
import OSLog

// MARK: - TranscriptMessage

struct TranscriptMessage: Identifiable {
    enum Role { case user, assistant, system }
    let id        = UUID()
    let role:      Role
    var text:      String
    let timestamp: Date

    init(role: Role, text: String) {
        self.role      = role
        self.text      = text
        self.timestamp = Date()
    }
}

// MARK: - Protocol

protocol AIAssistantViewModelProtocol: ObservableObject {
    var messages:      [TranscriptMessage] { get }
    var isConnected:   Bool                { get }
    var isListening:   Bool                { get }
    var isGPTSpeaking: Bool                { get }
    var statusMessage: String              { get }
    var errorMessage:  String?             { get }
    @MainActor func connect()    async
    @MainActor func disconnect() async
}

// MARK: - ViewModel

final class AIAssistantViewModel: ObservableObject, AIAssistantViewModelProtocol {

    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "AI.ViewModel"
    )

    private let sessionManager: RealtimeSessionManager
    private let webRTCManager:  WebRTCManager

    @Published var messages:      [TranscriptMessage] = []
    @Published var isConnected:   Bool   = false
    @Published var isListening:   Bool   = false
    @Published var isGPTSpeaking: Bool   = false
    @Published var statusMessage: String = "Tap to connect"
    @Published var errorMessage:  String?

    private var cancellables = Set<AnyCancellable>()

    init(
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol
    ) {
        let toolsManager = StockToolsManager(
            fetchStockUseCase:          fetchStockUseCase,
            searchStocksUseCase:        searchStocksUseCase,
            fetchWatchlistUseCase:      fetchWatchlistUseCase,
            addToWatchlistUseCase:      addToWatchlistUseCase,
            removeFromWatchlistUseCase: removeFromWatchlistUseCase
        )

        self.sessionManager = RealtimeSessionManager()
        self.webRTCManager  = WebRTCManager(stockToolsManager: toolsManager)

        setupBindings()
    }

    // MARK: - Public

    @MainActor
    func connect() async {
        statusMessage = "Connecting..."
        errorMessage  = nil

        await sessionManager.fetchEphemeralToken()

        guard let token = sessionManager.sessionToken else {
            errorMessage  = sessionManager.errorMessage ?? "Failed to get token"
            statusMessage = "Connection failed"
            return
        }

        await webRTCManager.startSession(token: token)
    }

    @MainActor
    func disconnect() async {
        webRTCManager.disconnect()
        messages.removeAll()
        statusMessage = "Tap to connect"
        errorMessage  = nil
    }

    // MARK: - Private

    private func setupBindings() {
        webRTCManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isConnected   = self.webRTCManager.isConnected
                    self.isListening   = self.webRTCManager.isListening
                    self.isGPTSpeaking = self.webRTCManager.isGPTSpeaking
                    self.statusMessage = self.webRTCManager.statusMessage
                    self.messages      = self.webRTCManager.messages
                }
            }
            .store(in: &cancellables)
    }
}
