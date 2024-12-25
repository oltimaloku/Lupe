import SwiftUI

@MainActor
class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    let openAIService: OpenAIService
    let topicRepository: TopicRepository
    
    // View Model store to maintain references and prevent recreation
    private var viewModelStore: [UUID: ExplainViewModel] = [:]
    
    private init() {
        self.openAIService = OpenAIService.shared
        self.topicRepository = TopicRepository()
    }
    
    // MARK: - View Model Factory Methods
    
    func explainViewModel(for topicId: UUID) -> ExplainViewModel {
        if let existingViewModel = viewModelStore[topicId] {
            return existingViewModel
        }
        
        let viewModel = createExplainViewModel()
        viewModelStore[topicId] = viewModel
        return viewModel
    }
    
    func removeViewModel(for topicId: UUID) {
        viewModelStore.removeValue(forKey: topicId)
    }
    
    @MainActor
    private func createExplainViewModel() -> ExplainViewModel {
        let questionGenerator = OpenAIQuestionGenerationService(openAIService: openAIService)
        let gradingService = OpenAIGradingService(openAIService: openAIService)
        let definitionService = OpenAIConceptDefinitionService(openAIService: openAIService)
        let conceptHierarchyService = DefaultConceptHierarchyService(topicRepository: topicRepository)
        
        return ExplainViewModel(
            questionGenerator: questionGenerator,
            gradingService: gradingService,
            definitionService: definitionService,
            topicRepository: topicRepository,
            conceptHierarchyService: conceptHierarchyService
        )
    }
    
    func createTopicViewModel(topic: Topic) -> TopicViewModel {
        return TopicViewModel(
            topic: topic,
            topicRepository: topicRepository,
            conceptHierarchyService: DefaultConceptHierarchyService(topicRepository: topicRepository),
            questionGenerator: OpenAIQuestionGenerationService(openAIService: openAIService)
        )
    }
    
    func createConceptViewModel(concept: Concept, topicId: UUID) -> ConceptViewModel {
        return ConceptViewModel(
            concept: concept,
            topicId: topicId,
            topicRepository: topicRepository,
            conceptHierarchyService: DefaultConceptHierarchyService(topicRepository: topicRepository),
            questionGenerator: OpenAIQuestionGenerationService(openAIService: openAIService)
        )
    }
}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
