import Foundation
import Combine

@MainActor
class ExplainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var currentTopic: Topic?
    @Published var topics: [Topic] = []
    @Published var currentQuestions: [Question] = []
    @Published var userResponses: [UUID: String] = [:]
    @Published var questionFeedback: [UUID: FeedbackAnalysis] = [:]
    @Published var showingFeedback = false
    @Published var currentQuestionIndex = 0
    @Published var definitions: [String: String] = [:]
    
    // MARK: - Dependencies
    private let questionGenerator: QuestionGenerationService
    private let gradingService: ResponseGradingService
    private let definitionService: ConceptDefinitionService
    private let topicRepository: TopicRepository
    private let proficiencyManager = ConceptProficiencyManager.shared
    private let conceptHierarchyService: ConceptHierarchyService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        questionGenerator: QuestionGenerationService,
        gradingService: ResponseGradingService,
        definitionService: ConceptDefinitionService,
        topicRepository: TopicRepository,
        conceptHierarchyService: ConceptHierarchyService
    ) {
        self.questionGenerator = questionGenerator
        self.gradingService = gradingService
        self.definitionService = definitionService
        self.topicRepository = topicRepository
        self.conceptHierarchyService = conceptHierarchyService
        
        // Load initial topics
        self.topics = topicRepository.topics
        
        // Set up observation of topics changes
        topicRepository.$topics
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedTopics in
                self?.topics = updatedTopics
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }
    
    // MARK: - Navigation Methods
    func setNextQuestion() {
        if currentQuestionIndex < currentQuestions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func setPreviousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func showFeedbackView() {
        showingFeedback = true
    }
    
    func showExplainView() {
        showingFeedback = false
    }
    
    // MARK: - Topic and Question Management
    func generateQuestions(for topicName: String) async throws {
        isLoading = true
        // sets isLoading to false once the function completes
        defer { isLoading = false }
        print("topicName: \(topicName)")
        // Generate and store questions
        currentQuestions = try await questionGenerator.generateQuestionsForTopic(for: topicName)
        print("currentQuestions for \(topicName): \(currentQuestions)")
        // Reset responses and feedback
        userResponses.removeAll()
        questionFeedback.removeAll()
        currentQuestionIndex = 0
    }
    
    
    func initializeLearningFlow(for topicId: UUID, for concept: Concept) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let topic = try topicRepository.getTopic(with: topicId)
        
        currentTopic = topic
        
        currentQuestions = try await questionGenerator.generateQuestionsForConcept(for: concept, in: topic)
        
        userResponses.removeAll()
        questionFeedback.removeAll()
        currentQuestionIndex = 0
    }
       
       // New method just for creating a topic
       func createTopic(name: String) throws -> Topic {
           // Create new topic
           let newTopic = Topic(
               id: UUID(),
               name: name,
               icon: "book",
               concepts: []
           )
           
           // Add to repository
           topicRepository.addTopic(newTopic)
           
           return newTopic
       }
       
       // Updated method that uses the split functionality
       func initializeTopic(for topicName: String) async throws {
           isLoading = true
           defer { isLoading = false }
           
           currentTopic = try createTopic(name: topicName)
           
           // Generate questions
           try await generateQuestions(for: topicName)
       }
    
    func deleteTopic(_ topic: Topic) {
            topicRepository.removeTopic(topic)
            // Reset current topic if we're deleting it
            if currentTopic?.id == topic.id {
                currentTopic = nil
            }
        }
    
    // MARK: - Response Management
    func saveResponse(for question: Question, text: String) {
        userResponses[question.id] = text
    }
    
    func getResponse(for questionId: UUID) -> String? {
        return userResponses[questionId]
    }
    
    func resetFeedback(for questionId: UUID) {
        questionFeedback[questionId] = nil
    }
    
    // MARK: - Grading
    func gradeResponse(question: Question, text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let feedbackSegments = try await gradingService.gradeResponse(question: question, response: text)
            let overallGrade = gradingService.calculateOverallGrade(for: feedbackSegments)
            let feedback = FeedbackAnalysis(segments: feedbackSegments, overallGrade: overallGrade)
            
            questionFeedback[question.id] = feedback
            
            // Update proficiency for each concept mentioned in the feedback
            try await updateConceptProficiencies(with: feedbackSegments, feedback: feedback)
        } catch {
            print("Error grading response: \(error.localizedDescription)")
        }
    }

    // Separate method to handle concept updates
    private func updateConceptProficiencies(with segments: [FeedbackSegment], feedback: FeedbackAnalysis) throws {
        guard var currentTopic = currentTopic else {
            throw TopicError.topicNotFound
        }
        
        for segment in segments {
            if let concept = conceptHierarchyService.findConceptInHierarchy(
                name: segment.concept ?? "",
                in: currentTopic.concepts
            ) {
                var updatedConcept = concept
                // Pass the conceptHierarchyService to handle parent updates
                proficiencyManager.updateFromFeedback(
                    concept: &updatedConcept,
                    feedbackAnalysis: feedback,
                    conceptHierarchy: conceptHierarchyService, topicId: currentTopic.id
                )
                
                // Update the concept in the hierarchy
                try conceptHierarchyService.updateConceptInHierarchy(
                    updatedConcept,
                    in: &currentTopic.concepts
                )
            }
        }
        
        // Update topic only once after all concepts have been updated
        self.currentTopic = currentTopic
        try topicRepository.updateTopic(currentTopic)
    }
        
    
    private func findConceptByName(_ name: String) -> Concept? {
            return currentTopic?.concepts.first {
                $0.name.lowercased() == name.lowercased()
            }
        }
        
        private func updateConceptInTopic(_ concept: Concept) throws {
            guard var currentTopic = currentTopic else {
                throw TopicError.topicNotFound
            }
            
            if let index = currentTopic.concepts.firstIndex(where: { $0.id == concept.id }) {
                currentTopic.concepts[index] = concept
                self.currentTopic = currentTopic
                try topicRepository.updateTopic(currentTopic)
            }
        }
    
    // MARK: - Concept Management
    func getDefinition(for concept: String) async throws -> String {
        if let cachedDefinition = definitions[concept] {
            return cachedDefinition
        }
        
        guard let topicName = currentTopic?.name else {
            throw TopicError.topicNotFound
        }
        
        let definition = try await definitionService.getDefinition(for: concept, in: topicName)
        definitions[concept] = definition
        return definition
    }
    
    func addNewConceptFromFeedback(conceptName: String, definition: String?) throws {
        guard let currentTopic = currentTopic else {
            throw TopicError.topicNotFound
        }
        
        let newConcept = Concept(id: UUID(), name: conceptName, definition: definition)
        try topicRepository.addConceptToTopic(newConcept, topicId: currentTopic.id)
        
        if let def = definition {
            definitions[conceptName] = def
        }
    }
    
    func addSubconcept(_ newConcept: Concept, to parentConcept: Concept) async throws {
            guard var currentTopic = currentTopic else {
                throw TopicError.topicNotFound
            }
            
            var concepts = currentTopic.concepts
            try conceptHierarchyService.addConceptToHierarchy(
                newConcept,
                parentId: parentConcept.id,
                in: &concepts
            )
            
            currentTopic.concepts = concepts
            try topicRepository.updateTopic(currentTopic)
        }
    
    func resetCurrentSession() {
        // Reset current question state
        currentQuestionIndex = 0
        userResponses.removeAll()
        questionFeedback.removeAll()
        currentQuestions.removeAll()
        showingFeedback = false
    }
    
    func printState() {
        print("ExplainViewModel State: \n")
        print("  • isLoading: \(isLoading) \n")
        print("  • currentTopic: \(String(describing: currentTopic)) \n")
        print("  • topics: \(topics) \n")
        print("  • currentQuestions: \(currentQuestions) \n")
        print("  • userResponses: \(userResponses) \n")
        print("  • questionFeedback: \(questionFeedback) \n")
        print("  • showingFeedback: \(showingFeedback) \n")
        print("  • currentQuestionIndex: \(currentQuestionIndex) \n")
        print("  • definitions: \(definitions) \n")
    }
}
