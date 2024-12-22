//
//  TopicCard.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-15.
//

import SwiftUI

struct TopicCard: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack {
            createHeader()
            createActionRow()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5)))
    }
    
    private func createHeader() -> some View {
        HStack(alignment: .center) {
            IconBox(iconName: icon, backgroundColor: Color.green.opacity(0.2), foregroundColor: Color.green)
            Text(name)
                .font(.headline)
                .foregroundColor(Color(UIColor.label))
                .fontWeight(.regular)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
    
    private func createActionRow() -> some View {
        HStack {
            // Add buttons or actions here if needed
        }
    }
    
    private func createActionContainer(icon: String, text: String) -> some View {
        let containerWidth = (UIScreen.main.bounds.width / 3) - 30
        return Button(action: {
        }) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
                Spacer()
                Text(text)
                    .foregroundColor(.black)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(width: containerWidth, height: 100)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.2)))
        }
    }
}

#Preview {
    TopicCard(name: "Computer Networking", icon: "computer")
}
