import SwiftUI

struct QuestionFlowContainerView: View {
    @EnvironmentObject private var viewModel: ExplainViewModel
    
    private var isLastQuestion: Bool {
        viewModel.currentQuestionIndex >= viewModel.currentQuestions.count - 1
    }
    
    private var showingReview: Bool {
        isLastQuestion && viewModel.showingFeedback &&
        viewModel.questionFeedback[viewModel.currentQuestion?.id ?? UUID()] != nil
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                LoadingIndicatorView()
            }
            else if showingReview {
                ReviewView()
                    .environmentObject(viewModel)
            }
            else if viewModel.showingFeedback {
                FeedbackView(
                    onNextQuestion: {
                        if !isLastQuestion {
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
                ).environmentObject(viewModel)
            } else {
                ExplainView {
                    viewModel.showFeedbackView()
                }.environmentObject(viewModel)
            }
        }
    }
}
