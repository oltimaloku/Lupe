import SwiftUI

struct TopicView: View {
    let topic: Topic
    @EnvironmentObject private var viewModel: ExplainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @Environment(\.presentationMode) private var presentationMode
    @State private var isStartingQuestionFlow = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(topic.name)
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(topic.concepts, id: \.id) { concept in
                            NavigationLink(destination: ConceptView(concept: concept)) {
                                TopicCard(name: concept.name, icon: "image")
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            // Question Flow Button
            Button(action: startQuestionFlow) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Start Learning Flow")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 2, y: -2)
            .disabled(viewModel.isLoading)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Topic", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTopic()
            }
        } message: {
            Text("Are you sure you want to delete '\(topic.name)'? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $isStartingQuestionFlow) {
            QuestionFlowContainerView()
                .environmentObject(viewModel)
        }.onAppear {
            print("navigated to topic: \(topic)")
        }
    }
    
    
    private func deleteTopic() {
        viewModel.deleteTopic(topic)
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func startQuestionFlow() {
        Task {
            do {
                viewModel.currentTopic = topic // Set the current topic
                try await viewModel.generateQuestions(for: topic.name)
                await MainActor.run {
                    isStartingQuestionFlow = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isStartingQuestionFlow = false
                }
            }
        }
    }
}
