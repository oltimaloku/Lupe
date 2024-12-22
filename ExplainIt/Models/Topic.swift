//
//  File.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-15.
//

import Foundation

struct Topic: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    var concepts: [Concept]
}

