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
                ReviewView()
                    .environmentObject(viewModel)
            } else if viewModel.showingFeedback {
                FeedbackView(
                    onNextQuestion: {
                        if hasCompletedLastQuestion {
                            showingReview = true
                        } else {
                            viewModel.setNextQuestion()
                            viewModel.showExplainView()
                        }
                    },
                    onPreviousQuestion: {
                        viewModel.setPreviousQuestion()
                        viewModel.showExplainView()
                    },
                    onRetryQuestion: {
                        if let question = viewModel.currentQuestion {
                            viewModel.resetFeedback(for: question.id)
                        }
                        viewModel.showExplainView()
                    }
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
        viewModel.currentQuestionIndex >= viewModel.currentQuestions.count - 1 &&
        viewModel.showingFeedback &&
        viewModel.questionFeedback[viewModel.currentQuestion?.id ?? UUID()] != nil
    }
}
