//
//  ConceptProficiencyManager.swift
//  ExplainIt
//

import Foundation

class ConceptProficiencyManager {
    private let decayRate: Double = 0.1 // 10% decay per week
    private let minConfidence: Double = 0.3
    private let parentProficiencyImpact: Double = 0.3 // Parent concepts receive 30% of child's impact
    
    static let shared = ConceptProficiencyManager()
    
    private init() {}
    
    func updateFromFeedback(
        concept: inout Concept,
        feedbackAnalysis: FeedbackAnalysis,
        conceptHierarchy: ConceptHierarchyService
    ) {
        // Initialize proficiency if it doesn't exist
        if concept.proficiency == nil {
            concept.proficiency = ConceptProficiency(conceptId: concept.id)
        }
        
        guard var proficiency = concept.proficiency else { return }
        
        // Calculate direct impact
        let scoreImpact = calculateScoreImpact(from: feedbackAnalysis)
        
        let interaction = ProficiencyInteraction(
            date: Date(),
            interactionType: .explanation,
            scoreImpact: scoreImpact,
            details: generateInteractionDetails(from: feedbackAnalysis),
            feedbackId: feedbackAnalysis.id
        )
        
        // Update the concept's proficiency
        updateProficiency(proficiency: &proficiency, interaction: interaction)
        concept.proficiency = proficiency
        
        // Propagate updates to parent concepts if they exist
        if let parentId = concept.parentConceptId {
            propagateToParent(
                childConcept: concept,
                parentId: parentId,
                scoreImpact: scoreImpact,
                feedbackAnalysis: feedbackAnalysis,
                conceptHierarchy: conceptHierarchy
            )
        }
    }
    
    private func propagateToParent(
        childConcept: Concept,
        parentId: UUID,
        scoreImpact: Double,
        feedbackAnalysis: FeedbackAnalysis,
        conceptHierarchy: ConceptHierarchyService
    ) {
        // Calculate reduced impact for parent
        let parentImpact = scoreImpact * parentProficiencyImpact
        
        let parentInteraction = ProficiencyInteraction(
            date: Date(),
            interactionType: .indirect,
            scoreImpact: parentImpact,
            details: "Indirect update from sub-concept: \(childConcept.name)",
            feedbackId: feedbackAnalysis.id
        )
        
        // Create parent proficiency if it doesn't exist
        if var parentConcept = findParentConcept(parentId, conceptHierarchy: conceptHierarchy) {
            if parentConcept.proficiency == nil {
                parentConcept.proficiency = ConceptProficiency(conceptId: parentId)
            }
            
            if var parentProficiency = parentConcept.proficiency {
                updateProficiency(proficiency: &parentProficiency, interaction: parentInteraction)
                parentConcept.proficiency = parentProficiency
                
                // Continue propagating up the hierarchy if there's another parent
                if let grandparentId = parentConcept.parentConceptId {
                    propagateToParent(
                        childConcept: parentConcept,
                        parentId: grandparentId,
                        scoreImpact: parentImpact,
                        feedbackAnalysis: feedbackAnalysis,
                        conceptHierarchy: conceptHierarchy
                    )
                }
            }
        }
    }
    
    private func findParentConcept(_ parentId: UUID, conceptHierarchy: ConceptHierarchyService) -> Concept? {
        // This would need to be implemented based on your concept hierarchy structure
        return nil // Placeholder
    }
    
    private func calculateScoreImpact(from feedback: FeedbackAnalysis) -> Double {
        // Calculate base impact from overall grade
        let baseImpact = (feedback.overallGrade - 0.5) * 20 // Scale to roughly -10 to +10
        
        // Analyze individual segments for bonus impact
        let segmentBonus = calculateSegmentBonus(feedback.segments)
        
        return baseImpact + segmentBonus
    }
    
    private func calculateSegmentBonus(_ segments: [FeedbackSegment]) -> Double {
        let correctSegments = segments.filter { $0.feedbackType == .correct }.count
        let partiallyCorrectSegments = segments.filter { $0.feedbackType == .partiallyCorrect }.count
        
        let bonus = (Double(correctSegments) * 2.0 + Double(partiallyCorrectSegments) * 1.0) / Double(segments.count)
        return min(bonus, 5.0) // Cap bonus at 5 points
    }
    
    private func generateInteractionDetails(from feedback: FeedbackAnalysis) -> String {
        let correctCount = feedback.segments.filter { $0.feedbackType == .correct }.count
        let totalCount = feedback.segments.count
        return "Explained \(correctCount)/\(totalCount) concepts correctly"
    }
    
    func updateProficiency(
        proficiency: inout ConceptProficiency,
        interaction: ProficiencyInteraction
    ) {
        // Apply time-based decay first
        applyDecay(&proficiency)
        
        // Calculate score impact with confidence weighting
        let weightedImpact = interaction.scoreImpact * proficiency.confidence
        
        // Update the proficiency score
        proficiency.proficiencyScore = max(0, min(100,
            proficiency.proficiencyScore + weightedImpact
        ))
        
        // Update confidence based on consistency
        updateConfidence(&proficiency, interaction: interaction)
        
        // Add the interaction to history
        proficiency.interactions.append(interaction)
        proficiency.lastInteractionDate = interaction.date
    }
    
    private func applyDecay(_ proficiency: inout ConceptProficiency) {
        let weeksSinceLastInteraction = Date().timeIntervalSince(proficiency.lastInteractionDate) / (7 * 24 * 3600)
        let decayAmount = decayRate * weeksSinceLastInteraction
        proficiency.proficiencyScore = max(0, proficiency.proficiencyScore * (1 - decayAmount))
    }
    
    private func updateConfidence(
        _ proficiency: inout ConceptProficiency,
        interaction: ProficiencyInteraction
    ) {
        // Analyze recent interactions for consistency
        let recentInteractions = proficiency.interactions.suffix(5)
        let consistencyFactor = calculateConsistencyFactor(recentInteractions)
        
        // Adjust confidence based on interaction type
        let baseConfidenceChange = interaction.scoreImpact > 0 ? 0.1 : -0.15
        let typeMultiplier = interaction.interactionType == .indirect ? 0.5 : 1.0
        
        let confidenceChange = baseConfidenceChange * typeMultiplier
        
        proficiency.confidence = max(minConfidence, min(1.0,
            proficiency.confidence + (confidenceChange * consistencyFactor)
        ))
    }
    
    private func calculateConsistencyFactor(_ interactions: ArraySlice<ProficiencyInteraction>) -> Double {
        guard !interactions.isEmpty else { return 1.0 }
        
        let scores = interactions.map { $0.scoreImpact }
        let average = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - average, 2) }.reduce(0, +) / Double(scores.count)
        
        // Lower variance means more consistency, leading to higher confidence
        return 1.0 / (1.0 + variance)
    }
}

