//
//  ConceptQuestionsView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-28.
//

import SwiftUI

struct ConceptQuestionsView: View {
    let concept: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Follow-up questions for \(concept) will appear here")
                    .padding()
            }
            .navigationTitle(concept)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
