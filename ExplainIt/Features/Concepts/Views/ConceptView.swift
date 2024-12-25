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



struct SubconceptsSection: View {
    let subconcepts: [Concept]
    let topicId: UUID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subconcepts")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(subconcepts) { subconcept in
                NavigationLink(destination: ConceptView(concept: subconcept, topicId: topicId)) {
                    SubconceptCard(concept: subconcept)
                }
            }
        }
    }
}

struct SubconceptCard: View {
    let concept: Concept
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(concept.name)
                    .font(.headline)
                
                Spacer()
                
                if let proficiency = concept.proficiency {
                    ProficiencyBadge(proficiency: proficiency)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            if let definition = concept.definition {
                Text(definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if !concept.subConcepts.isEmpty {
                HStack {
                    Image(systemName: "rectangle.stack")
                    Text("\(concept.subConcepts.count) subconcepts")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AddSubconceptSheet: View {
    @ObservedObject var viewModel: ConceptViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var conceptName = ""
    @State private var conceptDefinition = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Subconcept")) {
                    TextField("Name", text: $conceptName)
                    TextEditor(text: $conceptDefinition)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Subconcept")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { addSubconcept() }
                    .disabled(conceptName.isEmpty || viewModel.isLoading)
            )
            .alert("Error", isPresented: .constant(viewModel.showError)) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private func addSubconcept() {
        let newConcept = Concept(
            name: conceptName,
            definition: conceptDefinition.isEmpty ? nil : conceptDefinition,
            parentConceptId: viewModel.concept.id,
            metadata: ConceptMetadata(
                depth: viewModel.concept.metadata.depth + 1,
                path: viewModel.concept.metadata.path + [viewModel.concept.id]
            )
        )
        
        Task {
            do {
                try await viewModel.addSubconcept(newConcept)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Error is handled by the view model
            }
        }
    }
}


