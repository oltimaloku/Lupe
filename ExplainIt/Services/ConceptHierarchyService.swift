import Foundation

/// A service that provides hierarchy-related operations for `Concept` objects.
protocol ConceptHierarchyService {
    
    /// Searches for a `Concept` by name within a list of concepts (and their descendants).
    ///
    /// - Parameters:
    ///   - name: The name of the `Concept` to find.
    ///   - concepts: The array of top-level `Concept` objects within which the search should be performed.
    /// - Returns:
    ///   An optional `Concept` matching the specified `name`, or `nil` if no match is found.
    func findConceptInHierarchy(name: String, in concepts: [Concept]) -> Concept?
    
    /// Updates an existing `Concept` in the hierarchy.
    ///
    /// This method attempts to locate the specified `concept` (by its `id`) in the `concepts` array or its sub-hierarchies. If found, the concept is updated with the new data provided in the `concept` parameter.
    ///
    /// - Parameters:
    ///   - concept: The `Concept` containing updated data (must have an existing `id`).
    ///   - concepts: An in-out parameter representing the hierarchy of concepts.
    /// - Throws:
    ///   - `ConceptHierarchyError.conceptNotFound` if no concept with the same `id` is found in the hierarchy.
    func updateConceptInHierarchy(_ concept: Concept, in concepts: inout [Concept]) throws
    
    /// Adds a new `Concept` into the hierarchy.
    ///
    /// If `parentId` is `nil`, the concept is added as a root-level concept. Otherwise, it is inserted under the concept that has the matching `parentId`.
    ///
    /// - Parameters:
    ///   - concept: The `Concept` to add.
    ///   - parentId: The `id` of the parent `Concept`, or `nil` if adding as a root concept.
    ///   - concepts: An in-out array of root `Concept`s into which the new concept will be inserted.
    /// - Throws:
    ///   - `ConceptHierarchyError.invalidParentConcept` if the given `parentId` does not exist.
    ///   - `ConceptHierarchyError.maxDepthExceeded` if adding the concept exceeds the maximum allowed depth.
    ///   - Other validation errors might be thrown if the hierarchy is invalid.
    func addConceptToHierarchy(_ concept: Concept, parentId: UUID?, in concepts: inout [Concept]) throws
    
    /// Validates the integrity of a `Concept` hierarchy.
    ///
    /// Checks for:
    /// 1. **Circular references** (a concept cannot appear within its own ancestry).
    /// 2. **Duplicate concepts** (a concept `id` should not appear more than once in the same path).
    /// 3. **Depth violations** (exceeding a maximum depth limit).
    ///
    /// - Parameter concepts: The array of root `Concept`s to validate (including all sub-concepts).
    /// - Throws:
    ///   - `ConceptHierarchyError.circularReference` if a concept references itself in its ancestry.
    ///   - `ConceptHierarchyError.duplicateConceptInPath` if the same `Concept.id` is encountered more than once in the same path.
    ///   - `ConceptHierarchyError.maxDepthExceeded` if the hierarchy depth is beyond the supported maximum.
    func validateHierarchy(_ concepts: [Concept]) throws
    
    /// Calculates updated metadata for a `Concept` based on its position in the hierarchy.
    ///
    /// - Parameters:
    ///   - concept: The `Concept` whose metadata you want to update.
    ///   - parentPath: An array of `UUID`s representing the path of ancestor concepts leading to this one.
    ///   - depth: The current depth of the `Concept` in the hierarchy.
    /// - Returns:
    ///   A `ConceptMetadata` object containing the new depth and path for the specified `Concept`.
    func calculateUpdatedMetadata(for concept: Concept, parentPath: [UUID], depth: Int) -> ConceptMetadata
    
    /// Retrieves all root-level `Concept`s for the given `topicId`.
    ///
    /// A root-level concept is one that does not have a `parentConceptId`.
    ///
    /// - Parameter topicId: The `UUID` of the topic whose root concepts you want to retrieve.
    /// - Returns:
    ///   An array of `Concept`s that have no parent (an empty array if none are found).
    func getRootConcepts(for topicId: UUID) -> [Concept]
    
    /// Attempts to update an ancestor `Concept`, either in the provided hierarchy or in an external data source.
    ///
    /// If the ancestor is not found locally in the provided `concepts` array, an external lookup or update is attempted (e.g., from a database or repository).
    ///
    /// - Parameters:
    ///   - ancestor: The `Concept` representing the ancestor to update (with a valid `id`).
    ///   - concepts: An in-out array representing the current known hierarchy of `Concept`s.
    /// - Throws:
    ///   - `ConceptHierarchyError.conceptNotFound` if the ancestor cannot be found in either the local hierarchy or the external data source.
    func updateAncestor(_ ancestor: Concept, in concepts: inout [Concept]) throws
}

class DefaultConceptHierarchyService: ConceptHierarchyService {
    // MARK: - Properties
    private let maxDepth = 10
    private let topicRepository: TopicRepository
    
