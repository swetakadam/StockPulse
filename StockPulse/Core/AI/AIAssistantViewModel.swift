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
    var isMuted:       Bool                { get }
    var statusMessage: String              { get }
    var errorMessage:  String?             { get }
    @MainActor func connect()    async
    @MainActor func disconnect() async
    func toggleMute()
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
    @Published var isMuted:       Bool   = false
    @Published var statusMessage: String = "Tap to connect"
    @Published var errorMessage:  String?

    private var cancellables = Set<AnyCancellable>()
    private var lastWebRTCSyncCount: Int = 0
    // Paired indices for the currently-streaming assistant bubble.
    // webRTCManager replaces the struct on every delta (new UUID each time), and
    // non-assistant messages (tool bubbles, user messages) can be appended after it,
    // so we must track the exact array positions in both arrays rather than using .last.
    private var streamingMessageIndex: Int? = nil   // position in self.messages
    private var streamingWebRTCIndex: Int? = nil    // position in webRTCManager.messages
    // Slot reserved for user transcription. Inserted on speech_stopped (before the model
    // responds) so the bubble appears in the correct chronological position. Filled when
    // whisper transcription arrives (which is always late — after the assistant response).
    private var pendingUserBubbleIndex: Int? = nil

    init(
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol,
        agentOrchestrator:          AgentOrchestrator
    ) {
        let toolsManager = StockToolsManager(
            fetchStockUseCase:          fetchStockUseCase,
            searchStocksUseCase:        searchStocksUseCase,
            fetchWatchlistUseCase:      fetchWatchlistUseCase,
            addToWatchlistUseCase:      addToWatchlistUseCase,
            removeFromWatchlistUseCase: removeFromWatchlistUseCase,
            agentOrchestrator:          agentOrchestrator
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

    func toggleMute() {
        webRTCManager.toggleMute()
    }

    @MainActor
    func disconnect() async {
        webRTCManager.disconnect()
        messages.removeAll()
        lastWebRTCSyncCount   = 0
        streamingMessageIndex = nil
        streamingWebRTCIndex  = nil
        pendingUserBubbleIndex = nil
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
                    self.isMuted       = self.webRTCManager.isMuted
                    self.statusMessage = self.webRTCManager.statusMessage

                    let webRTCMessages = self.webRTCManager.messages

                    // Streaming delta: WebRTCManager replaces the struct (new UUID each delta),
                    // so track position rather than identity. Use streamingWebRTCIndex to read
                    // the correct WebRTC message — .last would point to a tool bubble if one
                    // was appended after the assistant bubble.
                    if webRTCMessages.count == self.lastWebRTCSyncCount,
                       let selfIdx = self.streamingMessageIndex,
                       let webRTCIdx = self.streamingWebRTCIndex,
                       webRTCIdx < webRTCMessages.count,
                       selfIdx < self.messages.count,
                       self.messages[selfIdx].text != webRTCMessages[webRTCIdx].text {
                        self.messages[selfIdx].text = webRTCMessages[webRTCIdx].text
                    }

                    // Append new WebRTC messages and refresh the streaming indices
                    let newMessages = Array(webRTCMessages.dropFirst(self.lastWebRTCSyncCount))
                    if !newMessages.isEmpty {
                        let insertBase = self.messages.count
                        let previousSyncCount = self.lastWebRTCSyncCount
                        self.messages.append(contentsOf: newMessages)
                        self.lastWebRTCSyncCount = webRTCMessages.count
                        // Track whichever new message is the assistant bubble for streaming
                        for (offset, msg) in newMessages.enumerated() where msg.role == .assistant {
                            self.streamingMessageIndex = insertBase + offset
                            self.streamingWebRTCIndex  = previousSyncCount + offset
                        }
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: .agentStepProgress,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let msg = note.userInfo?["message"] as? String else { return }
            self.messages.append(TranscriptMessage(role: .system, text: msg))
        }

        // Insert a "..." placeholder at the current position the moment the user stops
        // speaking — before the model responds — so the bubble lands in the right order.
        NotificationCenter.default.addObserver(
            forName: .userSpeechStopped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.pendingUserBubbleIndex = self.messages.count
            self.messages.append(TranscriptMessage(role: .user, text: "..."))
        }

        // When whisper finishes (always late), fill in the placeholder in place.
        NotificationCenter.default.addObserver(
            forName: .userTranscriptReady,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let transcript = note.userInfo?["transcript"] as? String else { return }
            if let idx = self.pendingUserBubbleIndex, idx < self.messages.count {
                self.messages[idx].text = transcript
                self.pendingUserBubbleIndex = nil
            }
        }

        NotificationCenter.default.addObserver(
            forName: .sessionSilenceTimeout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.messages.append(TranscriptMessage(
                role: .system,
                text: "Session ended after 1 minute of silence."
            ))
            Task { @MainActor [weak self] in
                await self?.disconnect()
            }
        }
    }
}
