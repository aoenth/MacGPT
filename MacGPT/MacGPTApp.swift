//
//  MacGPTApp.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import ChatGPTSwift
import SwiftUI

@main
struct MacGPTApp: App {
    @AppStorage("apiKey") private var apiKey = ""
//    @ObservedObject var interactor = GPTInteractor(
//        bot: EmptyChatBot(),
//        attributeContainer: {
//            var ac = AttributeContainer()
//            #if os(macOS)
//            ac.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
//            #endif
//            return ac
//        }()
//    )
    @ObservedObject var interactor = DesignTimeInteractor()

    var body: some Scene {
        WindowGroup {
            ContentView(interactor: interactor)
                .onAppear {
                    if !apiKey.isEmpty {
                        interactor.updateBot(ChatGPTAPI(apiKey: apiKey))
                    }
                }
        }
        Settings {
            SettingsView(apiKey: $apiKey)
        }
        .onChange(of: apiKey) { newValue in
            if newValue.isEmpty {
                interactor.updateBot(EmptyChatBot())
            } else {
                interactor.updateBot(ChatGPTAPI(apiKey: newValue))
            }
        }
    }
}
