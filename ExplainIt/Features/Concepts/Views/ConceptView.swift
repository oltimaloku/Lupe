import SwiftUI
import MarkdownUI

struct ConceptView: View {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var viewModel: ConceptViewModel
    @ViewModelProvider private var explainViewModel: ExplainViewModel
    
    init(concept: Concept, topicId: UUID) {
        _viewModel = StateObject(wrappedValue: DIContainer.shared.createConceptViewModel(concept: concept, topicId: topicId))
        _explainViewModel = ViewModelProvider(topicId: topicId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Breadcrumb Navigation
                if !viewModel.concept.metadata.path.isEmpty {
                    BreadcrumbView(path: viewModel.concept.metadata.path, topicId: viewModel.topicId)
                        .padding(.bottom, 8)
                }
                
                // Header
                Text(viewModel.concept.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)
                
                // Proficiency Card
                if let proficiency = viewModel.concept.proficiency {
                    ProficiencyCard(proficiency: proficiency)
                        .padding(.bottom, 8)
                }
                
                // Definition
                if let definition = viewModel.concept.definition {
                    Markdown(definition)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    Text("No definition available")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                // Subconcepts Section
                if !viewModel.concept.subConcepts.isEmpty {
                    SubconceptsSection(
                        subconcepts: viewModel.concept.subConcepts,
                        topicId: viewModel.topicId
                    )
                    .padding(.top, 16)
                }
                
                // Practice History
                if let proficiency = viewModel.concept.proficiency,
                   !proficiency.interactions.isEmpty {
                    PracticeHistorySection(interactions: proficiency.interactions)
                        .padding(.top, 8)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Learning Flow Button
                    Button(action: {
                        Task {
                            await startLearningFlow()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Start Learning Flow")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    // Add Subconcept Button
                    Button(action: { viewModel.showAddSubconceptSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Subconcept")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.isStartingLearningFlow) {
            QuestionFlowContainerView(topicId: viewModel.topicId)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showAddSubconceptSheet) {
            AddSubconceptSheet(viewModel: viewModel)
        }
    }
    
    private func startLearningFlow() async {
       await viewModel.startLearningFlow()
        try? await explainViewModel.generateQuestions(for: viewModel.concept.name)
    }
}

// MARK: - Supporting Views






