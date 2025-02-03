import SwiftUI
import AVFoundation

struct ATCResponseCard: View {
    let responseText: String
    @State private var isPlaying = false
    private let synthesizer = AVSpeechSynthesizer()
    
    private func formatSpeechText(_ text: String) -> String {
        var speechText = text
        
        // Replace callsigns (e.g., N8521R)
        if let callSignPattern = try? NSRegularExpression(pattern: "N\\d{2,4}[A-Z]{1,2}") {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = callSignPattern.matches(in: text, range: range)
            
            // Process matches in reverse to not affect other match positions
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let callSign = String(text[range])
                    var formatted = ""
                    for char in callSign {
                        if char.isNumber {
                            formatted += " \(char)"
                        } else {
                            switch char.uppercased() {
                            case "N": formatted += "November"
                            case "A": formatted += "Alpha"
                            case "B": formatted += "Bravo"
                            case "C": formatted += "Charlie"
                            case "D": formatted += "Delta"
                            case "E": formatted += "Echo"
                            case "F": formatted += "Foxtrot"
                            case "G": formatted += "Golf"
                            case "H": formatted += "Hotel"
                            case "I": formatted += "India"
                            case "J": formatted += "Juliet"
                            case "K": formatted += "Kilo"
                            case "L": formatted += "Lima"
                            case "M": formatted += "Mike"
                            case "O": formatted += "Oscar"
                            case "P": formatted += "Papa"
                            case "Q": formatted += "Quebec"
                            case "R": formatted += "Romeo"
                            case "S": formatted += "Sierra"
                            case "T": formatted += "Tango"
                            case "U": formatted += "Uniform"
                            case "V": formatted += "Victor"
                            case "W": formatted += "Whiskey"
                            case "X": formatted += "Xray"
                            case "Y": formatted += "Yankee"
                            case "Z": formatted += "Zulu"
                            default: formatted += String(char)
                            }
                        }
                        formatted += " "
                    }
                    speechText = speechText.replacingCharacters(in: range, with: formatted.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        
        // Replace runway numbers (e.g., "Runway 27")
        if let runwayPattern = try? NSRegularExpression(pattern: "Runway (\\d+)") {
            let range = NSRange(speechText.startIndex..<speechText.endIndex, in: speechText)
            let matches = runwayPattern.matches(in: speechText, range: range)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: speechText) {
                    let runway = String(speechText[range])
                    let numbers = runway.filter { $0.isNumber }
                    let spoken = numbers.map { String($0) }.joined(separator: " ")
                    speechText = speechText.replacingCharacters(in: range, with: "Runway \(spoken)")
                }
            }
        }
        
        return speechText
    }
    
    private func speakResponse() {
        let speechText = formatSpeechText(responseText)
        let components = speechText.components(separatedBy: ",")
        
        for (index, component) in components.enumerated() {
            let utterance = AVSpeechUtterance(string: component.trimmingCharacters(in: .whitespaces))
            
            if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-premium") {
                utterance.voice = voice
            }
            
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            
            if index < components.count - 1 {
                utterance.postUtteranceDelay = 0.3
            }
            
            synthesizer.speak(utterance)
        }
        
        isPlaying = true
        
        NotificationCenter.default.addObserver(
            forName: .didFinishSpeaking,
            object: synthesizer,
            queue: .main
        ) { _ in
            isPlaying = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title with radio icon and speaker
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("ATC Response")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Speaker button
                Button(action: {
                    if isPlaying {
                        synthesizer.stopSpeaking(at: .immediate)
                        isPlaying = false
                    } else {
                        speakResponse()
                    }
                }) {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            // Response text shows standard format
            Text(responseText)
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onDisappear {
            // Clean up when view disappears
            synthesizer.stopSpeaking(at: .immediate)
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// Extension to define the notification name
extension Notification.Name {
    static let didFinishSpeaking = Notification.Name("AVSpeechSynthesizerDidFinishSpeaking")
} 