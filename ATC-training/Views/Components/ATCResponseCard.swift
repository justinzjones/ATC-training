import SwiftUI
import AVFoundation
import Combine

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    @Binding var isPlaying: Bool
    
    init(isPlaying: Binding<Bool>) {
        _isPlaying = isPlaying
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPlaying = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}

struct ATCResponseCard: View {
    let responseText: String
    @State private var isPlaying = false
    @State private var speechDelegate: SpeechDelegate?
    private let synthesizer = AVSpeechSynthesizer()
    
    private func formatSpeechText(_ text: String) -> String {
        var speechText = text
        let phraseology = loadPhraseology()
        let numbersDict = phraseology?.numbers ?? [:]
        let designators = phraseology?.runway.designators ?? [:]
        let phoneticAlphabet = phraseology?.phoneticAlphabet ?? []

        // 1. Process callsigns first (most specific pattern)
        processCallsigns(&speechText, numbersDict: numbersDict, phoneticAlphabet: phoneticAlphabet)
        
        // 2. Process runway designators with explicit "Runway" prefix
        processRunwayDesignators(&speechText, numbersDict: numbersDict, designators: designators)
        
        // 3. Process standalone runway numbers
        processStandaloneRunwayNumbers(&speechText, numbersDict: numbersDict)
        
        return speechText
    }

    private func processCallsigns(_ text: inout String, numbersDict: [String: String], phoneticAlphabet: [String]) {
        let pattern = "N\\d{2,4}[A-Z]{1,2}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text) else { continue }
            let callsign = String(text[range])
            
            var formatted = ""
            for char in callsign {
                let charStr = String(char)
                if let numberWord = numbersDict[charStr] {
                    formatted += " \(numberWord)"
                } else if let phonetic = phoneticAlphabet.first(where: { $0.hasPrefix(charStr.uppercased()) }) {
                    formatted += " \(phonetic)"
                } else {
                    formatted += " \(charStr)"
                }
            }
            
            text = text.replacingCharacters(in: range, with: formatted.trimmingCharacters(in: .whitespaces))
        }
    }

    private func processRunwayDesignators(_ text: inout String, numbersDict: [String: String], designators: [String: String]) {
        let pattern = "(?i)\\b(Runway )?(\\d{1,2})([LRC])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard match.numberOfRanges >= 4,
                  let fullRange = Range(match.range, in: text),
                  let numberRange = Range(match.range(at: 2), in: text),
                  let designatorRange = Range(match.range(at: 3), in: text) else { continue }
            
            let numbers = String(text[numberRange])
            let designator = String(text[designatorRange])
            
            // Convert numbers
            let numbersSpoken = numbers.compactMap { numbersDict[String($0)] }.joined(separator: " ")
            
            // Get designator pronunciation
            let designatorSpoken = designators[designator] ?? designator
            
            text = text.replacingCharacters(
                in: fullRange,
                with: "Runway \(numbersSpoken) \(designatorSpoken)"
            )
        }
    }

    private func processStandaloneRunwayNumbers(_ text: inout String, numbersDict: [String: String]) {
        let pattern = "\\b(\\d{1,2})\\b(?![A-Za-z])" // Avoid overlapping with callsigns
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text) else { continue }
            let numbers = String(text[range])
            let numbersSpoken = numbers.compactMap { numbersDict[String($0)] }.joined(separator: " ")
            
            text = text.replacingCharacters(in: range, with: numbersSpoken)
        }
    }
    
    private func speakResponse() {
        speechDelegate = SpeechDelegate(isPlaying: $isPlaying)
        synthesizer.delegate = speechDelegate
        
        let speechText = formatSpeechText(responseText)
        let components = speechText.components(separatedBy: ",")
        
        synthesizer.stopSpeaking(at: .immediate)
        
        for (index, component) in components.enumerated() {
            let utterance = AVSpeechUtterance(string: component.trimmingCharacters(in: .whitespaces))
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            
            if index < components.count - 1 {
                utterance.postUtteranceDelay = 0.3
            }
            
            synthesizer.speak(utterance)
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
            synthesizer.stopSpeaking(at: .immediate)
            speechDelegate = nil
        }
    }
    
    // Add helper function to load phraseology data
    private func loadPhraseology() -> Phraseology? {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(PhraseologyWrapper.self, from: data)
        else {
            return nil
        }
        return wrapper.phraseology
    }
}

// Extension to define the notification name
extension Notification.Name {
    static let didFinishSpeaking = Notification.Name("AVSpeechSynthesizerDidFinishSpeaking")
} 
