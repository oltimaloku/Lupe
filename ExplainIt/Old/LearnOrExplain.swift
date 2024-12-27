import SwiftUI

struct LearnOrExplain: View {
    let concept: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .label))
                }
                
                Spacer()
                
                Text(concept)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Cards
            VStack(spacing: 24) { // Increased spacing between cards
                NavigationLink(destination: Text("Learn View")) {
                    ModeCard(
                        title: "Learn",
                        description: "Get a detailed explanation of this concept",
                        icon: "book.fill",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: Text("Explain View")) {
                    ModeCard(
                        title: "Explain",
                        description: "Try explaining this concept in your own words",
                        icon: "mic.fill",
                        color: .green
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .navigationBarHidden(true)
    }
}

struct ModeCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon at the top
            HStack {
                IconBox(
                    iconName: icon,
                    boxSize: 60, // Larger icon box
                    iconSize: 24, // Larger icon
                    backgroundColor: color.opacity(0.2),
                    foregroundColor: color
                ).padding(.trailing, 8)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(uiColor: .label))
            }
            
            
            
            // Title and description
            VStack(alignment: .leading, spacing: 8) {
                
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            
            // Chevron at the bottom
            
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.3) // 30% of screen height
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        )
    }
}



#Preview {
    NavigationView {
        LearnOrExplain(concept: "Computer Networking")
    }
}
