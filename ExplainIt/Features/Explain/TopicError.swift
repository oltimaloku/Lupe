import Foundation

enum TopicError: LocalizedError {
    case topicNotFound
    case conceptAlreadyExists(String)
    
    var errorDescription: String? {
        switch self {
        case .topicNotFound:
            return "The specified topic could not be found"
        case .conceptAlreadyExists(let conceptName):
            return "A concept with name '\(conceptName)' already exists in this topic"
        }
    }
}
