import SwiftUI

// MARK: - Supporting Types
struct ConceptProgressData {
    let concept: Concept
    let previousScore: Double
    let currentScore: Double
    let masteryLevel: MasteryLevel
    
    var improvement: Double {
        currentScore - previousScore
    }
}

struct ConceptProgressRow: View {
    let concept: Concept
    let previousScore: Double
    let currentScore: Double
    let masteryLevel: MasteryLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(concept.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: "%.0f%%", previousScore))
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", currentScore))
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: currentScore, total: 100)
                    .tint(masteryColor)
                
                HStack {
                    Text(masteryLevel.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("+\(String(format: "%.1f", currentScore - previousScore))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let lastPractice = concept.proficiency?.lastInteractionDate {
                Text("Last practiced: \(formattedDate(lastPractice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(masteryColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var masteryColor: Color {
        switch masteryLevel {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Main Review View
struct ReviewView: View {
    @EnvironmentObject private var viewModel: ExplainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                newConceptsCard
                improvedConceptsCard
                suggestedNextStepsCard
                actionButtons
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - View Components
    
    private var header: some View {
        VStack(spacing: 16) {
            Text("Great Job! Here's Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: calculateOverallProgress())
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(calculateOverallProgress() * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("You've completed all questions!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var newConceptsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Concepts Encountered")
                .font(.headline)
            
            ForEach(getNewConcepts(), id: \.self) { concept in
                VStack(alignment: .leading, spacing: 8) {
                    Text(concept)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let definition = viewModel.definitions[concept] {
                        Text(definition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var improvedConceptsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Improved Concepts")
                .font(.headline)
            
            if let conceptProgress = getConceptProgress() {
                if conceptProgress.isEmpty {
                    Text("No improvements yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(conceptProgress, id: \.concept.id) { progress in
                        ConceptProgressRow(
                            concept: progress.concept,
                            previousScore: progress.previousScore,
                            currentScore: progress.currentScore,
                            masteryLevel: progress.masteryLevel
                        )
                    }
                }
            } else {
                Text("No concept progress data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var suggestedNextStepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Next Steps")
                .font(.headline)
            
            ForEach(generateSuggestions(), id: \.self) { suggestion in
                Button(action: {
                    handleSuggestion(suggestion)
                }) {
                    HStack {
                        Text(suggestion)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Reset current questions and start over
                viewModel.resetCurrentSession()
                dismiss()
            }) {
                Label("Retry Questions", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: {
                dismiss()
            }) {
                Label("Return to Home", systemImage: "house")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallProgress() -> Double {
        let scores = viewModel.questionFeedback.values.map { $0.overallGrade }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private func getNewConcepts() -> [String] {
        let allConcepts = Set(viewModel.questionFeedback.values.flatMap { feedback in
            feedback.segments.map { $0.concept }
        })
        return Array(allConcepts).sorted()
    }
    
    private func getConceptProgress() -> [ConceptProgressData]? {
        guard let topic = viewModel.currentTopic else { return nil }
        
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
    
    private func generateSuggestions() -> [String] {
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
    
    private func handleSuggestion(_ suggestion: String) {
        // TODO: Implement navigation to suggested content
        switch suggestion {
        case "Review weak concepts":
            // Navigate to review weak concepts view
            break
        case "Try advanced questions":
            // Navigate to advanced questions
            break
        case "Explore related topics":
            // Navigate to related topics
            break
        default:
            break
        }
    }
}

