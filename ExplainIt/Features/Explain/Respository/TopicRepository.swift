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
    
    func addConceptToTopic(_ concept: Concept, topicId: UUID) throws {
        guard var topic = topics.first(where: { $0.id == topicId }) else {
            throw TopicError.topicNotFound
        }
        
        // Check if concept already exists
        if topic.concepts.contains(where: { $0.name.lowercased() == concept.name.lowercased() }) {
            throw TopicError.conceptAlreadyExists(concept.name)
        }
        
        // Create updated topic with new concept
        var updatedConcepts = topic.concepts
        updatedConcepts.append(concept)
        let updatedTopic = Topic(id: topic.id, name: topic.name, icon: topic.icon, concepts: updatedConcepts)
        
        // Update topics array
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            topics[index] = updatedTopic
            saveTopics()
        }
    }
}
