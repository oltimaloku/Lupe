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
                    // Progress Indicator Section
                    if let feedback = viewModel.questionFeedback[viewModel.currentQuestions[viewModel.currentQuestionIndex].id] {
                        ProgressIndicatorView(score: feedback.overallGrade)
                            .frame(height: 200)
                            .padding(.top)
                        
                        // Concepts Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Key Concepts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ConceptListView(segments: feedback.segments) { concept in
                                selectedConcept = concept
                                showConceptQuestions.toggle()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Detailed Feedback Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detailed Feedback")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            FeedbackMessageView(feedbackAnalysis: feedback)
                        }
                        .padding(.horizontal)
                        
                        // Model Answer Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Model Answer")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(viewModel.currentQuestions[viewModel.currentQuestionIndex].modelAnswer)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                    } else {
                        Text("No feedback available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Navigation Buttons outside ScrollView
            VStack {
                Divider()
                
                HStack(spacing: 20) {
                    Button(action: onPreviousQuestion) {
                        Label("Previous", systemImage: "arrow.left")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.currentQuestionIndex == 0)
                    
                    Button(action: onRetryQuestion) {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: onNextQuestion) {
                        Label(isLastQuestion ? "Finish" : "Next", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isLastQuestion)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Question \(viewModel.currentQuestionIndex + 1) Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConceptQuestions) {
            if let concept = selectedConcept {
                ConceptQuestionsView(concept: concept)
            }
        }
    }
}
