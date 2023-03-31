//
//  DesignTimeInteractor.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import Foundation

class DesignTimeInteractor: Interactable {

    var currentResponse: String = "What is the color of the sky?"

    var state: InteractorState = .idle

    var transcript: [TranscriptionMessage] = [
        ("I am kinda smart now.", Date(timeIntervalSince1970: 0)),
        ("Hopefully one day I can be smarter with quantum computers.\n", Date(timeIntervalSince1970: 1))
    ].map(TranscriptionMessage.init)

    func ask(question: String) {}
    func stop() {}
    func updateBot(_ bot: ChatBot) {}

    func clearHistory() {
        transcript.removeAll()
    }
}
