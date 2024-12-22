//
//  ExplainViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-21.
//

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
    
    // MARK: - Initialization
    init(
        questionGenerator: QuestionGenerationService,
        gradingService: ResponseGradingService,
        definitionService: ConceptDefinitionService,
        topicRepository: TopicRepository
    ) {
        self.questionGenerator = questionGenerator
        self.gradingService = gradingService
        self.definitionService = definitionService
        self.topicRepository = topicRepository
        self.topics = topicRepository.topics
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
    func setupTopicAndGenerateQuestions(for topicName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Create and set new topic
        let newTopic = Topic(id: UUID(), name: topicName, icon: "book", concepts: [])
        currentTopic = newTopic
        topicRepository.addTopic(newTopic)
        
        // Generate and store questions
        currentQuestions = try await questionGenerator.generateQuestions(for: topicName)
        
        // Reset responses and feedback
        userResponses.removeAll()
        questionFeedback.removeAll()
        currentQuestionIndex = 0
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
        } catch {
            print("Error grading response: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Concept Management
    func getDefinition(for concept: String) async throws -> String {
        if let cachedDefinition = definitions[concept] {
            return cachedDefinition
        }
        
        let definition = try await definitionService.getDefinition(for: concept)
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
}
