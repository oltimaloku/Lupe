
import SwiftUI
import SwiftWhisper
import AVFoundation
import os.log

class WhisperTranscriptionService: NSObject, ObservableObject, AVAudioRecorderDelegate, WhisperDelegate {
    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published private(set) var isUsingCoreML: Bool = false
    @Published var transcriptionProgress: Double = 0
    var onTranscriptionComplete: ((String) -> Void)?
    
    private var whisper: Whisper?
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession!
    private let logger = Logger(subsystem: "com.app.WhisperTranscription", category: "Transcription")
    
    override init() {
        super.init()
        logger.info("Initializing WhisperTranscriptionService")
        checkCoreMLStatus()
        setupWhisper()
        setupAudioSession()
    }
    
    private func checkCoreMLStatus() {
        if let coreMLURL = Bundle.main.url(forResource: "ggml-base.en-encoder", withExtension: "mlmodelc") {
            isUsingCoreML = true
            logger.info("✅ CoreML model found at: \(coreMLURL.path)")
        } else {
            isUsingCoreML = false
            logger.warning("⚠️ CoreML model not found - transcription may be slower")
        }
    }
    
    private func setupWhisper() {
        logger.info("Setting up Whisper model")
        guard let modelURL = Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin") else {
            logger.error("❌ Failed to find Whisper model file")
            return
        }
        
        logger.info("📦 Model URL: \(modelURL.path)")
        
