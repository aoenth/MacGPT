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
    func message(at index: Int) -> String
    func clearHistory()
}

extension ChatGPTAPI: ChatBot {
    func ask(question: String) async throws -> AsyncThrowingStream<String, Error> {
        try await sendMessageStream(text: question)
    }

    func message(at index: Int) -> String {
        historyList[index].content
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

    func message(at index: Int) -> String {
        "Your API key is not configured."
    }
}
