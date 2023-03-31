//
//  Interactor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import AppKit
import Pasteboard

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
    func clearHistory()
    func updateBot(_ bot: ChatBot)
    func ask(question: String)
    func stop()
    func copyMessage(at index: Int)
}

extension Interactable {
    func copyMessage(at index: Int) {
        let message = transcript[index].message

        /// Using this syntax for conversion for performance reasons. See https://forums.swift.org/t/attributedstring-to-string/61667
        let string = String(message.characters[...])

        setPasteboardContent(string)
    }
}

enum InteractorState {
    case idle
    case asking
    case writingResponse
}

class GPTInteractor: Interactable {

    @Published private(set) var transcript: [TranscriptionMessage] = []
    @Published private(set) var currentResponse = ""
    private var bot: ChatBot
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

    func clearHistory() {
        bot.clearHistory()
        transcript.removeAll()
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
