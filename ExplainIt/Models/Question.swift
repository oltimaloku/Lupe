
import Foundation

struct Question: Codable, Identifiable {
    var id: UUID
    let text: String
    let modelAnswer: String
    let concepts: [String]
    let rubric: GradingRubric
    
    // Custom decoder to handle potential string IDs from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle either UUID or String ID from API
        if let stringId = try? container.decode(String.self, forKey: .id) {
            // If string ID provided, generate new UUID
            id = UUID()
        } else {
            // If UUID provided, use it
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        text = try container.decode(String.self, forKey: .text)
        modelAnswer = try container.decode(String.self, forKey: .modelAnswer)
        concepts = try container.decode([String].self, forKey: .concepts)
        rubric = try container.decode(GradingRubric.self, forKey: .rubric)
    }
    
    // Manual initializer for creating questions
    init(id: UUID = UUID(),
         text: String,
         modelAnswer: String,
         concepts: [String],
         rubric: GradingRubric) {
        self.id = id
        self.text = text
        self.modelAnswer = modelAnswer
        self.concepts = concepts
        self.rubric = rubric
    }
    
    // Ensure proper encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(modelAnswer, forKey: .modelAnswer)
        try container.encode(concepts, forKey: .concepts)
        try container.encode(rubric, forKey: .rubric)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text, modelAnswer, concepts, rubric
    }
}

struct GradingRubric: Codable {
    let keyPoints: [String]
    let requiredConcepts: [String]
    let gradingCriteria: [GradingCriterion]
    
    enum CodingKeys: String, CodingKey {
        case keyPoints = "keyPoints"  // Ensure consistent casing
        case requiredConcepts = "requiredConcepts"
        case gradingCriteria = "gradingCriteria"
    }
}

struct GradingCriterion: Codable {
    let description: String
    let weight: Double
    let examples: [String]
    
    // Add validation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        description = try container.decode(String.self, forKey: .description)
        weight = try container.decode(Double.self, forKey: .weight)
        examples = try container.decode([String].self, forKey: .examples)
        
        // Validate weight is between 0 and 1
        guard weight >= 0 && weight <= 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .weight,
                in: container,
                debugDescription: "Weight must be between 0 and 1"
            )
        }
    }
    
    init(description: String, weight: Double, examples: [String]) {
            self.description = description
            self.weight = weight
            self.examples = examples
        }
}

// Extension to validate rubrics
extension GradingRubric {
    func validate() throws {
        // Ensure we have at least one key point
        guard !keyPoints.isEmpty else {
            throw ValidationError.emptyKeyPoints
        }
        
        // Ensure we have at least one required concept
        guard !requiredConcepts.isEmpty else {
            throw ValidationError.emptyRequiredConcepts
        }
        
        // Ensure we have at least one grading criterion
        guard !gradingCriteria.isEmpty else {
            throw ValidationError.emptyGradingCriteria
        }
        
        // Validate weights sum to approximately 1
        let totalWeight = gradingCriteria.reduce(0) { $0 + $1.weight }
        guard abs(totalWeight - 1.0) < 0.001 else {
            throw ValidationError.invalidWeights(total: totalWeight)
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyKeyPoints
    case emptyRequiredConcepts
    case emptyGradingCriteria
    case invalidWeights(total: Double)
    
    var errorDescription: String? {
        switch self {
        case .emptyKeyPoints:
            return "Rubric must contain at least one key point"
        case .emptyRequiredConcepts:
            return "Rubric must contain at least one required concept"
        case .emptyGradingCriteria:
            return "Rubric must contain at least one grading criterion"
        case .invalidWeights(let total):
            return "Grading criteria weights must sum to 1.0 (current: \(total))"
        }
    }
}
