import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject private var viewModel: ExplainViewModel
    @State private var selectedConcept: String?
    @State private var showConceptQuestions = false
    
    let onNextQuestion: () -> Void
    let onPreviousQuestion: () -> Void
    let onRetryQuestion: () -> Void
    
    private var isLastQuestion: Bool {
        viewModel.currentQuestionIndex >= viewModel.currentQuestions.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    if let feedback = viewModel.questionFeedback[viewModel.currentQuestions[viewModel.currentQuestionIndex].id] {
                        // Progress Indicator
                        ProgressIndicatorView(score: feedback.overallGrade)
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
                                .background(Theme.accentColor.opacity(0.1))
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
            
            // Navigation Buttons
            VStack {
                Divider()
                
                HStack(spacing: 20) {
                    Button(action: onPreviousQuestion) {
                        Label("Previous", systemImage: "arrow.left")
                            .frame(maxWidth: .infinity)
                            .font(Theme.Fonts.body)
                    }
                    .disabled(viewModel.currentQuestionIndex == 0)
                    .tint(Theme.accentColor)
                    
                    Button(action: onRetryQuestion) {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .font(Theme.Fonts.body)
                    }
                    .tint(Theme.accentColor)
                    
                    Button(action: onNextQuestion) {
                        Label(isLastQuestion ? "Finish" : "Next", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                            .font(Theme.Fonts.body)
                    }
                    .tint(Theme.accentColor)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Question \(viewModel.currentQuestionIndex + 1) Feedback").font(Theme.Fonts.heading)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConceptQuestions) {
            if let concept = selectedConcept {
                ConceptQuestionsView(concept: concept)
            }
        }
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
            if let existingSegment = conceptSegments[segment.concept] {
                let shouldReplace = compareFeedbackTypes(new: segment.feedbackType,
                                                       existing: existingSegment.feedbackType)
                if shouldReplace {
                    conceptSegments[segment.concept] = segment
                }
            } else {
                conceptSegments[segment.concept] = segment
            }
        }
        
        return Array(conceptSegments.values).sorted { $0.concept < $1.concept }
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
                    onTap: { onConceptTap(segment.concept) }
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
                    Text(segment.concept)
                        .font(Theme.Fonts.body)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: feedbackIcon)
                        .foregroundColor(segment.feedbackType.color)
                }
                
                // Proficiency Progress
                if let concept = viewModel.currentTopic?.concepts.first(where: { $0.name == segment.concept }),
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
        }
    }
}

