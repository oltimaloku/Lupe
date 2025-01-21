//
//  PracticeHistorySection.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-24.
//

import SwiftUI

struct PracticeHistorySection: View {
    let interactions: [ProficiencyInteraction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice History")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(interactions.prefix(5), id: \.date) { interaction in
                HStack {
                    Image(systemName: interactionIcon(for: interaction.interactionType))
                        .foregroundColor(interactionColor(for: interaction))
                    
                    VStack(alignment: .leading) {
                        Text(interaction.details)
                            .font(.subheadline)
                        Text(formattedDate(interaction.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(scoreImpactText(for: interaction))
                        .font(.caption)
                        .foregroundColor(scoreImpactColor(for: interaction))
                }
                .padding(.vertical, 4)
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
    
    private func interactionIcon(for type: InteractionType) -> String {
        switch type {
        case .explanation: return "text.bubble.fill"
        case .quiz: return "checkmark.circle.fill"
        case .review: return "book.fill"
        case .decay: return "arrow.down.circle.fill"
        case .indirect: return "arrow.triangle.branch"
        }
    }
    
    private func interactionColor(for interaction: ProficiencyInteraction) -> Color {
        switch interaction.interactionType {
        case .decay: return .red
        default: return interaction.scoreImpact >= 0 ? .green : .red
        }
    }
    
    private func scoreImpactText(for interaction: ProficiencyInteraction) -> String {
        if interaction.scoreImpact >= 0 {
            return "+\(String(format: "%.1f", interaction.scoreImpact))%"
        } else {
            return "\(String(format: "%.1f", interaction.scoreImpact))%"
        }
    }
    
    private func scoreImpactColor(for interaction: ProficiencyInteraction) -> Color {
        interaction.scoreImpact >= 0 ? .green : .red
    }
}
