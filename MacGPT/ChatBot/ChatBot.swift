//
//  ChatBot.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import ChatGPTSwift
import Foundation

protocol ChatBot {
    func ask(question: String) async throws -> AsyncThrowingStream<String, Error>
    func clearHistory()
}

extension ChatGPTAPI: ChatBot {
    func ask(question: String) async throws -> AsyncThrowingStream<String, Error> {
        try await sendMessageStream(text: question)
    }

    func clearHistory() {
        deleteHistoryList()
    }
}

struct EmptyChatBot: ChatBot {
    func ask(question: String) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Your API key is not configured.")
            continuation.finish()
        }
    }

    func clearHistory() {}
}
