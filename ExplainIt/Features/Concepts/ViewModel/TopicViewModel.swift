//
//  TopicViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import Foundation

@MainActor
class TopicViewModel: ObservableObject {
    @Published private(set) var topic: Topic
    @Published var isLoading = false
    @Published var expandedConcepts = Set<UUID>()
    @Published var showDeleteConfirmation = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isStartingQuestionFlow = false
    
    private let topicRepository: TopicRepository
    private let conceptHierarchyService: ConceptHierarchyService
    private let questionGenerator: QuestionGenerationService
    
    init(topic: Topic,
         topicRepository: TopicRepository = TopicRepository(),
         conceptHierarchyService: ConceptHierarchyService = DefaultConceptHierarchyService(topicRepository: TopicRepository()),
         questionGenerator: QuestionGenerationService = OpenAIQuestionGenerationService(openAIService: .shared)) {
        self.topic = topic
        self.topicRepository = topicRepository
        self.conceptHierarchyService = conceptHierarchyService
        self.questionGenerator = questionGenerator
    }
    
    func deleteTopic() {
        topicRepository.removeTopic(topic)
    }
    
    func startQuestionFlow() async {
       isStartingQuestionFlow = true
    }
    
    func toggleConceptExpansion(_ conceptId: UUID) {
        if expandedConcepts.contains(conceptId) {
            expandedConcepts.remove(conceptId)
        } else {
            expandedConcepts.insert(conceptId)
        }
    }
}
