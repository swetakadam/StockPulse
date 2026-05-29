//
//  WebRTCManager.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import AVFoundation
import WebRTC
import OSLog

/// Manages WebRTC peer connection lifecycle for Azure OpenAI Realtime API.
/// ObservableObject so AIAssistantViewModel can observe via objectWillChange.sink.
/// Constructor injection — StockToolsManager passed from AIAssistantViewModel.
final class WebRTCManager: NSObject, ObservableObject {

    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "AI.WebRTC"
    )

    private let stockToolsManager: StockToolsManager

    @Published var isConnected:   Bool   = false
    @Published var isListening:   Bool   = false
    @Published var isGPTSpeaking: Bool   = false
    @Published var isMuted:       Bool   = false
    @Published var statusMessage: String = "Ready"
    @Published var messages: [TranscriptMessage] = []

    private var peerConnection:  RTCPeerConnection?
    private var dataChannel:     RTCDataChannel?
    private var localAudioTrack: RTCAudioTrack?
    private let factory:         RTCPeerConnectionFactory

    // Accumulates partial transcript deltas from streaming responses
    private var currentAssistantText    = ""
    private var currentToolCallId       = ""
    private var currentToolName         = ""
    private var currentToolArgs         = ""
    // Set when a new audio response starts — forces the next delta to open a fresh bubble
    private var needsNewAssistantBubble = true
    // Auto-disconnect after 60 s of user silence
    private var silenceWorkItem: DispatchWorkItem?
    private let silenceTimeout: TimeInterval = 60
    // Timestamp when output_audio_buffer.stopped fired — used to calculate
    // remaining pipeline drain time before the mic can safely be opened.
    private let audioDrainWindow: TimeInterval = 1.2
    private var audioStoppedAt: Date? = nil
    // True while a tool call has been dispatched but the follow-up response
    // hasn't started yet. Mic must stay muted during this window.
    private var isToolCallPending = false

    init(stockToolsManager: StockToolsManager) {
        self.stockToolsManager = stockToolsManager

        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
        super.init()
    }

    // MARK: - Session Lifecycle

    func startSession(token: String) async {
        setupAudioSession()
        await MainActor.run { statusMessage = "Setting up connection..." }
        logger.debug("🔧 Starting WebRTC session")

        // 1. Build ICE configuration (Azure doesn't require STUN/TURN)
        let config = RTCConfiguration()
        config.iceServers = []
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )

        // 2. Create peer connection
        guard let pc = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        ) else {
            await MainActor.run {
                statusMessage = "Failed to create peer connection"
                self.logger.error("❌ RTCPeerConnection creation failed")
            }
            return
        }
        peerConnection = pc

        // 3. Add audio track (microphone → GPT hears user)
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )
        let audioSource = factory.audioSource(with: audioConstraints)
        let audioTrack  = factory.audioTrack(with: audioSource, trackId: "audio0")
        localAudioTrack = audioTrack
        pc.add(audioTrack, streamIds: ["stream0"])
        logger.debug("🎤 Audio track added")

        // 4. Create data channel for signaling events
        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        guard let dc = pc.dataChannel(forLabel: "oai-events", configuration: dcConfig) else {
            logger.error("❌ Data channel creation failed")
            return
        }
        dataChannel = dc
        dc.delegate = self
        stockToolsManager.dataChannel = dc
        logger.debug("📡 Data channel created")

        // 5. Create SDP offer
        let offerConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )

        let offer: RTCSessionDescription
        do {
            offer = try await withCheckedThrowingContinuation { continuation in
                pc.offer(for: offerConstraints) { sdp, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let sdp {
                        continuation.resume(returning: sdp)
                    } else {
                        continuation.resume(
                            throwing: NSError(
                                domain: "WebRTC", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No SDP returned"]
                            )
                        )
                    }
                }
            }
        } catch {
            logger.error("❌ Offer creation failed: \(error.localizedDescription)")
            return
        }

        // 6. Set local description
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                pc.setLocalDescription(offer) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            logger.error("❌ Set local description failed: \(error.localizedDescription)")
            return
        }

        logger.debug("📤 Local description set, sending offer to Azure")
        await MainActor.run { statusMessage = "Connecting to Azure..." }

        // 7. POST SDP offer to WebRTC endpoint
        guard let url = URL(string: "\(RealtimeConfig.webRTCEndpoint)?model=\(RealtimeConfig.deploymentName)") else {
            logger.error("❌ Invalid WebRTC endpoint URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.sdp.data(using: .utf8)

        let answerSDP: String
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                logger.debug("WebRTC endpoint status: \(http.statusCode)")
                guard http.statusCode == 201 else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    logger.error("❌ WebRTC endpoint error: \(body)")
                    await MainActor.run { statusMessage = "Azure connection failed (\(http.statusCode))" }
                    return
                }
            }
            answerSDP = String(data: data, encoding: .utf8) ?? ""
        } catch {
            logger.error("❌ SDP exchange failed: \(error.localizedDescription)")
            await MainActor.run { statusMessage = "Network error" }
            return
        }

        // 8. Set remote description with answer
        let answer = RTCSessionDescription(type: .answer, sdp: answerSDP)
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                pc.setRemoteDescription(answer) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            logger.debug("✅ Remote description set — ICE negotiation in progress")
        } catch {
            logger.error("❌ Set remote description failed: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        cancelSilenceTimer()
        dataChannel?.close()
        peerConnection?.close()
        dataChannel     = nil
        peerConnection  = nil
        localAudioTrack = nil
        stockToolsManager.dataChannel = nil
        currentAssistantText    = ""
        currentToolCallId       = ""
        currentToolName         = ""
        currentToolArgs         = ""
        needsNewAssistantBubble = true
        isToolCallPending       = false
        audioStoppedAt          = nil
        DispatchQueue.main.async { [weak self] in
            self?.messages      = []
            self?.isConnected   = false
            self?.isListening   = false
            self?.isGPTSpeaking = false
            self?.isMuted       = false
            self?.statusMessage = "Disconnected"
        }
        logger.debug("🔌 Disconnected")
    }

    func toggleMute() {
        guard let track = localAudioTrack else { return }
        let unmuting = !track.isEnabled

        if unmuting {
            if isGPTSpeaking {
                // Force server to flush queued audio + cancel the active response.
                // output_audio_buffer.clear makes the server stop sending audio
                // immediately, which triggers output_audio_buffer.stopped — that
                // handler owns the drain-aware mic re-enable, so we don't open the
                // mic here. The earlier "0.4s after response.cancelled" path was
                // too short: device speakers were still playing buffered audio
                // when the mic opened, looping the AI back to itself.
                stockToolsManager.sendDataChannelMessage(["type": "output_audio_buffer.clear"])
                stockToolsManager.sendDataChannelMessage(["type": "response.cancel"])
                DispatchQueue.main.async { [weak self] in
                    self?.statusMessage = "Stopping..."
                }
                logger.debug("🎤 Stop+unmute requested — awaiting output_audio_buffer.stopped")
                return
            }

            // AI not actively speaking but pipeline may still be draining.
            // Wait out whatever drain time remains before opening the mic.
            let elapsed  = audioStoppedAt.map { Date().timeIntervalSince($0) } ?? audioDrainWindow
            let remaining = max(0, audioDrainWindow - elapsed)

            if remaining > 0 {
                logger.debug("🎤 Drain window: \(remaining, format: .fixed(precision: 2))s remaining — delaying mic open")
                DispatchQueue.main.async { [weak self] in
                    self?.statusMessage = "🟢 Releasing mic..."
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                    self?.localAudioTrack?.isEnabled = true
                    self?.isMuted = false
                    self?.statusMessage = "🟢 Connected — speak now!"
                }
            } else {
                track.isEnabled = true
                DispatchQueue.main.async { [weak self] in
                    self?.isMuted = false
                    self?.statusMessage = "🟢 Connected — speak now!"
                }
            }
            return
        }

        // Muting: immediate
        track.isEnabled = false
        DispatchQueue.main.async { [weak self] in self?.isMuted = true }
        logger.debug("🎤 Mic muted by user")
    }

    // MARK: - Silence Timer

    private func startSilenceTimer() {
        silenceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.logger.debug("⏱️ 60 s silence — auto-disconnecting")
            NotificationCenter.default.post(name: .sessionSilenceTimeout, object: nil)
        }
        silenceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + silenceTimeout, execute: work)
    }

    private func cancelSilenceTimer() {
        silenceWorkItem?.cancel()
        silenceWorkItem = nil
    }

    // MARK: - Audio Session

    func setupAudioSession() {
        let configuration = RTCAudioSessionConfiguration.webRTC()
        // voiceChat mode activates hardware AEC on real devices so the mic
        // doesn't pick up speaker output. The simulator has no hardware AEC
        // so some echo is expected there — use headphones when testing.
        configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
        configuration.categoryOptions = AVAudioSession.CategoryOptions([
            .allowBluetooth,
            .allowBluetoothA2DP
        ])

        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setConfiguration(configuration, active: true)
            logger.debug("✅ RTCAudioSession configured with voiceChat AEC")
        } catch {
            logger.error("❌ RTCAudioSession error: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }

    func forceSpeakerOutput() {
        // Only force speaker if no external audio device connected
        let session = AVAudioSession.sharedInstance()
        let hasExternalOutput = session.currentRoute.outputs.contains {
            $0.portType == .headphones ||
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothHFP ||
            $0.portType == .bluetoothLE
        }

        guard !hasExternalOutput else {
            logger.debug("🎧 External audio detected — skipping speaker override")
            return
        }

        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.overrideOutputAudioPort(.speaker)
            logger.debug("✅ Speaker output applied — no headphones detected")
        } catch {
            logger.error("❌ Force speaker error: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }

    // MARK: - Data Channel Event Handling

    private func handleDataChannelMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else { return }

        logger.debug("📨 Event: \(type)")

        switch type {

        case "session.created":
            stockToolsManager.sendSessionUpdate()

        case "response.created":
            // New response starting — tool result has been processed, clear pending flag.
            isToolCallPending   = false
            currentAssistantText    = ""
            needsNewAssistantBubble = true

        case "input_audio_buffer.speech_started":
            cancelSilenceTimer()
            DispatchQueue.main.async { [weak self] in
                self?.isListening   = true
                self?.statusMessage = "Listening..."
            }

        case "input_audio_buffer.speech_stopped":
            DispatchQueue.main.async { [weak self] in
                self?.isListening   = false
                self?.statusMessage = "Processing..."
            }
            // Post before the model responds so the ViewModel can reserve a slot
            // at the correct position — transcription arrives too late to append normally.
            NotificationCenter.default.post(name: .userSpeechStopped, object: nil)

        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String, !transcript.isEmpty {
                NotificationCenter.default.post(
                    name: .userTranscriptReady,
                    object: nil,
                    userInfo: ["transcript": transcript]
                )
            }

        case "response.audio.started":
            currentAssistantText    = ""
            needsNewAssistantBubble = true
            DispatchQueue.main.async { [weak self] in
                self?.isGPTSpeaking = true
                self?.statusMessage = "🟢 Connected — speaking..."
            }

        case "response.audio_transcript.delta":
            if let delta = json["delta"] as? String {
                currentAssistantText += delta
                let snapshot   = currentAssistantText
                let isNewBubble = needsNewAssistantBubble
                if isNewBubble { needsNewAssistantBubble = false }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if isNewBubble {
                        self.messages.append(TranscriptMessage(role: .assistant, text: snapshot))
                    } else if let idx = self.messages.lastIndex(where: { $0.role == .assistant }) {
                        self.messages[idx] = TranscriptMessage(role: .assistant, text: snapshot)
                    }
                }
            }

        case "response.audio.done":
            DispatchQueue.main.async { [weak self] in
                self?.isGPTSpeaking = false
                self?.statusMessage = "🟢 Connected — speak now!"
            }

        case "output_audio_buffer.started":
            audioStoppedAt = nil
            DispatchQueue.main.async { [weak self] in
                self?.localAudioTrack?.isEnabled = false
                self?.isMuted       = true
                self?.isGPTSpeaking = true
                self?.statusMessage = "Speaking..."
            }

        case "output_audio_buffer.stopped":
            audioStoppedAt = Date()
            startSilenceTimer()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isGPTSpeaking = false
                // Don't say "speak now" yet — mic is still draining. The button
                // would say "Muted" while the header says "speak now", which
                // confuses the user. Hold "Releasing mic..." until the drain
                // handler actually flips the mic on.
                self.statusMessage = self.isToolCallPending
                    ? "Processing..."
                    : "🟢 Releasing mic..."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + audioDrainWindow) { [weak self] in
                guard let self, self.localAudioTrack?.isEnabled == false else { return }
                guard !self.isToolCallPending else {
                    self.logger.debug("🎤 Auto-unmute skipped — tool call still pending")
                    return
                }
                self.localAudioTrack?.isEnabled = true
                self.isMuted = false
                self.statusMessage = "🟢 Connected — speak now!"
            }

        case "response.cancelled":
            // Mic re-enable is owned by output_audio_buffer.stopped (which fires
            // after output_audio_buffer.clear). Don't open the mic here — the
            // previous 0.4s drain was too short and let speaker residue echo
            // back into the mic, looping AI → mic → AI.
            DispatchQueue.main.async { [weak self] in
                self?.isGPTSpeaking = false
            }

        case "response.audio_transcript.done":
            DispatchQueue.main.async { [weak self] in
                self?.isGPTSpeaking = false
                // Don't re-enable mic here — wait for output_audio_buffer.stopped
            }

        case "response.function_call_arguments.delta":
            if let delta = json["delta"] as? String { currentToolArgs += delta }
            if currentToolName.isEmpty,
               let name = json["name"] as? String { currentToolName = name }
            if currentToolCallId.isEmpty,
               let callId = json["call_id"] as? String { currentToolCallId = callId }

        case "response.function_call_arguments.done":
            isToolCallPending = true   // mic stays muted until response.created
            if let callId = json["call_id"]    as? String { currentToolCallId = callId }
            if let name   = json["name"]        as? String { currentToolName   = name   }
            if let args   = json["arguments"]   as? String { currentToolArgs   = args   }

            let toolMessage = TranscriptMessage(
                role: .system,
                text: "🔧 Calling \(currentToolName)..."
            )
            DispatchQueue.main.async { [weak self] in
                self?.messages.append(toolMessage)
            }

            stockToolsManager.handleToolCall(
                name:       currentToolName,
                callId:     currentToolCallId,
                argsString: currentToolArgs
            )
            currentToolName   = ""
            currentToolCallId = ""
            currentToolArgs   = ""

        case "error":
            if let errObj  = json["error"] as? [String: Any],
               let message = errObj["message"] as? String {
                logger.error("❌ Server error: \(message)")
                // Benign in our stop-during-drain flow: response ended on the
                // server before our cancel reached it. Don't surface to user.
                let isBenignCancelError =
                    message.contains("Cancellation failed") ||
                    message.contains("no active response")
                if !isBenignCancelError {
                    DispatchQueue.main.async { [weak self] in
                        self?.statusMessage = "Error: \(message)"
                    }
                }
            }

        default:
            break
        }
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCManager: RTCPeerConnectionDelegate {

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        logger.debug("Signaling state: \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {}

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {}

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        logger.debug("ICE connection state: \(newState.rawValue)")
        switch newState {
        case .connected, .completed:
            startSilenceTimer()
            DispatchQueue.main.async { [weak self] in
                self?.isConnected   = true
                self?.statusMessage = "🟢 Connected — speak now!"
                self?.forceSpeakerOutput()
            }
        case .disconnected, .failed, .closed:
            DispatchQueue.main.async { [weak self] in
                self?.isConnected   = false
                self?.isListening   = false
                self?.isGPTSpeaking = false
                self?.statusMessage = "Disconnected"
            }
        default:
            break
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        logger.debug("ICE gathering state: \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {}

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        logger.debug("📡 Data channel opened (delegate)")
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCManager: RTCDataChannelDelegate {

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        logger.debug("Data channel state: \(dataChannel.readyState.rawValue)")
        if dataChannel.readyState == .open {
            logger.debug("✅ Data channel open")
        }
    }

    func dataChannel(_ dataChannel: RTCDataChannel,
                     didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let text = String(data: buffer.data, encoding: .utf8) else { return }
        handleDataChannelMessage(text)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userSpeechStopped   = Notification.Name("userSpeechStopped")
    static let userTranscriptReady = Notification.Name("userTranscriptReady")
    static let sessionSilenceTimeout = Notification.Name("sessionSilenceTimeout")
}
