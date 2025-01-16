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
            VStack(alignment: .center, spacing: 0) {
                // Title section at the top
                Text("Lupe")
                    .primaryTitle()
                    .padding(.top, 40)
                
                Spacer()
                
                // Main content section
                VStack(spacing: 20) {
                    Text("Learn anything.")
                        .bodyText()
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
                                    backgroundColor: Theme.accentColor,
                                    foregroundColor: Color(.systemBackground)
                                )
                            }
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                    }
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Navigation handling
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
