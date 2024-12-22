import SwiftUI
import os.log

struct ExplainView: View {
    @StateObject private var speechRecognizer = WhisperTranscriptionService()
    @EnvironmentObject private var viewModel: ExplainViewModel
    @State private var userResponse: String = ""
    @State private var isEditing: Bool = false
    let onAnswerSubmitted: () -> Void
    
    private let logger = Logger(subsystem: "com.app.ExplainView", category: "UI")
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if let question = viewModel.currentQuestion {
                        // Question Text
                        Text(question.text)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.label))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        
                        // Concepts
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(question.concepts, id: \.self) { concept in
                                    Text(concept)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Response Input Area
                        VStack(spacing: 16) {
                            if isEditing {
                                TextEditor(text: $userResponse)
                                    .frame(height: 150)
                                    .padding(8)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                Text(userResponse.isEmpty ? "Tap to enter your answer or use the microphone" : userResponse)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Edit/Done Button
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Done" : "Edit")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Submit Button
                        if !userResponse.isEmpty {
                            Button(action: submitResponse) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Answer")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView("Analyzing your response...")
                                .foregroundColor(Color(UIColor.label))
                                .padding(.top, 20)
                        }
                    } else {
                        Text("You've completed all questions!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .onAppear {
                    speechRecognizer.requestAuthorization()
                    if let question = viewModel.currentQuestion,
                       let savedResponse = viewModel.getResponse(for: question.id) {
                        userResponse = savedResponse
                    }
                }
            }
            
            Spacer()
            
            // Voice Recording Button
            recordButton
                .padding(.bottom, 20)
        }
        .navigationTitle("Question \(viewModel.currentQuestionIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: speechRecognizer.recognizedText) { newText in
            if !newText.isEmpty {
                userResponse = newText
                isEditing = true
            }
        }
    }
    
    private var recordButton: some View {
        Button(action: handleRecordButton) {
            ZStack {
                Circle()
                    .fill(speechRecognizer.isRecording ? Color.red : Color.blue)
                    .frame(width: 70, height: 70)
                    .shadow(color: speechRecognizer.isRecording ? Color.red.opacity(0.7) : Color.blue.opacity(0.7), radius: 10, x: 0, y: 5)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func handleRecordButton() {
        logger.debug("Microphone button tapped, recording state: \(speechRecognizer.isRecording)")
        speechRecognizer.toggleRecording()
        
        if !speechRecognizer.isRecording {
            logger.info("Recording stopped, transcription will be available for editing")
        } else {
            logger.info("Starting new recording")
            speechRecognizer.resetTranscript()
        }
    }
    
    private func submitResponse() {
        guard let question = viewModel.currentQuestion else { return }
        
        Task {
            // Save the response
            viewModel.saveResponse(for: question, text: userResponse)
            
            // Grade the response
            await viewModel.gradeResponse(
                question: question,
                text: userResponse
            )
            
            // Navigate to feedback view
            onAnswerSubmitted()
        }
    }
}
