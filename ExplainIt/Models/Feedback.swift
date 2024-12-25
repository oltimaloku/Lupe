import SwiftUI

// FeedbackAnalysis.swift
struct FeedbackAnalysis: Identifiable {
    let id = UUID()
    let segments: [FeedbackSegment]
    let overallGrade: Double
}

struct FeedbackSegment: Identifiable, Codable {
    let id: UUID
    let text: String
    let feedbackType: FeedbackType
    let explanation: String
    let concept: String
    let keyPointsAddressed: [String]
    let criteriaMatched: [String]
    let definition: String?
    let isNewConcept: Bool
    let relatedToConceptId: UUID?
    
    init(id: UUID = UUID(),
         text: String,
         feedbackType: FeedbackType,
         explanation: String,
         concept: String,
         keyPointsAddressed: [String],
         criteriaMatched: [String],
         definition: String? = nil,
         isNewConcept: Bool,
         relatedToConceptId: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.feedbackType = feedbackType
        self.explanation = explanation
        self.concept = concept
        self.keyPointsAddressed = keyPointsAddressed
        self.criteriaMatched = criteriaMatched
        self.definition = definition
        self.isNewConcept = isNewConcept
        self.relatedToConceptId = relatedToConceptId
    }
    
    // Custom decoder to handle the feedbackType coming from the API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = UUID()
        text = try container.decode(String.self, forKey: .text)
        explanation = try container.decode(String.self, forKey: .explanation)
        concept = try container.decode(String.self, forKey: .concept)
        keyPointsAddressed = try container.decode([String].self, forKey: .keyPointsAddressed)
        criteriaMatched = try container.decode([String].self, forKey: .criteriaMatched)
        definition = try container.decodeIfPresent(String.self, forKey: .definition)
        isNewConcept = try container.decode(Bool.self, forKey: .isNewConcept)
        relatedToConceptId = try container.decodeIfPresent(UUID.self, forKey: .relatedToConceptId)
        
        let feedbackTypeString = try container.decode(String.self, forKey: .feedbackType)
        switch feedbackTypeString.lowercased() {
        case "correct":
            feedbackType = .correct
        case "partially correct", "partially_correct", "partial":
            feedbackType = .partiallyCorrect
        case "incorrect":
            feedbackType = .incorrect
        
        default:
            throw DecodingError.dataCorruptedError(forKey: .feedbackType,
                in: container,
                debugDescription: "Invalid feedback type")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case text, feedbackType, explanation, concept, keyPointsAddressed, criteriaMatched, definition, isNewConcept, relatedToConceptId
    }
}

enum FeedbackType: String, Codable {
    case correct
    case partiallyCorrect
    case incorrect
    
    var color: Color {
        switch self {
        case .correct: return .green.opacity(0.3)
        case .partiallyCorrect: return .yellow.opacity(0.3)
        case .incorrect: return .red.opacity(0.3)
        }
    }
}

enum GradingError: LocalizedError {
    case invalidResponse
    case invalidGradingCriteria(String)
    case missingRequiredConcepts([String])
    case gradingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to get a valid response from the grading system"
        case .invalidGradingCriteria(let criteria):
            return "Invalid grading criteria: \(criteria)"
        case .missingRequiredConcepts(let concepts):
            return "Response missing required concepts: \(concepts.joined(separator: ", "))"
        case .gradingFailed(let error):
            return "Grading failed: \(error.localizedDescription)"
        }
    }
}
