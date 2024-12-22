//
//  ExplainViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-21.
//

import Foundation

@MainActor
class ExplainViewModel: ObservableObject {
    @Published var feedbackAnalysis: FeedbackAnalysis?
    @Published var isLoading: Bool = false
    @Published var definitions: [String: String] = [:]
    @Published var currentTopic: Topic?
    @Published var topics: [Topic] = []
    @Published var currentQuestions: [Question] = []
    @Published var userResponses: [UUID: String] = [:]
    @Published var questionFeedback: [UUID: FeedbackAnalysis] = [:]
    @Published var showingFeedback = false
    @Published var currentQuestionIndex = 0
    
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService = .shared) {
        self.openAIService = openAIService
        topics = getMockTopics()
    }
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }
    
    func setNextQuestion() {
        if currentQuestionIndex < currentQuestions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func setPreviousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func showFeedbackView() {
        showingFeedback = true
    }
    
    func showExplainView() {
        showingFeedback = false
    }
    
    func setupTopicAndGenerateQuestions(for topicName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Create and set new topic
        let newTopic = Topic(id: UUID(), name: topicName, icon: "book", concepts: [])
        currentTopic = newTopic
        
        // Add to topics if not exists
        if !topics.contains(where: { $0.name == topicName }) {
            topics.append(newTopic)
        }
        
        // Generate and store questions
        currentQuestions = try await generateQuestions(for: topicName)
        
        // Reset responses and feedback for new questions
        userResponses.removeAll()
        questionFeedback.removeAll()
    }
    
    func saveResponse(for question: Question, text: String) {
        userResponses[question.id] = text
    }
    
    func getResponse(for questionId: UUID) -> String? {
        return userResponses[questionId]
    }
    
    func gradeResponse(question: Question, text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let feedbackSegments = try await gradeSentenceSegments(question: question, fullResponse: text)
            let overallGrade = calculateOverallGrade(for: feedbackSegments)
            let feedback = FeedbackAnalysis(segments: feedbackSegments, overallGrade: overallGrade)
            
            // Store feedback for this specific question
            questionFeedback[question.id] = feedback
        } catch {
            print("Error grading response: \(error.localizedDescription)")
        }
    }
    
    func resetFeedback(for questionId: UUID) {
        questionFeedback[questionId] = nil
    }
    
    private func splitTextIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func generateQuestions(for topic: String) async throws -> [Question] {
        let systemMessage = GPTMessage(
            role: "system",
            content: """
                You are an educational assistant specializing in creating comprehensive assessment questions. \
                For each question, provide a model answer, relevant concepts, and detailed grading criteria. \
                Format your response as a JSON array of question objects.
                Do not return markdown.
                """
        )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
                Generate 3 questions to assess understanding of "\(topic)". \
                For each question, include:
                1. The question text
                2. A model answer
                3. Key concepts addressed
                4. A grading rubric with key points and criteria
                
                Format as JSON like this:
                {
                    "questions": [
                        {
                            "id": "1",
                            "text": "What is...?",
                            "modelAnswer": "A comprehensive explanation...",
                            "concepts": ["concept1", "concept2"],
                            "rubric": {
                                "keyPoints": ["point1", "point2"],
                                "requiredConcepts": ["concept1"],
                                "gradingCriteria": [
                                    {
                                        "description": "Explains basic principle",
                                        "weight": 0.3,
                                        "examples": ["Example good response"]
                                    }
                                ]
                            }
                        }
                    ]
                }
                """
        )
        
        let response = try await openAIService.chatCompletion(
            messages: [systemMessage, userGPTMessage]
        )
        
        guard let content = response.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let decoder = JSONDecoder()
        let questionResponse = try decoder.decode(QuestionResponse.self, from: data)
        return questionResponse.questions.map { question in
            Question(
                id: UUID(), // Generate new UUID for each question
                text: question.text,
                modelAnswer: question.modelAnswer,
                concepts: question.concepts,
                rubric: question.rubric
            )
        }
    }
    
    
        private func gradeSentenceSegments(question: Question, fullResponse: String) async throws -> [FeedbackSegment] {
            let systemMessage = GPTMessage(
                role: "system",
                content: """
                You are a detailed grader for an educational app that assesses users' understanding of complex topics. \
                Grade the response using these specific criteria:
                1. Model Answer to Compare Against: "\(question.modelAnswer)"
                2. Required Key Points: \(question.rubric.keyPoints.joined(separator: ", "))
                3. Required Concepts: \(question.rubric.requiredConcepts.joined(separator: ", "))
                4. Grading Criteria:
                \(question.rubric.gradingCriteria.map { "   - \($0.description) (Weight: \($0.weight))" }.joined(separator: "\n"))
                
                Example good responses for reference:
                \(question.rubric.gradingCriteria.flatMap { criterion in
                    criterion.examples.map { "- \($0)" }
                }.joined(separator: "\n"))
                
                The user's response is a casual speech transcript, so do not penalize for punctuation, grammar, or informal phrasing. \
                Focus solely on the correctness and clarity of the content in their explanation. Do not return markdown. 
                """
            )
            
            print("systemMessage: " + systemMessage.content)
            
            let userGPTMessage = GPTMessage(
                role: "user",
                content: """
                Grade this response to the question "\(question.text)".
                Response: "\(fullResponse)"
                
                For each sentence, evaluate based on the provided model answer, key points, required concepts, and grading criteria.
                Return feedback as a JSON array with this structure for each sentence:
                {
                    "text": "sentence from response",
                    "feedbackType": "correct",
                    "explanation": "explanation referencing specific criteria from the rubric",
                    "concept": "concept from the required concepts list being addressed",
                    "keyPointsAddressed": ["specific key points addressed in this sentence"],
                    "criteriaMatched": ["specific grading criteria matched"]
                }
                
                Ensure each feedback maps to specific criteria and concepts from the rubric.
                """
            )
            
            let response = try await openAIService.chatCompletion(
                messages: [systemMessage, userGPTMessage]
            )
            
            guard let content = response.choices.first?.message.content,
                  let data = content.data(using: .utf8) else {
                throw GradingError.invalidResponse
            }
            
            print("Grading response data: ", data)
            print("Grading response content: ", content)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([FeedbackSegment].self, from: data)
        }
    
    
    func getDefinition(for concept: String) async throws -> String {
        // Return cached definition if available
        if let cachedDefinition = definitions[concept] {
            return cachedDefinition
        }
        
        let systemMessage = GPTMessage(
            role: "system",
            content: """
               You are an AI assistant providing detailed, concise definitions for educational purposes. \
               Your task is to define the concept and explain its importance.
               """
        )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
               Please provide a detailed definition of the concept "\(concept)" and explain its relevance or application in learning or practical contexts.
               """
        )
        
        let response = try await openAIService.chatCompletion(
            messages: [systemMessage, userGPTMessage]
        )
        
        if let content = response.choices.first?.message.content {
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Cache the definition
            definitions[concept] = trimmedContent
            return trimmedContent
        } else {
            throw NSError(domain: "NoContent", code: -1, userInfo: nil)
        }
    }
    
    func addNewConceptFromFeedback(conceptName: String, definition: String?) throws {
            guard var currentTopic = currentTopic else {
                throw GradingError.gradingFailed(underlying: NSError(
                    domain: "CurrentTopicNotSet",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No topic is currently selected."])
                )
            }
            
            // Check if the concept already exists
            if currentTopic.concepts.contains(where: { $0.name.lowercased() == conceptName.lowercased() }) {
                throw GradingError.gradingFailed(underlying: NSError(
                    domain: "ConceptAlreadyExists",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "The concept '\(conceptName)' already exists in the current topic."])
                )
            }
            
            // Create and add the new concept
            let newConcept = Concept(id: UUID(), name: conceptName, definition: definition)
            
            // Update the current topic
            if let index = topics.firstIndex(where: { $0.id == currentTopic.id }) {
                topics[index].concepts.append(newConcept)
                // Update currentTopic to reflect the change
                currentTopic = topics[index]
            }
            
            // Cache the definition if provided
            if let def = definition {
                definitions[conceptName] = def
            }
        }
        
        private func calculateOverallGrade(for segments: [FeedbackSegment]) -> Double {
            let totalCount = segments.count
            let weightedPoints = segments.reduce(0.0) { points, segment in
                let basePoints = switch segment.feedbackType {
                case .correct: 1.0
                case .partiallyCorrect: 0.5
                case .incorrect: 0.0
                }
                
                // Add bonus points for meeting multiple criteria or addressing key points
                let bonusPoints = Double(segment.keyPointsAddressed.count + segment.criteriaMatched.count) * 0.1
                return points + basePoints + min(bonusPoints, 0.5) // Cap bonus points at 0.5
            }
            
            guard totalCount > 0 else { return 0.0 }
            return min(weightedPoints / Double(totalCount), 1.0) // Ensure we don't exceed 100%
        }
    
    func getMockTopics() -> [Topic] {
        return [
            Topic(
                id: UUID(),
                name: "Mathematics",
                icon: "function",
                concepts: [
                    Concept(id: UUID(), name: "Calculus", definition: "The mathematical study of continuous change."),
                    Concept(id: UUID(), name: "Linear Algebra", definition: nil), // No definition provided
                    Concept(id: UUID(), name: "Probability and Statistics", definition: "The study of randomness and data interpretation.")
                ]
            ),
            Topic(
                id: UUID(),
                name: "Biology",
                icon: "leaf",
                concepts: [
                    Concept(id: UUID(), name: "Cell Structure", definition: "The composition and organization of cells."),
                    Concept(id: UUID(), name: "DNA and Genetics", definition: "The study of heredity and genetic information."),
                    Concept(id: UUID(), name: "Evolutionary Theory", definition: nil) // No definition provided
                ]
            ),
            Topic(
                id: UUID(),
                name: "Technology",
                icon: "gear",
                concepts: [
                    Concept(id: UUID(), name: "Artificial Intelligence", definition: "The simulation of human intelligence in machines."),
                    Concept(id: UUID(), name: "Cybersecurity", definition: nil), // No definition provided
                    Concept(id: UUID(), name: "Blockchain", definition: "A distributed ledger technology for secure transactions.")
                ]
            )
        ]
    }
    
    private struct QuestionResponse: Codable {
        let questions: [Question]
    }
    
}

enum GradingError: LocalizedError {
    case invalidResponse
    case invalidGradingCriteria(String)
    case missingRequiredConcepts([String])
    case gradingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to get a valid response from the grading system"
        case .invalidGradingCriteria(let criteria):
            return "Invalid grading criteria: \(criteria)"
        case .missingRequiredConcepts(let concepts):
            return "Response missing required concepts: \(concepts.joined(separator: ", "))"
        case .gradingFailed(let error):
            return "Grading failed: \(error.localizedDescription)"
        }
    }
}
