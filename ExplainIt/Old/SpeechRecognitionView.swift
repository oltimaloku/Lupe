import SwiftUI

struct SpeechRecognitionView: View {
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    
    var body: some View {
        ZStack {
            // Galaxy animation background
            if speechRecognizer.isRecording {
                GalaxyView()
                    .edgesIgnoringSafeArea(.all)
            }

            // Main content
            VStack {
                Text(speechRecognizer.recognizedText)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                
                Button(action: {
                    speechRecognizer.toggleRecording()
                }) {
                    Text(speechRecognizer.isRecording ? "Stop Recording" : "Start Recording")
                        .padding()
                        .background(speechRecognizer.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear {
            speechRecognizer.requestAuthorization()
        }
    }
}

struct SpeechRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechRecognitionView()
    }
}

struct GalaxyView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black  // Set background color if needed

        // Create the emitter layer
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        // Create the particle cell
        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "sparkle")?.withTintColor(.white).cgImage
        cell.birthRate = 100
        cell.lifetime = 5.0
        cell.lifetimeRange = 2.0
        cell.velocity = 50
        cell.velocityRange = 20
        cell.emissionRange = CGFloat.pi * 2
        cell.spin = 2.0
        cell.spinRange = 3.0
        cell.scale = 0.01
        cell.scaleRange = 0.02
        cell.alphaSpeed = -0.2
        cell.color = UIColor.white.cgColor
        cell.redRange = 0.5
        cell.greenRange = 0.5
        cell.blueRange = 0.5

        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed for static emitter
    }
}
