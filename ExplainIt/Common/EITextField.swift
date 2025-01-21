import SwiftUI

struct EITextField: View {
    @Binding var text: String
    var placeholder: String
    var cornerRadius: CGFloat = 25
    var padding: CGFloat = 10
    var icon: String = "magnifyingglass"
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(Theme.Fonts.body)
                .padding(.vertical, padding)
                .textFieldStyle(PlainTextFieldStyle())
                // Apply the Georgia font to placeholder text
                .tint(Theme.accentColor) // Cursor color
                // Custom modifier to style the placeholder
                .modifier(PlaceholderStyle(showPlaceholder: text.isEmpty,
                                         placeholder: placeholder))
        }
        .padding(.horizontal, padding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        )
    }
}

// Custom modifier to style the placeholder text
struct PlaceholderStyle: ViewModifier {
    var showPlaceholder: Bool
    var placeholder: String

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if showPlaceholder {
                Text(placeholder)
                    .font(Theme.Fonts.body)
                    .foregroundColor(.secondary)
                    .opacity(0.3)
            }
            content
        }
    }
}

#Preview {
    EITextField(text: .constant(""), placeholder: "Ask me anything...")
}
