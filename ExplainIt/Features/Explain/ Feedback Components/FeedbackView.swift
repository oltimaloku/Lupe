import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject private var viewModel: ExplainViewModel
    @State private var selectedConcept: String?
    @State private var showConceptQuestions = false
    @State private var showBadgeExplanation = false  // New state for badge overlay
    
    let onNextQuestion: () -> Void
    let onPreviousQuestion: () -> Void
    let onRetryQuestion: () -> Void
    
    private var isLastQuestion: Bool {
        viewModel.currentQuestionIndex >= viewModel.currentQuestions.count - 1
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        if let feedback = viewModel.questionFeedback[viewModel.currentQuestions[viewModel.currentQuestionIndex].id] {
                            // Use the updated FeedbackBadge and pass the onBadgeTapped callback.
                            FeedbackBadge(overallGrade: feedback.overallGrade, onBadgeTapped: {
                                withAnimation {
                                    showBadgeExplanation = true
                                }
                            })
                            .frame(height: 200)
                            .padding(.top)
                            
                            // Concepts Section with Proficiency
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Key Concepts")
                                    .heading()
                                    .foregroundColor(Color(UIColor.label))
                                
                                EnhancedConceptListView(
                                    segments: feedback.segments,
                                    viewModel: viewModel,
                                    selectedConcept: $selectedConcept
                                ) { concept in
                                    if selectedConcept == concept {
                                        selectedConcept = nil // Deselect if already selected
                                    } else {
                                        selectedConcept = concept // Select new concept
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Detailed Feedback
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Detailed Feedback")
                                    .heading()
                                    .foregroundColor(Color(UIColor.label))
                                
                                FeedbackMessageView(
                                    feedbackAnalysis: feedback,
                                    selectedConcept: selectedConcept
                                )
                            }
                            .padding(.horizontal)
                            
                            // Model Answer
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Model Answer")
                                    .heading()
                                    .foregroundColor(Color(UIColor.label))
                                
                                Text(viewModel.currentQuestions[viewModel.currentQuestionIndex].modelAnswer)
                                    .font(Theme.Fonts.body)
                                    .padding()
                                    .background(Color.black.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        } else {
                            Text("No feedback available")
                                .font(Theme.Fonts.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                submitButton
                    .padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
            }
            
            // Full-screen overlay for badge explanations.
            if showBadgeExplanation {
                BadgeExplanationOverlay {
                    withAnimation {
                        showBadgeExplanation = false
                    }
                }
                .zIndex(1)
            }
        }
        .navigationTitle("Question \(viewModel.currentQuestionIndex + 1) Feedback")
        .font(Theme.Fonts.heading)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConceptQuestions) {
            if let concept = selectedConcept {
                ConceptQuestionsView(concept: concept)
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: onNextQuestion) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text(isLastQuestion ? "Finish" : "Continue")
                    .font(.custom("Georgia", size: 16)).bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accentColor)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Supporting Views

struct EnhancedConceptListView: View {
    let segments: [FeedbackSegment]
    let viewModel: ExplainViewModel
    @Binding var selectedConcept: String?
    let onConceptTap: (String) -> Void
    
    private var uniqueSegments: [FeedbackSegment] {
        var conceptSegments: [String: FeedbackSegment] = [:]
        
        for segment in segments {
            // Skip segments with no concept
            guard let concept = segment.concept else { continue }
            
            if let existingSegment = conceptSegments[concept] {
                let shouldReplace = compareFeedbackTypes(new: segment.feedbackType,
                                                       existing: existingSegment.feedbackType)
                if shouldReplace {
                    conceptSegments[concept] = segment
                }
            } else {
                conceptSegments[concept] = segment
            }
        }
        
        return Array(conceptSegments.values).sorted { $0.concept ?? "" < $1.concept ?? "" }
    }
    
    private func compareFeedbackTypes(new: FeedbackType, existing: FeedbackType) -> Bool {
        let priority: [FeedbackType] = [.correct, .partiallyCorrect, .incorrect]
        return priority.firstIndex(of: new)! < priority.firstIndex(of: existing)!
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(uniqueSegments, id: \.concept) { segment in
                ConceptProgressCard(
                    segment: segment,
                    viewModel: viewModel,
                    isSelected: selectedConcept == segment.concept,
                    onTap: { if let concept = segment.concept {
                        onConceptTap(concept)
                    }}
                )
            }
        }
    }
}

struct ConceptProgressCard: View {
    let segment: FeedbackSegment
    let viewModel: ExplainViewModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Concept Name and Status
                HStack {
                    Text(segment.concept ?? "Irrelevant Content")  // Add fallback text
                        .font(Theme.Fonts.body)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: feedbackIcon)
                        .foregroundColor(segment.feedbackType.color)
                }
                
                // Only show proficiency progress if we have a concept
                if let conceptName = segment.concept,
                   let concept = viewModel.currentTopic?.concepts.first(where: { $0.name == conceptName }),
                   let proficiency = concept.proficiency {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: proficiency.proficiencyScore, total: 100)
                            .tint(masteryColor(for: proficiency.masteryLevel))
                        
                        HStack {
                            Text(proficiency.masteryLevel.rawValue.capitalized)
                                .font(Theme.Fonts.small)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(proficiency.proficiencyScore))%")
                                .font(Theme.Fonts.small)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if segment.feedbackType == .irrelevant {
                    // Show explanation for irrelevant content
                    Text(segment.explanation)
                        .font(Theme.Fonts.small)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(segment.feedbackType.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? getBorderColor(for: segment.feedbackType) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var feedbackIcon: String {
        switch segment.feedbackType {
        case .correct: return "checkmark.circle.fill"
        case .partiallyCorrect: return "exclamationmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .irrelevant: return "minus.circle.fill"  // Changed to minus as discussed earlier
        }
    }
    
    private func masteryColor(for level: MasteryLevel) -> Color {
        switch level {
        case .novice: return Theme.accentColor
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
    
    private func getBorderColor(for feedbackType: FeedbackType) -> Color {
        switch feedbackType {
        case .correct:
            return Color.green.opacity(0.8)
        case .partiallyCorrect:
            return Color.yellow.opacity(0.8)
        case .incorrect:
            return Theme.accentColor.opacity(0.8)
        case .irrelevant:
            return .gray.opacity(0.8)
        }
    }
}

#Preview {
    NavigationView {
        FeedbackView(
            onNextQuestion: {},
            onPreviousQuestion: {},
            onRetryQuestion: {}
        )
        .environmentObject(ExplainViewModel.createForPreview())
    }
}
