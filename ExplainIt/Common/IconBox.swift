//
//  IconBox.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-15.
//

import SwiftUI

struct IconBox: View {
    var iconName: String
    var boxSize: CGFloat = 50
    var iconSize: CGFloat = 20
    var backgroundColor: Color = Color(uiColor: .secondarySystemBackground)
    var foregroundColor: Color = Color(uiColor: .label)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .frame(width: boxSize, height: boxSize)
            
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(foregroundColor)
        }
    }
}

#Preview {
    IconBox(iconName: "star.fill")
}
