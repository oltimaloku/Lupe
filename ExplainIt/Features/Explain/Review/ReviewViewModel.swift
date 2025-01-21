//
//  ReviewViewModel.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-26.
//

import Foundation

@MainActor
class ReviewViewModel: ObservableObject {
    @Published private(set) var currentTopic: Topic?
    @Published private(set) var questionFeedback: [UUID: FeedbackAnalysis] = [:]
    
    private let explainViewModel: ExplainViewModel
    
    init(explainViewModel: ExplainViewModel) {
        self.explainViewModel = explainViewModel
        self.loadData()
    }
    
    private func loadData() {
        self.currentTopic = explainViewModel.currentTopic
        self.questionFeedback = explainViewModel.questionFeedback
    }
    
    func getNewConcepts() -> [String] {
        let allConcepts = Set(questionFeedback.values.flatMap { feedback in
            feedback.segments
                .compactMap { $0.concept }  // Filter out nil concepts
                .filter { !$0.isEmpty }  // Filter out empty strings just in case
        })
        return Array(allConcepts).sorted()
    }
    
    func getQuestionFeedback() -> [(index: Int, feedback: FeedbackAnalysis)] {
        return Array(questionFeedback.values).enumerated().map { index, feedback in
            (index: index + 1, feedback: feedback)
        }
    }
    
    func getConceptProgress() -> [ConceptProgressData]? {
        guard let topic = currentTopic else { return nil }
        
        return topic.concepts.compactMap { concept in
            guard let proficiency = concept.proficiency else { return nil }
            
            let previousScore = proficiency.interactions.dropLast().last?.scoreImpact ?? 0
            
            return ConceptProgressData(
                concept: concept,
                previousScore: previousScore,
                currentScore: proficiency.proficiencyScore,
                masteryLevel: proficiency.masteryLevel
            )
        }
        .filter { $0.currentScore > $0.previousScore }
        .sorted { $0.improvement > $1.improvement }
    }
    
    func generateSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if let progress = getConceptProgress() {
            // Add mastery-based suggestions
            let lowMasteryConcepts = progress.filter { $0.currentScore < 60 }
            if !lowMasteryConcepts.isEmpty {
                suggestions.append("Review weak concepts")
            }
            
            let advancedConcepts = progress.filter { $0.currentScore >= 80 }
            if !advancedConcepts.isEmpty {
                suggestions.append("Try advanced questions")
            }
        }
        
        suggestions.append("Explore related topics")
        return suggestions
    }
    
    func resetAndReturn() {
        explainViewModel.resetCurrentSession()
    }
}

struct ConceptProgressData {
    let concept: Concept
    let previousScore: Double
    let currentScore: Double
    let masteryLevel: MasteryLevel
    
    var improvement: Double {
        currentScore - previousScore
    }
}

extension ConceptProgressData: Identifiable {
    var id: UUID {
        concept.id
    }
}

// MARK: - Preview Helpers
extension ReviewViewModel {
    static func createPreviewModel() -> ReviewViewModel {
        let mockTopic = createMockTopic()
        let repository = TopicRepository()
        repository.addTopic(mockTopic)
        
        let explainVM = ExplainViewModel.create(topicRepository: repository)
        explainVM.currentTopic = mockTopic
        explainVM.questionFeedback = createMockFeedback()
        
        return ReviewViewModel(explainViewModel: explainVM)
    }
    
    static func createMockTopic() -> Topic {
        let calculus = Concept(
            id: UUID(),
            name: "Calculus",
            definition: "The mathematical study of continuous change",
            proficiency: createMockProficiency(score: 85.0, previousScore: 75.0),
            subConcepts: []
        )
        
        let linearAlgebra = Concept(
            id: UUID(),
            name: "Linear Algebra",
            definition: "The study of linear equations and functions",
            proficiency: createMockProficiency(score: 65.0, previousScore: 45.0),
            subConcepts: []
        )
        
        let statistics = Concept(
            id: UUID(),
            name: "Statistics",
            definition: "The study of collecting and analyzing numerical data",
            proficiency: createMockProficiency(score: 45.0, previousScore: 30.0),
            subConcepts: []
        )
        
        return Topic(
            id: UUID(),
            name: "Mathematics",
            icon: "function",
            concepts: [calculus, linearAlgebra, statistics]
        )
    }
    
    static func createMockProficiency(score: Double, previousScore: Double) -> ConceptProficiency {
        var proficiency = ConceptProficiency(conceptId: UUID())
        proficiency.proficiencyScore = score
        proficiency.confidence = 0.8
        proficiency.lastInteractionDate = Date()
        
        // Add some mock interactions
        proficiency.interactions = [
            ProficiencyInteraction(
                date: Date().addingTimeInterval(-86400), // Yesterday
                interactionType: .explanation,
                scoreImpact: score - previousScore,
                details: "Demonstrated good understanding",
                feedbackId: UUID()
            )
        ]
        
        return proficiency
    }
    
    static func createMockFeedback() -> [UUID: FeedbackAnalysis] {
        let questionId = UUID()
        let segments = [
            FeedbackSegment(
                text: "The derivative measures the rate of change",
                feedbackType: .correct,
                explanation: "Correctly explained the basic concept",
                concept: "Calculus",
                keyPointsAddressed: ["Rate of change", "Derivatives"],
                criteriaMatched: ["Basic understanding"],
                isNewConcept: false
            ),
            FeedbackSegment(
                text: "Linear algebra helps solve systems of equations",
                feedbackType: .partiallyCorrect,
                explanation: "Partially explained the concept",
                concept: "Linear Algebra",
                keyPointsAddressed: ["Systems of equations"],
                criteriaMatched: ["Basic application"],
                isNewConcept: true
            )
        ]
        
        return [
            questionId: FeedbackAnalysis(
                segments: segments,
                overallGrade: 0.85
            )
        ]
    }
}
