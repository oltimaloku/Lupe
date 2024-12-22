import Foundation

protocol QuestionGenerationService {
    func generateQuestions(for topic: String) async throws -> [Question]
}

class OpenAIQuestionGenerationService: QuestionGenerationService {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
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
            throw GradingError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let questionResponse = try decoder.decode(QuestionResponse.self, from: data)
        return questionResponse.questions.map { question in
            Question(
                id: UUID(),
                text: question.text,
                modelAnswer: question.modelAnswer,
                concepts: question.concepts,
                rubric: question.rubric
            )
        }
    }
    
    private struct QuestionResponse: Codable {
        let questions: [Question]
    }
}