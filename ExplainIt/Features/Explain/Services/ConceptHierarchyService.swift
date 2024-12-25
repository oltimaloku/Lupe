//
//  ConceptHierarchyService.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-23.
//

import Foundation

protocol ConceptHierarchyService {
    func findConceptInHierarchy(name: String, in concepts: [Concept]) -> Concept?
    func updateConceptInHierarchy(_ concept: Concept, in concepts: inout [Concept]) throws
    func addConceptToHierarchy(_ concept: Concept, parentId: UUID?, in concepts: inout [Concept]) throws
}

class DefaultConceptHierarchyService: ConceptHierarchyService {
    func findConceptInHierarchy(name: String, in concepts: [Concept]) -> Concept? {
        func search(in concepts: [Concept]) -> Concept? {
            for concept in concepts {
                if concept.name.lowercased() == name.lowercased() {
                    return concept
                }
                if let found = search(in: concept.subConcepts) {
                    return found
                }
            }
            return nil
        }
        
        return concepts.compactMap { search(in: [$0]) }.first
    }
    
    func updateConceptInHierarchy(_ concept: Concept, in concepts: inout [Concept]) throws {
        func update(concepts: inout [Concept]) -> Bool {
            for index in concepts.indices {
                if concepts[index].id == concept.id {
                    concepts[index] = concept
                    return true
                }
                var updatedSubConcepts = concepts[index].subConcepts
                if update(concepts: &updatedSubConcepts) {
                    concepts[index].subConcepts = updatedSubConcepts
                    return true
                }
            }
            return false
        }
        
        if !update(concepts: &concepts) {
            throw ConceptError.conceptNotFound
        }
    }
    
    func addConceptToHierarchy(_ concept: Concept, parentId: UUID?, in concepts: inout [Concept]) throws {
        if parentId == nil {
            // Add as root concept
            concepts.append(concept)
            return
        }
        
        func addToParent(concepts: inout [Concept]) -> Bool {
            for index in concepts.indices {
                if concepts[index].id == parentId {
                    concepts[index].subConcepts.append(concept)
                    return true
                }
                var subConcepts = concepts[index].subConcepts
                if addToParent(concepts: &subConcepts) {
                    concepts[index].subConcepts = subConcepts
                    return true
                }
            }
            return false
        }
        
        if !addToParent(concepts: &concepts) {
            throw ConceptError.parentConceptNotFound
        }
    }
}

enum ConceptError: LocalizedError {
    case conceptNotFound
    case parentConceptNotFound
    
    var errorDescription: String? {
        switch self {
        case .conceptNotFound:
            return "The specified concept could not be found in the hierarchy"
        case .parentConceptNotFound:
            return "The specified parent concept could not be found in the hierarchy"
        }
    }
}
