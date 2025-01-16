//
//  LoadingIndicator.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-28.
//

import SwiftUI

struct LoadingIndicatorView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground) // Background color
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView() // Default spinning activity indicator
                    .scaleEffect(2) // Increase the size
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.accentColor)) // Custom color
                
                Text("Loading...")
                    .font(Theme.Fonts.georgia(size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    LoadingIndicatorView()
}

