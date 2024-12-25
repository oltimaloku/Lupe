import SwiftUI

struct PromptView: View {
    @State private var inputText: String = ""
    @State private var isNavigating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @StateObject private var viewModel = ExplainViewModel.create()
    
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
                        IconBox(
                            iconName: "arrow.up",
                            backgroundColor: Color(UIColor.label),
                            foregroundColor: Color(.systemBackground)
                        )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                Text("My Concepts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.topics, id: \.id) { topic in
                           
                            NavigationLink(destination: TopicView(topic: topic).environmentObject(viewModel)) {
                                TopicCard(name: topic.name, icon: topic.icon)
                            }
                        }
                    }
                }
                
                // New navigation using NavigationStack
                NavigationLink(
                    destination: QuestionFlowContainerView()
                        .environmentObject(viewModel),
                    isActive: $isNavigating
                ) {
                    EmptyView()
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleTopicSubmission() {
        isNavigating = true
        Task {
            do {
                try await viewModel.initializeTopic(for: inputText)
                await MainActor.run {
                    isNavigating = true
                    inputText = "" // Clear the input after successful submission
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

#Preview {
    PromptView()
}
