//
//  ConceptsView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-23.
//

import SwiftUI

struct TopicView: View {
    
    let topic: Topic
    
    var body: some View {
        VStack (alignment: .leading) {
            Text(topic.name).font(.largeTitle).bold().frame(maxWidth: .infinity, alignment: .leading)
            LazyVStack (spacing: 16) {
                ForEach(topic.concepts, id: \.id) { concept in
                    NavigationLink (destination: ConceptView(concept: concept)) {
                        TopicCard(name: concept.name, icon: "image")
                    }
                    
                    
                }
            }
            Spacer()
        }.padding(20)
    }
}

#Preview {
    TopicView(topic: Topic(
        id: UUID(),
        name: "Technology",
        icon: "gear",
        concepts: [
            Concept(id: UUID(), name: "Artificial Intelligence"),
            Concept(id: UUID(), name: "Cybersecurity"),
            Concept(id: UUID(), name: "Blockchain")
        ]
    ))
}
