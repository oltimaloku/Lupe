//
//  EITextField.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-15.
//

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
                .foregroundStyle(.secondary) // More adaptive than .gray
            TextField(placeholder, text: $text)
                .padding(.vertical, padding)
                .textFieldStyle(PlainTextFieldStyle())
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

#Preview {
    EITextField(text: .constant(""), placeholder: "Ask me anything...")
}
