//
//  ConceptProficiency.swift
//  ExplainIt
//

import Foundation

struct ConceptProficiency: Codable {
    let conceptId: UUID
    var proficiencyScore: Double // 0-100
    var confidence: Double // 0-1
    var lastInteractionDate: Date
    var interactions: [ProficiencyInteraction]
    
    init(conceptId: UUID) {
        self.conceptId = conceptId
        self.proficiencyScore = 0
        self.confidence = 0.3 // Starting confidence
        self.lastInteractionDate = Date()
        self.interactions = []
    }
    
    var masteryLevel: MasteryLevel {
        switch proficiencyScore {
        case 0..<40: return .novice
        case 40..<60: return .beginner
        case 60..<75: return .intermediate
        case 75..<90: return .advanced
        default: return .expert
        }
    }
}

// MARK: - Supporting Types
struct ProficiencyInteraction: Codable {
    let date: Date
    let interactionType: InteractionType
    let scoreImpact: Double
    let details: String
    let feedbackId: UUID? // Link to FeedbackAnalysis if applicable
}

enum InteractionType: String, Codable {
    case explanation // From ExplainView responses
    case quiz       // From question responses
    case review     // From concept reviews
    case decay      // Time-based decay
    case indirect 
}

enum MasteryLevel: String, Codable {
    case novice
    case beginner
    case intermediate
    case advanced
    case expert
    
    var description: String {
        switch self {
        case .novice: return "Just starting to learn this concept"
        case .beginner: return "Basic understanding with room for improvement"
        case .intermediate: return "Good grasp of fundamentals"
        case .advanced: return "Strong understanding and application"
        case .expert: return "Mastery of the concept"
        }
    }
}
