//
//  AIAssistantView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct AIAssistantView<ViewModel: AIAssistantViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            transcriptView
            controlPanel
        }
        .navigationTitle("Stock Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isConnected ? Color(.systemGreen) : Color(.systemGray))
                .frame(width: 10, height: 10)
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if viewModel.isConnected {
                Button("Disconnect") {
                    Task { await viewModel.disconnect() }
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Transcript

    private var transcriptView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty && !viewModel.isConnected {
                        emptyState
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isGPTSpeaking {
                        TypingIndicator()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Stock Assistant")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Ask me about stock prices,\nmanage your watchlist,\nor navigate to any stock.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Control Panel

    private var controlPanel: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                if viewModel.isConnected {
                    Task { await viewModel.disconnect() }
                } else {
                    Task { await viewModel.connect() }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isConnected
                          ? "stop.circle.fill"
                          : "mic.circle.fill")
                        .font(.title2)
                    Text(viewModel.isConnected ? "Stop Session" : "Start Voice Session")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.isConnected ? Color(.systemRed) : Color(.systemBlue))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: TranscriptMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading,
                   spacing: 4) {
                Text(roleLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: 280,
                   alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user { Spacer() }
        }
    }

    private var roleLabel: String {
        switch message.role {
        case .user:      return "You"
        case .assistant: return "Assistant"
        case .system:    return "System"
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user:      return Color(.systemBlue)
        case .assistant: return Color(.systemGray5)
        case .system:    return Color(.systemOrange).opacity(0.2)
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { animating = true }
    }
}

// MARK: - Preview Mock

private final class MockAIAssistantViewModel: ObservableObject,
                                              AIAssistantViewModelProtocol {
    @Published var messages: [TranscriptMessage] = [
        TranscriptMessage(role: .user,      text: "What is Apple stock price?"),
        TranscriptMessage(role: .system,    text: "🔧 Calling get_stock_price(AAPL)..."),
        TranscriptMessage(role: .assistant, text: "Apple is trading at $250.12, down 2.21% today.")
    ]
    @Published var isConnected:   Bool    = true
    @Published var isListening:   Bool    = false
    @Published var isGPTSpeaking: Bool    = false
    @Published var statusMessage: String  = "🟢 Connected — speak now!"
    @Published var errorMessage:  String? = nil

    func connect()    async {}
    func disconnect() async {}
}

#Preview {
    NavigationStack {
        AIAssistantView(viewModel: MockAIAssistantViewModel())
    }
}
