import Foundation

protocol TopicRepository {
    var topics: [Topic] { get }
    func addTopic(_ topic: Topic)
    func updateTopic(_ topic: Topic)
    func addConceptToTopic(_ concept: Concept, topicId: UUID) throws
    func getTopic(withId id: UUID) -> Topic?
}

class InMemoryTopicRepository: TopicRepository {
    @Published private(set) var topics: [Topic] = []
    
    init(initialTopics: [Topic] = []) {
        self.topics = initialTopics
    }
    
    func addTopic(_ topic: Topic) {
        if !topics.contains(where: { $0.id == topic.id }) {
            topics.append(topic)
        }
    }
    
    func updateTopic(_ topic: Topic) {
        if let index = topics.firstIndex(where: { $0.id == topic.id }) {
            topics[index] = topic
        }
    }
    
    func addConceptToTopic(_ concept: Concept, topicId: UUID) throws {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else {
            throw TopicError.topicNotFound
        }
        
        if !topics[index].concepts.contains(where: { $0.id == concept.id }) {
            topics[index].concepts.append(concept)
        }
    }
    
    func getTopic(withId id: UUID) -> Topic? {
        return topics.first(where: { $0.id == id })
    }
} 