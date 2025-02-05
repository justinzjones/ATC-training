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
    
    @Published private(set) var currentStep: Int = 1
    @Published private(set) var totalSteps: Int = 1
    private var communications: [Communication] = []
    
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
            let comms = try await ContentLoader.shared.loadCommunications()
            
            // Filter communications for this lesson
            communications = comms.filter {
                $0.lessonID == "VFR-\(lesson.subsection.replacingOccurrences(of: " ", with: ""))-\(lesson.lessonNumber)"
            }.sorted { $0.stepNumber < $1.stepNumber }
            
            totalSteps = communications.count
            
            // Load first step
            guard let firstComm = communications.first else {
                throw ContentError.lessonNotFound
            }
            
            currentCommunication = firstComm
            
            // Select appropriate airport
            let airports = try await ContentLoader.shared.loadAirports()
            let availableAirports = airports.filter { $0.isControlled == lesson.isControlled }
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
            situationText = firstComm.situationText
                .replacingOccurrences(of: "{{airport_name}}", with: airport.name)
                .replacingOccurrences(of: "{{airport location}}", with: randomFBO.location)
                .replacingOccurrences(of: "{{atis_information}}", with: atisInfo)
            
            // Replace placeholders in pilot request
            pilotRequest = firstComm.pilotRequest?
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
    
    private func advanceToNextStep() {
        print("📖 Advancing to step \(currentStep + 1) of \(totalSteps)")
        
        // Clear all state before advancing
        withAnimation(.easeInOut) {
            pilotRequest = nil
            atcResponse = nil
            pilotReadback = nil
            currentState = .initial
        }
        
        // Advance step counter
        currentStep += 1
        currentCommunication = communications[currentStep - 1]
        
        // Load new step content with existing airport and callsign
        guard let airport = selectedAirport,
              let randomFBO = airport.fbos.randomElement() else {
            return
        }
        
        // Generate runway number once for consistency
        let runwayNumber = getRandomRunwayNumber(from: airport)
        
        // Process situation text
        situationText = (currentCommunication?.situationText ?? "")
            .replacingOccurrences(of: "{{airport_name}}", with: airport.name)
            .replacingOccurrences(of: "{{airport location}}", with: randomFBO.location)
            .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
            .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
        
        // Process pilot request if exists
        pilotRequest = currentCommunication?.pilotRequest.map { text in
            text.replacingOccurrences(of: "{{airport_name}}", with: airport.shortName)
                .replacingOccurrences(of: "{{call_sign}}", with: lessonCallSign ?? "")
                .replacingOccurrences(of: "{{airport_location}}", with: randomFBO.location)
                .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
                .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
        }
        
        // Process ATC response if exists
        atcResponse = currentCommunication?.atcResponse.map { text in
            text.replacingOccurrences(of: "{{airport_name}}", with: airport.shortName)
                .replacingOccurrences(of: "{{call_sign}}", with: lessonCallSign ?? "")
                .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
                .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
        }
        
        // Process pilot readback if exists
        pilotReadback = currentCommunication?.pilotReadback.map { text in
            text.replacingOccurrences(of: "{{airport_name}}", with: airport.shortName)
                .replacingOccurrences(of: "{{call_sign}}", with: lessonCallSign ?? "")
                .replacingOccurrences(of: "{{runway_number}}", with: runwayNumber)
                .replacingOccurrences(of: "{{runway number}}", with: runwayNumber)
        }
        
        // Process taxiway placeholders
        let taxiway = getRandomTaxiway(from: airport) ?? "Juliet" // Fallback to a default taxiway
        let phoneticTaxiway = formatTaxiway(taxiway)
        
        // Update all text elements with the taxiway
        situationText = situationText.replacingOccurrences(of: "{{taxi_way}}", with: phoneticTaxiway)
        pilotRequest = pilotRequest?.replacingOccurrences(of: "{{taxi_way}}", with: phoneticTaxiway)
        atcResponse = atcResponse?.replacingOccurrences(of: "{{taxi_way}}", with: phoneticTaxiway)
        pilotReadback = pilotReadback?.replacingOccurrences(of: "{{taxi_way}}", with: phoneticTaxiway)
        
        // Start the next step in the appropriate state
        withAnimation(.easeInOut) {
            currentState = currentCommunication?.pilotRequest != nil ? .pilotRequest : .atcResponse
        }
        
        print("📖 New step state initialized - State: \(currentState)")
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
            print("📖 Readback complete")
            // Check if there are more steps before completing
            if currentStep < totalSteps {
                print("📖 Moving to next step")
                advanceToNextStep()
            } else {
                print("📖 All steps complete - showing summary")
                withAnimation(.easeInOut) {
                    currentState = .complete
                }
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
        var speechText = text
        
        // Format callsigns (N1234AB -> "November one two three four alpha bravo")
        if let callSignPattern = try? NSRegularExpression(pattern: "N\\d{2,4}[A-Z]{1,2}") {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = callSignPattern.matches(in: text, range: range)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let callSign = String(text[range])
                    var formatted = ""
                    
                    // Process each character according to standardized pronunciations
                    for char in callSign {
                        if char.isNumber {
                            // Use standardized number pronunciation
                            let number = String(char)
                            switch number {
                            case "0": formatted += "zero "
                            case "1": formatted += "one "
                            case "2": formatted += "two "
                            case "3": formatted += "three "
                            case "4": formatted += "four "
                            case "5": formatted += "five "
                            case "6": formatted += "six "
                            case "7": formatted += "seven "
                            case "8": formatted += "eight "
                            case "9": formatted += "niner "
                            default: formatted += "\(char) "
                            }
                        } else {
                            // Use phonetic alphabet for letters
                            switch char.uppercased() {
                            case "N": formatted += "November "
                            case "A": formatted += "Alpha "
                            // ... rest of phonetic alphabet
                            default: formatted += String(char)
                            }
                        }
                    }
                    speechText = speechText.replacingCharacters(in: range, with: formatted.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        
        // Format runway numbers (27L -> "two seven left", 9 -> "niner")
        if let runwayPattern = try? NSRegularExpression(pattern: "Runway \\d{1,2}[LRC]?") {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = runwayPattern.matches(in: text, range: range)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let runway = String(text[range])
                    var formatted = "Runway "
                    
                    // Extract numbers and designator
                    let components = runway.components(separatedBy: .whitespaces)[1]
                    let numbers = components.filter { $0.isNumber }
                    let designator = components.filter { !$0.isNumber }
                    
                    // Format numbers according to standard
                    for char in numbers {
                        switch char {
                        case "0": formatted += "zero "
                        case "1": formatted += "one "
                        case "2": formatted += "two "
                        case "3": formatted += "three "
                        case "4": formatted += "four "
                        case "5": formatted += "five "
                        case "6": formatted += "six "
                        case "7": formatted += "seven "
                        case "8": formatted += "eight "
                        case "9": formatted += "niner "
                        default: formatted += "\(char) "
                        }
                    }
                    
                    // Add designator if present
                    if !designator.isEmpty {
                        switch designator {
                        case "L": formatted += "left"
                        case "R": formatted += "right"
                        case "C": formatted += "center"
                        default: break
                        }
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
        print("🎯 Pilot readback successful")
        if currentStep < totalSteps {
            print("🎯 Moving to next step (\(currentStep + 1) of \(totalSteps))")
            advanceToNextStep()
        } else {
            print("🎯 All steps complete - showing summary")
            withAnimation(.easeInOut) {
                currentState = .complete
            }
        }
    }
} 