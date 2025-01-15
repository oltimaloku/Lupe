//
//  ExplainItApp.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-07.
//

import SwiftUI

@main
struct ExplainItApp: App {
    @StateObject private var diContainer = DIContainer.shared
    
    var body: some Scene { 
        WindowGroup {
            PromptView()
                .environment(\.diContainer, diContainer)
        }
    }
}
