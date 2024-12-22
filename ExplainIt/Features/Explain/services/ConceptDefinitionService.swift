import Foundation

protocol ConceptDefinitionService {
    func getDefinition(for concept: String) async throws -> String
    func clearCache()
}

class OpenAIConceptDefinitionService: ConceptDefinitionService {
    private let openAIService: OpenAIService
    private var definitionCache: [String: String] = [:]
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func getDefinition(for concept: String) async throws -> String {
        if let cachedDefinition = definitionCache[concept] {
            return cachedDefinition
        }
        
        let systemMessage = GPTMessage(
            role: "system",
            content: """
            You are an AI assistant providing detailed, concise definitions for educational purposes. \
            Your task is to define the concept and explain its importance.
            """
        )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
            Please provide a detailed definition of the concept "\(concept)" and explain its relevance or application in learning or practical contexts.
            """
        )
        
        let response = try await openAIService.chatCompletion(
            messages: [systemMessage, userGPTMessage]
        )
        
        guard let content = response.choices.first?.message.content else {
            throw GradingError.invalidResponse
        }
        
        let definition = content.trimmingCharacters(in: .whitespacesAndNewlines)
        definitionCache[concept] = definition
        return definition
    }
    
    func clearCache() {
        definitionCache.removeAll()
    }
}
