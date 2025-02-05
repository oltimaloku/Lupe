import SwiftUI

enum FeedbackCategory: String, CaseIterable {
    case beginning = "Beginning"
    case proficiency = "Proficiency"
    case mastery = "Mastery"
    
    /// Determine which category a given score falls into.
    static func category(for score: Double) -> FeedbackCategory {
        if score >= 0.80 {
            return .mastery
        } else if score >= 0.50 {
            return .proficiency
        } else {
            return .beginning
        }
    }
}

struct FeedbackBadge: View {
    let overallGrade: Double
    /// Callback to let the parent know the badge was tapped.
    let onBadgeTapped: () -> Void
    
    private var selectedCategory: FeedbackCategory {
        FeedbackCategory.category(for: overallGrade)
    }
    
    @State private var animateBadge = false
    
    var body: some View {
        VStack {
            Image(imageName(for: selectedCategory))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .padding(0)
                // Animate the badge coming in with a scale and fade effect.
                .scaleEffect(animateBadge ? 1.0 : 0.5)
                .opacity(animateBadge ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: animateBadge)
            
            Text(selectedCategory.rawValue)
                .font(.custom("Georgia", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(animateBadge ? 1.0 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: animateBadge)
        }
        .onAppear {
            animateBadge = true
        }
        .onTapGesture {
            onBadgeTapped()
        }
    }
    
    /// Return the name of the image asset for a given category.
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
}
