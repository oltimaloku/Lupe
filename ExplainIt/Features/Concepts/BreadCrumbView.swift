//
//  BreadCrumbView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-12-25.
//

import SwiftUI

struct BreadcrumbView: View {
    let path: [UUID]
    let topicId: UUID
    @StateObject private var viewModel: BreadcrumbViewModel
    
    init(path: [UUID], topicId: UUID) {
        self.path = path
        self.topicId = topicId
        _viewModel = StateObject(wrappedValue: BreadcrumbViewModel(path: path, topicId: topicId))
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.conceptNames, id: \.self) { name in
                    HStack {
                        Text(name)
                            .foregroundColor(.blue)
                        if name != viewModel.conceptNames.last {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}
