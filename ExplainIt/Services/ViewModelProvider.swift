//
//  ViewModelProvider.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import SwiftUI

@propertyWrapper
struct ViewModelProvider<T: ObservableObject>: DynamicProperty {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var viewModel: T
    
    init(topicId: UUID) where T == ExplainViewModel {
        _viewModel = StateObject(wrappedValue: DIContainer.shared.explainViewModel(for: topicId))
    }
    
    var wrappedValue: T {
        viewModel
    }
    
    var projectedValue: ObservedObject<T>.Wrapper {
        $viewModel
    }
}
