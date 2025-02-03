import Foundation
import SwiftUI

@MainActor
final class LessonDetailViewModel: ObservableObject {
    enum LessonState: Int, Comparable {
        case initial = 0
        case pilotRequest = 1
        case atcResponse = 2
        case pilotReadback = 3
        case complete = 4
        
        static func < (lhs: LessonState, rhs: LessonState) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    @Published private(set) var situationText: String = ""
    @Published private(set) var pilotRequest: String?
    @Published private(set) var atcResponse: String?
    @Published private(set) var pilotReadback: String?
    @Published private(set) var currentState: LessonState = .initial {
        didSet {
            logStateTransition(from: oldValue, to: currentState)
        }
    }
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let lesson: Lesson
    private var selectedAirport: Airport?
    private var currentCommunication: Communication?
    private var lessonCallSign: String?  // Store callsign for the lesson
    
    init(lesson: Lesson) {
        self.lesson = lesson
        print("📖 LessonDetailView: Initialized for lesson \(lesson.id)")
    }
    
    private func generateCallSign() -> String {
        // Format: N + 2-4 numbers + 1-2 letters
        let numbers = String((100...9999).randomElement() ?? 0)
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"  // Excluding I and O to avoid confusion
        let letterCount = Bool.random() ? 1 : 2
        let randomLetters = String((0..<letterCount).map { _ in letters.randomElement() ?? "X" })
        return "N\(numbers)\(randomLetters)"
    }
    
    private func getRandomRunwayNumber(from airport: Airport) -> String {
        guard let runway = airport.runways.randomElement() else { return "XX" }
        // Split "16/34" into ["16", "34"] and randomly select one
        let directions = runway.identifier.split(separator: "/")
        return String(directions.randomElement() ?? "XX")
    }
    
    private func getRandomAtisLetter() async throws -> String {
        let alphabet = try await ContentLoader.shared.loadPhoneticAlphabet()
        return alphabet.randomElement() ?? "Information not available"
    }
    
    private func formatCallSign(_ callSign: String) -> String {
        // Convert N788X to "November seven eight eight xray"
        var formatted = ""
        for char in callSign {
            if char.isNumber {
                formatted += " \(char)"
            } else {
                switch char.uppercased() {
                case "N": formatted += "November"
                case "A": formatted += "Alpha"
                case "B": formatted += "Bravo"
                // ... rest of phonetic alphabet ...
                case "X": formatted += "Xray"
                case "Y": formatted += "Yankee"
                case "Z": formatted += "Zulu"
                default: formatted += String(char)
                }
            }
            formatted += " "
        }
        return formatted.trimmingCharacters(in: .whitespaces)
    }
    
    private func formatRunway(_ runway: String) -> String {
        // Convert "17L" to "one seven left"
        var formatted = ""
        var numbers = ""
        var suffix = ""
        
        for char in runway {
            if char.isNumber {
                numbers += String(char)
            } else {
                switch char.uppercased() {
                case "L": suffix = "left"
                case "R": suffix = "right"
                case "C": suffix = "center"
                default: break
                }
            }
        }
        
        // Format numbers individually
        for digit in numbers {
            formatted += "\(digit) "
        }
        
        if !suffix.isEmpty {
            formatted += suffix
        }
        
        return formatted.trimmingCharacters(in: .whitespaces)
    }
    
    private func getRandomTaxiway(from airport: Airport) -> String? {
        airport.taxiways.randomElement()?.identifier
    }
    
