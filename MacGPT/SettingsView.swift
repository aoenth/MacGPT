//
//  SettingsView.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import SwiftUI

struct SettingsView: View {
    @State private var currentAPIKey: String = ""
    @Binding var apiKey: String

    var body: some View {
        VStack {
            TextField("API Key", text: $currentAPIKey)
                .monospaced()
            Button("Save") {
                apiKey = currentAPIKey
            }
            .disabled(apiKey == currentAPIKey)
        }
        .padding()
        .onAppear {
            currentAPIKey = apiKey
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(apiKey: .constant("123"))
    }
}
