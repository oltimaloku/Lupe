//
//  ProficiencyCard.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-24.
//

import SwiftUI

struct ProficiencyCard: View {
    let proficiency: ConceptProficiency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mastery Level:")
                    .font(.headline)
                Spacer()
                Text(proficiency.masteryLevel.rawValue.capitalized)
                    .foregroundColor(masteryColor)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: proficiency.proficiencyScore, total: 100)
                .tint(masteryColor)
            
            Text(proficiency.masteryLevel.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Last practice: \(formattedDate(proficiency.lastInteractionDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var masteryColor: Color {
        switch proficiency.masteryLevel {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
}
