import SwiftUI
import os.log

struct ExplainView: View {
    @StateObject private var speechRecognizer = WhisperTranscriptionService()
    @EnvironmentObject private var viewModel: ExplainViewModel
    @State private var userResponse: String = ""
    @State private var isEditing: Bool = false
    let onAnswerSubmitted: () -> Void
    
    private let logger = Logger(subsystem: "com.app.ExplainView", category: "UI")
    private let accentColor = Color(UIColor(red: 1.0, green: 87/255, blue: 87/255, alpha: 1))
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if let question = viewModel.currentQuestion {
                            // Question Text and Concepts
                            Text(question.text)
                                .heading()
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor.label))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(question.concepts, id: \.self) { concept in
                                        Text(concept)
                                            .font(Theme.Fonts.small)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Theme.accentColor.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            if userResponse.isEmpty {
                                Text("Tap to type your answer or use the microphone")
                            }
                            
                            // Response Input Area
                            TextEditor(text: $userResponse)
                                .font(Theme.Fonts.body)
                                .frame(minHeight: 150)
                                .padding(.horizontal, 24)
                                
                            
                            // Submit Button
                            if !userResponse.isEmpty {
                                Button(action: submitResponse) {
                                    HStack {
                                        Image(systemName: "paperplane.fill")
                                        Text("Submit Answer")
                                            .font(.custom("Georgia", size: 16))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                            }
                        } else {
                            Text("You've completed all questions!")
                                .heading()
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Spacer()
                
                // Voice Recording Button
                recordButton
                    .padding(.bottom, 20)
            }
            
            // Centered Orb View
            if speechRecognizer.isRecording || viewModel.isLoading {
                VStack {
                    OrbView(configuration: OrbConfiguration(
                        backgroundColors: [Theme.accentColor],
                        glowColor: Theme.accentColor,
                        coreGlowIntensity: 1.5,
                        speed: 120
                    ))
                    .frame(width: 120, height: 120)
                    
                    Text(speechRecognizer.isRecording ? "Listening..." : "Transcribing...")
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(Theme.accentColor)
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Question \(viewModel.currentQuestionIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: speechRecognizer.recognizedText) { newText in
            if !newText.isEmpty {
                userResponse = newText
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
    
    private var recordButton: some View {
        Button(action: handleRecordButton) {
            ZStack {
                Circle()
                    .fill(speechRecognizer.isRecording ? Color.red : Theme.accentColor)
                    .frame(width: 70, height: 70)
                    .shadow(color: speechRecognizer.isRecording ? Color.red.opacity(0.7) : Theme.accentColor.opacity(0.7), radius: 10, x: 0, y: 5)
                
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
            viewModel.saveResponse(for: question, text: userResponse)
            await viewModel.gradeResponse(
                question: question,
                text: userResponse
            )
            onAnswerSubmitted()
        }
    }
}

// ViewModifier for placeholder text in TextEditor
struct PlaceholderViewModifier: ViewModifier {
    let placeholder: () -> any View
    let shouldShow: Bool
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            if shouldShow {
                AnyView(placeholder())
            }
            content
        }
    }
}


