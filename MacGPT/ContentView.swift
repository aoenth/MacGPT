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

    var body: some View {
        VStack {
            Text("Program is " + String(describing: interactor.state))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(interactor.transcript, id: \.self) { line in
                            Text(line)
                                .lineSpacing(1)
                        }
                        Text(interactor.currentResponse)
                            .lineSpacing(1)
                        EmptyView()
                            .id(0)
                    }
                }
                .onChange(of: interactor.currentResponse) { newValue in
                    proxy.scrollTo(0)
                }
            }
            .frame(height: 400)

            HStack {
                Image(systemName: "text.bubble")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                TextField("Prompt", text: $question)
                    .onSubmit(submit)
                Button("Submit", action: submit)
            }
        }
        .padding()
    }

    func submit() {
        interactor.ask(question: question)
        question.removeAll()
    }

}

protocol Interactable: ObservableObject {
    var state: InteractorState { get }
    var transcript: [AttributedString] { get }
    var currentResponse: String { get }
    func ask(question: String)
    func stop()
}

enum InteractorState {
    case idle
    case asking
    case writingResponse
}

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

class GPTInteractor: Interactable {
    @Published private(set) var transcript: [AttributedString] = []
    @Published private(set) var currentResponse = ""
    private var api: ChatGPTAPI?
    private(set) var state = InteractorState.idle
    private var timeOut: Task<Void, Never>?
    private let attributeContainer: AttributeContainer = {
        var ac = AttributeContainer()
        ac.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        return ac
    }()

    func updateAPIKey(_ apiKey: String) {
        api = ChatGPTAPI(apiKey: apiKey)
    }

    func ask(question: String) {
        transcript.append(AttributedString(question, attributes: attributeContainer))

        state = .asking

        Task {
            guard let api else {
                await appendResponse("You need to configure your API in the settings first.")
                return
            }
            do {
                let stream = try await api.sendMessageStream(text: question)
                state = .writingResponse
                for try await line in stream {
                    timeOut?.cancel()
                    guard state == .writingResponse else {
                        state = .idle
                        return
                    }
                    await appendResponse(line)
                    startTimeout()
                }
            } catch {
                await appendResponse(error.localizedDescription)
            }
            await appendResponse("\n")
            state = .idle
            timeOut?.cancel()
            timeOut = nil
            await commitToChat()
        }
    }

    @MainActor
    func commitToChat() {
        transcript.append(AttributedString(currentResponse))
        currentResponse.removeAll()
    }

    func startTimeout() {
        timeOut = Task.detached { [weak self] in
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                // Came back within reasonable time of 5 seconds
                return
            }
            await self?.stop()
        }
    }

    @MainActor
    func appendResponse(_ text: String) {
        currentResponse += text
    }

    @MainActor
    func stop() {
        appendResponse("\n")
        commitToChat()
        state = .idle
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(interactor: DesignTimeInteractor())
    }
}
