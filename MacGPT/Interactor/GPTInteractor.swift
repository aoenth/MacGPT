//
//  GPTInteractor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-31.
//

import AppKit

class GPTInteractor: Interactable {

    @Published private(set) var transcript: [TranscriptionMessage] = []
    @Published private(set) var currentResponse = ""
    @Published private(set) var state = InteractorState.idle

    private var bot: ChatBot
    private var timeOut: Task<Void, Never>?
    private let attributeContainer: AttributeContainer
    
    init(bot: ChatBot, attributeContainer: AttributeContainer) {
        self.bot = bot
        self.attributeContainer = attributeContainer
    }

    func updateBot(_ bot: ChatBot) {
        self.bot = bot
    }

    func clearHistory() {
        bot.clearHistory()
        transcript.removeAll()
    }

    func ask(question: String) {
        transcript.append(
            TranscriptionMessage(message: question, type: .question)
        )

        state = .asking

        Task {
            do {
                let stream = try await bot.ask(question: question)
                await setState(.writingResponse)
                for try await line in stream {
                    timeOut?.cancel()
                    guard state == .writingResponse else {
                        state = .idle
                        return
                    }
                    await appendResponse(line)
                    startTimeout()
                }
            } catch {
                await appendResponse(error.localizedDescription)
            }
            await appendResponse("\n")
            await setState(.idle)
            timeOut?.cancel()
            timeOut = nil
            await commitToChat()
        }
    }

    @MainActor
    func commitToChat() async {
        let response = currentResponse
        currentResponse.removeAll()
        transcript.append(TranscriptionMessage(message: response, type: .answer))
    }

    @MainActor
    func setState(_ newState: InteractorState) async {
        state = newState
    }

    func startTimeout() {
        timeOut = Task.detached { [weak self] in
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }
            self?.stop()
        }
    }

    @MainActor
    func appendResponse(_ text: String) async {
        currentResponse += text
    }

    func stop() {
        Task {
            await appendResponse("\n\n")
            await commitToChat()
            state = .idle
        }
    }
}
