//
//  MessageBubbleView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-10.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(background)
                .foregroundColor(message.isUserMessage ? .white : .primary)
                .cornerRadius(20)
            
            if !message.isUserMessage {
                Spacer()
            }
        }
    }
    
    private var background: Color {
        if message.isError {
            return .red.opacity(0.8)
        }
        return message.isUserMessage ? .blue : Color(.systemGray6)
    }
}

