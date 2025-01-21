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
                // Concept Header (only show for non-irrelevant feedback)
                if let concept = feedbackSegment.concept {
                    HStack {
                        Text(concept)
                            .font(Theme.Fonts.heading).bold()
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                        if showAddConceptButton {
                            Button(action: addConceptToTopic) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.accentColor)
                                    .font(.system(size: 30))
                            }
                        }
                    }
                } else {
                    Text("Irrelevant Content")
                        .font(Theme.Fonts.heading).bold()
                        .foregroundColor(.secondary)
                }
                
                // User's Response
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Response:")
                        .font(Theme.Fonts.body)
                        .fontWeight(.semibold)
                    Text(feedbackSegment.text)
                        .font(Theme.Fonts.body)
                        .padding()
                        .background(feedbackSegment.feedbackType.color)
                        .cornerRadius(8)
                }
                
                // Feedback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback:")
                        .font(Theme.Fonts.body)
                        .fontWeight(.semibold)
                    Text(feedbackSegment.explanation)
                        .font(Theme.Fonts.body)
                        .padding()
                        .background(Theme.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Only show key points and criteria for non-irrelevant feedback
                    if feedbackSegment.feedbackType != .irrelevant {
                        if !feedbackSegment.keyPointsAddressed.isEmpty {
                            Text("Key Points Addressed:")
                                .font(Theme.Fonts.body)
                                .fontWeight(.semibold)
                            ForEach(feedbackSegment.keyPointsAddressed, id: \.self) { point in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(point)
                                        .font(Theme.Fonts.body)
                                }
                                .padding(.leading)
                            }
                        }
                        
                        if !feedbackSegment.criteriaMatched.isEmpty {
                            Text("Criteria Met:")
                                .font(Theme.Fonts.body)
                                .fontWeight(.semibold)
                            ForEach(feedbackSegment.criteriaMatched, id: \.self) { criterion in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(criterion)
                                        .font(Theme.Fonts.body)
                                }
                                .padding(.leading)
                            }
                        }
                    }
                }
                
                // Only show definition button for non-irrelevant feedback with a concept
                if let concept = feedbackSegment.concept {
                    // Generate Definition Button
                    Button(action: {
                        showDefinitionSection = true
                        fetchDefinitionIfNeeded()
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Generate Definition")
                                .font(Theme.Fonts.body)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(showDefinitionSection)
                    
                    // Definition section
                    if showDefinitionSection {
                        VStack(alignment: .center, spacing: 8) {
                            if let definition = definition {
                                Text("Correct Understanding:")
                                    .font(Theme.Fonts.body)
                                    .fontWeight(.semibold)
                                Markdown(definition)
                                    .padding()
                                    .background(Theme.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                            } else if isLoading {
                                ProgressView("Loading correct explanation...")
                                    .padding(.top)
                            }
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
        guard let concept = feedbackSegment.concept else { return }
        
        if let cachedDefinition = viewModel.definitions[concept] {
            self.definition = cachedDefinition
            return
        }
        
        guard definition == nil && !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let fetchedDefinition = try await viewModel.getDefinition(for: concept)
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
        guard let concept = feedbackSegment.concept else { return }
        
        do {
            try viewModel.addNewConceptFromFeedback(
                conceptName: concept,
                definition: definition
            )
            showAddConceptButton = false
        } catch {
            print("Error adding concept: \(error.localizedDescription)")
        }
    }
    
    private func checkIfConceptExists() {
        guard let concept = feedbackSegment.concept else {
            showAddConceptButton = false
            return
        }
        
        if let currentTopic = viewModel.currentTopic {
            showAddConceptButton = !currentTopic.concepts.contains(where: {
                $0.name.lowercased() == concept.lowercased()
            })
        }
    }
}
