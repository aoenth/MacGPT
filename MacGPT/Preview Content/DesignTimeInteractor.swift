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

    var transcript: [AttributedString] = [
        "I am kinda smart now.",
        "Hopefully one day I can be smarter with quantum computers.\n"
    ].map(AttributedString.init)

    func ask(question: String) {}
    func stop() {}
}
