//
//  Interactor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import AppKit

struct TranscriptionMessage: Identifiable {
    let message: AttributedString
    let timestamp: Date

    var id: Date {
        timestamp
    }
}

protocol Interactable: ObservableObject {
    var state: InteractorState { get }
    var transcript: [TranscriptionMessage] { get }
    var currentResponse: String { get }
    func updateBot(_ bot: ChatBot)
    func ask(question: String)
    func stop()
}

enum InteractorState {
    case idle
    case asking
    case writingResponse
}

class GPTInteractor: Interactable {
    @Published private(set) var transcript: [TranscriptionMessage] = []
    @Published private(set) var currentResponse = ""
    private var bot: ChatBot?
    private(set) var state = InteractorState.idle
    private var timeOut: Task<Void, Never>?
    private let attributeContainer: AttributeContainer = {
        var ac = AttributeContainer()
        ac.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        return ac
    }()

    init(bot: ChatBot) {
        self.bot = bot
    }

    func updateBot(_ bot: ChatBot) {
        self.bot = bot
    }

    func ask(question: String) {
        transcript.append(
            TranscriptionMessage(
                message: AttributedString(
                    question,
                    attributes: attributeContainer
                ),
                timestamp: Date()
            )
        )

        state = .asking

        Task {
            guard let bot else {
                await appendResponse("You need to configure your API in the settings first.\n")
                return
            }
            do {
                let stream = try await bot.ask(question: question)
                state = .writingResponse
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
            state = .idle
            timeOut?.cancel()
            timeOut = nil
            await commitToChat()
        }
    }

    @MainActor
    func commitToChat() {
        transcript.append(TranscriptionMessage(message: AttributedString(currentResponse), timestamp: Date()))
        currentResponse.removeAll()
    }

    func startTimeout() {
        timeOut = Task.detached { [weak self] in
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }
            await self?.stop()
        }
    }

    @MainActor
    func appendResponse(_ text: String) {
        currentResponse += text
    }

    @MainActor
    func stop() {
        appendResponse("\n\n")
        commitToChat()
        state = .idle
    }

}
