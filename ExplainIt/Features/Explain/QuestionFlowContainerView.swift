import SwiftUI

struct QuestionFlowContainerView: View {
    @ViewModelProvider private var viewModel: ExplainViewModel
    @State private var showingReview = false
    
    init(topicId: UUID) {
        _viewModel = ViewModelProvider(topicId: topicId)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingIndicatorView()
            } else if showingReview {
                ReviewView(explainViewModel: viewModel)
            } else if viewModel.showingFeedback {
                FeedbackView(
                    onNextQuestion: handleNextQuestion,
                    onPreviousQuestion: handlePreviousQuestion,
                    onRetryQuestion: handleRetryQuestion
                )
                .environmentObject(viewModel)
            } else {
                ExplainView {
                    viewModel.showFeedbackView()
                }
                .environmentObject(viewModel)
            }
        }
    }
    
    private var hasCompletedLastQuestion: Bool {
        guard let currentQuestion = viewModel.currentQuestion else { return false }
        return viewModel.currentQuestionIndex >= viewModel.currentQuestions.count - 1 &&
            viewModel.showingFeedback &&
            viewModel.questionFeedback[currentQuestion.id] != nil
    }
    
    // MARK: - Action Handlers
    private func handleNextQuestion() {
        if hasCompletedLastQuestion {
            showingReview = true
        } else {
            viewModel.setNextQuestion()
            viewModel.showExplainView()
        }
    }
    
    private func handlePreviousQuestion() {
        viewModel.setPreviousQuestion()
        viewModel.showExplainView()
    }
    
    private func handleRetryQuestion() {
        if let question = viewModel.currentQuestion {
            viewModel.resetFeedback(for: question.id)
        }
        viewModel.showExplainView()
    }
}
