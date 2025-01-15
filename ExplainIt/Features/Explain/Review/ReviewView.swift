import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(explainViewModel: ExplainViewModel) {
        _viewModel = StateObject(wrappedValue: ReviewViewModel(explainViewModel: explainViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
    private var newConceptsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Concepts Encountered")
                .font(.headline)
            
            ForEach(viewModel.getNewConcepts(), id: \.self) { concept in
                VStack(alignment: .leading, spacing: 8) {
                    Text(concept)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
            
            if let conceptProgress = viewModel.getConceptProgress() {
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
            
            ForEach(viewModel.generateSuggestions(), id: \.self) { suggestion in
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
                viewModel.resetAndReturn()
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


// MARK: - Preview
#Preview {
    NavigationView {
        ReviewView(explainViewModel: ExplainViewModel.create())
    }
}
