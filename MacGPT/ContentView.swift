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
                        ForEach(interactor.transcript) { line in
                            Text(line.message)
                                .textSelection(.enabled)
                                .lineSpacing(1)
                        }
                        Text(interactor.currentResponse)
                            .lineSpacing(1)
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
                    .foregroundColor(.white)
                TextField("Prompt", text: $question)
                    .onSubmit(submit)
                Button("Submit", action: submit)
                    .disabled(question.isEmpty)
            }
        }
        .padding()
    }

    func submit() {
        interactor.ask(question: question)
        question.removeAll()
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(interactor: DesignTimeInteractor())
    }
}
