import SwiftUI

struct BadgeExplanationOverlay: View {
    /// Callback to dismiss the overlay.
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed full-screen background.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        onDismiss()
                    }
                }
            
            // The explanation card (scrollable if needed).
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Badge Explanations")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                onDismiss()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        HStack(alignment: .top, spacing: 12) {
                            Image(imageName(for: category))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.rawValue)
                                    .font(.headline)
                                Text(explanation(for: category))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(32)
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut, value: UUID())  // triggers animation on state change
    }
    
    private func imageName(for category: FeedbackCategory) -> String {
        switch category {
        case .beginning:
            return "beginningBadge"
        case .proficiency:
            return "proficientBadge"
        case .mastery:
            return "masteryBadge"
        }
    }
    
    private func explanation(for category: FeedbackCategory) -> String {
        switch category {
        case .beginning:
            return "Just starting out. More practice needed."
        case .proficiency:
            return "Good grasp of the material, keep improving."
        case .mastery:
            return "Excellent! You've mastered the topic."
        }
    }
}
