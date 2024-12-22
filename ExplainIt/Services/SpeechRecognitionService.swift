import SwiftUI
import Speech
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized.")
                @unknown default:
                    fatalError("Unknown authorization status.")
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        stopRecording()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            print("Speech recognition is not available")
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate the format before using it
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            print("Invalid recording format: \(recordingFormat)")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        // Stop the audio engine first
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Cancel the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End and nil out the recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        isRecording = false
    }
    
    // **Add this method**
    func resetTranscript() {
        recognizedText = ""
    }
}
