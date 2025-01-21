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
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Lupe")
                            .font(.custom("Georgia", size: 48))
                            .fontWeight(.bold)
                        
                        Text("Learn anything.")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Input Section
                    VStack(spacing: 16) {
                        // Search Input
                        HStack(spacing: 16) {
                            EITextField(
                                text: $inputText,
                                placeholder: "Enter a concept",
                                padding: 16,
                                icon: "brain"
                            )
                            
                            Button(action: handleTopicSubmission) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                }
                            }
                            .background(Theme.accentColor)
                            .cornerRadius(16)
                            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                        }
                        
                        // Upload Button
                        Button(action: {
                            // Handle upload action
                        }) {
                            HStack {
                                Image(systemName: "paperclip")
                                Text("Upload your notes").font(.custom("Georgia", size: 16)).bold()
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentColor.opacity(0.1))
                            .cornerRadius(40)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $viewModel.isStartingLearningFlow) {
                if let newTopicId = viewModel.newTopicId {
                    QuestionFlowContainerView(topicId: newTopicId).navigationBarBackButtonHidden(true)
                }
            }
            
            if let topicId = currentTopicId {
                NavigationLink(
                    destination: QuestionFlowContainerView(topicId: topicId).navigationBarBackButtonHidden(true),
                    isActive: $isNavigating
                ) {
                    EmptyView()
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
