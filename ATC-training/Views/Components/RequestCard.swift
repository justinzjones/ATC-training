import SwiftUI

struct RequestCard: View {
    let title: String  // e.g. "Your Request" or "Pilot Readback"
    let isCompleted: Bool
    @State private var isExpanded = true
    let elements: [String]
    let correctSequence: [String]  // Store the correct order
    @State private var selectedElements: [String] = []
    @State private var availableElements: [String]
    @State private var showError: Bool = false
    @State private var selectedAirport: Airport?
    let onSuccess: () -> Void
    let currentStep: Int
    
    init(title: String, isCompleted: Bool, pilotRequest: String, onSuccess: @escaping () -> Void, currentStep: Int) {
        self.title = title
        self.isCompleted = isCompleted
        self.correctSequence = pilotRequest.components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        self.elements = self.correctSequence
        
        // Create a new array and shuffle it thoroughly
        var shuffled = self.correctSequence
        for _ in 0...3 {
            shuffled.shuffle()
        }
        self.availableElements = shuffled
        self.onSuccess = onSuccess
        
        // Always start expanded and reset selected elements
        _isExpanded = State(initialValue: true)
        _selectedElements = State(initialValue: [])
        
        self.currentStep = currentStep
        
        print("🎲 New RequestCard initialized - Title: \(title)")
        print("🎲 Initial pill order: \(shuffled)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                if showError {
                    Text("Incorrect sequence. Try again!")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                // Selected elements
                FlowLayout(spacing: 8) {
                    ForEach(selectedElements.indices, id: \.self) { index in
                        PhraseElement(text: selectedElements[index], color: colorForPhrase(selectedElements[index]))
                            .onTapGesture {
                                removeElement(at: index)
                            }
                        }
                    
                    if selectedElements.count < elements.count {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .frame(width: 100, height: 36)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding(.vertical, 4)
                
                // Available elements
                FlowLayout(spacing: 8) {
                    ForEach(availableElements, id: \.self) { element in
                        PhraseElement(text: element, color: colorForPhrase(element))
                            .onTapGesture {
                                selectElement(element)
                            }
                    }
                }
                
                // Only show Submit button if not completed
                if !isCompleted {
                    Button(action: validateSequence) {
                        Text("Submit Request")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedElements.count == elements.count ? Color.blue : Color.gray)
                            )
                    }
                    .disabled(selectedElements.count != elements.count)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onChange(of: isCompleted) { completed in
            if completed {
                withAnimation(.spring()) {
                    isExpanded = false
                }
            }
        }
        .id("\(title)-\(correctSequence.joined(separator: ","))-\(currentStep)")  // Include step number in ID
    }
    
    private func selectElement(_ element: String) {
        selectedElements.append(element)
        availableElements.removeAll { $0 == element }
    }
    
    private func removeElement(at index: Int) {
        let element = selectedElements.remove(at: index)
        availableElements.append(element)
    }
    
    private func validateSequence() {
        let normalizedSelected = selectedElements.map { $0.trimmingCharacters(in: .whitespaces) }
        let normalizedCorrect = correctSequence.map { $0.trimmingCharacters(in: .whitespaces) }
        
        print("🎯 Validating sequence:")
        print("  Selected: \(normalizedSelected)")
        print("  Correct:  \(normalizedCorrect)")
        
        if normalizedSelected == normalizedCorrect {
            print("🎯 Sequence correct - calling onSuccess")
            withAnimation {
                showError = false
                isExpanded = false
                onSuccess()
            }
        } else {
            print("🎯 Sequence incorrect")
            withAnimation {
                showError = true
            }
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showError = false
                }
            }
        }
    }
    
    private func colorForPhrase(_ phrase: String) -> Color {
        // Check original template text rather than final content
        if phrase.contains("{{airport_name}}") || 
           (selectedAirport?.shortName != nil && phrase.contains(selectedAirport!.shortName)) { 
            return .purple  // Airport name
        }
        if phrase.contains("traffic") { return .orange }  // Traffic announcement
        if phrase.contains("{{call_sign}}") || phrase.contains("N") { return .blue }  // Callsign
        if phrase.contains("{{airport_location}}") || phrase.contains("ramp") || 
           phrase.contains("Ramp") { return .green }  // Location
        if phrase.contains("taxi") { return .red }  // Action
        if phrase.contains("{{runway number}}") || phrase.contains("runway") { return .yellow }  // Runway
        return .gray
    }
} 