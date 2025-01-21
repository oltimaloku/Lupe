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
        let repository = topicRepository ?? TopicRepository()
        
        return ExplainViewModel(
            questionGenerator: questionGenerator ?? OpenAIQuestionGenerationService(openAIService: openAIService),
            gradingService: gradingService ?? OpenAIGradingService(openAIService: openAIService),
            definitionService: definitionService ?? OpenAIConceptDefinitionService(openAIService: openAIService),
            topicRepository: topicRepository ?? TopicRepository(),
            conceptHierarchyService: conceptHierarchyService ?? DefaultConceptHierarchyService(topicRepository: repository)
        )
    }
    
    static func createForPreview() -> ExplainViewModel {
        let mockTopics = getMockTopics()
        let repository = TopicRepository()
        mockTopics.forEach { repository.addTopic($0) }
        
        let viewModel = create(topicRepository: repository)
        
        // Add mock questions
        let mockQuestions = [
            Question(
                id: UUID(),
                text: "Explain how calculus is used to solve real-world problems.",
                modelAnswer: "Calculus has numerous real-world applications. In physics, derivatives help us understand motion and rates of change, while integrals help us calculate total quantities. In engineering, calculus is used to optimize designs and analyze systems. In economics, it helps analyze market trends and maximize profits.",
                concepts: ["Calculus", "Real-world Applications", "Problem Solving"],
                rubric: GradingRubric(
                    keyPoints: [
                        "Identifies practical applications",
                        "Demonstrates understanding of calculus concepts",
                        "Links theory to practice"
                    ],
                    requiredConcepts: ["Calculus"],
                    gradingCriteria: [
                        GradingCriterion(
                            description: "Understanding of core concepts",
                            weight: 0.4,
                            examples: ["Shows clear understanding of derivatives and integrals"]
                        ),
                        GradingCriterion(
                            description: "Application examples",
                            weight: 0.3,
                            examples: ["Provides specific, relevant examples"]
                        ),
                        GradingCriterion(
                            description: "Clarity and coherence",
                            weight: 0.3,
                            examples: ["Explains concepts clearly and logically"]
                        )
                    ]
                )
            ),
            Question(
                id: UUID(),
                text: "Describe the fundamental theorem of calculus and its importance.",
                modelAnswer: "The Fundamental Theorem of Calculus establishes the relationship between differentiation and integration. It shows that these operations are inverse processes, connecting the concept of the derivative with the definite integral. This theorem is crucial as it provides a practical way to calculate definite integrals using antiderivatives.",
                concepts: ["Calculus", "Integration", "Differentiation"],
                rubric: GradingRubric(
                    keyPoints: [
                        "States the theorem correctly",
                        "Explains the relationship between derivatives and integrals",
                        "Discusses practical implications"
                    ],
                    requiredConcepts: ["Calculus", "Integration"],
                    gradingCriteria: [
                        GradingCriterion(
                            description: "Accurate theorem explanation",
                            weight: 0.5,
                            examples: ["Correctly states and explains the theorem"]
                        ),
                        GradingCriterion(
                            description: "Understanding implications",
                            weight: 0.5,
                            examples: ["Explains why the theorem is important"]
                        )
                    ]
                )
            )
        ]
        
        // Set up the initial state
        viewModel.currentQuestions = mockQuestions
        viewModel.currentTopic = mockTopics.first
        
        // Add a mock response for preview
        if let firstQuestion = mockQuestions.first {
            viewModel.userResponses[firstQuestion.id] = "Calculus is used extensively in real-world applications. For example, in physics, we use derivatives to calculate velocity and acceleration from position functions. In economics, we use calculus to optimize profit functions and analyze marginal costs..."
        }
        
        for question in mockQuestions {
                let feedbackSegments = [
                    FeedbackSegment(
                        text: "Calculus helps us understand rates of change in physics and engineering",
                        feedbackType: .correct,
                        explanation: "Excellent explanation of practical applications",
                        concept: "Calculus",
                        keyPointsAddressed: ["Identifies practical applications"],
                        criteriaMatched: ["Application examples"],
                        isNewConcept: false
                    ),
                    FeedbackSegment(
                        text: "Derivatives are used to optimize functions",
                        feedbackType: .correct,
                        explanation: "Good understanding of optimization applications",
                        concept: "Derivatives",
                        keyPointsAddressed: ["Demonstrates understanding of calculus concepts"],
                        criteriaMatched: ["Understanding of core concepts"],
                        definition: "Rate of change of a function",
                        isNewConcept: true
                    ),
                    FeedbackSegment(
                        text: "Integration helps find areas and volumes",
                        feedbackType: .partiallyCorrect,
                        explanation: "Basic understanding shown but could be more detailed",
                        concept: "Integration",
                        keyPointsAddressed: ["Links theory to practice"],
                        criteriaMatched: ["Clarity and coherence"],
                        definition: "Process of finding the area under a curve",
                        isNewConcept: true
                    )
                ]
                
                viewModel.questionFeedback[question.id] = FeedbackAnalysis(
                    segments: feedbackSegments,
                    overallGrade: 0.85
                )
                
                // Add mock user responses
                viewModel.userResponses[question.id] = """
                Calculus is used extensively in real-world applications. In physics, we use derivatives to calculate velocity and acceleration from position functions. In engineering, calculus helps optimize designs and solve complex problems. Integration is useful for calculating areas and volumes in various applications.
                """
            }
        
        return viewModel
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
