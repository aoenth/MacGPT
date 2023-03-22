//
//  MacGPTApp.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import SwiftUI

@main
struct MacGPTApp: App {
    @AppStorage("apiKey") private var apiKey = ""
    @StateObject var interactor = GPTInteractor()

    var body: some Scene {
        WindowGroup {
            ContentView(interactor: interactor)
                .onAppear {
                    if !apiKey.isEmpty {
                        interactor.updateAPIKey(apiKey)
                    }
                }
        }
        Settings {
            SettingsView(apiKey: $apiKey)
        }
        .onChange(of: apiKey) { newValue in
            interactor.updateAPIKey(newValue)
        }
    }
}
