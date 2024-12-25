//
//  ConceptHierarchyView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import SwiftUI

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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
