import SwiftUI

struct TopicView: View {
    @StateObject private var viewModel: TopicViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    init(topic: Topic) {
        _viewModel = StateObject(wrappedValue: TopicViewModel(topic: topic))
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
            
            Button(action: { Task { await viewModel.startQuestionFlow() } }) {
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
            QuestionFlowContainerView().environmentObject(ExplainViewModel.create()) // TODO: should we pass something in here?
        }
    }
}
// MARK: - Supporting Views
struct ConceptHierarchyView: View {
    let concept: Concept
    let depth: Int
    @Binding var expandedConcepts: Set<UUID>
    let onToggleExpansion: (UUID) -> Void
    let topicId: UUID
    
    private let indentAmount: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ConceptView(concept: concept, topicId: topicId)) {
                HStack {
                    // Indentation based on depth
                    if depth > 0 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: CGFloat(depth) * indentAmount)
                    }
                    
                    // Expand/Collapse button for concepts with children
                    if !concept.subConcepts.isEmpty {
                        Button(action: { onToggleExpansion(concept.id) }) {
                            Image(systemName: expandedConcepts.contains(concept.id) ? "chevron.down" : "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Concept Card
                    ConceptCardContent(concept: concept)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Subconcepts (if expanded)
            if expandedConcepts.contains(concept.id) {
                ForEach(concept.subConcepts) { subconcept in
                    ConceptHierarchyView(
                        concept: subconcept,
                        depth: depth + 1,
                        expandedConcepts: $expandedConcepts,
                        onToggleExpansion: onToggleExpansion,
                        topicId: topicId
                    )
                }
            }
        }
    }
}

struct ConceptCardContent: View {
    let concept: Concept
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(concept.name)
                    .font(.headline)
                
                if let proficiency = concept.proficiency {
                    Spacer()
                    ProficiencyBadge(proficiency: proficiency)
                }
            }
            
            if let definition = concept.definition {
                Text(definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

