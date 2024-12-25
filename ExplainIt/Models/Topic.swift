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

extension Topic: CustomDebugStringConvertible {
    var debugDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "Could not encode Topic"
        } catch {
            return "Error encoding Topic: \(error)"
        }
    }
}

enum TopicError: LocalizedError {
    case topicNotFound
    case conceptAlreadyExists(String)
    case conceptNotFound
    
    var errorDescription: String? {
        switch self {
        case .topicNotFound:
            return "The specified topic could not be found"
        case .conceptAlreadyExists(let conceptName):
            return "A concept with name '\(conceptName)' already exists in this topic"
        case .conceptNotFound:
            return "The specified concept could not be found"
        }
    }
}
