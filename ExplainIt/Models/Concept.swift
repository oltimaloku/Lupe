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
    var subConcepts: [Concept]
    var parentConceptId: UUID?
    var metadata: ConceptMetadata
    
    init(id: UUID = UUID(),
         name: String,
         definition: String? = nil,
         proficiency: ConceptProficiency? = nil,
         subConcepts: [Concept] = [],
         parentConceptId: UUID? = nil,
         metadata: ConceptMetadata? = nil) {
        self.id = id
        self.name = name
        self.definition = definition
        self.proficiency = proficiency
        self.subConcepts = subConcepts
        self.parentConceptId = parentConceptId
        self.metadata = metadata ?? ConceptMetadata(depth: 0, path: [id])
    }
}

struct ConceptMetadata: Codable {
    let depth: Int
    let path: [UUID]
    
    init(depth: Int, path: [UUID]) {
        self.depth = depth
        self.path = path
    }
}

enum ConceptHierarchyError: LocalizedError {
    case circularReference
    case conceptNotFound
    case invalidParentConcept
    case maxDepthExceeded
    case duplicateConceptInPath
    
    var errorDescription: String? {
        switch self {
        case .circularReference:
            return "Cannot create circular reference in concept hierarchy"
        case .conceptNotFound:
            return "Concept not found in hierarchy"
        case .invalidParentConcept:
            return "Invalid parent concept"
        case .maxDepthExceeded:
            return "Maximum hierarchy depth exceeded"
        case .duplicateConceptInPath:
            return "Duplicate concept found in hierarchy path"
        }
    }
}

