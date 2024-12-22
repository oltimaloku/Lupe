//
//  Concept.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-15.
//

import Foundation

struct Concept: Codable, Identifiable {
    let id: UUID
    let name: String
    let definition: String?
    
    init(id: UUID = UUID(), name: String, definition: String? = nil) {
        self.id = id
        self.name = name
        self.definition = definition
    }
}
