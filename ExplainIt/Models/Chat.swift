//
//  Chat.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-10.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUserMessage: Bool
    let timestamp: Date
    let feedbackAnalysis: FeedbackAnalysis?  
    let isError: Bool
    
    init(text: String, isUserMessage: Bool, timestamp: Date, feedbackAnalysis: FeedbackAnalysis? = nil, isError: Bool = false) {
        self.text = text
        self.isUserMessage = isUserMessage
        self.timestamp = timestamp
        self.feedbackAnalysis = feedbackAnalysis
        self.isError = isError
    }
}

struct ELI5Response: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}
