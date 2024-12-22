//
//  OpenAIService.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-10.
//

import Foundation

enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
}

enum OpenAIError: Error {
    case invalidURL
    case noDataReceived
    case invalidResponseFormat
    case apiError(String)
}

class OpenAIService {
    private let baseURL = "https://api.openai.com/v1"
    
    static let shared = OpenAIService()
    
    private init () {}
    
    func chatCompletion(messages: [GPTMessage], model: String = "gpt-4o-mini") async throws -> GPTResponse {
        let endpoint = "/chat/completions"
        let payload = GPTChatPayload(model: model, messages: messages)
        return try await performRequest(endpoint: endpoint, payload: payload)
    }
    
    // Can add more OpenAI-specific requests here like:
    // func createImage(prompt: String) async throws -> ImageResponse { ... }
    // func createEmbedding(input: String) async throws -> EmbeddingResponse { ... }
    // func streamChatCompletion(messages: [GPTMessage]) async throws -> AsyncStream<GPTResponse> { ... }
    
    private func performRequest<T: Encodable, U: Decodable>(
        endpoint: String,
        payload: T
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.post.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(Secrets.openAIApiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(payload)
        print("Url request: \(urlRequest)")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponseFormat
        }
    
        guard 200...299 ~= httpResponse.statusCode else {
            throw OpenAIError.apiError("API returned error \(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "Unknown error")")
        }
        
        return try JSONDecoder().decode(U.self, from: data)
    }
}

// Supporting Types
struct GPTChatPayload: Encodable {
    let model: String
    let messages: [GPTMessage]
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: GPTMessage
    }
}

