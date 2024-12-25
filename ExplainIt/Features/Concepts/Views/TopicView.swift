import SwiftUI

struct TopicView: View {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var viewModel: TopicViewModel
    @ViewModelProvider private var explainViewModel: ExplainViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    init(topic: Topic) {
        _viewModel = StateObject(wrappedValue: DIContainer.shared.createTopicViewModel(topic: topic))
        _explainViewModel = ViewModelProvider(topicId: topic.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(viewModel.topic.name)
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Only show root concepts initially
                    let rootConcepts = viewModel.topic.concepts.filter { $0.parentConceptId == nil }
                    LazyVStack(spacing: 16) {
                        ForEach(rootConcepts) { concept in
                            ConceptHierarchyView(
                                concept: concept,
                                depth: 0,
                                expandedConcepts: $viewModel.expandedConcepts,
                                onToggleExpansion: viewModel.toggleConceptExpansion,
                                topicId: viewModel.topic.id
                            )
                        }
                    }
                }
                .padding(20)
            }
            
            Button(action: { Task { await startLearningFlow() } }) {
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
                Button(action: { viewModel.showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Topic", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteTopic()
                dismiss()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.topic.name)'? This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationDestination(isPresented: $viewModel.isStartingQuestionFlow) {
            QuestionFlowContainerView(topicId: viewModel.topic.id)
        }
    }
    
    private func startLearningFlow() async {
        await viewModel.startQuestionFlow()
        try? await explainViewModel.generateQuestions(for: viewModel.topic.name)
    }
}
