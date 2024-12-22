import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var viewModel: ExplainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Progress
                header
                
                // New Concepts Section
                newConceptsCard
                
                // Improved Concepts Section
                improvedConceptsCard
                
                // Suggested Next Steps Section
                suggestedNextStepsCard
                
                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Text("Great Job! Here's Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Circular Progress View
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
            
            ForEach(getImprovedConcepts(), id: \.0) { concept, progress in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(concept)
                            .font(.subheadline)
                        Spacer()
                        Text("+\(Int(progress * 100))%")
                            .foregroundColor(.green)
                    }
                    
                    ProgressView(value: progress)
                        .tint(.green)
                }
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
            
            // TODO: Implement dynamic suggestions based on user performance
            ForEach(["Review weak concepts", "Try advanced questions", "Explore related topics"], id: \.self) { suggestion in
                Button(action: {
                    // TODO: Implement navigation to suggested content
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
                // TODO: Implement retry functionality
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
                // Return to home screen
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
        // Calculate average score from all question feedback
        let scores = viewModel.questionFeedback.values.map { $0.overallGrade }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private func getNewConcepts() -> [String] {
        // Get unique concepts from all feedback
        let allConcepts = Set(viewModel.questionFeedback.values.flatMap { feedback in
            feedback.segments.map { $0.concept }
        })
        return Array(allConcepts)
    }
    
    private func getImprovedConcepts() -> [(String, Double)] {
        // For now, return static improvements based on feedback
        // TODO: Implement proper progress tracking
        return getNewConcepts().map { concept in
            let progress = Double.random(in: 0.6...0.95) // Placeholder progress
            return (concept, progress)
        }
    }
}

#Preview {
    ReviewView()
        .environmentObject(ExplainViewModel())
}
