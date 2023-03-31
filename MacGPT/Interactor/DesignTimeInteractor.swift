//
//  DesignTimeInteractor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import Foundation

class DesignTimeInteractor: ObservableObject, Interactable {

    @Published var currentResponse: String = ""

    var state: InteractorState = .idle

    @Published var transcript: [TranscriptionMessage] = (-15 ..< -1).map {
        ("I am kinda smart now.", TranscriptionMessage.MessageType.answer, Date(timeIntervalSince1970: TimeInterval($0)))
    }.map(TranscriptionMessage.init)

    private var index = 0
    private var task: Task<Void, Error>?

    func ask(question: String) {
        transcript.append(.init(message: question, type: .question))
        let index = index
        state = .asking
        self.task = Task.detached { [weak self] in
            try await Task.sleep(for: .seconds(1))
            self?.state = .writingResponse
            defer {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.state = .idle
                    self.transcript.append(
                        TranscriptionMessage(
                            message: .init(self.currentResponse),
                            type: TranscriptionMessage.MessageType.answer,
                            timestamp: Date()
                        )
                    )
                    self.currentResponse.removeAll()
                }
            }
            for i in index ..< index + 50 {
                try await Task.sleep(for: .milliseconds(500))
                try Task.checkCancellation()
                guard let self else {
                    return
                }
                await MainActor.run {
                    self.currentResponse += "\(i)\n"
                }
                self.index += 1
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func updateBot(_ bot: ChatBot) {}

    func clearHistory() {
        transcript.removeAll()
    }
}
