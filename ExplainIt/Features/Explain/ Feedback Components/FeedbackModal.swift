//
//  FeedbackModal.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-22.
//

import SwiftUI
import MarkdownUI

struct FeedbackModal: View {
    let feedbackSegment: FeedbackSegment
    @EnvironmentObject var viewModel: ExplainViewModel
    @State private var definition: String?
    @State private var isLoading: Bool = false
    @State private var showAddConceptButton = true
    @State private var showDefinitionSection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Concept Header
                HStack {
                    Text(feedbackSegment.concept)
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    if showAddConceptButton {
                        Button(action: addConceptToTopic) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(UIColor.label))
                                .font(.system(size: 30))
                        }
                    }
                }
                
                // User's Response
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Response:")
                        .font(.headline)
                    Text(feedbackSegment.text)
                        .padding()
                        .background(feedbackSegment.feedbackType.color)
                        .cornerRadius(8)
                }
                
                // Feedback and Key Points
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback:")
                        .font(.headline)
                    Text(feedbackSegment.explanation)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    if !feedbackSegment.keyPointsAddressed.isEmpty {
                        Text("Key Points Addressed:")
                            .font(.headline)
                        ForEach(feedbackSegment.keyPointsAddressed, id: \.self) { point in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(point)
                            }
                            .padding(.leading)
                        }
                    }
                    
                    if !feedbackSegment.criteriaMatched.isEmpty {
                        Text("Criteria Met:")
                            .font(.headline)
                        ForEach(feedbackSegment.criteriaMatched, id: \.self) { criterion in
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(criterion)
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                // Generate Definition Button
                Button(action: {
                    showDefinitionSection = true
                    fetchDefinitionIfNeeded()
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Generate Definition")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(showDefinitionSection)
                
                // Definition section
                if showDefinitionSection {
                    VStack(alignment: .leading, spacing: 8) {
                        if let definition = definition {
                            Text("Correct Understanding:")
                                .font(.headline)
                            Markdown(definition)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        } else if isLoading {
                            ProgressView("Loading correct explanation...")
                                .padding(.top)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            checkIfConceptExists()
        }
    }
    
    private func fetchDefinitionIfNeeded() {
        print("test1")
        if let cachedDefinition = viewModel.definitions[feedbackSegment.concept] {
            self.definition = cachedDefinition
            return
        }
        print("test2")
        guard definition == nil && !isLoading else { return }
        isLoading = true
        print("test3")
        Task {
            do {
                let fetchedDefinition = try await viewModel.getDefinition(for: feedbackSegment.concept)
                print("fetchedDefinition: \(fetchedDefinition)")
                await MainActor.run {
                    self.definition = fetchedDefinition
                    self.isLoading = false
                }
            } catch {
                print("Error fetching definition: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addConceptToTopic() {
        do {
            try viewModel.addNewConceptFromFeedback(
                conceptName: feedbackSegment.concept,
                definition: definition
            )
            showAddConceptButton = false
        } catch {
            print("Error adding concept: \(error.localizedDescription)")
        }
    }
    
    private func checkIfConceptExists() {
        if let currentTopic = viewModel.currentTopic {
            showAddConceptButton = !currentTopic.concepts.contains(where: {
                $0.name.lowercased() == feedbackSegment.concept.lowercased()
            })
        }
    }
}


