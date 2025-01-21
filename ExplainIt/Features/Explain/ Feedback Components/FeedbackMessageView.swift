import SwiftUI

struct FeedbackMessageView: View {
    let feedbackAnalysis: FeedbackAnalysis
    let selectedConcept: String?
    @EnvironmentObject var viewModel: ExplainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(feedbackAnalysis.segments) { segment in
                FeedbackSegmentView(
                    segment: segment,
                    isSelected: selectedConcept == segment.concept
                )
            }
        }
    }
    
    private func getPercentageColour(percent: Double) -> Color {
        switch percent {
        case ..<0.5:
            return Theme.accentColor
        case 0.5..<0.75:
            return .orange
        case 0.75...0.95:
            return Theme.accentColor
        case 0.95...1:
            return .green
        default:
            return .gray
        }
    }
}

struct FeedbackSegmentView: View {
    let segment: FeedbackSegment
    let isSelected: Bool
    @EnvironmentObject var viewModel: ExplainViewModel
    @State private var showExplanation = false
    
    var body: some View {
        Text(segment.text)
            .font(Theme.Fonts.body)
            .padding()
            .background(segment.feedbackType.color)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? getBorderColor(for: segment.feedbackType) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .onTapGesture {
                showExplanation.toggle()
            }
            .popover(isPresented: $showExplanation) {
                FeedbackModal(feedbackSegment: segment)
                    .environmentObject(viewModel)
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
