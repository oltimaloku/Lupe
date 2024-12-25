//
//  ConceptViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import Foundation

@MainActor
class ConceptViewModel: ObservableObject {
    // MARK: - Public Properties
    let topicId: UUID
    
    @Published private(set) var concept: Concept
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showAddSubconceptSheet = false
    @Published var isStartingLearningFlow = false
    
    // MARK: - Private Properties
    private let topicRepository: TopicRepository
    private let conceptHierarchyService: ConceptHierarchyService
    private let questionGenerator: QuestionGenerationService
    
    // MARK: - Initialization
    init(concept: Concept,
         topicId: UUID,
         topicRepository: TopicRepository = TopicRepository(),
         conceptHierarchyService: ConceptHierarchyService = DefaultConceptHierarchyService(topicRepository: TopicRepository()),
         questionGenerator: QuestionGenerationService = OpenAIQuestionGenerationService(openAIService: .shared)) {
        self.concept = concept
        self.topicId = topicId
        self.topicRepository = topicRepository
        self.conceptHierarchyService = conceptHierarchyService
        self.questionGenerator = questionGenerator
    }
    
    // MARK: - Public Methods
    func startLearningFlow() async {
       isStartingLearningFlow = true
    }
    
    func addSubconcept(_ newConcept: Concept) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await addSubconceptToHierarchy(newConcept)
            try await refreshConcept()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func addSubconceptToHierarchy(_ newConcept: Concept) async throws {
        guard var topic = topicRepository.topics.first(where: { $0.id == topicId }) else {
            throw TopicError.topicNotFound
        }
        
        var concepts = topic.concepts
        try conceptHierarchyService.addConceptToHierarchy(
            newConcept,
            parentId: concept.id,
            in: &concepts
        )
        
        topic.concepts = concepts
        try topicRepository.updateTopic(topic)
    }
    
    private func refreshConcept() async throws {
        guard let topic = topicRepository.topics.first(where: { $0.id == topicId }),
              let updated = conceptHierarchyService.findConceptInHierarchy(name: concept.name, in: topic.concepts) else {
            throw TopicError.conceptNotFound
        }
        concept = updated
    }
}