        do {
            let params = WhisperParams.default
            params.language = .english
            params.translate = false
            params.no_context = true
            params.single_segment = false
            params.duration_ms = 0
            params.print_progress = true
            logger.info("⚙️ Whisper params configured")
            
            whisper = try Whisper(fromFileURL: modelURL, withParams: params)
            whisper?.delegate = self
            logger.info("✅ Successfully initialized Whisper model")
        } catch {
            logger.error("❌ Failed to initialize Whisper: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                logger.error("Error details - Domain: \(nsError.domain), Code: \(nsError.code)")
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                    logger.error("Underlying error: \(underlyingError)")
                }
            }
        }
    }
    
    private func setupAudioSession() {
        logger.info("Setting up audio session")
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            logger.info("✅ Successfully set up audio session")
        } catch {
            logger.error("❌ Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func requestAuthorization() {
        logger.info("Requesting microphone authorization")
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.logger.info("✅ Microphone permission granted")
                } else {
                    self?.logger.error("❌ Microphone permission denied")
                }
            }
        }
    }
    
    func toggleRecording() {
        logger.info("Toggle recording called. Current state: \(self.isRecording)")
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        logger.info("Starting recording")
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recorded_audio.wav")
        logger.debug("Audio file path: \(audioFilename.path)")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            logger.info("✅ Successfully started recording")
        } catch {
            logger.error("❌ Failed to start recording: \(error.localizedDescription)")
            isRecording = false
        }
    }
    
    private func stopRecording() {
        logger.info("Stopping recording")
        audioRecorder?.stop()
        isRecording = false
        if let url = audioRecorder?.url {
            logger.debug("Audio file URL: \(url.path)")
            transcribeAudio(from: url)
        } else {
            logger.error("❌ No audio URL available after recording")
        }
    }
    
    // MARK: - WhisperDelegate Methods
    
    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        DispatchQueue.main.async {
            self.transcriptionProgress = progress
            self.logger.info("📊 Transcription progress: \(progress * 100)%")
        }
    }
    
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        DispatchQueue.main.async {
            self.logger.info("🔄 Processing new segments at index: \(index)")
            let text = segments.map(\.text).joined(separator: " ")
            self.recognizedText = text
        }
    }
    
    func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
        let text = segments.map(\.text).joined(separator: " ")
        self.logger.info("✅ Completed transcription with \(segments.count) segments")
        DispatchQueue.main.async {
            self.recognizedText = text
            self.onTranscriptionComplete?(text)
        }
    }
    
    func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
        logger.error("❌ Whisper error: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            logger.error("""
                Error details:
                Domain: \(nsError.domain)
                Code: \(nsError.code)
                Description: \(nsError.localizedDescription)
                User Info: \(nsError.userInfo)
                """)
            
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                logger.error("Underlying error: \(underlyingError)")
            }
        }
    }
    
    func transcribeAudio(from audioURL: URL) {
        logger.info("Starting transcription from URL: \(audioURL.lastPathComponent)")
        extractTextFromAudio(audioURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcription):
                    self?.logger.info("✅ Transcription successful: \(transcription)")
                    self?.recognizedText = transcription
                    self?.onTranscriptionComplete?(transcription)
                case .failure(let error):
                    self?.logger.error("❌ Transcription failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func extractTextFromAudio(_ audioURL: URL, completionHandler: @escaping (Result<String, Error>) -> Void) {
        logger.info("Extracting text from audio")
        guard let whisper = whisper else {
            logger.error("❌ Whisper model not initialized")
            completionHandler(.failure(NSError(domain: "WhisperError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Whisper model not initialized"])))
            return
        }
        
        let logger = self.logger
        
        convertAudioFileToPCMArray(fileURL: audioURL) { [weak self] result in
            switch result {
            case .success(let pcmArray):
                logger.info("Successfully converted audio to PCM array with \(pcmArray.count) samples")
                
                Task {
                    do {
                        let segments = try await whisper.transcribe(audioFrames: pcmArray)
                        logger.info("✅ Successfully transcribed audio into \(segments.count) segments")
                        let transcribedText = segments.map(\.text).joined()
                        
                        await MainActor.run {
                            completionHandler(.success(transcribedText))
                        }
                    } catch {
                        logger.error("❌ Whisper transcription failed: \(error.localizedDescription)")
                        await MainActor.run {
                            completionHandler(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                logger.error("❌ PCM conversion failed: \(error.localizedDescription)")
                completionHandler(.failure(error))
            }
        }
    }
    
    private func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
        logger.info("Converting audio file to PCM array")
        logger.info("📂 Input file: \(fileURL.path)")
        
        do {
            let file = try AVAudioFile(forReading: fileURL)
            logger.info("📊 Audio file details:")
            logger.info("   - Length: \(file.length) frames")
            logger.info("   - Sample rate: \(file.fileFormat.sampleRate) Hz")
            logger.info("   - Channels: \(file.fileFormat.channelCount)")
            
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: 16000,
                                           channels: 1,
                                           interleaved: false) else {
                logger.error("❌ Failed to create audio format")
                completionHandler(.failure(NSError(domain: "AudioFormatError",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"])))
                return
            }
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                              frameCapacity: AVAudioFrameCount(file.length)) else {
                logger.error("❌ Failed to create audio buffer")
                completionHandler(.failure(NSError(domain: "BufferError",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])))
                return
            }
            
            try file.read(into: buffer)
            logger.info("📥 Read \(buffer.frameLength) frames into buffer")
            
            if let floatChannelData = buffer.floatChannelData {
                let frameLength = Int(buffer.frameLength)
                var samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
                
                // Log audio statistics
                let maxAmplitude = samples.map(abs).max() ?? 0
                let avgAmplitude = samples.map(abs).reduce(0, +) / Float(samples.count)
                logger.info("""
                    📊 Audio statistics:
                    - Samples: \(samples.count)
                    - Max amplitude: \(maxAmplitude)
                    - Avg amplitude: \(avgAmplitude)
                    """)
                
                // Normalize if needed
                if maxAmplitude > 1.0 {
                    logger.info("⚠️ Normalizing audio samples (max amplitude > 1.0)")
                    samples = samples.map { $0 / maxAmplitude }
                }
                
                logger.info("✅ Successfully converted audio to \(samples.count) PCM samples")
                completionHandler(.success(samples))
            } else {
                logger.error("❌ Failed to get float channel data from buffer")
                completionHandler(.failure(NSError(domain: "AudioDataError",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to get audio data"])))
            }
        } catch {
            logger.error("❌ Audio file reading failed: \(error.localizedDescription)")
            if let avError = error as? AVError {
                logger.error("AVFoundation error: \(avError.localizedDescription)")
                logger.error("Error code: \(avError.code.rawValue)")
            }
            completionHandler(.failure(error))
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func resetTranscript() {
        logger.info("🔄 Resetting transcription")
        recognizedText = ""
        transcriptionProgress = 0
    }
}
