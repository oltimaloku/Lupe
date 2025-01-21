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
            mainContent
            if speechRecognizer.isRecording || viewModel.isLoading {
                loadingOverlay
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
            setupInitialState()
        }
    }
    
    // MARK: - Main Content Components
    
    private var mainContent: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let question = viewModel.currentQuestion {
                        questionContent(question)
                    } else {
                        completionMessage
                    }
                }
            }
            Spacer()
            HStack(spacing: 30) {
                
                
                recordButton
                    .transition(.move(edge: .trailing))
                if !userResponse.isEmpty {
                    submitButton
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(20)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: !userResponse.isEmpty)
            
        }
    }
    
    private func questionContent(_ question: Question) -> some View {
        VStack(spacing: 20) {
            questionHeader(question)
            conceptsList(question)
            responseArea
            
            
        }
    }
    
    // MARK: - Question Components
    
    private func questionHeader(_ question: Question) -> some View {
        Text(question.text)
            .heading()
            .fontWeight(.bold)
            .foregroundColor(Color(UIColor.label))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            .padding(.top, 10)
    }
    
    private func conceptsList(_ question: Question) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(question.concepts, id: \.self) { concept in
                    conceptTag(concept)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func conceptTag(_ concept: String) -> some View {
        Text(concept)
            .font(Theme.Fonts.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accentColor.opacity(0.1))
            .cornerRadius(12)
    }
    
    // MARK: - Response Components
    
    private var responseArea: some View {
        ZStack(alignment: .center) {
            TextEditor(text: $userResponse)
                .font(Theme.Fonts.body)
                .frame(minHeight: UIScreen.main.bounds.height * 0.4)
                .padding(.horizontal, 24)
            
            if userResponse.isEmpty || userResponse == "" {
                Text("Tap to type your answer or use the microphone")
                    .font(Theme.Fonts.body)
                    .foregroundColor(.gray.opacity(0.5))
                    .allowsHitTesting(false) // This lets touches pass through to the TextEditor
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: submitResponse) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Evaluate")
                    .font(.custom("Georgia", size: 16)).bold()
            }
            .frame(maxWidth: 150)
            .padding()
            .background(accentColor)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
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
    
    private var completionMessage: some View {
        Text("You've completed all questions!")
            .heading()
            .fontWeight(.bold)
    }
    
    // MARK: - Recording Button
    
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
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        speechRecognizer.requestAuthorization()
        if let question = viewModel.currentQuestion,
           let savedResponse = viewModel.getResponse(for: question.id) {
            userResponse = savedResponse
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

// MARK: - Supporting Types

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

#Preview {
    NavigationView {
        ExplainView(onAnswerSubmitted: {})
            .environmentObject(ExplainViewModel.createForPreview())
    }
}