    private func formatTaxiway(_ identifier: String) -> String {
        // Convert "A" to "Alpha", "B1" to "Bravo One", etc.
        var formatted = ""
        for char in identifier {
            if char.isNumber {
                formatted += " \(char)"
            } else {
                switch char.uppercased() {
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
                case "N": formatted += "November"
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
        return formatted.trimmingCharacters(in: .whitespaces)
    }
    
    private func getOrGenerateCallSign() -> String {
        if let existingCallSign = lessonCallSign {
            return existingCallSign
        }
        lessonCallSign = generateCallSign()
        return lessonCallSign!
    }
    
    func loadContent() async {
        print("📖 LessonDetailView: Loading content for lesson \(lesson.id)")
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load communications and airports
            async let communications = ContentLoader.shared.loadCommunications()
            async let airports = ContentLoader.shared.loadAirports()
            
            let (comms, airportList) = try await (communications, airports)
            
            print("📖 Looking for communication with lessonID: VFR-\(lesson.subsection)-\(lesson.lessonNumber)")
            print("📖 Available communications: \(comms.map { $0.lessonID })")
            
            // Find the communication for this lesson
            guard let communication = comms.first(where: { 
                let expectedId = "VFR-\(lesson.subsection.replacingOccurrences(of: " ", with: ""))-\(lesson.lessonNumber)"
                let matches = $0.lessonID == expectedId && $0.stepNumber == 1
                print("📖 Checking \($0.lessonID) against \(expectedId): \(matches)")
                return matches
            }) else {
                throw ContentError.lessonNotFound
            }
            
            // Store the communication for state management
            currentCommunication = communication
            
            // Select appropriate airport
            let availableAirports = airportList.filter { $0.isControlled == lesson.isControlled }
            print("📖 Found \(availableAirports.count) matching airports")
            
            guard let airport = availableAirports.randomElement() else {
                throw ContentError.noAirportsAvailable
            }
            
            // Select random FBO location
            guard let randomFBO = airport.fbos.randomElement() else {
                throw ContentError.custom("No FBO locations available for this airport")
            }
            
            selectedAirport = airport
            
            // Generate values once
            lessonCallSign = generateCallSign()  // Generate once
            let runwayNumber = getRandomRunwayNumber(from: airport)
            let atisInfo = try await getRandomAtisLetter()
            
            // Replace placeholders in situation text
            situationText = communication.situationText
                .replacingOccurrences(of: "{{airport_name}}", with: airport.name)
                .replacingOccurrences(of: "{{airport location}}", with: randomFBO.location)
                .replacingOccurrences(of: "{{atis_information}}", with: atisInfo)
            
            // Replace placeholders in pilot request
            pilotRequest = communication.pilotRequest?
                .replacingOccurrences(of: "{{airport_name}}", with: airport.shortName)
                .replacingOccurrences(of: "{{call_sign}}", with: lessonCallSign!)  // Use stored callsign
                .replacingOccurrences(of: "{{airport_location}}", with: randomFBO.location)
                .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
                .replacingOccurrences(of: "{{atis_information}}", with: atisInfo)
            
            // Advance to pilot request state
            currentState = .pilotRequest
            
            print("📖 LessonDetailView: Content loaded with airport: \(airport.name), FBO: \(randomFBO.location), Callsign: \(lessonCallSign!), Runway: \(runwayNumber), ATIS: \(atisInfo)")
        } catch let decodingError as DecodingError {
            print("❌ LessonDetailView: Decoding error - \(decodingError)")
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context)")
            case .typeMismatch(let type, let context):
                print("Type '\(type)' mismatch: \(context)")
            case .valueNotFound(let type, let context):
                print("Value of type '\(type)' not found: \(context)")
            @unknown default:
                print("Unknown decoding error")
            }
            self.error = decodingError
        } catch {
            print("❌ LessonDetailView: Error loading content - \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func advanceToNextState() {
        guard let communication = currentCommunication else {
            print("📖 No communication found")
            return
        }
        
        print("📖 Current state: \(currentState)")
        print("📖 Communication structure:")
        print("  - Has ATC Response: \(communication.atcResponse != nil)")
        print("  - Has Pilot Readback: \(communication.pilotReadback != nil)")
        
        switch currentState {
        case .initial:
            currentState = .pilotRequest
            print("📖 Advanced to pilot request")
            
        case .pilotRequest:
            if communication.atcResponse != nil {
                currentState = .atcResponse
                print("📖 Advanced to ATC response")
                
                // Process ATC response and readback...
                if let airport = selectedAirport {
                    let runwayNumber = getRandomRunwayNumber(from: airport)
                    
                    // Process ATC response with runway
                    atcResponse = communication.atcResponse?
                        .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
                        .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
                    
                    // Process readback with same runway
                    if let readbackText = communication.pilotReadback {
                        pilotReadback = readbackText
                            .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
                            .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
                    }
                    
                    // Process other placeholders
                    atcResponse = processPlaceholders(in: atcResponse ?? "")
                    pilotReadback = processPlaceholders(in: pilotReadback ?? "")
                }
            } else {
                print("📖 No ATC response - completing lesson")
                withAnimation(.easeInOut) {
                    currentState = .complete
                }
            }
            
        case .atcResponse:
            if communication.pilotReadback != nil {
                print("📖 Advanced to pilot readback")
                currentState = .pilotReadback
            } else {
                print("📖 No readback - completing lesson")
                withAnimation(.easeInOut) {
                    currentState = .complete
                }
            }
            
        case .pilotReadback:
            print("📖 Readback complete - completing lesson")
            withAnimation(.easeInOut) {
                print("📖 Transitioning from readback to complete state")
                currentState = .complete
                print("📖 New state after transition: \(currentState)")
            }
            
        case .complete:
            print("📖 Lesson already complete")
            break
        }
        
        print("📖 New state: \(currentState)")
    }
    
    private func formatDisplayText(_ text: String) -> String {
        var displayText = text
        
        // Format taxiways to phonetic
        if let airport = selectedAirport,
           let taxiway = getRandomTaxiway(from: airport) {
            displayText = displayText.replacingOccurrences(
                of: "{{taxi_way}}", 
                with: formatTaxiway(taxiway)
            )
        }
        
        return displayText
    }
    
    private func formatSpeechText(_ text: String) -> String {
        // Convert N1867KX to "November one eight six seven kilo x-ray"
        // Convert Runway 27L to "Runway two seven left"
        // Keep taxiway phonetic (already converted in display text)
        var speechText = text
        
        // Format callsigns for speech
        if let callSignPattern = try? NSRegularExpression(pattern: "N\\d{2,4}[A-Z]{1,2}") {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = callSignPattern.matches(in: text, range: range)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let callSign = String(text[range])
                    var formatted = ""
                    for char in callSign {
                        if char.isNumber {
                            formatted += " \(char)"  // Speak each number individually
                        } else {
                            switch char.uppercased() {
                            case "N": formatted += "November"
                            case "A": formatted += "Alpha"
                            // ... rest of phonetic alphabet ...
                            default: formatted += String(char)
                            }
                        }
                        formatted += " "
                    }
                    speechText = speechText.replacingCharacters(in: range, with: formatted.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        
        return speechText
    }
    
    private func processPlaceholders(in text: String) -> String {
        guard let airport = selectedAirport,
              let randomFBO = airport.fbos.randomElement() else {
            return text
        }
        
        var processedText = text
            .replacingOccurrences(of: "{{airport_name}}", with: airport.shortName)
            .replacingOccurrences(of: "{{call_sign}}", with: lessonCallSign ?? "")  // Use stored callsign
            .replacingOccurrences(of: "{{airport_location}}", with: randomFBO.location)
            .replacingOccurrences(of: "{{runway number}}", with: getRandomRunwayNumber(from: airport))
        
        // Format taxiways to phonetic for both display and speech
        if let taxiway = getRandomTaxiway(from: airport) {
            let phoneticTaxiway = formatTaxiway(taxiway)  // Convert A to Alpha, etc.
            processedText = processedText.replacingOccurrences(
                of: "{{taxi_way}}", 
                with: phoneticTaxiway
            )
        }
        
        return processedText
    }
    
    private func colorForPhrase(_ phrase: String) -> Color {
        if phrase.contains("{{runway number}}") || phrase.contains("runway") { 
            return .orange
        }
        return .gray
    }
    
    private func logStateTransition(from oldState: LessonState, to newState: LessonState) {
        print("📖 State transition: \(oldState) -> \(newState)")
        if newState == .complete {
            print("📖 Lesson completed - showing summary view")
        }
    }
    
    func completeReadback() {
        print("🎯 Pilot readback successful - completing lesson")
        withAnimation(.easeInOut) {
            currentState = .complete
        }
    }
} 