//
//  ConceptProgressRow.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-26.
//

import SwiftUI

struct ConceptProgressRow: View {
    let concept: Concept
    let previousScore: Double
    let currentScore: Double
    let masteryLevel: MasteryLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(concept.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: "%.0f%%", previousScore))
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", currentScore))
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: currentScore, total: 100)
                    .tint(masteryColor)
                
                HStack {
                    Text(masteryLevel.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("+\(String(format: "%.1f", currentScore - previousScore))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let lastPractice = concept.proficiency?.lastInteractionDate {
                Text("Last practiced: \(formattedDate(lastPractice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(masteryColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var masteryColor: Color {
        switch masteryLevel {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
