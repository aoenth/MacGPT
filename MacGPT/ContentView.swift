//
//  ContentView.swift
//  MacGPT
//
//  Created by Peng, Kevin [C] on 2023-03-21.
//

import ChatGPTSwift
import SwiftUI

struct ContentView<Interactor: Interactable>: View {
    @ObservedObject var interactor: Interactor
    @State private var question = ""
    @State private var scrollToBottom: (() -> Void)?
    @State private var scrollToTop: (() -> Void)?
    @State private var hoveredTranscriptTimestamp: Date?

    private let attributeContainer = {
        var ac = AttributeContainer()
#if os(macOS)
        ac.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
#endif
        return ac
    }()

    var body: some View {
        VStack {
            commandButtons

            chatTranscript
                .frame(height: 400)

            chatInput
        }
        .padding()
    }

    var commandButtons: some View {
        HStack {
            Button("Stop Generating") {
                interactor.stop()
            }
            Button("Clear History") {
                interactor.clearHistory()
            }
            Button("Scroll to Top") {
                scrollToTop?()
            }
            Button("Scroll to Bottom") {
                scrollToBottom?()
            }
        }
    }

    var chatTranscript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text("Program is " + String(describing: interactor.state.rawValue.capitalized))
                    .id(0)
                LazyVStack(alignment: .leading) {
                    ForEach(interactor.transcript) { line in
                        HStack(alignment: .bottom) {
                            Text(AttributedString(line.message, attributes: line.type == .question ? attributeContainer : AttributeContainer()))
                                .textSelection(.enabled)
                                .lineSpacing(1)
                            Spacer()
                            Button {
                                interactor.copyMessage(line.message)
                            } label: {
                                Image(systemName: "clipboard")
                            }
                            .onHover { isHovered in
                                hoveredTranscriptTimestamp = isHovered ? line.timestamp : nil
                            }
                        }
                        .padding()
                        .background(line.timestamp == hoveredTranscriptTimestamp ? Color(white: 1, opacity: 0.1) : Color.clear)
                    }
                    Text(interactor.currentResponse)
                        .padding()
                        .lineSpacing(1)
                }
                Text("")
                    .id(1)
            }
            .onAppear {
                scrollToBottom = { proxy.scrollTo(1) }
                scrollToTop = { proxy.scrollTo(0) }
            }
            .onChange(of: interactor.transcript.count) { newValue in
                scrollToBottom?()
            }
            .onChange(of: interactor.currentResponse) { newValue in
                scrollToBottom?()
            }
        }
    }

    var chatInput: some View {
        HStack {
            Image(systemName: "text.bubble")
                .imageScale(.large)
                .foregroundColor(.primary)
            TextEditor(text: $question)
                .font(.subheadline)
                .lineLimit(4)
                .border(Color.gray)
            VStack {
                Button("Submit", action: submit)
                    .keyboardShortcut(.return)
                    .disabled(question.isEmpty || exceededLimit)
                VStack(spacing: 1) {
                    Text("\(question.count)")
                    Divider()
                    Text("2,048")
                }
                .monospacedDigit()
                .frame(width: 40)
                .padding(2)
                .border(exceededLimit ? Color.red : .clear)
            }
        }
    }

    var exceededLimit: Bool {
        question.count > 2048
    }

    func submit() {
        guard !exceededLimit else { return }
        interactor.ask(question: question)
        question.removeAll()
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(interactor: DesignTimeInteractor())
    }
}
