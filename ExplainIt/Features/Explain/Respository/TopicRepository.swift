import Foundation

class TopicRepository {
    private let userDefaults: UserDefaults
    private let topicsKey = "saved_topics"
    
    @Published private(set) var topics: [Topic] = []
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadTopics()
    }
    
    func loadTopics() {
        if let data = userDefaults.data(forKey: topicsKey),
           let decodedTopics = try? JSONDecoder().decode([Topic].self, from: data) {
            topics = decodedTopics
        }
    }
    
    private func saveTopics() {
        if let encodedData = try? JSONEncoder().encode(topics) {
            userDefaults.set(encodedData, forKey: topicsKey)
        }
    }
    
    func getTopic(with topicID: UUID) throws -> Topic {
        guard let topic = topics.first(where: { $0.id == topicID }) else {
            throw TopicError.topicNotFound
        }
        return topic
    }
    
    func addTopic(_ topic: Topic) {
        if !topics.contains(where: { $0.id == topic.id }) {
            topics.append(topic)
            saveTopics()
        }
    }
    
    func removeTopic(_ topic: Topic) {
        topics.removeAll { $0.id == topic.id }
        saveTopics()
    }
    
    func updateTopic(_ updatedTopic: Topic) throws {
        guard let index = topics.firstIndex(where: { $0.id == updatedTopic.id }) else {
            throw TopicError.topicNotFound
        }
        
        // Ensure we're not creating duplicate concept names within the topic
        let conceptNames = updatedTopic.concepts.map { $0.name.lowercased() }
        if Set(conceptNames).count != conceptNames.count {
            throw TopicError.conceptAlreadyExists("Duplicate concept names found")
        }
        
        topics[index] = updatedTopic
        saveTopics()
    }
    
    func addConceptToTopic(_ concept: Concept, topicId: UUID, parentConceptId: UUID? = nil) throws {
            guard var topic = topics.first(where: { $0.id == topicId }) else {
                throw TopicError.topicNotFound
            }
            
            // Check if concept already exists
            if topic.concepts.contains(where: { $0.name.lowercased() == concept.name.lowercased() }) {
                throw TopicError.conceptAlreadyExists(concept.name)
            }
            
            var newConcept = concept
            if let parentId = parentConceptId {
                // Set parent ID and update metadata
                newConcept.parentConceptId = parentId
                if let parentIndex = topic.concepts.firstIndex(where: { $0.id == parentId }) {
                    var parentConcept = topic.concepts[parentIndex]
                    parentConcept.subConcepts.append(newConcept)
                    topic.concepts[parentIndex] = parentConcept
                }
            } else {
                // Add as root concept
                topic.concepts.append(newConcept)
            }
            
            // Update topic
            if let index = topics.firstIndex(where: { $0.id == topicId }) {
                topics[index] = topic
                saveTopics()
            }
        }
}
