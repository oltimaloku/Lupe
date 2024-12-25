//
//  BreadCrumbViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import Foundation

class BreadcrumbViewModel: ObservableObject {
    @Published var conceptNames: [String] = []
    private let topicRepository: TopicRepository
    
    init(path: [UUID], topicId: UUID, topicRepository: TopicRepository = TopicRepository()) {
        self.topicRepository = topicRepository
        loadConceptNames(path: path, topicId: topicId)
    }
    
    private func loadConceptNames(path: [UUID], topicId: UUID) {
        guard let topic = topicRepository.topics.first(where: { $0.id == topicId }) else { return }
        conceptNames = path.compactMap { id in
            findConceptName(id: id, in: topic.concepts)
        }
    }
    
    private func findConceptName(id: UUID, in concepts: [Concept]) -> String? {
        for concept in concepts {
            if concept.id == id {
                return concept.name
            }
            if let found = findConceptName(id: id, in: concept.subConcepts) {
                return found
            }
        }
        return nil
    }
}