    // MARK: - Initialization
    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }
    
    // MARK: - Public Methods
    func findConceptInHierarchy(name: String, in concepts: [Concept]) -> Concept? {
        for concept in concepts {
            if concept.name.lowercased() == name.lowercased() {
                return concept
            }
            if let found = findConceptInHierarchy(name: name, in: concept.subConcepts) {
                return found
            }
        }
        return nil
    }
    
    func updateConceptInHierarchy(_ concept: Concept, in concepts: inout [Concept]) throws {
        if !updateConceptInHierarchyRecursive(concept, in: &concepts) {
            throw ConceptHierarchyError.conceptNotFound
        }
    }
    
    func addConceptToHierarchy(_ concept: Concept, parentId: UUID?, in concepts: inout [Concept]) throws {
        // Validate hierarchy before adding
        try validateHierarchy(concepts)
        
        if parentId == nil {
            // Add as root concept
            concepts.append(concept)
            return
        }
        
        guard let unwrappedParentId = parentId else {
            throw ConceptHierarchyError.invalidParentConcept
        }
        
        if try !addToParent(
            concepts: &concepts,
            concept: concept,
            parentId: unwrappedParentId,
            depth: 0,
            parentPath: []
        ) {
            throw ConceptHierarchyError.invalidParentConcept
        }
    }
    
    func validateHierarchy(_ concepts: [Concept]) throws {
        var seenIds = Set<UUID>()
        
        for concept in concepts {
            try validateConcept(concept, parentPath: [], seenIds: &seenIds)
        }
    }
    
    func calculateUpdatedMetadata(for concept: Concept, parentPath: [UUID], depth: Int) -> ConceptMetadata {
        ConceptMetadata(
            depth: depth,
            path: parentPath + [concept.id]
        )
    }
    
    func getRootConcepts(for topicId: UUID) -> [Concept] {
        guard let topic = topicRepository.topics.first(where: { $0.id == topicId }) else {
            return []
        }
        return topic.concepts.filter { $0.parentConceptId == nil }
    }
    
    func updateAncestor(_ ancestor: Concept, in concepts: inout [Concept]) throws {
        // First try to update in the current concepts array
        do {
            try updateConceptInHierarchy(ancestor, in: &concepts)
            return
        } catch {
            // If not found in current concepts, try to update in the topic repository
            guard let topicId = findTopicId(for: ancestor.id),
                  var topic = topicRepository.topics.first(where: { $0.id == topicId }) else {
                throw ConceptHierarchyError.conceptNotFound
            }
            
            var topicConcepts = topic.concepts
            try updateConceptInHierarchy(ancestor, in: &topicConcepts)
            topic.concepts = topicConcepts
            try topicRepository.updateTopic(topic)
        }
    }
    
    // MARK: - Private Helper Methods
    private func addToParent(
        concepts: inout [Concept],
        concept: Concept,
        parentId: UUID,
        depth: Int,
        parentPath: [UUID]
    ) throws -> Bool {
        for index in concepts.indices {
            if concepts[index].id == parentId {
                // Update metadata for the new concept
                var newConcept = concept
                newConcept.metadata = calculateUpdatedMetadata(
                    for: concept,
                    parentPath: parentPath + [concepts[index].id],
                    depth: depth + 1
                )
                
                // Validate depth
                if newConcept.metadata.depth >= maxDepth {
                    throw ConceptHierarchyError.maxDepthExceeded
                }
                
                concepts[index].subConcepts.append(newConcept)
                return true
            }
            
            var subConcepts = concepts[index].subConcepts
            if try addToParent(
                concepts: &subConcepts,
                concept: concept,
                parentId: parentId,
                depth: depth + 1,
                parentPath: parentPath + [concepts[index].id]
            ) {
                concepts[index].subConcepts = subConcepts
                return true
            }
        }
        return false
    }
    
    private func validateConcept(_ concept: Concept, parentPath: [UUID], seenIds: inout Set<UUID>) throws {
        // Check for circular references
        if parentPath.contains(concept.id) {
            throw ConceptHierarchyError.circularReference
        }
        
        // Check for duplicate concepts
        if seenIds.contains(concept.id) {
            throw ConceptHierarchyError.duplicateConceptInPath
        }
        seenIds.insert(concept.id)
        
        // Validate depth
        if concept.metadata.depth >= maxDepth {
            throw ConceptHierarchyError.maxDepthExceeded
        }
        
        // Recursively validate subconcepts
        for subconcept in concept.subConcepts {
            try validateConcept(subconcept, parentPath: parentPath + [concept.id], seenIds: &seenIds)
        }
    }
    
    private func findTopicId(for conceptId: UUID) -> UUID? {
        for topic in topicRepository.topics {
            if findConceptInTopicHierarchy(conceptId: conceptId, in: topic.concepts) {
                return topic.id
            }
        }
        return nil
    }
    
    private func findConceptInTopicHierarchy(conceptId: UUID, in concepts: [Concept]) -> Bool {
        for concept in concepts {
            if concept.id == conceptId {
                return true
            }
            if findConceptInTopicHierarchy(conceptId: conceptId, in: concept.subConcepts) {
                return true
            }
        }
        return false
    }
    
    private func updateConceptInHierarchyRecursive(_ concept: Concept, in concepts: inout [Concept]) -> Bool {
        for index in concepts.indices {
            if concepts[index].id == concept.id {
                concepts[index] = concept
                return true
            }
            var updatedSubConcepts = concepts[index].subConcepts
            if updateConceptInHierarchyRecursive(concept, in: &updatedSubConcepts) {
                concepts[index].subConcepts = updatedSubConcepts
                return true
            }
        }
        return false
    }
}


