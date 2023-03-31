//
//  Interactor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import AppKit
import Pasteboard

struct TranscriptionMessage: Identifiable {

    let message: String
    let type: MessageType
    let timestamp: Date

    init(message: String, type: MessageType, timestamp: Date = Date()) {
        self.message = message
        self.type = type
        self.timestamp = timestamp
    }

    var id: Date {
        timestamp
    }

    enum MessageType {
        case question
        case answer
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
    func copyMessage(_ message: String)
}

extension Interactable {
    func copyMessage(_ message: String) {
        setPasteboardContent(message)
    }
}

enum InteractorState: String {
    case idle
    case asking
    case writingResponse = "Writing Response"
}
