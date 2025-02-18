import Foundation

protocol QuestionGenerationService {
    func generateQuestionsForConcept(for concept: Concept, in topic: Topic) async throws -> [Question]
    func generateQuestionsForTopic(for topic: String) async throws -> [Question]
}

class OpenAIQuestionGenerationService: QuestionGenerationService {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func generateQuestionsForConcept(for concept: Concept, in topic: Topic) async throws -> [Question] {
        let systemMessage = GPTMessage(
            role: "system",
            content: """
                       Generate questions that test understanding of "\(concept.name)" in the context of the overall topic of \(topic.name).
                       Include questions that:
                       1. Directly test the main concept
                       2. Test relationships with known sub-concepts: \(concept.subConcepts.map { $0.name }.joined(separator: ", "))
                       3. Introduce related new concepts the user hasn't learned yet
                       
                       For each question, clearly mark which concepts it tests and which are new concepts.
                       Do not return markdown.
                       """
        )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
                Generate 3 questions to assess understanding of this concept: "\(concept)".  in the context of \(topic.name)
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
                
                Do not return markdown.
                """
        )
        
        let response = try await openAIService.chatCompletion(
            messages: [systemMessage, userGPTMessage]
        )
        
        guard let content = response.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw GradingError.invalidResponse
        }
        
        print("content: \(content)")
        
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
    
    func generateQuestionsForTopic(for topic: String) async throws -> [Question] {
        let systemMessage = GPTMessage(
                    role: "system",
                    content: """
                        You are an educational assistant specializing in creating comprehensive assessment questions. \
                        For each question, provide a model answer, relevant concepts, and detailed grading criteria. \
                        Format your response as a JSON array of question objects. Assume that the student can only answer the \
                        question using text so do not ask for diagrams or pictures. \
                        Do not return markdown.
                        """
                )
        
        let userGPTMessage = GPTMessage(
            role: "user",
            content: """
                Generate 3 questions to assess understanding of this concept: "\(topic)". \
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
