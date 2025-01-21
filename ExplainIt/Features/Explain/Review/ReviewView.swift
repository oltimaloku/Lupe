import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(explainViewModel: ExplainViewModel) {
        _viewModel = StateObject(wrappedValue: ReviewViewModel(explainViewModel: explainViewModel))
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Great work!")
                            .font(.custom("Georgia", size: 32))
                            .fontWeight(.bold)
                        
                        Text("Here's what you learned")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Content Cards
                    VStack(spacing: 24) {
                        newConceptsCard
                        //suggestedNextStepsCard
                        questionFeedbackCard
                        
                    }
                    
                }
                
            }
            Spacer()
            actionButtons
        }.navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .padding(.horizontal, 20)
        
    }
    
    private var newConceptsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Concepts")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
            
            ForEach(viewModel.getNewConcepts(), id: \.self) { concept in
                HStack(spacing: 12) {
                    Image(systemName: "brain.fill")
                        .foregroundColor(Theme.accentColor)
                    
                    Text(concept)
                        .font(.custom("Georgia", size: 16))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentColor.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var questionFeedbackCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Performance")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
            
            ForEach(viewModel.getQuestionFeedback(), id: \.feedback.id) { index, feedback in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        // Question number badge
                        Text("\(index)")
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Theme.accentColor)
                            .cornerRadius(14)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Question text
                            Text("Question \(index)")
                                .font(.custom("Georgia", size: 16))
                                .fontWeight(.semibold)
                            
                            // Concepts covered
                            let concepts = feedback.segments
                                .compactMap { $0.concept }
                                .filter { !$0.isEmpty }

                            Text(concepts.isEmpty ? "No specific concepts" : concepts.joined(separator: ", "))
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Score with color
                        Text("\(Int(feedback.overallGrade * 100))%")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(for: feedback.overallGrade))
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 4)
                                .opacity(0.1)
                                .foregroundColor(Theme.accentColor)
                            
                            Rectangle()
                                .frame(width: geometry.size.width * feedback.overallGrade, height: 4)
                                .foregroundColor(scoreColor(for: feedback.overallGrade))
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentColor.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var suggestedNextStepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
            
            ForEach(viewModel.generateSuggestions(), id: \.self) { suggestion in
                Button(action: {
                    handleSuggestion(suggestion)
                }) {
                    HStack {
                        Image(systemName: suggestionsIcon(for: suggestion))
                            .foregroundColor(Theme.accentColor)
                        
                        Text(suggestion)
                            .font(.custom("Georgia", size: 16))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var actionButtons: some View {
        Button(action: {
            viewModel.resetAndReturn()
            dismiss()
        }) {
            HStack {
                Image(systemName: "house.fill")
                Text("Return Home")
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.bold)
            }
            .foregroundColor(Theme.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accentColor.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private func suggestionsIcon(for suggestion: String) -> String {
        switch suggestion {
        case "Review weak concepts":
            return "book.fill"
        case "Try advanced questions":
            return "star.fill"
        case "Explore related topics":
            return "network"
        default:
            return "chevron.right.circle.fill"
        }
    }
    
    private func handleSuggestion(_ suggestion: String) {
        // TODO: Implement navigation to suggested content
        switch suggestion {
        case "Review weak concepts":
            break
        case "Try advanced questions":
            break
        case "Explore related topics":
            break
        default:
            break
        }
    }
}

#Preview {
    NavigationView {
        ReviewView(explainViewModel: ExplainViewModel.createForPreview())
    }
}
