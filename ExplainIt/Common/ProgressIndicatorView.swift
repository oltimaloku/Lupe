//
//  ProgressIndicatorView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-28.
//

import SwiftUI

struct ProgressIndicatorView: View {
    let score: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: score)
                .stroke(
                    score >= 0.75 ? Color.green :
                        score >= 0.5 ? Color.yellow :
                        Color.red,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: score)
            
            VStack {
                Text("\(Int(score * 100))%")
                    .font(.system(size: 48, weight: .bold))
                Text("Score")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}


#Preview {
    ProgressIndicatorView(score: 10)
}
