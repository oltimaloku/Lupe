import SwiftUI

struct PromptView: View {
    @StateObject private var viewModel: PromptViewModel
    @State private var inputText: String = ""
    @State private var isNavigating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentTopicId: UUID?
    
    @Environment(\.diContainer) private var diContainer
    
    init() {
        _viewModel = StateObject(wrappedValue: PromptViewModel(diContainer: DIContainer.shared))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Text("Learn Everything.")
                    .font(.title2)
                    .fontWeight(.regular)
                    .padding(.bottom, 8)
                
                HStack(alignment: .center) {
                    EITextField(text: $inputText, placeholder: "Enter a concept", padding: 16, icon: "brain")
                        .alignmentGuide(.bottom) { $0[.bottom] }
                    
                    Button(action: handleTopicSubmission) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(Color(.systemBackground))
                        } else {
                            IconBox(
                                iconName: "arrow.up",
                                backgroundColor: Color(UIColor.label),
                                foregroundColor: Color(.systemBackground)
                            )
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                
                Text("My Concepts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.topics, id: \.id) { topic in
                            NavigationLink(destination: TopicView(topic: topic)) {
                                TopicCard(name: topic.name, icon: topic.icon)
                            }
                        }
                    }
                }
                
                // Navigation to question flow
                if let topicId = currentTopicId {
                    NavigationLink(
                        destination: QuestionFlowContainerView(topicId: topicId),
                        isActive: $isNavigating
                    ) {
                        EmptyView()
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $viewModel.isStartingLearningFlow) {
                if let newTopicId = viewModel.newTopicId {
                    QuestionFlowContainerView(topicId: newTopicId)
                }
                
            }
        }
    }
    
    private func handleTopicSubmission() {
        Task {
            do {
                let topicId = try await viewModel.initializeTopic(name: inputText)
                await MainActor.run {
                    currentTopicId = topicId
                    isNavigating = true
                    inputText = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
