import Foundation

class ConceptProficiencyManager {
    // MARK: - Constants
    private let decayRate: Double = 0.1 // 10% decay per week
    private let minConfidence: Double = 0.3
    private let parentProficiencyImpact: Double = 0.3 // Parent concepts receive 30% of child's impact
    private let minimumImpactWeight: Double = 0.01 // 1% minimum impact
    private let maxRecentInteractions = 5 // Number of recent interactions to consider for consistency
    
    // MARK: - Singleton
    static let shared = ConceptProficiencyManager()
    private init() {}
    
    // MARK: - Public Methods
    func updateFromFeedback(
        concept: inout Concept,
        feedbackAnalysis: FeedbackAnalysis,
        conceptHierarchy: ConceptHierarchyService,
        topicId: UUID
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
        
        // Use metadata path for propagation
        if !concept.metadata.path.isEmpty {
            let ancestors = Array(concept.metadata.path.dropFirst()) // Skip current concept
            propagateToAncestors(
                from: concept,
                ancestors: ancestors,
                currentDepth: concept.metadata.depth,
                scoreImpact: scoreImpact,
                feedbackAnalysis: feedbackAnalysis,
                conceptHierarchy: conceptHierarchy,
                topicId: topicId
            )
        }
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
    
    // MARK: - Private Methods - Propagation
    private func propagateToAncestors(
        from concept: Concept,
        ancestors: [UUID],
        currentDepth: Int,
        scoreImpact: Double,
        feedbackAnalysis: FeedbackAnalysis,
        conceptHierarchy: ConceptHierarchyService,
        topicId: UUID
    ) {
        var rootConcepts = conceptHierarchy.getRootConcepts(for: topicId)
        
        for (index, ancestorId) in ancestors.enumerated() {
            let depth = currentDepth + index + 1
            let impact = calculateImpactForDepth(scoreImpact: scoreImpact, depth: depth)
            
            let interaction = ProficiencyInteraction(
                date: Date(),
                interactionType: .indirect,
                scoreImpact: impact,
                details: "Indirect update from \(concept.name) (\(depth) levels below)",
                feedbackId: feedbackAnalysis.id
            )
            
            // Find and update ancestor
            if var ancestor = findConceptById(ancestorId, using: conceptHierarchy, in: rootConcepts) {
                if ancestor.proficiency == nil {
                    ancestor.proficiency = ConceptProficiency(conceptId: ancestorId)
                }
                
                if var proficiency = ancestor.proficiency {
                    updateProficiency(proficiency: &proficiency, interaction: interaction)
                    ancestor.proficiency = proficiency
                    
                    do {
                        try conceptHierarchy.updateAncestor(ancestor, in: &rootConcepts)
                    } catch {
                        print("Failed to update ancestor concept: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func findConceptById(_ id: UUID, using conceptHierarchy: ConceptHierarchyService, in concepts: [Concept]) -> Concept? {
        func search(in concepts: [Concept]) -> Concept? {
            for concept in concepts {
                if concept.id == id {
                    return concept
                }
                if let found = search(in: concept.subConcepts) {
                    return found
                }
            }
            return nil
        }
        
        return search(in: concepts)
    }
    
    private func calculateImpactForDepth(scoreImpact: Double, depth: Int) -> Double {
        // Calculate diminishing impact based on depth
        let impact = scoreImpact * pow(parentProficiencyImpact, Double(depth))
        return max(impact, scoreImpact * minimumImpactWeight)
    }
    
    // MARK: - Private Methods - Score Calculation
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
    
    // MARK: - Private Methods - Proficiency Management
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
        let recentInteractions = proficiency.interactions.suffix(maxRecentInteractions)
        let consistencyFactor = calculateConsistencyFactor(recentInteractions)
        
        // Adjust confidence based on interaction type
        let baseConfidenceChange = interaction.scoreImpact > 0 ? 0.1 : -0.15
        let typeMultiplier = interaction.interactionType == .indirect ? 0.5 : 1.0
        
        let confidenceChange = baseConfidenceChange * typeMultiplier * consistencyFactor
        
        proficiency.confidence = max(minConfidence, min(1.0,
            proficiency.confidence + confidenceChange
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

// MARK: - Extension for Testing Support
extension ConceptProficiencyManager {
    #if DEBUG
    func calculateTestImpact(
        scoreImpact: Double,
        depth: Int
    ) -> Double {
        return calculateImpactForDepth(scoreImpact: scoreImpact, depth: depth)
    }
    
    var testDecayRate: Double { decayRate }
    var testMinConfidence: Double { minConfidence }
    var testParentProficiencyImpact: Double { parentProficiencyImpact }
    var testMinimumImpactWeight: Double { minimumImpactWeight }
    #endif
}
