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
            LabeledContent("API Key") {
                TextField("API Key", text: $currentAPIKey)
                    .monospaced()
            }
            HStack {
                Button("Save") {
                    apiKey = currentAPIKey
                    NSApplication.shared.keyWindow?.close()
                }
                .disabled(apiKey == currentAPIKey)
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
            }
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
