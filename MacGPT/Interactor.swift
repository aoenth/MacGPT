//
//  Interactor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import AppKit
import ChatGPTSwift

protocol Interactable: ObservableObject {
    var state: InteractorState { get }
    var transcript: [AttributedString] { get }
    var currentResponse: String { get }
    func ask(question: String)
    func stop()
}

enum InteractorState {
    case idle
    case asking
    case writingResponse
}

class GPTInteractor: Interactable {
    @Published private(set) var transcript: [AttributedString] = []
    @Published private(set) var currentResponse = ""
    private var api: ChatGPTAPI?
    private(set) var state = InteractorState.idle
    private var timeOut: Task<Void, Never>?
    private let attributeContainer: AttributeContainer = {
        var ac = AttributeContainer()
        ac.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        return ac
    }()

    func updateAPIKey(_ apiKey: String) {
        api = ChatGPTAPI(apiKey: apiKey)
    }

    func ask(question: String) {
        transcript.append(AttributedString(question, attributes: attributeContainer))

        state = .asking

        Task {
            guard let api else {
                await appendResponse("You need to configure your API in the settings first.\n")
                return
            }
            do {
                let stream = try await api.sendMessageStream(text: question)
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
        transcript.append(AttributedString(currentResponse))
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
        appendResponse("\n")
        commitToChat()
        state = .idle
    }

}
