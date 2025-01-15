import Foundation

protocol ResponseGradingService {
    func gradeResponse(question: Question, response: String) async throws -> [FeedbackSegment]
    func calculateOverallGrade(for segments: [FeedbackSegment]) -> Double
}

class OpenAIGradingService: ResponseGradingService {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func gradeResponse(question: Question, response: String) async throws -> [FeedbackSegment] {
        let systemMessage = GPTMessage(
            role: "system",
            content: """
            You are a detailed grader for an educational app that assesses users' understanding of complex topics. \
            Grade the response using these specific criteria:
            1. Model Answer to Compare Against: "\(question.modelAnswer)"
            2. Required Key Points: \(question.rubric.keyPoints.joined(separator: ", "))
            3. Required Concepts: \(question.rubric.requiredConcepts.joined(separator: ", "))
            4. Grading Criteria:
            \(question.rubric.gradingCriteria.map { "   - \($0.description) (Weight: \($0.weight))" }.joined(separator: "\n"))
            
            Example good responses for reference:
            \(question.rubric.gradingCriteria.flatMap { criterion in
                criterion.examples.map { "- \($0)" }
            }.joined(separator: "\n"))
            
            The user's response is a casual speech transcript, so do not penalize for punctuation, grammar, or informal phrasing. \
            Focus solely on the correctness and clarity of the content in their explanation. Do not return markdown.
            """
        )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
            Grade this response to the question "\(question.text)".
            Response: "\(response)"
            
            For each sentence, evaluate based on the provided model answer, key points, required concepts, and grading criteria.
            Return feedback as a JSON array with this structure for each sentence:
            {
                "text": "sentence from response",
                "feedbackType": "correct",
                "explanation": "explanation referencing specific criteria from the rubric",
                "concept": "concept from the required concepts list being addressed",
                "keyPointsAddressed": ["specific key points addressed in this sentence"],
                "criteriaMatched": ["specific grading criteria matched"],
                "isNewConcept": false,
                "relatedToConceptId": null
            }
            
            For concepts that are not in the required concepts list but are relevant to the topic:
            - Set isNewConcept to true
            - Set relatedToConceptId to null
            - Still provide feedback on correctness and explanation
            
            Required concepts and their IDs:
            \(question.rubric.requiredConcepts.map { concept in
                "- \(concept): \(UUID())"
            }.joined(separator: "\n"))
            
            Ensure each feedback maps to specific criteria and concepts from the rubric.
            """
        )
        
        print("System message: \n \(systemMessage) \n userGPTMessage: \n \(userGPTMessage)")
        
        let response = try await openAIService.chatCompletion(
            messages: [systemMessage, userGPTMessage]
        )
        
        guard let content = response.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw GradingError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        print("content: \(content)")
        return try decoder.decode([FeedbackSegment].self, from: data)
    }
    
    func calculateOverallGrade(for segments: [FeedbackSegment]) -> Double {
        let totalCount = segments.count
        let weightedPoints = segments.reduce(0.0) { points, segment in
            let basePoints = switch segment.feedbackType {
            case .correct: 1.0
            case .partiallyCorrect: 0.5
            case .incorrect: 0.0
            }
            
            let bonusPoints = Double(segment.keyPointsAddressed.count + segment.criteriaMatched.count) * 0.1
            return points + basePoints + min(bonusPoints, 0.5)
        }
        
        guard totalCount > 0 else { return 0.0 }
        return min(weightedPoints / Double(totalCount), 1.0)
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
