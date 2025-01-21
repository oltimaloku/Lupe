////
////  ConceptListView.swift
////  ExplainIt
////
////  Created by Olti Maloku on 2024-11-28.
////
//
//import SwiftUI
//
//struct ConceptListView: View {
//    let segments: [FeedbackSegment]
//    let onConceptTap: (String) -> Void
//    
//    private var uniqueConcepts: [String: FeedbackType] {
//        Dictionary(
//            segments.map { ($0.concept, $0.feedbackType) },
//            uniquingKeysWith: { first, _ in first }
//        )
//    }
//    
//    var body: some View {
//        LazyVGrid(columns: [
//            GridItem(.flexible()),
//            GridItem(.flexible())
//        ], spacing: 12) {
//            ForEach(Array(uniqueConcepts.keys.sorted()), id: \.self) { concept in
//                if let feedbackType = uniqueConcepts[concept] {
//                    Button(action: { onConceptTap(concept) }) {
//                        HStack {
//                            Text(concept)
//                                .lineLimit(2)
//                                .minimumScaleFactor(0.8)
//                            Spacer()
//                            Image(systemName: feedbackType == .correct ? "checkmark.circle.fill" :
//                                    feedbackType == .partiallyCorrect ? "exclamationmark.circle.fill" :
//                                    "xmark.circle.fill")
//                        }
//                        .padding()
//                        .background(feedbackType.color)
//                        .cornerRadius(12)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//        }
//    }
//}
//
