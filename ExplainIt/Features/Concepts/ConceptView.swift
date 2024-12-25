import SwiftUI
import MarkdownUI

struct ConceptView: View {
    @StateObject private var viewModel = ExplainViewModel.create()
    @State private var isStartingLearningFlow = false
    @State private var showError = false
    @State private var errorMessage = ""
    let concept: Concept
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(concept.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)
                
                // Proficiency Card
                if let proficiency = concept.proficiency {
                    ProficiencyCard(proficiency: proficiency)
                        .padding(.bottom, 8)
                }
                
                // Definition
                if let definition = concept.definition {
                    Markdown(definition)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    Text("No definition available")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                // Practice History
                if let proficiency = concept.proficiency,
                   !proficiency.interactions.isEmpty {
                    PracticeHistorySection(interactions: proficiency.interactions)
                        .padding(.top, 8)
                }
                
                // Learning Flow Button
                Button(action: startLearningFlow) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Start Learning Flow")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.top, 16)
                .disabled(viewModel.isLoading)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isStartingLearningFlow) {
            QuestionFlowContainerView()
                .environmentObject(viewModel)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startLearningFlow() {
        Task {
            do {
                try viewModel.createTopic(name: concept.name)
                try await viewModel.generateQuestions(for: concept.name)
                
                await MainActor.run {
                    isStartingLearningFlow = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isStartingLearningFlow = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProficiencyCard: View {
    let proficiency: ConceptProficiency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mastery Level:")
                    .font(.headline)
                Spacer()
                Text(proficiency.masteryLevel.rawValue.capitalized)
                    .foregroundColor(masteryColor)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: proficiency.proficiencyScore, total: 100)
                .tint(masteryColor)
            
            Text(proficiency.masteryLevel.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Last practice: \(formattedDate(proficiency.lastInteractionDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var masteryColor: Color {
        switch proficiency.masteryLevel {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
}

struct PracticeHistorySection: View {
    let interactions: [ProficiencyInteraction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice History")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(interactions.prefix(5), id: \.date) { interaction in
                HStack {
                    Image(systemName: interactionIcon(for: interaction.interactionType))
                        .foregroundColor(interactionColor(for: interaction))
                    
                    VStack(alignment: .leading) {
                        Text(interaction.details)
                            .font(.subheadline)
                        Text(formattedDate(interaction.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(scoreImpactText(for: interaction))
                        .font(.caption)
                        .foregroundColor(scoreImpactColor(for: interaction))
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func interactionIcon(for type: InteractionType) -> String {
        switch type {
        case .explanation: return "text.bubble.fill"
        case .quiz: return "checkmark.circle.fill"
        case .review: return "book.fill"
        case .decay: return "arrow.down.circle.fill"
        case .indirect: return "arrow.triangle.branch" 
        }
    }
    
    private func interactionColor(for interaction: ProficiencyInteraction) -> Color {
        switch interaction.interactionType {
        case .decay: return .red
        default: return interaction.scoreImpact >= 0 ? .green : .red
        }
    }
    
    private func scoreImpactText(for interaction: ProficiencyInteraction) -> String {
        if interaction.scoreImpact >= 0 {
            return "+\(String(format: "%.1f", interaction.scoreImpact))%"
        } else {
            return "\(String(format: "%.1f", interaction.scoreImpact))%"
        }
    }
    
    private func scoreImpactColor(for interaction: ProficiencyInteraction) -> Color {
        interaction.scoreImpact >= 0 ? .green : .red
    }
}
