//
//  PromptViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import SwiftUI
import Combine

@MainActor
class PromptViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var isLoading: Bool = false
    
    private let topicRepository: TopicRepository
    private let diContainer: DIContainer
    private var cancellables = Set<AnyCancellable>()
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        self.topicRepository = diContainer.topicRepository
        
        // Observe topics changes
        topicRepository.$topics
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedTopics in
                self?.topics = updatedTopics
            }
            .store(in: &cancellables)
    }
    
    func initializeTopic(name: String) async throws -> UUID {
        isLoading = true
        defer { isLoading = false }
        
        // Create new topic
        let topic = Topic(
            id: UUID(),
            name: name,
            icon: "book",
            concepts: []
        )
        
        // Add to repository
        topicRepository.addTopic(topic)
        
        // Initialize the topic's ExplainViewModel
        let viewModel = diContainer.explainViewModel(for: topic.id)
        try await viewModel.initializeTopic(for: name)
        
        return topic.id
    }
}
