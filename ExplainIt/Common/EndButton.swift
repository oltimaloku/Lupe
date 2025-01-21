//
//  EndButton.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2025-01-15.
//

import SwiftUI

struct RoundedButton: View {
    let title: String
    let action: () -> Void
    
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Georgia", size: 16))
                .bold()
                .foregroundColor(.white)
                .frame(height: 30)
                .frame(maxWidth: 70)
                .padding(.horizontal, 24)
                .background(Theme.accentColor)
                .clipShape(Capsule())
        }
    }
}

// Usage Example
struct RoundedButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundedButton(title: "End") {
            print("Button tapped")
        }
        .padding()
    }
}
