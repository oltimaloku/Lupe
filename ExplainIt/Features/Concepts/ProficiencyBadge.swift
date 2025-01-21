//
//  ProficiencyBadge.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-24.
//

import SwiftUI

struct ProficiencyBadge: View {
    let proficiency: ConceptProficiency
    
    var body: some View {
        Text("\(Int(proficiency.proficiencyScore))%")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(proficiencyColor.opacity(0.2))
            .foregroundColor(proficiencyColor)
            .cornerRadius(8)
    }
    
    private var proficiencyColor: Color {
        switch proficiency.masteryLevel {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return .green
        }
    }
}
