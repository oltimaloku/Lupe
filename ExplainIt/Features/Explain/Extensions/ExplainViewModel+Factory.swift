import Foundation

extension ExplainViewModel {
    static func create(
        questionGenerator: QuestionGenerationService? = nil,
        gradingService: ResponseGradingService? = nil,
        definitionService: ConceptDefinitionService? = nil,
        topicRepository: TopicRepository? = nil,
        conceptHierarchyService: ConceptHierarchyService? = nil
    ) -> ExplainViewModel {
        let openAIService = OpenAIService.shared
        
        return ExplainViewModel(
            questionGenerator: questionGenerator ?? OpenAIQuestionGenerationService(openAIService: openAIService),
            gradingService: gradingService ?? OpenAIGradingService(openAIService: openAIService),
            definitionService: definitionService ?? OpenAIConceptDefinitionService(openAIService: openAIService),
            topicRepository: topicRepository ?? TopicRepository(),
            conceptHierarchyService: conceptHierarchyService ?? DefaultConceptHierarchyService()
        )
    }
    
    static func createForPreview() -> ExplainViewModel {
        let mockTopics = getMockTopics()
        let repository = TopicRepository()
        mockTopics.forEach { repository.addTopic($0) }
        
        return create(topicRepository: repository)
    }
    
    private static func getMockTopics() -> [Topic] {
        return [
            Topic(
                id: UUID(),
                name: "Mathematics",
                icon: "function",
                concepts: [
                    Concept(id: UUID(), name: "Calculus", definition: "The mathematical study of continuous change."),
                    Concept(id: UUID(), name: "Linear Algebra", definition: nil),
                    Concept(id: UUID(), name: "Probability and Statistics", definition: "The study of randomness and data interpretation.")
                ]
            ),
            Topic(
                id: UUID(),
                name: "Biology",
                icon: "leaf",
                concepts: [
                    Concept(id: UUID(), name: "Cell Structure", definition: "The composition and organization of cells."),
                    Concept(id: UUID(), name: "DNA and Genetics", definition: "The study of heredity and genetic information."),
                    Concept(id: UUID(), name: "Evolutionary Theory", definition: nil)
                ]
            ),
            Topic(
                id: UUID(),
                name: "Technology",
                icon: "gear",
                concepts: [
                    Concept(id: UUID(), name: "Artificial Intelligence", definition: "The simulation of human intelligence in machines."),
                    Concept(id: UUID(), name: "Cybersecurity", definition: nil),
                    Concept(id: UUID(), name: "Blockchain", definition: "A distributed ledger technology for secure transactions.")
                ]
            )
        ]
    }
}
