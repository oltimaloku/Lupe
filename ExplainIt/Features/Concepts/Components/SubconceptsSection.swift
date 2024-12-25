//
//  SubconceptsSection.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import SwiftUI

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
