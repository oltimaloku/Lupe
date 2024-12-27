// ChatViewModel.swift
import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService = .shared) {
        self.openAIService = openAIService
    }
    
    // Mock initializer for previewing with sample data
    convenience init(mockMessages: [ChatMessage]) {
        self.init(openAIService: OpenAIService.shared) // Pass any service or mock service here
        self.messages = mockMessages
    }
    
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            text: inputText,
            isUserMessage: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let sentences = splitTextIntoSentences(inputText)
        inputText = ""
        isLoading = true
        
        var feedbackSegments: [FeedbackSegment] = []
        
        do {
            for sentence in sentences {
                let sentenceSegments = await gradeSentenceSegments(sentence)
                feedbackSegments.append(contentsOf: sentenceSegments)
            }
            
            let overallGrade = calculateOverallGrade(for: feedbackSegments)
            
            let feedbackAnalysis = FeedbackAnalysis(segments: feedbackSegments, overallGrade: overallGrade)
            
            let aiMessage = ChatMessage(
                text: inputText,
                isUserMessage: false,
                timestamp: Date(),
                feedbackAnalysis: feedbackAnalysis
            )
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(
                text: "Sorry, I couldn't get an answer. Please try again.",
                isUserMessage: false,
                timestamp: Date(),
                isError: true
            )
            messages.append(errorMessage)
        }
        
        isLoading = false
    }
    
    private func splitTextIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func gradeSentenceSegments(_ sentence: String) async -> [FeedbackSegment] {
        do {
            let systemMessage = GPTMessage(
                role: "system",
                content: """
                You are a detailed grader for an educational app that assesses users' understanding of complex topics. \
                Your role is to evaluate each small segment of the user's explanation sentence by sentence.
                """
            )
            
            let userGPTMessage = GPTMessage(
                role: "user",
                content: """
                Please break down the following sentence into smaller parts. \
                For each part, provide feedback on correctness with a JSON structure:
                {
                    "text": "<part of the sentence>",
                    "feedbackType": "<correct | partiallyCorrect | incorrect>",
                    "explanation": "<brief explanation of why this part is marked as such>",
                    "concept": "<The concept addressed by this part>"
                }
                Respond with JSON only, no markdown. Sentence to evaluate: "\(sentence)"
                """
            )
            
            let response = try await openAIService.chatCompletion(
                messages: [systemMessage, userGPTMessage]
            )
            
            if let content = response.choices.first?.message.content {
                let sentenceSegments = try JSONDecoder().decode([FeedbackSegment].self, from: Data(content.utf8))
                return sentenceSegments
            } else {
                return []
            }
        } catch {
            print("Error parsing response")
            return []
        }
    }
    
    private func calculateOverallGrade(for segments: [FeedbackSegment]) -> Double {
        let correctCount = segments.filter { $0.feedbackType == .correct }.count
        let totalCount = segments.count
        
        // Example grading logic based on the percentage of correct segments
        return (Double(correctCount) / Double(totalCount)) * 100
    }
}
