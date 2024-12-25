//
//  Concept.swift
//  ExplainIt
//

import Foundation

struct Concept: Codable, Identifiable {
    let id: UUID
    let name: String
    let definition: String?
    var proficiency: ConceptProficiency?
    var subConcepts: [Concept] // Add this for hierarchy
    var parentConceptId: UUID? // Add this to track relationship
    
    init(id: UUID = UUID(),
         name: String,
         definition: String? = nil,
         proficiency: ConceptProficiency? = nil,
         subConcepts: [Concept] = [],
         parentConceptId: UUID? = nil) {
        self.id = id
        self.name = name
        self.definition = definition
        self.proficiency = proficiency
        self.subConcepts = subConcepts
        self.parentConceptId = parentConceptId
    }
}
