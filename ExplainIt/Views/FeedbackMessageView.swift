//
//  FeedbackSegmentView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-22.
//

import SwiftUI

struct FeedbackMessageView: View {
    let feedbackAnalysis: FeedbackAnalysis
    @EnvironmentObject var viewModel: ExplainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer() // Pushes the text to the right
                Text("\(Int(feedbackAnalysis.overallGrade * 100))%")
                    .font(.headline)
                    .padding(.bottom, 4)
                    .foregroundColor(getPercentageColour(percent: feedbackAnalysis.overallGrade))
            }
            
            ForEach(feedbackAnalysis.segments) { segment in
                FeedbackSegmentView(segment: segment)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func getPercentageColour(percent: Double) -> Color{
        switch percent {
        case ..<0.5:
            return .red
        case 0.5..<0.75:
            return .orange
        case 0.75...0.95:
            return Color(red: 218/255, green: 165/255, blue: 32/255)
        case 0.95...1:
            return .green
        default:
            return .gray
        }
    }
}

struct FeedbackSegmentView: View {
    let segment: FeedbackSegment
    @EnvironmentObject var viewModel: ExplainViewModel
    @State private var showExplanation = false
    
    var body: some View {
        Text(segment.text)
            .padding(6)
            .background(segment.feedbackType.color)
            .cornerRadius(8)
            .onTapGesture {
                showExplanation.toggle()
            }
            .popover(isPresented: $showExplanation) {
                FeedbackModal(feedbackSegment: segment)
                    .environmentObject(viewModel)
            }
    }
}

